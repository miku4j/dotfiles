/**
 * Safeguard Extension
 *
 * Asks for confirmation before:
 *   1. Reading files that commonly hold secrets (`.env`, private keys, creds...).
 *   2. Writing/editing those same sensitive files.
 *   3. Running dangerous / destructive bash commands (rm -rf, sudo, dd, curl|sh...).
 *
 * Choices: "Allow once", "Allow for session" (remember the exact file/command),
 * or "Deny". Non-interactive modes deny by default (fail-safe).
 *
 * Toggle at runtime with `/safeguard` (on/off/status).
 */

import type { ExtensionAPI, ToolCallEvent } from "@earendil-works/pi-coding-agent";
import * as path from "node:path";

/** Files/globs that commonly contain secrets. Matched against basename + full path. */
const SENSITIVE_BASENAME = [
	/^\.env(\..+)?$/i,
	/^\.envrc$/i,
	/^id_(rsa|dsa|ecdsa|ed25519|ecdsa_sk|ed25519_sk)$/i,
	/^\.?(npmrc|netrc|pgpass|pypirc|htpasswd|dockercfg|git-credentials)$/i,
	/^credentials(\.json|\.yaml)?$/i,
	/^secrets?\.(json|ya?ml|toml|txt|properties)$/i,
	/^auth\.json$/i,
	/^service[-_]?account.*\.json$/i,
	/\.(pem|key|p12|pfx|jks|keystore|ppk)$/i,
	/^\.my\.cnf$/i,
	/^wp-config\.php$/i,
];

/** Directory names that hold credentials. Matched against any path segment. */
const SENSITIVE_DIRS = new Set([
	".ssh",
	".aws",
	".gnupg",
	".kube",
	".azure",
	".terraform.d",
	"gcloud",
]);

/** Sensitive full paths (matched on the normalized absolute path). */
const SENSITIVE_PATH = [
	/\/\.docker\/config\.json$/,
	/\/\.config\/gh\//,
	/\/\.config\/glab\.yml$/,
	/^\/(etc|private\/etc)\/(shadow|sudoers|gshadow)$/,
];

/** Destructive / high-risk shell commands. */
const DANGEROUS_COMMAND = [
	/\brm\s+(-[a-z-]*[rf][a-z-]*\s+)*/i, // rm with recursive/force flags
	/\brm\s+--(recursive|force|no-preserve-root)\b/i,
	/\bsudo\b|\bdoas\b|\bsu\s+-/i,
	/\b(chmod|chown)\b.*\b777\b/i,
	/\b(chmod|chown)\b\s+(-[a-zA-Z]+\s+)*-[a-zA-Z]*R/i,
	/\bmkfs(\.\w+)?\b/i,
	/\bdd\b[^\n]*\bof=\/dev\//i,
	/\b(shutdown|reboot|halt|poweroff|init\s+0|init\s+6)\b/i,
	/\b(kill|pkill|killall)\b[^\n]*(-9|SIGKILL)/i,
	/\b:\(\)\s*\{\s*:\s*\|\s*:\s*&\s*\}\s*;\s*:/, // fork bomb
	/\b>\s*\/dev\/(sd|hd|nvme|vd)/i,
	/\b(curl|wget)\b[^\n|]*\|\s*(sudo\s+)?(ba|z|da)?sh\b/i, // pipe download into shell
	/\bgit\s+(commit|push)\b/i, // never commit/push without explicit approval
	/\bgit\s+(push\s+.*(--force|-f)\b|reset\s+--hard|clean\s+-[a-z]*[fd])/i,
	/\b(shred|wipefs|fdisk|parted|blkdiscard)\b/i,
	/\b(DROP|TRUNCATE)\s+(TABLE|DATABASE|SCHEMA)\b/i,
	/\bmv\b[^\n]*\s\/dev\/null\b/i,
	/\btruncate\b[^\n]*\s-[sS]\s*0\b/i,
];

/** Destructive / high-risk PowerShell commands. */
const POWERSHELL_DANGER = [
	/\bRemove-Item\b[^\n]*(-Recurse|-Force|-r\b|-f\b)/i,
	/\b(Format-Volume|Clear-Disk|Initialize-Disk|Remove-Partition)\b/i,
	/\b(Stop-Computer|Restart-Computer)\b/i,
	/\bSet-ExecutionPolicy\b[^\n]*\b(Unrestricted|Bypass)\b/i,
	/\b(Invoke-Expression|iex)\b[^\n]*\|/i,
	/\b(Invoke-WebRequest|iwr|curl|wget)\b[^\n|]*\|\s*(Invoke-Expression|iex)\b/i,
];

const READ_LIKE = new Set(["read", "grep", "find", "ls"]);
const WRITE_LIKE = new Set(["write", "edit"]);

