#!/usr/bin/env python3
"""Deny Bash commands that could print a Terraform secret file into the transcript.

A PreToolUse hook for the Bash tool. The Read deny rules in settings.json reach Bash only through
the file commands Claude Code recognizes, such as cat, head and sed, so this covers what they miss:
any other command that names a secret file or a glob matching one, Terraform subcommands that print
state or outputs, `terraform fmt -diff` over a directory and recursive searches that sweep the
files up.

It matches command text, so it is a best-effort guard rather than a security boundary; the Bash
sandbox is the one the operating system enforces. Known gaps: a name that reaches a reader through
a pipe, xargs, find -exec or a script on disk; a wrapper option that takes a value, as in
`nice -n 10 grep -r`; and a command shlex cannot parse, which is allowed unless its text names a
secret file.
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
ADVICE = (
    "Terraform secret files (*.tfvars, *.tfstate and the Terraform CLI credential files) must stay "
    "out of the transcript, and a mere mention of one in a command is enough to trigger this "
    "check. Search with the Grep tool where available or with grep on named files that hold no "
    "secrets, change files with the Edit or Write tool, or ask the user to run the command."
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
            "permissionDecisionReason": f"{reason} {ADVICE}",
        }
    }


def check(command, cwd):
    try:
        text, bodies = prepare(command)
        segments = split_segments(text)
    except ValueError:
        if SECRET.search(command):
            return "Could not parse a command that names a Terraform secret file."
        return None

    for tokens in segments:
        if tokens[0] in ("cd", "pushd"):
            cwd = change_directory(tokens, cwd)
            continue
        reason = check_segment(tokens, bodies, cwd)
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


def check_segment(tokens, bodies, cwd):
    tokens, own_bodies = split_bodies(tokens, bodies)
    words = unwrap(strip_redirections(tokens))
    name = os.path.basename(words[0]) if words else ""

    if name in SHELLS and (shell_script(words) is not None or own_bodies):
        return check_shell(words, own_bodies, cwd)
    if name == "terraform":
        return check_terraform(words[1:])
    if not names_only(name, words) and names_secret(name, words, tokens, own_bodies, cwd):
        return f"`{name or 'an assignment'}` names a Terraform secret file or a glob matching one."
    if is_recursive_search(name, words):
        return check_search_roots(name, words, cwd)
    return None


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


def check_shell(words, bodies, cwd):
    script = shell_script(words)
    scripts = bodies if script is None else [script, *bodies]
    return next(filter(None, (check(each, cwd) for each in scripts)), None)


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
        return f"`terraform {' '.join(printer)}` prints state or outputs, secrets included."
    if rest[:1] == ["fmt"] and fmt_diff_reaches_secrets(rest[1:]):
        return "`terraform fmt -diff` prints tfvars files unless given only .tf files."
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


def names_secret(name, words, tokens, bodies, cwd):
    patterns = search_patterns(name, words)
    scanned = [token for token in tokens if token not in patterns]
    if INTERPRETER.fullmatch(name):
        scanned += bodies
    return any(SECRET.search(token) for token in expand_globs(scanned, cwd))


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
            return (
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
