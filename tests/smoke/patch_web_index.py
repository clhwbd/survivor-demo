#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path

SCRIPT_TEMPLATE = """const GODOT_CONFIG = __CONFIG_JSON__;
const bootVariantLabel = '完整验收版';
GODOT_CONFIG.args = Array.isArray(GODOT_CONFIG.args) ? GODOT_CONFIG.args.slice() : [];
const GODOT_THREADS_ENABLED = false;
const engine = new Engine(GODOT_CONFIG);

(function () {
	const statusOverlay = document.getElementById('status');
	const statusProgress = document.getElementById('status-progress');
	const statusNotice = document.getElementById('status-notice');
	const runtimeSize = GODOT_CONFIG.fileSizes || {};
	const totalBytes = Object.values(runtimeSize).reduce((sum, value) => sum + Number(value || 0), 0);

	let initializing = true;
	let statusMode = '';
	let slowBootTimer = null;

	function formatBytes(bytes) {
		if (!bytes || Number.isNaN(bytes)) {
			return '未知大小';
		}
		return `${(bytes / (1024 * 1024)).toFixed(bytes >= 1024 * 1024 ? 1 : 2)} MB`;
	}

	function setStatusMode(mode) {
		if (statusMode === mode || !initializing) {
			return;
		}
		if (mode === 'hidden') {
			statusOverlay.remove();
			initializing = false;
			if (slowBootTimer) {
				clearTimeout(slowBootTimer);
				slowBootTimer = null;
			}
			return;
		}
		statusOverlay.style.visibility = 'visible';
		statusProgress.style.display = mode === 'progress' ? 'block' : 'none';
		statusNotice.style.display = (mode === 'progress' || mode === 'notice') ? 'block' : 'none';
		statusMode = mode;
	}

	function setStatusNotice(text) {
		while (statusNotice.lastChild) {
			statusNotice.removeChild(statusNotice.lastChild);
		}
		const lines = text.split('\n');
		lines.forEach((line, index) => {
			statusNotice.appendChild(document.createTextNode(line));
			if (index !== lines.length - 1) {
				statusNotice.appendChild(document.createElement('br'));
			}
		});
	}

	function renderProgressNotice(current, total) {
		const resolvedTotal = total > 0 ? total : totalBytes;
		const percent = resolvedTotal > 0 && current > 0 ? Math.min(100, Math.round((current / resolvedTotal) * 100)) : null;
		const progressLine = percent === null
			? `正在装载 Web 运行时（约 ${formatBytes(totalBytes)}）`
			: `正在装载 Web 运行时：${percent}% · ${formatBytes(current)} / ${formatBytes(resolvedTotal)}`;
		const modeLine = '当前外链保持完整版本；若加载明显偏长，应优先切换更合适的托管/CDN，而不是降级功能。';
		setStatusNotice(`${bootVariantLabel}\n${progressLine}\n${modeLine}`);
	}

	function displayFailureNotice(err) {
		console.error(err);
		if (slowBootTimer) {
			clearTimeout(slowBootTimer);
			slowBootTimer = null;
		}
		if (err instanceof Error) {
			setStatusNotice(`加载失败\n${err.message}\n若当前托管是 GitHub Pages，建议切到 Cloudflare Pages 压缩版。`);
		} else if (typeof err === 'string') {
			setStatusNotice(`加载失败\n${err}\n若当前托管是 GitHub Pages，建议切到 Cloudflare Pages 压缩版。`);
		} else {
			setStatusNotice('加载失败\n发生未知错误。\n若当前托管是 GitHub Pages，建议切到 Cloudflare Pages 压缩版。');
		}
		setStatusMode('notice');
		initializing = false;
	}

	const missing = Engine.getMissingFeatures({
		threads: GODOT_THREADS_ENABLED,
	});

	if (missing.length !== 0) {
		if (GODOT_CONFIG['serviceWorker'] && GODOT_CONFIG['ensureCrossOriginIsolationHeaders'] && 'serviceWorker' in navigator) {
			let serviceWorkerRegistrationPromise;
			try {
				serviceWorkerRegistrationPromise = navigator.serviceWorker.getRegistration();
			} catch (err) {
				serviceWorkerRegistrationPromise = Promise.reject(new Error('Service worker registration failed.'));
			}
			Promise.race([
				serviceWorkerRegistrationPromise.then((registration) => {
					if (registration != null) {
						return Promise.reject(new Error('Service worker already exists.'));
					}
					return registration;
				}).then(() => engine.installServiceWorker()),
				new Promise((resolve) => {
					setTimeout(() => resolve(), 2000);
				}),
			]).then(() => {
				window.location.reload();
			}).catch((err) => {
				console.error('Error while registering service worker:', err);
			});
		} else {
			const missingMsg = 'Error\nThe following features required to run Godot projects on the Web are missing:\n';
			displayFailureNotice(missingMsg + missing.join('\n'));
		}
	} else {
		setStatusMode('progress');
		renderProgressNotice(0, totalBytes);
		slowBootTimer = window.setTimeout(() => {
			if (!initializing) {
				return;
			}
			setStatusNotice(`${bootVariantLabel}\n加载时间明显偏长，通常是 wasm 首包过大或托管未压缩。\n如当前外链仍跑在 GitHub Pages，请优先改发 Cloudflare Pages 完整版目录。`);
		}, 12000);
		engine.startGame({
			'onProgress': function (current, total) {
				renderProgressNotice(current, total);
				if (current > 0 && total > 0) {
					statusProgress.value = current;
					statusProgress.max = total;
				} else {
					statusProgress.removeAttribute('value');
					statusProgress.removeAttribute('max');
				}
			},
		}).then(() => {
			setStatusMode('hidden');
		}, displayFailureNotice);
	}
}());"""


def patch_index(path: Path) -> None:
    html = path.read_text(encoding="utf-8")
    config_match = re.search(r"const GODOT_CONFIG = (\{.*?\});\s*const GODOT_THREADS_ENABLED = false;", html, re.S)
    if not config_match:
        raise SystemExit("failed to locate GODOT_CONFIG block")
    config_json = config_match.group(1)
    patched_script = SCRIPT_TEMPLATE.replace("__CONFIG_JSON__", config_json)
    html = re.sub(
        r"const GODOT_CONFIG = \{.*?\}\);\s*</script>",
        patched_script + "\n\t\t</script>",
        html,
        flags=re.S,
    )
    html = re.sub(r"<title>.*?</title>", "<title>survivor-demo · Web 完整验收版</title>", html, count=1, flags=re.S)
    html = re.sub(
        r"#status-progress, #status-notice \{\n\tdisplay: none;\n\}\n(?:\n#status-progress \{\n\theight: 0\.85rem;\n\taccent-color: #c8653b;\n\}\n)*",
        "#status-progress, #status-notice {\n\tdisplay: none;\n}\n\n#status-progress {\n\theight: 0.85rem;\n\taccent-color: #c8653b;\n}\n",
        html,
        count=1,
    )
    html = html.replace("padding: 1rem;", "padding: 1rem 1.15rem;")
    path.write_text(html, encoding="utf-8")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: patch_web_index.py <path-to-index.html>")
    patch_index(Path(sys.argv[1]).resolve())
    print(f"patched {sys.argv[1]}")
