# swarm installer

Source is private. This repo is the public tarball + `install.sh`.

```bash
curl -fsSL https://raw.githubusercontent.com/Eric-Boss/swarm-install/main/install.sh | bash
source ~/.bashrc    # zsh: ~/.zshrc · fish: ~/.config/fish/config.fish · nu: ~/.config/nushell/env.nu
swarm doctor
```

That installs the `swarm` CLI to `~/.swarm/` **and** the `/swarm` director
skill into Claude, Cursor, Grok, Codex, OpenCode, Pi, and `~/.agents/skills`.
In Codex, invoke `$swarm` or select swarm from `/skills`.
Codex gets one shared skill copy at `~/.agents/skills/swarm`.
Restart the coding agent after install to refresh its skill list.

Current release: swarm 0.2.6 (`v0.2.6`).
