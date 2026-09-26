/**
 * TPS Extension
 *
 * Shows the throughput (tokens/second) of the LAST assistant message in the
 * footer, measured from provider stream events (Pi records no generation
 * timing in the message metadata itself). Request timing starts at Pi's
 * before_provider_request hook, so TTFT includes provider latency/prefill.
 *
 *   /tps            show current settings + last metrics
 *   /tps on|off     toggle the footer readout
 *   /tps decode     headline = pure decode speed  (default, excludes prefill)
 *   /tps wall       headline = end-to-end speed   (includes prefill + network)
 *   /tps ttft       headline = time to first token
 *
 * The last metrics are persisted as a `tps` custom session entry, so the
 * readout survives session resume / branch switches. Custom entries are never
 * sent to the model.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

type Metric = "decode" | "wall" | "ttft";

interface Metrics {
	/** Completion tokens reported by the provider. */
	output: number;
	/** Reasoning tokens (subset of output), when the provider reports them. */
	reasoning: number;
	/** Full provider wall time: request start -> message end. */
	wallMs: number;
	/** Decode time: first token -> message end. Undefined for non-streaming responses. */
	decodeMs?: number;
	/** Time to first token: request start -> first delta. */
	ttftMs?: number;
	stopReason: string;
}

const STATE_KEY = "tps";

