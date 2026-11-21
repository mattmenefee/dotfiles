#!/usr/bin/env python3
"""Deny Bash commands that could print a Terraform secret file or Rails credentials.

A PreToolUse hook for the Bash tool. The Read deny rules in settings.json reach Bash only through
the file commands Claude Code recognizes, such as cat, head and sed, so this covers what they miss:
any other command that names a Terraform secret file or a glob matching one, Terraform subcommands
that print state or outputs, `terraform fmt -diff` over a directory and recursive searches that
sweep the files up.

The deny rules also stop the Rails commands that decrypt credentials, but not Ruby that reads them
itself. This denies a command that runs Ruby through `ruby`, `jruby`, `irb`, `rails runner` or
`rails console`, behind `bundle exec` or `spring`, when its text or a heredoc body reaches the
credentials API or a key file, or when it names a file, as an argument, a redirection or a
substitution, whose contents do. It denies `ssh`, `docker`, `docker-compose`, `kubectl` and `podman`
on the same text, since they hand their arguments or stdin to code elsewhere. A command that runs no
Ruby and only mentions the API, such as a search or a commit message, is allowed. Any other command
that names a key file is denied, as for Terraform secret files.

It matches command text, so it is a best-effort guard rather than a security boundary; the Bash
sandbox is the one the operating system enforces. Known gaps: a Terraform secret file name that
reaches a reader through a pipe, xargs, find -exec or a script on disk; a wrapper option that takes
a value, as in `nice -n 10 grep -r`; a command shlex cannot parse, which is allowed unless its text
names a secret file or the credentials API; Ruby that reaches credentials indirectly, such as
through `send`, a built string or a file a script loads; and Ruby run by a program not listed here.
Known false positives: a command that runs unrelated Ruby while it also mentions the credentials API
or names a file that does, as in `grep … && rails runner …` or `ruby -Itest test/x_test.rb` on a
test that stubs credentials, where `bin/rails test` runs the same test; and a remote command whose
text only names the API or a key file, such as a remote search or a `docker build --secret`.
"""

import fnmatch
import glob
import json
import os
import re
import shlex
import subprocess
import sys