function matchAny(patterns: RegExp[], value: string): boolean {
	return patterns.some((p) => p.test(value));
}

/** Find a token in a shell command that references a sensitive file. */
function findSensitiveToken(command: string, cwd: string): string | undefined {
	const home = process.env.HOME ?? process.env.USERPROFILE ?? "";
	const tokens = command
		.replace(/([~])(?=\/)/g, home)
		.split(/[\s|;&()<>'"`=,]+/)
		.filter(Boolean);

	for (const token of tokens) {
		if (isSensitivePath(token, cwd)) return token;
	}
	return undefined;
}

function isSensitivePath(rawPath: string, cwd: string): boolean {
	if (!rawPath) return false;
	const normalized = rawPath.replace(/\\/g, "/");
	const abs = path.isAbsolute(normalized) ? normalized : path.resolve(cwd, normalized);
	const base = path.basename(abs);

	if (matchAny(SENSITIVE_BASENAME, base)) return true;
	if (abs.split("/").some((seg) => SENSITIVE_DIRS.has(seg))) return true;
	if (matchAny(SENSITIVE_PATH, `/${abs.replace(/^\/+/, "")}`)) return true;
	return false;
}

export default function (pi: ExtensionAPI) {
	let enabled = true;
	// Exact paths / commands the user chose to allow for this session.
	const allowedPaths = new Set<string>();
	const allowedCommands = new Set<string>();

	pi.registerCommand("safeguard", {
		description: "Show or toggle the safeguard (on/off)",
		handler: async (args, ctx) => {
			const arg = (args || "").trim().toLowerCase();
			if (arg === "on" || arg === "off") {
				enabled = arg === "on";
			} else if (arg && arg !== "status") {
				ctx.ui.notify("Usage: /safeguard [on|off|status]", "warning");
				return;
			}

			if (enabled && arg === "on") {
				allowedPaths.clear();
				allowedCommands.clear();
			}

			ctx.ui.notify(
				`Safeguard is ${enabled ? "ON" : "OFF"} ` +
					`(${allowedPaths.size} path(s), ${allowedCommands.size} command(s) allowed this session)`,
				enabled ? "info" : "warning",
			);
		},
	});

	pi.on("tool_call", async (event: ToolCallEvent, ctx) => {
		if (!enabled) return undefined;

		// --- Sensitive file access ---
		const toolName = event.toolName;
		if (READ_LIKE.has(toolName) || WRITE_LIKE.has(toolName)) {
			const input = event.input as Record<string, unknown>;
			const rawPath = (input.path ?? input.file_path) as string | undefined;
			if (rawPath && isSensitivePath(rawPath, ctx.cwd)) {
				const action = WRITE_LIKE.has(toolName) ? "modify" : "read";
				if (allowedPaths.has(rawPath)) return undefined;

				if (!ctx.hasUI) {
					return { block: true, reason: `Sensitive file ${action} blocked (no UI for confirmation): ${rawPath}` };
				}
				const choice = await ctx.ui.select(
					`⚠️  Sensitive file ${action.toUpperCase()}: ${rawPath}\n\nThis may expose secrets. Allow?`,
					["Allow once", "Allow for session", "Deny"],
				);
				if (choice === "Deny" || !choice) {
					return { block: true, reason: `Sensitive file ${action} denied by user: ${rawPath}` };
				}
				if (choice === "Allow for session") allowedPaths.add(rawPath);
				return undefined;
			}
		}

		// --- Dangerous shell commands (and secret reads via shell) ---
		if (toolName === "bash" || toolName === "powershell") {
			const command = (event.input as { command?: string }).command ?? "";
			const danger = matchAny(toolName === "powershell" ? POWERSHELL_DANGER : DANGEROUS_COMMAND, command);
			const secret = findSensitiveToken(command, ctx.cwd);
			if (!danger && !secret) return undefined;
			if (allowedCommands.has(command)) return undefined;

			const label = danger
				? `⚠️  Potentially DANGEROUS command:\n\n  ${command}`
				: `⚠️  Command touches a SENSITIVE file (${secret}):\n\n  ${command}`;
			const reason = danger ? `Dangerous command` : `Sensitive file access`;

			if (!ctx.hasUI) {
				return { block: true, reason: `${reason} blocked (no UI for confirmation): ${command}` };
			}
			const choice = await ctx.ui.select(`${label}\n\nAllow?`, ["Allow once", "Allow for session", "Deny"]);
			if (choice === "Deny" || !choice) {
				return { block: true, reason: `${reason} denied by user: ${command}` };
			}
			if (choice === "Allow for session") allowedCommands.add(command);
			return undefined;
		}

		return undefined;
	});
}