export default function tpsExtension(pi: ExtensionAPI) {
	let enabled = true;
	let metric: Metric = "decode";
	let last: Metrics | undefined;

	// Per-message timing scratch (reset on every assistant message_start).
	let pendingRequestAt: number | null = null;
	let startAt = 0;
	let firstTokenAt: number | null = null;

	const fmt = (n: number, digits = 1) => n.toFixed(digits);

	/** Seconds, preferring s once we cross the 1s mark. */
	const fmtDuration = (ms: number) => (ms >= 1000 ? `${fmt(ms / 1000)}s` : `${Math.round(ms)}ms`);

	const metricValue = (m: Metrics): { label: string; value: string } | undefined => {
		const wallS = m.wallMs / 1000;
		const decodeS = m.decodeMs !== undefined ? m.decodeMs / 1000 : undefined;

		switch (metric) {
			case "ttft":
				return m.ttftMs !== undefined ? { label: "ttft", value: fmtDuration(m.ttftMs) } : undefined;
			case "wall":
				return wallS > 0 ? { label: "tok/s wall", value: fmt(m.output / wallS) } : undefined;
			case "decode":
			default:
				if (decodeS !== undefined && decodeS > 0) return { label: "tok/s", value: fmt(m.output / decodeS) };
				// No deltas (non-streaming response): fall back to wall, labeled.
				return wallS > 0 ? { label: "tok/s wall", value: fmt(m.output / wallS) } : undefined;
		}
	};

	const render = (ctx: ExtensionContext) => {
		if (!ctx.hasUI) return;
		if (!enabled) {
			ctx.ui.setStatus(STATE_KEY, undefined);
			return;
		}
		if (!last) {
			ctx.ui.setStatus(STATE_KEY, ctx.ui.theme.fg("dim", "⚡ — tok/s"));
			return;
		}

		const theme = ctx.ui.theme;
		const parts: string[] = [];
		const primary = metricValue(last);

		// Headline metric, or a dash when the provider gave us nothing usable.
		if (primary && last.output > 0) {
			parts.push(theme.fg("success", `⚡ ${primary.value} ${primary.label}`));
		} else {
			parts.push(theme.fg("dim", "⚡ — tok/s"));
		}

		parts.push(theme.fg("dim", `· ${last.output} out`));
		if (last.reasoning > 0) parts.push(theme.fg("dim", `· ${last.reasoning} think`));

		// Show the other timing dimensions when the headline is a TPS number.
		if (primary?.label === "tok/s" && last.ttftMs !== undefined) {
			parts.push(theme.fg("dim", `· ttft ${fmtDuration(last.ttftMs)}`));
		}
		if (primary?.label === "ttft" && last.decodeMs !== undefined && last.decodeMs > 0) {
			parts.push(theme.fg("dim", `· ${fmt(last.output / (last.decodeMs / 1000))} tok/s`));
		}

		if (last.stopReason === "aborted" || last.stopReason === "error") {
			parts.push(theme.fg("warning", `· ${last.stopReason}`));
		}

		ctx.ui.setStatus(STATE_KEY, parts.join(" "));
	};

	/** Rebuild `last` from the current branch's persisted entries. */
	const restore = (ctx: ExtensionContext) => {
		last = undefined;
		for (const entry of ctx.sessionManager.getBranch()) {
			if (entry.type !== "custom" || entry.customType !== STATE_KEY) continue;
			const data = entry.data as Metrics | undefined;
			if (data && typeof data.output === "number") last = data;
		}
		render(ctx);
	};

	pi.on("session_start", (_event, ctx) => restore(ctx));
	pi.on("session_tree", (_event, ctx) => restore(ctx));

	pi.on("before_provider_request", () => {
		pendingRequestAt = performance.now();
	});

	pi.on("message_start", (event) => {
		if (event.message.role !== "assistant") return;
		startAt = pendingRequestAt ?? performance.now();
		pendingRequestAt = null;
		firstTokenAt = null;
	});

	pi.on("message_update", (event) => {
		if (event.message.role !== "assistant") return;
		if (firstTokenAt === null) firstTokenAt = performance.now();
	});

	pi.on("message_end", (event, ctx) => {
		const message = event.message;
		if (message.role !== "assistant") return;

		const endAt = performance.now();
		const usage = message.usage;
		const output = usage?.output ?? 0;

		// No start stamp (e.g. message_start suppressed): nothing trustworthy to report.
		if (startAt === 0) return;

		const wallMs = Math.max(0, endAt - startAt);
		const decodeMs = firstTokenAt !== null ? Math.max(0, endAt - firstTokenAt) : undefined;
		const ttftMs = firstTokenAt !== null ? Math.max(0, firstTokenAt - startAt) : undefined;

		last = {
			output,
			reasoning: usage?.reasoning ?? 0,
			wallMs,
			decodeMs,
			ttftMs,
			stopReason: message.stopReason,
		};
		startAt = 0;
		firstTokenAt = null;

		// Persist a compact record so the readout survives resume/branch switches.
		pi.appendEntry(STATE_KEY, last);

		render(ctx);
	});

	pi.on("session_shutdown", (_event, ctx) => {
		if (ctx.hasUI) ctx.ui.setStatus(STATE_KEY, undefined);
	});

	pi.registerCommand("tps", {
		description: "Show or configure the tokens/second readout",
		getArgumentCompletions: (prefix) =>
			["on", "off", "decode", "wall", "ttft", "status"]
				.filter((a) => a.startsWith(prefix))
				.map((a) => ({ value: a, label: a })),
		handler: async (args, ctx) => {
			const arg = args.trim().toLowerCase();

			if (arg === "on" || arg === "off") {
				enabled = arg === "on";
				render(ctx);
				ctx.ui.notify(`TPS readout ${enabled ? "enabled" : "disabled"}`, "info");
				return;
			}

			if (arg === "decode" || arg === "wall" || arg === "ttft") {
				metric = arg;
				render(ctx);
				ctx.ui.notify(`TPS headline metric: ${metric}`, "info");
				return;
			}

			if (arg && arg !== "status") {
				ctx.ui.notify(`Unknown option "${arg}". Use: on | off | decode | wall | ttft`, "warning");
				return;
			}

			const lastText = last
				? [
						`output: ${last.output} tok` + (last.reasoning ? ` (${last.reasoning} reasoning)` : ""),
						`wall:   ${fmtDuration(last.wallMs)}`,
						last.decodeMs !== undefined && last.decodeMs > 0
							? `decode: ${fmtDuration(last.decodeMs)} → ${fmt(last.output / (last.decodeMs / 1000))} tok/s`
							: "decode: n/a (non-streaming)",
						last.ttftMs !== undefined ? `ttft:   ${fmtDuration(last.ttftMs)}` : "ttft:   n/a",
						`stop:   ${last.stopReason}`,
					].join("\n")
				: "no assistant message yet";

			ctx.ui.notify(
				`TPS readout: ${enabled ? "on" : "off"} | headline: ${metric}\n\nLast message:\n${lastText}`,
				"info",
			);
		},
	});
}
