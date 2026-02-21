# Agent Notes (Vibe Stack)

This repo defines a private, Tailscale-first Docker development stack:
- `devbox`: code-server + ttyd (no in-stack auth)
- `llm-server`: llama.cpp OpenAI-compatible API on the internal Docker network only

The security model is: Tailscale on the host + host port binding discipline. Do not weaken that without explicit user approval.

## Hard Rules (Do Not Change)
- Do NOT mount `/var/run/docker.sock` into containers.
- Do NOT use `privileged: true`.
- Do NOT expose `llm-server` to the host (keep `expose`, no host `ports`).
- Do NOT publish code-server/ttyd/preview ports to `0.0.0.0`.
  - Use `BIND_IP` and bind only to `127.0.0.1` (host-only) or the host's Tailscale IP (usually `100.x`).
- Do NOT add public internet components (Caddy, reverse proxies for WAN access, tunnels, public TLS, fail2ban, etc.).
- Do NOT install or run Tailscale inside Docker. Tailscale runs on the host.
- Do NOT add additional auth layers inside this stack unless the user explicitly requests it.

## What You *Can* Modify
Safe areas to change (with care):
- `docker-compose.yml`: services, resource limits, network wiring, `BIND_IP` behavior, env passthrough.
- `Dockerfile`: add dev tooling, pin versions, update agent CLIs, improve install robustness.
- `supervisord.conf`: how code-server/ttyd are launched.
- `agent-shell.sh`: how ttyd spawns the agent shell/CLI.
- `config/code-server/config.yaml`: keep `auth: none` and `cert: false` (this is intentional for tailnet-only access).
- `.env.example` and `README.md`: documentation and tunables.

Avoid changing persistence model unless requested:
- `/workspace` and config dirs are Docker named volumes to avoid bind-mount permission issues.
- Saving is expected to happen primarily via git pushes.

## Agent CLI Defaults
- Installed CLIs: `codex`, `aider`, `qwen`.
- Source-controlled defaults live under `config/agent/` and are seeded into `/home/coder/.config/agent` on first run.
- Runtime symlinks map those files into expected paths:
  - `/home/coder/.codex/config.toml`
  - `/home/coder/.aider.conf.yml`
  - `/home/coder/.qwen/settings.json`
- Keep OpenAI-compatible clients (`codex`, `aider`, `qwen`) pointed at `http://llm-server:8081/v1`.

## How To Edit Stack Config From Inside devbox
The stack repo is bind-mounted into `devbox` at:
- `/stack`

Edit files in `/stack` using code-server or ttyd.

## How To Relaunch The Stack (No Docker Socket)
Do not try to run Docker inside `devbox`.

Instead, use SSH from `devbox` to the host and run Docker Compose on the host:
- Helper: `/usr/local/bin/stack-relaunch` (source: `/stack/stack-relaunch.sh`)

### Required environment (provided via `docker-compose.yml`)
Set these in the host `.env` file so they are passed into `devbox`:
- `STACK_SSH_TARGET`: e.g. `saejin@<host-tailnet-name-or-tailnet-ip>`
- `STACK_HOST_DIR`: host path to this repo, e.g. `/Users/saejin/Projects/personal/viber`
- `STACK_SSH_IDENTITY_FILE` (optional): path inside `devbox` to private key, e.g. `/home/coder/.config/agent/id_ed25519`
- `STACK_RELAUNCH_CMD` (optional): defaults to `docker compose up -d --build`

### One-time SSH setup (typical)
1. Enable SSH on the host (macOS: System Settings -> Remote Login).
2. In `devbox`, create a key if you don't have one:
   - `ssh-keygen -t ed25519 -f ~/.config/agent/id_ed25519 -N ""`
3. Add `~/.config/agent/id_ed25519.pub` to the host user's `~/.ssh/authorized_keys`.
   - Prefer a restricted user / forced command if you want tighter control.
4. From `devbox`, run:
   - `stack-relaunch`

## Port Publishing Guidance (Phone Access)
- Default safe mode: `BIND_IP=127.0.0.1` (host-only).
- Phone mode (tailnet-only): set `BIND_IP` to the host's Tailscale IPv4 (usually `100.x`).
- Never set `BIND_IP=0.0.0.0` unless the user explicitly wants LAN/WAN exposure and has firewall rules in place.

## Updating Pinned Images
If you update pinned base images:
- Update `Dockerfile` (`codercom/code-server:<tag>`) and keep it pinned to a specific version.
- Update `llm-server` image digest in `docker-compose.yml`.
- Prefer pinning by digest for `llm-server` to avoid surprise changes.

## Operational Notes
- `devbox-init` exists to seed config defaults and chmod/chown the named volumes so the non-root `coder` user can write. Do not remove it unless you replace it with an equivalent strategy.
- If `docker compose` on the host is too old to support `depends_on.condition`, you may need to run once on the host:
  - `docker compose run --rm devbox-init`
  - then `docker compose up -d --build`
