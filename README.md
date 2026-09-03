# swarm installer

Source is private. This repo is the public tarball + `install.sh`.

```bash
curl -fsSL https://raw.githubusercontent.com/Eric-Boss/swarm-install/main/install.sh | bash
source ~/.bashrc    # zsh: ~/.zshrc · fish: ~/.config/fish/config.fish · nu: ~/.config/nushell/env.nu
swarm doctor
```

That installs the `swarm` CLI to `~/.swarm/` **and** the `/swarm` director
skill into Claude, Cursor, Grok, Codex, OpenCode, Pi, and `~/.agents/skills`.
Restart the coding agent after install or it will not see `/swarm`.

Current release: swarm 0.2.4 (`v0.2.4`).