SECRET = re.compile(
    r"(?:\.tfvars(?:\.json)?|\.tfstate(?:\.[\w.]+)?|credentials\.tfrc\.json|\.terraformrc)"
    r"(?![\w.])"
)
# Commands that print names, metadata, counts or their own arguments, never file contents
NAME_ONLY_COMMANDS = {"[", "echo", "ls", "printf", "stat", "test", "wc"}
GIT_NAME_ONLY_SUBCOMMANDS = {"check-ignore", "ls-files", "status"}
GIT_VALUE_OPTIONS = {"-C", "-c"}
# find prints names unless one of these runs a command on what it finds
FIND_ACTIONS = {"-exec", "-execdir", "-ok", "-okdir"}
TERRAFORM_PRINTERS = (("console",), ("output",), ("show",), ("state", "pull"))
GREP_COMMANDS = {"egrep", "fgrep", "ggrep", "grep"}
SEARCH_COMMANDS = {"ack", "ag", "rg"}
# Searches that skip gitignored files unless told otherwise
IGNORE_HONORING_COMMANDS = {"ag", "rg"}
IGNORE_OVERRIDES = {"-U", "-u", "-uu", "-uuu", "--skip-vcs-ignores", "--unrestricted"}
SHELLS = {"bash", "sh", "zsh"}
# A heredoc body is literal stdin text, so a filename in it reaches the file only when a shell or
# one of these runs the body as code
INTERPRETER = re.compile(r"python[\d.]*|ruby|irb|node|nodejs|deno|bun|perl|php|osascript|lua")
WRAPPERS = {
    "builtin",
    "command",
    "env",
    "exec",
    "nice",
    "nohup",
    "sudo",
    "time",
    "timeout",
    "xargs",
}
PATTERN_FLAGS = {"-e", "-f", "--file", "--regexp"}
# Skipped for speed: these grow large and never hold Terraform files. .terraform is walked, since
# its terraform.tfstate can hold backend credentials.
SKIPPED_DIRECTORIES = {".bundle", ".git", ".venv", "log", "node_modules", "tmp", "vendor"}
# A walk this long is denied rather than finished, since the hook must answer quickly
MAX_DIRECTORIES = 10000
OPERATOR = re.compile(r"[();&|<>]+")
HEREDOC = re.compile(r"(?<!<)<<(?!<)-?\s*(['\"]?)([A-Za-z_][A-Za-z0-9_]*)\1")
MARKER = re.compile(r"\0(\d+)\0")
GLOB_CHARACTERS = re.compile(r"[*?[]")
ASSIGNMENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*=")
RECURSIVE_FLAGS = {"--dereference-recursive", "--directories=recurse", "--recursive"}
SHORT_RECURSIVE_FLAG = re.compile(r"-[A-Za-z0-9]*[rR][A-Za-z0-9]*")
TERRAFORM_ADVICE = (
    "Terraform secret files (*.tfvars, *.tfstate and the Terraform CLI credential files) must stay "
    "out of the transcript, and a mere mention of one in a command is enough to trigger this "
    "check. Search with the Grep tool where available or with grep on named files that hold no "
    "secrets, change files with the Edit or Write tool, or ask the user to run the command."
)
# The files holding the keys that decrypt Rails credentials
KEY_FILE = r"master\.key\b|credentials/[\w.-]+\.key\b"
# Ruby that reaches decrypted Rails credentials or the key that decrypts them
CREDENTIALS_CODE = re.compile(
    rf"\.(?:credentials|encrypted|secret_key_base)\b|Encrypted(?:Configuration|File)\b|{KEY_FILE}"
)
KEY_FILES = re.compile(KEY_FILE)
RUBY_COMMANDS = {"irb", "jruby", "ruby"}
# rails subcommands that run Ruby given as an argument, on stdin or in a script file
RAILS_CODE_SUBCOMMANDS = {"c", "console", "r", "runner"}
# Programs that hand their arguments or stdin to a shell or Ruby on another host or in a container
REMOTE_COMMANDS = {"docker", "docker-compose", "kubectl", "podman", "ssh"}
# Pieces of a word that may name a file: an argument, a `-r./x.rb` value or a `$(cat x.rb)` path
FILE_CANDIDATE = re.compile(r"[^\s'\"$()<>|;&=`]+")
MAX_SCRIPT_BYTES = 1_000_000
# Files a Ruby-running command names are read for credential code, up to this many
MAX_SCRIPTS = 50
CREDENTIALS_ADVICE = (
    "Decrypted Rails credentials and the keys that decrypt them must stay out of the transcript. "
    "Read code that uses them with the Grep tool or grep, change it with the Edit or Write tool, "
    "or ask the user to run the command."
)


def main():
    try:
        payload = json.load(sys.stdin)
        command = payload["tool_input"]["command"]
        cwd = payload.get("cwd") or os.getcwd()
    except (ValueError, KeyError, TypeError):
        return 0

    reason = check(command, cwd)
    if reason:
        print(json.dumps(denial(reason)))
    return 0


def denial(reason):
    return {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }


def with_terraform_advice(reason):
    return f"{reason} {TERRAFORM_ADVICE}"


def with_credentials_advice(reason):
    return f"{reason} {CREDENTIALS_ADVICE}"


