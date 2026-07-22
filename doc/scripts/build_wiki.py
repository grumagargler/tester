#!/usr/bin/env python3
"""Build a GitHub Wiki mirror from the MkDocs documentation sources.

The script intentionally uses only the Python standard library so it can run in
GitHub Actions without installing project-specific dependencies.
"""

from __future__ import annotations

import argparse
import re
import shutil
import sys
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Dict, Iterable, List, Optional, Sequence, Tuple


DOC_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = DOC_ROOT / "docs"
DEFAULT_CONFIG = DOC_ROOT / "mkdocs.yml"

INCLUDE_RE = re.compile(r"\{!([^!]+)!\}")
ADMONITION_RE = re.compile(
    r'^(?P<indent>[ \t]*)!!!\s*(?P<kind>[A-Za-z0-9_-]+)'
    r'(?:\s+"(?P<title>[^"]*)")?\s*$'
)
VIDEO_RE = re.compile(
    r"!\[type:video\]\("
    r"https?://(?:www\.)?youtube\.com/embed/([^)?\s]+)(?:\?[^)\s]*)?"
    r"\)"
)
MARKDOWN_TARGET_RE = re.compile(
    r"(?P<prefix>!?\[[^\]\n]*\]\()"
    r"(?P<target>[^)\s]+)"
    r"(?P<suffix>(?:\s+(?:\"[^\"]*\"|'[^']*'))?\))"
)
NAV_ENTRY_RE = re.compile(
    r"^(?P<indent>\s*)-\s+(?P<title>.+?)\s*:\s*(?P<path>[^#]+\.md)?\s*$"
)


class BuildError(RuntimeError):
    """Raised when the source documentation cannot be mirrored safely."""


@dataclass(frozen=True)
class NavEntry:
    level: int
    title: str
    source_path: Optional[str]


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--source",
        type=Path,
        default=DEFAULT_SOURCE,
        help="MkDocs source directory (default: doc/docs)",
    )
    parser.add_argument(
        "--config",
        type=Path,
        default=DEFAULT_CONFIG,
        help="MkDocs configuration containing nav (default: doc/mkdocs.yml)",
    )
    parser.add_argument(
        "--output",
        type=Path,
        required=True,
        help="Directory in which to create the Wiki working tree",
    )
    parser.add_argument(
        "--repository",
        default="grumagargler/tester",
        help="GitHub owner/repository used in generated source links",
    )
    parser.add_argument(
        "--branch",
        default="master",
        help="Branch used in generated source links (default: master)",
    )
    parser.add_argument(
        "--site-url",
        default="http://tester.help",
        help="Alternative documentation site linked from the Wiki",
    )
    return parser.parse_args()


def parse_nav(config_path: Path) -> List[NavEntry]:
    lines = config_path.read_text(encoding="utf-8").splitlines()
    try:
        nav_start = next(index for index, line in enumerate(lines) if line.strip() == "nav:")
    except StopIteration as error:
        raise BuildError(f"No nav section found in {config_path}") from error

    entries: List[NavEntry] = []
    for line_number, line in enumerate(lines[nav_start + 1 :], nav_start + 2):
        if not line.strip() or line.lstrip().startswith("#"):
            continue

        match = NAV_ENTRY_RE.match(line)
        if not match:
            if line == line.lstrip() and not line.startswith("-"):
                break
            raise BuildError(
                f"Unsupported nav entry in {config_path}:{line_number}: {line!r}"
            )

        indent = match.group("indent")
        if "\t" in indent or len(indent) % 2:
            raise BuildError(
                f"Navigation indentation must use pairs of spaces in "
                f"{config_path}:{line_number}"
            )

        source_path = match.group("path")
        entries.append(
            NavEntry(
                level=len(indent) // 2,
                title=match.group("title").strip(),
                source_path=source_path.strip() if source_path else None,
            )
        )

    if not entries:
        raise BuildError(f"The nav section in {config_path} is empty")
    return entries


def expand_includes(
    text: str,
    source_root: Path,
    source_path: Path,
    stack: Tuple[Path, ...] = (),
) -> str:
    def replace_include(match: re.Match[str]) -> str:
        relative_path = Path(match.group(1))
        include_path = (source_root / relative_path).resolve()
        try:
            include_path.relative_to(source_root)
        except ValueError as error:
            raise BuildError(
                f"Include outside the documentation root in {source_path}: "
                f"{relative_path}"
            ) from error

        if include_path in stack:
            chain = " -> ".join(str(path) for path in (*stack, include_path))
            raise BuildError(f"Recursive documentation include: {chain}")
        if not include_path.is_file():
            raise BuildError(f"Missing include in {source_path}: {relative_path}")

        included_text = include_path.read_text(encoding="utf-8").rstrip("\n")
        return expand_includes(
            included_text,
            source_root,
            include_path,
            (*stack, include_path),
        )

    return INCLUDE_RE.sub(replace_include, text)


