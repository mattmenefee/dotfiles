#!/usr/bin/env python3
"""Print each changed block that a greedy refill would change.

Reads "path<TAB>first-last" rows, as changed-lines.sh prints them, on standard input, and runs from
the repository root, where those paths resolve. For every Markdown paragraph, list item, block
quote, YAML folded scalar or run of line comments that holds a changed line, it reports a line over
the limit that holds more than one unit, a line that could take the first word of the line after it
and a line that splits link text or a code span the next line could hold whole.

Usage: changed-lines.sh [path...] | unfilled-blocks.py --limit <columns> [path...]

Named paths, files or directories, limit the report to those files, and one that matches no row is
named on standard error. Markdown is measured in UTF-16 code units, as markdownlint counts, and
everything else in characters. Empty output with exit status 0 means every changed block is already
filled; exit status 1 means a file or row could not be read, so some blocks went unchecked.
"""

import argparse
import fnmatch
import os
import re
import sys
from collections import defaultdict

MARKDOWN = (".md", ".markdown", ".mdx")
YAML = (".yml", ".yaml")
WORKING_DOCUMENTS = ("*local-review*.md", "*DOC-REVIEW*.md", "*PLAN.md", "*HANDOFF.md")
LEADERS = {
    "//": (".js", ".mjs", ".cjs", ".ts", ".tsx", ".jsx", ".go", ".rs", ".c", ".h", ".cc", ".cpp",
           ".java", ".kt", ".swift", ".scss"),
    "--": (".sql", ".lua", ".hs"),
    ";": (".el", ".lisp", ".clj"),
}
# A tool directive right after the comment leader; merging one into prose would disable it
DIRECTIVE = re.compile(
    r"(rubocop:|shellcheck\s+(disable|enable|source|shell)|frozen_string_literal:|"
    r"eslint-(disable|enable)|yamllint\s+(disable|enable)|markdownlint-(disable|enable)|"
    r"noqa\b|type:\s*ignore|@ts-|prettier-ignore)"
)
ENCODING_COOKIE = re.compile(r"-\*-")
# Doc tags whose text is code or a signature, so their lines are never refilled
FIXED_TAGS = re.compile(r"@(example|overload|!)")
LIST_MARKER = re.compile(r"\s*([-*+]|\d+[.)])\s")
FOLDED_KEY = re.compile(
    r"""(\s*)(- )?(?:[\w.-]+|"[^"]*"|'[^']*'):\s*>[1-9]?[-+]?[1-9]?(?:\s+#.*)?\s*$"""
)
LINK_DEFINITION = re.compile(r"\s*\[[^\]]+\]:\s")
QUOTE = re.compile(r"\s*((?:>\s?)+)")
FENCE = re.compile(r"(`{3,}|~{3,})")
# A word that would open a new Markdown block if it started a continuation line
BLOCK_OPENER = re.compile(r"([-*+]|\d+[.)])(\s|$)|#|>|\||<|```|~~~")
# A whole line that Markdown reads as a setext underline or a thematic break
WHOLE_LINE_OPENER = re.compile(r"(=+|-+|([*_-])(\s*\2){2,})\s*$")
SETEXT_UNDERLINE = re.compile(r"(=+|-+)\s*$")


def width(text, markdown):
    return len(text.encode("utf-16-le")) // 2 if markdown else len(text)


def split_unit(text):
    """Split text into its first unbreakable unit and the rest.

    A unit runs to the first space outside a code span and outside link text, so neither is ever
    broken across lines.
    """
    i, depth = 0, 0
    while i < len(text):
        char = text[i]
        if char == "`":
            run = len(text[i:]) - len(text[i:].lstrip("`"))
            close = text.find("`" * run, i + run)
            i = close + run if close != -1 else i + run
            continue
        if char == "[":
            depth += 1
        elif char == "]" and depth:
            depth -= 1
        elif char == " " and not depth:
            break
        i += 1
    return text[:i], text[i:].lstrip(" ")


def open_unit(text):
    """Return where text's unclosed link text or code span begins, or None when none is open."""
    i, opened = 0, []
    while i < len(text):
        char = text[i]
        if char == "`":
            run = len(text[i:]) - len(text[i:].lstrip("`"))
            close = text.find("`" * run, i + run)
            if close == -1:
                return opened[0] if opened else i
            i = close + run
            continue
        if char == "[":
            opened.append(i)
        elif char == "]" and opened:
            opened.pop()
        i += 1
    return opened[0] if opened else None


