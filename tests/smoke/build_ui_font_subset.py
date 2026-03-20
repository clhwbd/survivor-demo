#!/usr/bin/env python3
from __future__ import annotations

import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
GAME_DIR = ROOT / "game"
SOURCE_FONT = GAME_DIR / "assets/fonts/SourceHanSansCN-Medium.ttf"
SUBSET_FONT = GAME_DIR / "assets/fonts/survivor-ui-subset.ttf"
CORPUS_FILE = GAME_DIR / "assets/fonts/survivor-ui-subset.txt"
SCAN_DIRS = [
    GAME_DIR / "scripts",
    GAME_DIR / "scenes",
    GAME_DIR / "data",
]
SCAN_FILES = [GAME_DIR / "project.godot"]
ASCII_BLOCK = ''.join(chr(i) for i in range(32, 127))
EXTRA_TEXT = "\n西游记古风Q版完整验收版掌中戏台花果山山门妖潮大圣筋斗闪军令达成速决赏命火修为行者斩妖头目起势起煞压场破阵继续试炼再闯一局暂停通关败阵战报告急压阵喝彩身法提示本劫军令第一页加载中首次打开需要下载引擎资源若进度长期不动建议改用CloudflarePages完整版Webmobile\n"


def collect_text() -> str:
    parts: list[str] = [ASCII_BLOCK, EXTRA_TEXT]
    for path in SCAN_FILES:
        if path.exists():
            parts.append(path.read_text(encoding="utf-8"))
    for directory in SCAN_DIRS:
        if not directory.exists():
            continue
        for path in sorted(directory.rglob("*")):
            if path.is_file() and path.suffix in {".gd", ".tscn", ".json", ".godot", ".cfg"}:
                parts.append(path.read_text(encoding="utf-8"))
    unique_chars = sorted(set(''.join(parts)))
    return ''.join(unique_chars)


def main() -> None:
    if not SOURCE_FONT.exists():
        raise SystemExit(f"missing source font: {SOURCE_FONT}")
    corpus = collect_text()
    CORPUS_FILE.write_text(corpus, encoding="utf-8")
    command = [
        "python3",
        "-m",
        "fontTools.subset",
        str(SOURCE_FONT),
        f"--text-file={CORPUS_FILE}",
        f"--output-file={SUBSET_FONT}",
        "--layout-features=*",
        "--name-IDs=*",
        "--glyph-names",
        "--symbol-cmap",
        "--legacy-cmap",
        "--notdef-glyph",
        "--notdef-outline",
        "--recommended-glyphs",
        "--hinting",
        "--desubroutinize",
    ]
    subprocess.run(command, check=True)
    print(f"subset font ready: {SUBSET_FONT} ({SUBSET_FONT.stat().st_size} bytes)")
    print(f"corpus chars: {len(corpus)}")


if __name__ == "__main__":
    main()
