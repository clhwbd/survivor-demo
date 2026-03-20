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
	const wasmBytes = Number(runtimeSize['index.wasm'] || 0);
	const pckBytes = Number(runtimeSize['index.pck'] || 0);
	const totalBytes = Object.values(runtimeSize).reduce((sum, value) => sum + Number(value || 0), 0);

	let initializing = true;
	let statusMode = '';
	let slowBootTimer = null;
	let currentStageKey = 'boot';
	let stageDetails = '';
	let stageHint = '若长时间停在同一阶段，更可能是网络、托管配置或资源加载问题，并非单纯黑屏。';
	let activeFetchKind = '';

	function formatBytes(bytes) {
		if (!bytes || Number.isNaN(bytes)) {
			return '未知大小';
		}
		if (bytes >= 1024 * 1024) {
			return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
		}
		return `${(bytes / 1024).toFixed(0)} KB`;
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
		const lines = text.split('\\n');
		lines.forEach((line, index) => {
			const row = document.createElement('div');
			row.textContent = line;
			row.className = index === 0 ? 'status-line status-line--title' : 'status-line';
			statusNotice.appendChild(row);
		});
	}

	function describeStage(key) {
		switch (key) {
			case 'wasm-request':
				return '阶段 1/3：正在请求引擎 wasm';
			case 'wasm-download':
				return '阶段 1/3：正在下载引擎 wasm';
			case 'pck-request':
				return '阶段 2/3：正在请求游戏资源 pck';
			case 'pck-download':
				return '阶段 2/3：正在下载游戏资源 pck';
			case 'runtime-init':
				return '阶段 3/3：正在初始化 Godot 运行时';
			default:
				return '准备连接 Web 运行时资源';
		}
	}

	function setStage(key, details, hint) {
		currentStageKey = key;
		stageDetails = details || '';
		if (hint) {
			stageHint = hint;
		}
	}

	function buildProgressLine(current, total) {
		const resolvedTotal = total > 0 ? total : totalBytes;
		if (!(resolvedTotal > 0) || !(current > 0)) {
			return `总进度：正在准备加载（完整版约 ${formatBytes(totalBytes)}）`;
		}
		const percent = Math.min(100, Math.round((current / resolvedTotal) * 100));
		return `总进度：${percent}% · ${formatBytes(current)} / ${formatBytes(resolvedTotal)}`;
	}

	function buildCurrentStageDetails(current) {
		if (currentStageKey === 'wasm-request') {
			return `即将拉取引擎核心（约 ${formatBytes(wasmBytes)}）`;
		}
		if (currentStageKey === 'wasm-download') {
			const phaseBytes = wasmBytes > 0 ? Math.min(current, wasmBytes) : current;
			return `引擎 wasm 约 ${formatBytes(wasmBytes)}，首次打开通常最慢` + (phaseBytes > 0 ? ` · 已接收约 ${formatBytes(phaseBytes)}` : '');
		}
		if (currentStageKey === 'pck-request') {
			return `即将拉取游戏资源包（约 ${formatBytes(pckBytes)}）`;
		}
		if (currentStageKey === 'pck-download') {
			const phaseBytes = pckBytes > 0 && wasmBytes > 0 ? Math.max(0, current - wasmBytes) : current;
			return `游戏资源 pck 约 ${formatBytes(pckBytes)}` + (phaseBytes > 0 ? ` · 已接收约 ${formatBytes(phaseBytes)}` : '');
		}
		if (currentStageKey === 'runtime-init') {
			return '资源已基本到位，正在创建 Godot 运行时与首屏场景';
		}
		return stageDetails || `当前构成：wasm ${formatBytes(wasmBytes)} · pck ${formatBytes(pckBytes)}`;
	}

	function inferStageFromProgress(current, total) {
		if (activeFetchKind === 'wasm') {
			return current > 0 ? 'wasm-download' : 'wasm-request';
		}
		if (activeFetchKind === 'pck') {
			return current > wasmBytes ? 'pck-download' : 'pck-request';
		}
		if (wasmBytes > 0 && current < Math.max(wasmBytes * 0.98, wasmBytes - 512 * 1024)) {
			return current > 0 ? 'wasm-download' : 'wasm-request';
		}
		if (pckBytes > 0 && current < Math.max((wasmBytes + pckBytes) * 0.98, wasmBytes + pckBytes - 128 * 1024)) {
			return current > wasmBytes ? 'pck-download' : 'pck-request';
		}
		if ((total > 0 && current >= total) || current >= wasmBytes + pckBytes) {
			return 'runtime-init';
		}
		return currentStageKey;
	}

	function renderProgressNotice(current, total) {
		const inferredStage = inferStageFromProgress(current, total);
		if (inferredStage !== currentStageKey) {
			setStage(inferredStage);
		}
		const progressLine = buildProgressLine(current, total);
		const stageLine = describeStage(currentStageKey);
		const detailLine = stageDetails || buildCurrentStageDetails(current);
		const sizeLine = `资源大小：wasm ${formatBytes(wasmBytes)} · pck ${formatBytes(pckBytes)}`;
		setStatusNotice(`${bootVariantLabel}\n${stageLine}\n${progressLine}\n${detailLine}\n${sizeLine}\n${stageHint}`);
	}

	function displayFailureNotice(err) {
		console.error(err);
		if (slowBootTimer) {
			clearTimeout(slowBootTimer);
			slowBootTimer = null;
		}
		const fallback = '更可能是网络、托管配置或资源文件加载失败；建议优先检查 wasm / pck 请求是否成功，而不是把它当成普通黑屏。';
		if (err instanceof Error) {
			setStatusNotice(`加载失败\n${err.message}\n${fallback}`);
		} else if (typeof err === 'string') {
			setStatusNotice(`加载失败\n${err}\n${fallback}`);
		} else {
			setStatusNotice(`加载失败\n发生未知错误。\n${fallback}`);
		}
		setStatusMode('notice');
		initializing = false;
	}

	function trackFetchResource(url, onSuccess) {
		if (typeof url !== 'string') {
			return '';
		}
		if (url.indexOf('.wasm') !== -1) {
			setStage('wasm-request', `即将拉取引擎核心（约 ${formatBytes(wasmBytes)}）`);
			activeFetchKind = 'wasm';
			if (onSuccess) {
				onSuccess('wasm');
			}
			return 'wasm';
		}
		if (url.indexOf('.pck') !== -1) {
			setStage('pck-request', `即将拉取游戏资源包（约 ${formatBytes(pckBytes)}）`);
			activeFetchKind = 'pck';
			if (onSuccess) {
				onSuccess('pck');
			}
			return 'pck';
		}
		return '';
	}

	if (typeof window.fetch === 'function') {
		const nativeFetch = window.fetch.bind(window);
		window.fetch = function (resource, options) {
			const url = typeof resource === 'string' ? resource : (resource && typeof resource.url === 'string' ? resource.url : '');
			const trackedKind = trackFetchResource(url, function (kind) {
				setStage(kind === 'wasm' ? 'wasm-request' : 'pck-request');
			});
			return nativeFetch(resource, options).then(function (response) {
				if (trackedKind === 'wasm') {
					setStage('wasm-download', `引擎 wasm 响应已返回，开始下载（约 ${formatBytes(wasmBytes)}）`);
				}
				if (trackedKind === 'pck') {
					setStage('pck-download', `资源包响应已返回，开始下载（约 ${formatBytes(pckBytes)}）`);
				}
				return response;
			});
		};
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
			const missingMsg = 'Error\\nThe following features required to run Godot projects on the Web are missing:\\n';
			displayFailureNotice(missingMsg + missing.join('\\n'));
		}
	} else {
		setStatusMode('progress');
		setStage('boot', `当前构成：wasm ${formatBytes(wasmBytes)} · pck ${formatBytes(pckBytes)}`);
		renderProgressNotice(0, totalBytes);
		slowBootTimer = window.setTimeout(() => {
			if (!initializing) {
				return;
			}
			const stageTitle = describeStage(currentStageKey);
			setStatusNotice(`${bootVariantLabel}\n${stageTitle}\n总进度：加载时间明显偏长\n这通常不是“纯黑屏”，更可能卡在网络下载、托管未命中 gzip/CDN，或 wasm / pck 请求异常。\n已知当前包体：wasm ${formatBytes(wasmBytes)} · pck ${formatBytes(pckBytes)}。\n如果当前链接跑在 GitHub Pages，优先检查资源请求与响应头，再考虑切换更稳定的托管。`);
			setStatusMode('notice');
		}, 12000);
		engine.startGame({
			'onProgress': function (current, total) {
				const inferredStage = inferStageFromProgress(current, total);
				if (inferredStage === 'runtime-init') {
					activeFetchKind = '';
					setStage('runtime-init', '资源下载已接近完成，正在初始化引擎与首屏 UI');
				}
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
    config_match = re.search(r"const GODOT_CONFIG = (\{.*?\});", html, re.S)
    if not config_match:
        raise SystemExit("failed to locate GODOT_CONFIG block")
    config_json = config_match.group(1)
    patched_script = SCRIPT_TEMPLATE.replace("__CONFIG_JSON__", config_json)
    html = re.sub(
        r"const GODOT_CONFIG = \{.*?</script>",
        lambda _: patched_script + "\n\t\t</script>",
        html,
        count=1,
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
    if ".status-line--title" not in html:
        html = html.replace(
            "#status-notice {\n\tbackground-color: #5b3943;",
            "#status-notice {\n\tbackground-color: rgba(49, 30, 36, 0.92);",
        )
        html = html.replace(
            "\tborder: 1px solid #9b3943;\n\tcolor: #e0e0e0;\n\tfont-family: 'Noto Sans', 'Droid Sans', Arial, sans-serif;\n\tline-height: 1.3;\n\tmargin: 0 2rem;\n\toverflow: hidden;\n\tpadding: 1rem 1.15rem;\n\ttext-align: center;\n\tz-index: 1;\n}",
            "\tborder: 1px solid rgba(203, 141, 93, 0.95);\n\tbox-shadow: 0 0.4rem 1.2rem rgba(0, 0, 0, 0.36);\n\tcolor: #f5e7d0;\n\tfont-family: 'Noto Sans SC', 'Noto Sans', 'Droid Sans', Arial, sans-serif;\n\tline-height: 1.42;\n\tmargin: 0 1.2rem;\n\tmax-width: min(31rem, calc(100vw - 2.4rem));\n\toverflow: hidden;\n\tpadding: 1rem 1.15rem;\n\ttext-align: left;\n\tz-index: 1;\n}\n\n.status-line {\n\tmargin-top: 0.32rem;\n}\n\n.status-line:first-child {\n\tmargin-top: 0;\n}\n\n.status-line--title {\n\tcolor: #ffd38b;\n\tfont-size: 1rem;\n\tfont-weight: 700;\n\tletter-spacing: 0.03em;\n}\n",
        )
    path.write_text(html, encoding="utf-8")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        raise SystemExit("usage: patch_web_index.py <path-to-index.html>")
    patch_index(Path(sys.argv[1]).resolve())
    print(f"patched {sys.argv[1]}")