def leader_pattern(path):
    """Match a line comment's indent and leader, accepting a run such as ;; or /// and //!.

    A run of # stays out, since ### opens a Markdown heading in a heredoc far more often than it
    leads a comment.
    """
    extension = os.path.splitext(path)[1].lower()
    leader = next((lead for lead, exts in LEADERS.items() if extension in exts), "#")
    run = re.escape(leader)
    if leader != "#":
        run += re.escape(leader[-1]) + "*" + ("!?" if leader == "//" else "")
    return re.compile(r"(\s*)(" + run + r")( |$)")


class Blocks:
    """Collects blocks as lists of (line number, line, content start) tuples."""

    def __init__(self):
        self.done = []
        self.current = []

    def add(self, number, line, start):
        self.current.append((number, line, start))

    def close(self):
        if self.current:
            self.done.append(self.current)
        self.current = []


def markdown_blocks(lines):
    blocks = Blocks()
    fence = None
    html_end = None
    front = lines[:1] == ["---"]
    folded = None
    depth = 0
    block_indent = 0
    for number, line in enumerate(lines, 1):
        if front:
            if number > 1 and line.strip() == "---":
                front = False
                blocks.close()
            elif number > 1:
                folded = yaml_line(blocks, number, line, folded)
            continue
        quote = QUOTE.match(line)
        prefix = quote.end() if quote else 0
        inner = line[prefix:]
        stripped = inner.strip()
        indent = len(inner) - len(inner.lstrip())
        if fence:
            if re.fullmatch(re.escape(fence[0]) + "{%d,}\\s*" % len(fence), stripped):
                fence = None
            continue
        if html_end:
            if html_end == "-->" and "-->" in line or html_end == "blank" and not stripped:
                html_end = None
            continue
        line_depth = quote.group(1).count(">") if quote else 0
        if blocks.current and line_depth != depth:
            blocks.close()
        depth = line_depth
        opening = FENCE.match(stripped)
        if opening:
            blocks.close()
            fence = opening.group(1)
            continue
        if stripped.startswith("<!--"):
            blocks.close()
            html_end = None if "-->" in stripped else "-->"
            continue
        if stripped.startswith("<"):
            # Only an HTML block that opens a paragraph runs to the next blank line
            html_end = None if blocks.current else "blank"
            blocks.close()
            continue
        if blocks.current and SETEXT_UNDERLINE.match(stripped):
            # The line above is a heading, not prose
            blocks.current.pop()
            blocks.close()
            continue
        # Indented code cannot interrupt a paragraph, so only a line that opens a block starts one
        indented_code = not blocks.current and indent >= 4 and not LIST_MARKER.match(inner)
        if (not stripped or stripped.startswith(("#", "|")) or LINK_DEFINITION.match(inner)
                or indented_code or WHOLE_LINE_OPENER.match(stripped)):
            blocks.close()
            continue
        marker = LIST_MARKER.match(inner)
        if blocks.current and (marker or indent < block_indent):
            blocks.close()
        if not blocks.current:
            block_indent = indent
        start = prefix + (marker.end() if marker else indent)
        blocks.add(number, line, start)
        if inner.endswith("  ") or inner.endswith("\\"):
            blocks.close()
    blocks.close()
    return blocks.done


def yaml_line(blocks, number, line, folded):
    """Add a YAML line to a folded scalar's block; return the column of the scalar's key or None."""
    indent = len(line) - len(line.lstrip())
    if folded is not None and not line.strip():
        # A blank line separates the scalar's paragraphs without ending it
        blocks.close()
        return folded
    if folded is not None and indent > folded:
        blocks.add(number, line, indent)
        return folded
    blocks.close()
    key = FOLDED_KEY.match(line)
    return len(key.group(1)) + len(key.group(2) or "") if key else None


