#!/usr/bin/env python3
from __future__ import annotations

import copy
import gzip
import io
import json
import os
import re
import shutil
import subprocess
import tempfile
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
GAME_DIR = ROOT / "game"
REPORT_JSON = ROOT / "reports/web_payload_matrix.json"
REPORT_MD = ROOT / "reports/web_payload_matrix.md"
GODOT_BIN = Path(os.environ.get("GODOT_BIN", "/Applications/Godot.app/Contents/MacOS/Godot"))
TEMPLATE_DIR = Path.home() / "Library/Application Support/Godot/export_templates/4.6.1.stable"
DEFAULT_EXCLUDE = "addons/godot_mcp/*,tests/*,.godot/*,assets/fonts/SourceHanSansCN-Medium.ttf,assets/fonts/SourceHanSansCN-Medium.ttf.import"


@dataclass
class Variant:
    key: str
    title: str
    mode: str
    custom_features: str = ""
    custom_template_release: str = ""
    notes: str = ""


VARIANTS = [
    Variant(
        key="baseline",
        title="当前仓库 Web 预设",
        mode="project_copy",
        notes="对应默认 Web 导出；当前产物大小就是这条线。",
    ),
    Variant(
        key="feature_tags_only",
        title="仅增加 custom_features / feature tag",
        mode="project_copy",
        custom_features="payload_test,web_bootstrap",
        notes="验证 feature tag 只影响项目条件分支，不会裁掉引擎 wasm。",
    ),
    Variant(
        key="forced_web_release_template",
        title="强制切到 web_release.zip",
        mode="project_copy",
        custom_template_release=str(TEMPLATE_DIR / "web_release.zip"),
        notes="验证换模板能否小幅下降 wasm，但仍不是项目分包。",
    ),
    Variant(
        key="dynamic_link_nothreads",
        title="dynamic linking nothreads",
        mode="project_copy",
        custom_template_release=str(TEMPLATE_DIR / "web_dlink_nothreads_release.zip"),
        notes="验证 Godot 4.6.1 的 dlink 是否真的能把 wasm 做成可用的分包。",
    ),
    Variant(
        key="minimal_project",
        title="极简空项目对照",
        mode="minimal_project",
        notes="用于证明 wasm 主要来自 Web 模板，而不是 survivor-demo 项目资源。",
    ),
]


def gzip_size(path: Path) -> int:
    data = path.read_bytes()
    buffer = io.BytesIO()
    with gzip.GzipFile(filename="", mode="wb", fileobj=buffer, compresslevel=9, mtime=0) as gz:
        gz.write(data)
    return len(buffer.getvalue())


def file_size(path: Path) -> int | None:
    return path.stat().st_size if path.exists() else None


def run(cmd: list[str], cwd: Path | None = None) -> None:
    subprocess.run(cmd, cwd=cwd, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)


def patch_export_preset(path: Path, variant: Variant) -> None:
    text = path.read_text(encoding="utf-8")
    if variant.custom_features:
        text = re.sub(r'custom_features="[^"]*"', f'custom_features="{variant.custom_features}"', text, count=1)
    if variant.custom_template_release:
        text = re.sub(
            r'custom_template/release="[^"]*"',
            f'custom_template/release="{variant.custom_template_release}"',
            text,
            count=1,
        )
    if DEFAULT_EXCLUDE not in text:
        text = re.sub(r'exclude_filter="[^"]*"', f'exclude_filter="{DEFAULT_EXCLUDE}"', text, count=1)
    path.write_text(text, encoding="utf-8")


def build_minimal_project(base_dir: Path) -> Path:
    game_dir = base_dir / "game"
    (game_dir / "scenes").mkdir(parents=True, exist_ok=True)
    (base_dir / "out").mkdir(parents=True, exist_ok=True)
    (game_dir / "project.godot").write_text(
        """; Engine configuration file.\nconfig_version=5\n\n[application]\nconfig/name=\"web-mini\"\nrun/main_scene=\"res://scenes/main.tscn\"\nconfig/features=PackedStringArray(\"4.6\")\n\n[display]\nwindow/size/viewport_width=1280\nwindow/size/viewport_height=720\nwindow/stretch/mode=\"canvas_items\"\nwindow/stretch/aspect=\"expand\"\n""",
        encoding="utf-8",
    )
    (game_dir / "export_presets.cfg").write_text(
        """[preset.0]\nname=\"Web\"\nplatform=\"Web\"\nrunnable=true\ndedicated_server=false\ncustom_features=\"\"\nexport_filter=\"all_resources\"\ninclude_filter=\"\"\nexclude_filter=\"\"\nexport_path=\"../out/index.html\"\npatches=PackedStringArray()\nencryption_include_filters=\"\"\nencryption_exclude_filters=\"\"\nencrypt_pck=false\nencrypt_directory=false\nscript_export_mode=1\n\n[preset.0.options]\ncustom_template/debug=\"\"\ncustom_template/release=\"\"\nvariant/extensions_support=false\nvram_texture_compression/for_desktop=true\nvram_texture_compression/for_mobile=false\nhtml/export_icon=false\nhtml/canvas_resize_policy=2\nhtml/focus_canvas_on_start=true\nhtml/experimental_virtual_keyboard=false\nprogressive_web_app/enabled=false\n""",
        encoding="utf-8",
    )
    (game_dir / "scenes/main.tscn").write_text(
        """[gd_scene format=3]\n\n[node name=\"Main\" type=\"Node2D\"]\n""",
        encoding="utf-8",
    )
    return game_dir