def convert_admonitions(text: str) -> str:
    lines = text.splitlines()
    converted: List[str] = []
    index = 0

    while index < len(lines):
        match = ADMONITION_RE.match(lines[index])
        if not match:
            converted.append(lines[index])
            index += 1
            continue

        indent = match.group("indent")
        title = match.group("title")
        index += 1
        body: List[str] = []

        while index < len(lines):
            line = lines[index]
            if not line.strip():
                body.append("")
                index += 1
                continue

            tab_prefix = indent + "\t"
            space_prefix = indent + "    "
            if line.startswith(tab_prefix):
                body.append(line[len(tab_prefix) :])
                index += 1
            elif line.startswith(space_prefix):
                body.append(line[len(space_prefix) :])
                index += 1
            else:
                break

        if title:
            converted.append(f"{indent}> **{title}**")
            if body:
                converted.append(f"{indent}>")

        for line in body:
            converted.append(f"{indent}> {line}" if line else f"{indent}>")

        if not title and not body:
            converted.append(f"{indent}> **{match.group('kind').title()}**")

    suffix = "\n" if text.endswith("\n") else ""
    return "\n".join(converted) + suffix


def page_destination(source_name: str) -> str:
    return "Home.md" if source_name == "index.md" else source_name


def rewrite_markdown_targets(
    text: str,
    page_map: Dict[str, str],
    source_path: Path,
) -> str:
    page_stems = {Path(destination).stem for destination in page_map.values()}

    def rewrite_target(target: str) -> str:
        if target.startswith("<") or target.startswith("#"):
            return target
        if re.match(r"^[A-Za-z][A-Za-z0-9+.-]*:", target):
            return target

        path, separator, fragment = target.partition("#")
        rewritten_path = path

        if path.startswith("/img/"):
            rewritten_path = "images/" + path[len("/img/") :]
        elif path.startswith("img/"):
            rewritten_path = "images/" + path[len("img/") :]
        elif path.lower().endswith(".md"):
            normalized = PurePosixPath(path.lstrip("/"))
            normalized_text = normalized.as_posix()
            if normalized_text.startswith("./"):
                normalized_text = normalized_text[2:]
            destination = page_map.get(normalized_text)
            if not destination:
                raise BuildError(
                    f"Link from {source_path} points to an unpublished page: {target}"
                )
            rewritten_path = Path(destination).stem
        elif path.startswith("/") and path.strip("/") in page_stems:
            rewritten_path = path.strip("/")

        return rewritten_path + (separator + fragment if separator else "")

    def replace_target(match: re.Match[str]) -> str:
        return (
            match.group("prefix")
            + rewrite_target(match.group("target"))
            + match.group("suffix")
        )

    return MARKDOWN_TARGET_RE.sub(replace_target, text)


def convert_page(
    source_path: Path,
    source_root: Path,
    page_map: Dict[str, str],
) -> str:
    text = source_path.read_text(encoding="utf-8")
    text = expand_includes(text, source_root.resolve(), source_path.resolve())
    text = convert_admonitions(text)
    text = VIDEO_RE.sub(
        lambda match: f"[▶ YouTube](https://youtu.be/{match.group(1)})",
        text,
    )
    return rewrite_markdown_targets(text, page_map, source_path)


def sidebar_content(
    entries: Sequence[NavEntry],
    page_map: Dict[str, str],
    source_url: str,
    site_url: str,
) -> str:
    lines = [
        "<!-- Generated by doc/scripts/build_wiki.py; do not edit in the Wiki. -->",
        "### Тестер",
        "",
    ]

    for entry in entries:
        prefix = "  " * entry.level + "- "
        if entry.source_path:
            destination = page_map.get(entry.source_path)
            if not destination:
                raise BuildError(
                    f"Navigation points to an unpublished page: {entry.source_path}"
                )
            lines.append(f"{prefix}[{entry.title}]({Path(destination).stem})")
        else:
            lines.append(f"{prefix}**{entry.title}**")

    lines.extend(
        [
            "",
            "---",
            "",
            f"[Исходники документации]({source_url})",
            "",
            f"[tester.help]({site_url})",
            "",
        ]
    )
    return "\n".join(lines)