def comment_blocks(lines, path):
    blocks = Blocks()
    pattern = leader_pattern(path)
    yaml = os.path.splitext(path)[1].lower() in YAML
    folded = None
    mode = None
    list_text = 0
    key = None
    for number, line in enumerate(lines, 1):
        indent = len(line) - len(line.lstrip())
        if yaml and folded is not None and (not line.strip() or indent > folded):
            # A folded scalar's text, even one that looks like a comment
            folded = yaml_line(blocks, number, line, folded)
            key = None
            continue
        match = pattern.match(line)
        text = line[match.end():] if match else ""
        if (not match or line.startswith("#!") or DIRECTIVE.match(text.lstrip())
                or ENCODING_COOKIE.search(line)):
            blocks.close()
            mode = None
            key = None
            folded = yaml_line(blocks, number, line, None) if yaml else None
            continue
        folded = None
        line_key = (match.group(1), match.group(2))
        if not text.strip():
            blocks.close()
            mode = None
            continue
        if blocks.current and line_key != key:
            blocks.close()
            mode = None
        extra = len(text) - len(text.lstrip())
        marker = LIST_MARKER.match(text)
        if marker or text.lstrip().startswith("@"):
            blocks.close()
            if not marker and FIXED_TAGS.match(text.lstrip()):
                mode = "skip"
                continue
            mode = "list" if marker else "tag"
            list_text = marker.end() if marker else extra
            start = match.end() + list_text
        elif mode == "skip" and extra:
            continue
        elif (mode == "list" and extra == list_text) or (mode == "tag" and extra > list_text):
            # A list item continues at its text column, a doc tag on lines indented under it
            start = match.end() + extra
        elif extra:
            # An indented example or diagram line, which is never refilled
            blocks.close()
            mode = None
            continue
        else:
            if mode is not None:
                blocks.close()
            mode = None
            start = match.end()
        blocks.add(number, line, start)
        key = line_key
    blocks.close()
    return blocks.done


def check(block, limit, markdown):
    issues = []
    for (number, line, own_start), (_, following, start) in zip(block, block[1:]):
        unit, rest = split_unit(following[start:])
        if not unit:
            continue
        if markdown:
            text = line[own_start:]
            opened = open_unit(text)
            if opened is not None:
                # A split unit is worth reporting only when the next line could hold it whole
                whole = text[text.rfind(" ", 0, opened) + 1:] + " " + unit
                if width(following[:start] + whole, markdown) <= limit:
                    issues.append(f"line {number} splits link text or a code span")
                continue
        if width(line, markdown) + 1 + width(unit, markdown) > limit:
            continue
        if markdown and rest and (BLOCK_OPENER.match(rest) or WHOLE_LINE_OPENER.match(rest)):
            continue
        issues.append(f"line {number} can take {unit!r} from line {number + 1}")
    for number, line, start in block:
        if width(line, markdown) > limit:
            unit, _ = split_unit(line[start:])
            # A line holding one unbreakable unit is left to run long
            if width(line[:start] + unit, markdown) < width(line, markdown):
                issues.append(f"line {number} is over {limit}")
    return issues


def changed_rows(stream):
    changed = defaultdict(set)
    malformed = []
    for row in stream:
        row = row.rstrip("\r\n")
        if not row.strip():
            continue
        path, _, span = row.rpartition("\t")
        first, _, last = span.partition("-")
        try:
            numbers = range(int(first), int(last) + 1)
        except ValueError:
            malformed.append(row)
            continue
        if not path:
            malformed.append(row)
            continue
        changed[path].update(numbers)
    return changed, malformed


def normalized(path):
    return os.path.relpath(os.path.realpath(path))


def selected(path, named):
    """Return the named paths that select path: the path itself or a directory holding it."""
    path = normalized(path)
    return [name for name in named if path == name or path.startswith(name.rstrip(os.sep) + os.sep)]


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--limit", type=int, required=True)
    parser.add_argument("paths", nargs="*")
    args = parser.parse_args()
    changed, malformed = changed_rows(sys.stdin)
    failed = bool(malformed)
    for row in malformed:
        print(f"skipped a malformed row: {row!r}", file=sys.stderr)
    named = {normalized(path): path for path in args.paths}
    matched = set()
    for path, numbers in sorted(changed.items()):
        if named:
            names = selected(path, named)
            if not names:
                continue
            matched.update(names)
        if any(fnmatch.fnmatch(os.path.basename(path), name) for name in WORKING_DOCUMENTS):
            print(f"skipped a working document: {path}", file=sys.stderr)
            continue
        try:
            with open(path, encoding="utf-8-sig") as source:
                lines = source.read().split("\n")
        except (OSError, UnicodeDecodeError) as error:
            print(f"could not read {path}: {error}", file=sys.stderr)
            failed = True
            continue
        markdown = path.lower().endswith(MARKDOWN)
        blocks = markdown_blocks(lines) if markdown else comment_blocks(lines, path)
        for block in blocks:
            if not numbers.intersection(number for number, _, _ in block):
                continue
            issues = check(block, args.limit, markdown)
            if issues:
                print(f"{path}:{block[0][0]}-{block[-1][0]}: " + "; ".join(issues))
    for name, path in named.items():
        if name not in matched:
            print(f"no changed lines for {path}: run from the repository root and name files as "
                  "changed-lines.sh prints them", file=sys.stderr)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