def check(command, cwd, outer_mention=False):
    """Return why the command is denied, or None.

    outer_mention carries a credentials mention from an enclosing command into a `sh -c` script,
    which may run Ruby on what the outer command pipes or feeds it.
    """
    try:
        text, bodies = prepare(command)
        segments = split_segments(text)
    except ValueError:
        if SECRET.search(command):
            return with_terraform_advice(
                "Could not parse a command that names a Terraform secret file."
            )
        if CREDENTIALS_CODE.search(command):
            return with_credentials_advice(
                "Could not parse a command that names the Rails credentials API."
            )
        return None

    # Searched after prepare drops comment lines, so a comment that names the API changes nothing
    mentions_credentials = outer_mention or any(
        CREDENTIALS_CODE.search(part) for part in [text, *bodies]
    )
    named = [token for tokens in segments for token in tokens]
    for tokens in segments:
        if tokens[0] in ("cd", "pushd"):
            cwd = change_directory(tokens, cwd)
            continue
        reason = check_segment(tokens, bodies, cwd, mentions_credentials, named)
        if reason:
            return reason
    return None


def prepare(command):
    """Return the command as one line, with each heredoc body moved to a list."""
    bodies = []
    lines = attach_heredocs(command.replace("\\\n", "").split("\n"), bodies)
    return " ; ".join(lines), bodies


def attach_heredocs(lines, bodies):
    """Drop comment lines and put a numbered marker for each heredoc body after its operator."""
    kept, queue = [], iter(lines)
    for line in queue:
        if line.lstrip().startswith("#"):
            continue
        matches = list(HEREDOC.finditer(line))
        markers = []
        for match in matches:
            bodies.append(read_body(queue, match.group(2)))
            markers.append(f" \0{len(bodies) - 1}\0 ")
        for match, marker in reversed(list(zip(matches, markers))):
            line = line[: match.end()] + marker + line[match.end() :]
        kept.append(line)
    return kept


def read_body(lines, terminator):
    body = []
    for line in lines:
        if line.strip() == terminator:
            break
        body.append(line)
    return "\n".join(body)