def footer_content(source_url: str, site_url: str) -> str:
    return (
        "<!-- Generated by doc/scripts/build_wiki.py; do not edit in the Wiki. -->\n"
        f"_Эта Wiki автоматически собрана из "
        f"[исходников документации]({source_url}). Изменения, сделанные только "
        f"в Wiki, будут перезаписаны. Альтернативный сайт: "
        f"[tester.help]({site_url})._\n"
    )


def validate_output(output_root: Path, page_destinations: Iterable[str]) -> None:
    page_stems = {Path(destination).stem for destination in page_destinations}
    page_stems.update({"_Sidebar", "_Footer"})
    problems: List[str] = []

    for markdown_path in sorted(output_root.glob("*.md")):
        text = markdown_path.read_text(encoding="utf-8")
        if INCLUDE_RE.search(text):
            problems.append(f"unexpanded include in {markdown_path.name}")
        if any(ADMONITION_RE.match(line) for line in text.splitlines()):
            problems.append(f"unconverted admonition in {markdown_path.name}")
        if "![type:video]" in text:
            problems.append(f"unconverted video in {markdown_path.name}")

        for match in MARKDOWN_TARGET_RE.finditer(text):
            target = match.group("target")
            if target.startswith("<") or target.startswith("#"):
                continue
            if re.match(r"^[A-Za-z][A-Za-z0-9+.-]*:", target):
                continue

            path = target.partition("#")[0]
            if path.startswith("images/"):
                if not (output_root / path).is_file():
                    problems.append(
                        f"missing image linked from {markdown_path.name}: {path}"
                    )
            elif path and path not in page_stems:
                problems.append(
                    f"unknown local link in {markdown_path.name}: {target}"
                )

    if problems:
        formatted = "\n".join(f"- {problem}" for problem in problems)
        raise BuildError(f"Wiki validation failed:\n{formatted}")


def clean_output(output_root: Path, source_root: Path) -> None:
    resolved_output = output_root.resolve()
    protected_paths = {
        Path("/").resolve(),
        source_root.resolve(),
        DOC_ROOT.resolve(),
        DOC_ROOT.parent.resolve(),
    }
    if resolved_output in protected_paths:
        raise BuildError(f"Refusing to replace protected directory: {resolved_output}")
    if output_root.exists():
        shutil.rmtree(output_root)
    output_root.mkdir(parents=True)


def build(args: argparse.Namespace) -> Tuple[int, int]:
    source_root = args.source.resolve()
    config_path = args.config.resolve()
    output_root = args.output.resolve()

    if not source_root.is_dir():
        raise BuildError(f"Documentation source directory not found: {source_root}")
    if not config_path.is_file():
        raise BuildError(f"MkDocs configuration not found: {config_path}")

    source_pages = sorted(source_root.glob("*.md"))
    if not source_pages:
        raise BuildError(f"No Markdown pages found in {source_root}")

    page_map = {
        source_path.name: page_destination(source_path.name)
        for source_path in source_pages
    }
    if "index.md" not in page_map:
        raise BuildError("The Wiki home page requires docs/index.md")

    nav_entries = parse_nav(config_path)
    clean_output(output_root, source_root)

    for source_path in source_pages:
        destination = output_root / page_map[source_path.name]
        destination.write_text(
            convert_page(source_path, source_root, page_map),
            encoding="utf-8",
        )

    source_images = source_root / "img"
    output_images = output_root / "images"
    if not source_images.is_dir():
        raise BuildError(f"Documentation image directory not found: {source_images}")
    shutil.copytree(source_images, output_images)

    source_url = (
        f"https://github.com/{args.repository}/tree/{args.branch}/doc/docs"
    )
    (output_root / "_Sidebar.md").write_text(
        sidebar_content(nav_entries, page_map, source_url, args.site_url),
        encoding="utf-8",
    )
    (output_root / "_Footer.md").write_text(
        footer_content(source_url, args.site_url),
        encoding="utf-8",
    )

    validate_output(output_root, page_map.values())
    image_count = sum(1 for path in output_images.rglob("*") if path.is_file())
    return len(source_pages), image_count


def main() -> int:
    args = parse_arguments()
    try:
        page_count, image_count = build(args)
    except (BuildError, OSError, UnicodeError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    print(
        f"Built GitHub Wiki mirror with {page_count} pages and "
        f"{image_count} images in {args.output.resolve()}"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