def export_variant(variant: Variant) -> dict[str, Any]:
    with tempfile.TemporaryDirectory(prefix=f"survivor-web-{variant.key}-") as tmp:
        tmp_dir = Path(tmp)
        out_dir = tmp_dir / "out"
        out_dir.mkdir(parents=True, exist_ok=True)

        if variant.mode == "project_copy":
            game_dir = tmp_dir / "game"
            shutil.copytree(GAME_DIR, game_dir)
            patch_export_preset(game_dir / "export_presets.cfg", variant)
        elif variant.mode == "minimal_project":
            game_dir = build_minimal_project(tmp_dir)
        else:
            raise ValueError(f"unknown mode: {variant.mode}")

        target = out_dir / "index.html"
        subprocess.run(
            [str(GODOT_BIN), "--headless", "--path", str(game_dir), "--export-release", "Web", str(target)],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
        )

        result = {
            "key": variant.key,
            "title": variant.title,
            "notes": variant.notes,
            "files": {
                "index.html": file_size(out_dir / "index.html"),
                "index.js": file_size(out_dir / "index.js"),
                "index.wasm": file_size(out_dir / "index.wasm"),
                "index.side.wasm": file_size(out_dir / "index.side.wasm"),
                "index.pck": file_size(out_dir / "index.pck"),
            },
            "gzip": {},
        }
        for name in ["index.js", "index.wasm", "index.side.wasm", "index.pck"]:
            path = out_dir / name
            if path.exists():
                result["gzip"][name] = gzip_size(path)
        result["runtime_transfer_bytes"] = sum(result["gzip"].values())

        index_html = out_dir / "index.html"
        if index_html.exists():
            html_text = index_html.read_text(encoding="utf-8", errors="ignore")
            match = re.search(r'const GODOT_CONFIG = (\{.*?\});\s*const GODOT_THREADS_ENABLED = (true|false);', html_text, re.S)
            if match:
                result["threads_enabled"] = match.group(2) == "true"
                result["godot_config"] = json.loads(match.group(1))
        return result


def inspect_templates() -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for path in sorted(TEMPLATE_DIR.glob("web*.zip")):
        with zipfile.ZipFile(path) as zf:
            files = {info.filename: info.file_size for info in zf.infolist() if not info.is_dir()}
        row = {
            "template": path.name,
            "godot.wasm": files.get("godot.wasm"),
            "godot.side.wasm": files.get("godot.side.wasm"),
            "godot.js": files.get("godot.js"),
        }
        rows.append(row)
    return rows


def fmt_bytes(value: int | None) -> str:
    if value is None:
        return "-"
    mib = value / (1024 * 1024)
    if mib >= 1:
        return f"{mib:.2f} MiB ({value:,} B)"
    kib = value / 1024
    return f"{kib:.1f} KiB ({value:,} B)"


def delta(value: int | None, baseline: int | None) -> str:
    if value is None or baseline is None:
        return "-"
    diff = value - baseline
    sign = "+" if diff > 0 else ""
    pct = (diff / baseline * 100.0) if baseline else 0.0
    return f"{sign}{diff:,} B ({sign}{pct:.1f}%)"


def write_markdown(report: dict[str, Any]) -> None:
    variants = report["variants"]
    baseline = next(item for item in variants if item["key"] == "baseline")
    lines: list[str] = []
    lines.append("# survivor-demo Web payload matrix\n")
    lines.append(f"- Godot: `{report['godot_version']}`")
    lines.append(f"- Generated by: `tests/smoke/web_payload_matrix.py`")
    lines.append("")
    lines.append("## Export template inventory\n")
    lines.append("| Template | godot.wasm | godot.side.wasm | godot.js |")
    lines.append("| --- | ---: | ---: | ---: |")
    for row in report["templates"]:
        lines.append(f"| {row['template']} | {fmt_bytes(row['godot.wasm'])} | {fmt_bytes(row['godot.side.wasm'])} | {fmt_bytes(row['godot.js'])} |")
    lines.append("")
    lines.append("## Variant results\n")
    lines.append("| Variant | wasm | side.wasm | pck | gzip runtime total | vs baseline wasm | vs baseline pck |")
    lines.append("| --- | ---: | ---: | ---: | ---: | ---: | ---: |")
    for item in variants:
        files = item["files"]
        lines.append(
            f"| {item['title']} | {fmt_bytes(files['index.wasm'])} | {fmt_bytes(files['index.side.wasm'])} | {fmt_bytes(files['index.pck'])} | {fmt_bytes(item['runtime_transfer_bytes'])} | {delta(files['index.wasm'], baseline['files']['index.wasm'])} | {delta(files['index.pck'], baseline['files']['index.pck'])} |"
        )
    lines.append("")
    lines.append("## Notes by variant\n")
    for item in variants:
        lines.append(f"### {item['title']}")
        lines.append(f"- 说明：{item['notes']}")
        lines.append(f"- threads_enabled: `{item.get('threads_enabled')}`")
        lines.append(f"- has side wasm artifact: `{item['files']['index.side.wasm'] is not None}`")
        config = item.get("godot_config") or {}
        if config:
            lines.append(f"- fileSizes: `{json.dumps(config.get('fileSizes', {}), ensure_ascii=False)}`")
        lines.append("")

    REPORT_MD.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    if not GODOT_BIN.exists():
        raise SystemExit(f"missing Godot binary: {GODOT_BIN}")
    templates = inspect_templates()
    godot_version = subprocess.run([str(GODOT_BIN), "--version"], check=True, stdout=subprocess.PIPE, text=True).stdout.strip()
    variants = [export_variant(variant) for variant in VARIANTS]
    report = {
        "godot_version": godot_version,
        "templates": templates,
        "variants": variants,
    }
    REPORT_JSON.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    write_markdown(report)
    print(f"wrote {REPORT_JSON}")
    print(f"wrote {REPORT_MD}")


if __name__ == "__main__":
    main()