def split_segments(text):
    lexer = shlex.shlex(text, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    lexer.commenters = ""
    segments, current = [], []
    for token in lexer:
        if OPERATOR.fullmatch(token) and not set(token) & set("<>"):
            segments.append(current)
            current = []
        else:
            current.append(token)
    segments.append(current)
    return [segment for segment in segments if segment]


def change_directory(tokens, cwd):
    target = next((token for token in tokens[1:] if token == "-" or token[:1] != "-"), "~")
    return cwd if target == "-" else resolve(target, cwd)


def resolve(path, cwd):
    return os.path.normpath(os.path.join(cwd, os.path.expanduser(os.path.expandvars(path))))


def check_segment(tokens, bodies, cwd, mentions_credentials, named):
    tokens, own_bodies = split_bodies(tokens, bodies)
    words = unwrap(strip_redirections(tokens))
    name = os.path.basename(words[0]) if words else ""

    if name in SHELLS and (shell_script(words) is not None or own_bodies):
        return check_shell(words, own_bodies, cwd, mentions_credentials)
    reason = check_credentials(words, mentions_credentials, named, cwd)
    if reason:
        return reason
    if name == "terraform":
        return check_terraform(words[1:])
    if not names_only(name, words):
        if names_secret(name, words, tokens, own_bodies, cwd, SECRET):
            return with_terraform_advice(
                f"`{name or 'an assignment'}` names a Terraform secret file or a glob matching one."
            )
        if names_secret(name, words, tokens, own_bodies, cwd, KEY_FILES):
            return with_credentials_advice(
                f"`{name or 'an assignment'}` names a Rails credentials key file or a glob "
                "matching one."
            )
    if is_recursive_search(name, words):
        return check_search_roots(name, words, cwd)
    return None


def check_credentials(words, mentions_credentials, named, cwd):
    """Deny Ruby that reads Rails credentials, in the command's text or a file it names."""
    launched = strip_launchers(words)
    program = os.path.basename(launched[0]) if launched else ""
    if program in REMOTE_COMMANDS:
        if mentions_credentials:
            return with_credentials_advice(
                f"`{program}` would run code that reads Rails credentials elsewhere."
            )
        return None
    runner = ruby_runner(launched)
    if not runner:
        return None
    if mentions_credentials:
        return with_credentials_advice(f"`{runner}` would run Ruby that reads Rails credentials.")
    if any(script_reads_credentials(path) for path in named_files(named, cwd)):
        return with_credentials_advice(
            f"`{runner}` would run Ruby alongside a file that reads Rails credentials."
        )
    return None


def strip_launchers(words):
    """Return the words past a leading `bundle exec` or `spring`, which run the next command."""
    rest = list(words)
    if rest and os.path.basename(rest[0]) == "bundle" and rest[1:2] == ["exec"]:
        rest = rest[2:]
    if rest and os.path.basename(rest[0]) == "spring":
        rest = rest[1:]
    return rest


def ruby_runner(words):
    """Return the name of the Ruby-running command the words start, or None."""
    name = os.path.basename(words[0]) if words else ""
    if name in RUBY_COMMANDS:
        return name
    if name == "rails" and words[1:2] and words[1] in RAILS_CODE_SUBCOMMANDS:
        return f"rails {words[1]}"
    return None


def named_files(tokens, cwd):
    """Return the existing files the tokens name, as arguments, redirections or substitutions."""
    paths = []
    for token in tokens:
        for candidate in FILE_CANDIDATE.findall(token):
            if candidate.startswith("-"):
                candidate = candidate[2:]
            path = resolve(candidate, cwd) if candidate else ""
            if path and path not in paths and os.path.isfile(path):
                paths.append(path)
    return paths[:MAX_SCRIPTS]


def script_reads_credentials(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as script:
            return CREDENTIALS_CODE.search(script.read(MAX_SCRIPT_BYTES)) is not None
    except OSError:
        return False


def split_bodies(tokens, bodies):
    """Return the tokens without heredoc markers, and the bodies those markers stand for."""
    found = [bodies[int(index)] for token in tokens for index in MARKER.findall(token)]
    visible = [MARKER.sub("", token) for token in tokens]
    return [token for token in visible if token], found


def strip_redirections(tokens):
    words, skip = [], False
    for token in tokens:
        if skip:
            skip = False
        elif OPERATOR.fullmatch(token):
            skip = True
        else:
            words.append(token)
    return words


def unwrap(words):
    words = list(words)
    while words:
        head = os.path.basename(words[0])
        if ASSIGNMENT.match(words[0]):
            words.pop(0)
        elif head in WRAPPERS:
            words.pop(0)
            while words and words[0].startswith("-"):
                words.pop(0)
            if head == "timeout" and words:
                words.pop(0)
        else:
            break
    return words


def check_shell(words, bodies, cwd, mentions_credentials):
    script = shell_script(words)
    scripts = bodies if script is None else [script, *bodies]
    return next(filter(None, (check(each, cwd, mentions_credentials) for each in scripts)), None)


def shell_script(words):
    """Return the script a `sh -c` style invocation runs, or None for any other invocation."""
    for index, word in enumerate(words[1:], start=1):
        if re.fullmatch(r"-[A-Za-z]*c[A-Za-z]*", word):
            return words[index + 1] if index + 1 < len(words) else None
    return None


def check_terraform(arguments):
    rest = subcommand(arguments)
    printer = next((p for p in TERRAFORM_PRINTERS if tuple(rest[: len(p)]) == p), None)
    if printer:
        return with_terraform_advice(
            f"`terraform {' '.join(printer)}` prints state or outputs, secrets included."
        )
    if rest[:1] == ["fmt"] and fmt_diff_reaches_secrets(rest[1:]):
        return with_terraform_advice(
            "`terraform fmt -diff` prints tfvars files unless given only .tf files."
        )
    return None


def subcommand(arguments, value_options=frozenset()):
    """Return the arguments from the subcommand on, past any global options."""
    rest = list(arguments)
    while rest and rest[0].startswith("-"):
        rest = rest[2:] if rest[0] in value_options else rest[1:]
    return rest


def fmt_diff_reaches_secrets(arguments):
    if not any(word.lstrip("-").startswith("diff") for word in arguments):
        return False
    files = [word for word in arguments if not word.startswith("-")]
    return not files or not all(file.endswith(".tf") for file in files)


def names_only(name, words):
    if name in NAME_ONLY_COMMANDS:
        return True
    if name == "find":
        return not FIND_ACTIONS & set(words)
    if name == "git":
        rest = subcommand(words[1:], GIT_VALUE_OPTIONS)
        return bool(rest) and rest[0] in GIT_NAME_ONLY_SUBCOMMANDS
    return False


def names_secret(name, words, tokens, bodies, cwd, pattern):
    patterns = search_patterns(name, words)
    scanned = [token for token in tokens if token not in patterns]
    if INTERPRETER.fullmatch(name):
        scanned += bodies
    return any(pattern.search(token) for token in expand_globs(scanned, cwd))


def search_patterns(name, words):
    """Return the words a search takes as its pattern, which name no file it reads."""
    if name not in GREP_COMMANDS | SEARCH_COMMANDS:
        return set()
    flagged = {words[i + 1] for i, word in enumerate(words[:-1]) if word in ("-e", "--regexp")}
    if flagged or PATTERN_FLAGS & set(words):
        return flagged
    return set([word for word in words[1:] if not word.startswith("-")][:1])


def expand_globs(tokens, cwd):
    names = list(tokens)
    for token in tokens:
        if GLOB_CHARACTERS.search(token) and "\n" not in token:
            names += glob.glob(resolve(token, cwd))
    return names


def is_recursive_search(name, words):
    if name in SEARCH_COMMANDS:
        return True
    return name in GREP_COMMANDS and any(recursive_flag(word) for word in words[1:])


def recursive_flag(word):
    return word in RECURSIVE_FLAGS or SHORT_RECURSIVE_FLAG.fullmatch(word) is not None


def search_roots(words, cwd):
    """Return the directories a search reads: its existing directory arguments, else cwd."""
    positional = [word for word in words[1:] if not word.startswith("-")]
    if positional and not PATTERN_FLAGS & set(words):
        positional.pop(0)
    existing = [resolve(word, cwd) for word in positional if os.path.exists(resolve(word, cwd))]
    if not existing:
        return [cwd]
    return [path for path in existing if os.path.isdir(path)]


def check_search_roots(name, words, cwd):
    reads = reader(name, words)
    for root in search_roots(words, cwd):
        if holds_secret(root, reads):
            return with_terraform_advice(
                f"`{name}` would search {root}, which holds a Terraform secret file it would read "
                "or is too large to check."
            )
    return None


def reader(name, words):
    """Return a test of whether the search reads a file, given the filters it honors."""
    includes = [word.split("=", 1)[1] for word in words if word.startswith("--include=")]
    honors_ignores = name in IGNORE_HONORING_COMMANDS and not any(
        word in IGNORE_OVERRIDES or word.startswith("--no-ignore") for word in words
    )

    def reads(path):
        base = os.path.basename(path)
        if includes and not any(fnmatch.fnmatch(base, pattern) for pattern in includes):
            return False
        return not (honors_ignores and git_ignored(path))

    return reads


def git_ignored(path):
    try:
        result = subprocess.run(
            ["git", "-C", os.path.dirname(path), "check-ignore", "-q", path],
            capture_output=True,
            check=False,
        )
    except OSError:
        return False
    return result.returncode == 0


def holds_secret(root, reads):
    for visited, (directory, subdirectories, files) in enumerate(os.walk(root), start=1):
        if visited > MAX_DIRECTORIES:
            return True
        if any(SECRET.search(file) and reads(os.path.join(directory, file)) for file in files):
            return True
        subdirectories[:] = [name for name in subdirectories if name not in SKIPPED_DIRECTORIES]
    return False


if __name__ == "__main__":
    sys.exit(main())
