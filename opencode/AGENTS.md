## Git Conventions

- Use semantic commit messages: `feat:`, `fix:`, `chore:`, `refactor:`, `test:`, `docs:`, `style:`, `perf:`, `ci:`, `build:`, `revert:`
- Keep the subject line under 72 characters
- Use the imperative mood ("add" not "added")
- NEVER run git commit or git push unless the user says "commit" or "push" explicitly. Do not infer commit intent from phrases like "fix this", "done?", "go", etc. The permission system also blocks these commands — you must ask the user to approve.

## System

- OS: Arch Linux WSL2
- Package manager: `pacman` (use `sudo pacman -S <package>` for system-wide installs)

## Nix Fallback

- If a command, package, or tool is not available on the current system, use Nix as the primary fallback to provide it.
- Prefer `nix shell nixpkgs#<package> -c <command>` for one-off commands.
- Prefer `nix run nixpkgs#<package>` for tools.
- Use `nix profile install nixpkgs#<package>` if the user wants to install permanently.
- Search for packages with `nix search nixpkgs <query>`.
- Only fall back to `pacman` or `pipx` if Nix is unavailable or the package doesn't exist in nixpkgs.
