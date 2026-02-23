# Private Tailscale Vibe Stack

## What this stack does

This project provides a private, Docker-based development setup for personal "vibe coding":

- `code-server` in browser on port `8080`
- `ttyd` terminal in browser on port `7681` for agent CLIs (`codex`, `aider`, `qwen`/`qwen-code`, or plain bash)
- local `llama.cpp` OpenAI-compatible API (`/v1`) on an internal Docker network only
- app preview pass-through on ports `3000-3010` for phone testing
- preinstalled agent CLIs inside `devbox`: `codex`, `aider`, `qwen`

By default, published ports bind to `127.0.0.1` on the host. For phone access over Tailscale, set `BIND_IP` to your host's Tailscale IP (usually `100.x`).

## Folder layout

```text
.
├── Dockerfile
├── docker-compose.yml
├── supervisord.conf
├── agent-shell.sh
├── .env.example
├── .gitignore
├── README.md
├── workspace/
├── models/
├── coder-local/
└── config/
    ├── agent/
    │   ├── aider/
    │   ├── codex/
    │   └── qwen/
    └── code-server/
      ├── config.yaml
      └── User/
         └── settings.json
```

Note: `docker-compose.yml` uses Docker named volumes by default for `/workspace`, `/home/coder` (dotfiles like `.bashrc`), and config dirs to avoid bind-mount permission problems. The files under `config/` are baked into the image as defaults and used to seed those volumes on first run.

## Defaults and seeded settings

- Source-controlled defaults are placed under `config/` and are copied into the image at build time. On first run `devbox-init` seeds these into the named volumes so they become the live defaults for the `coder` user.
- Current seeded VS Code user defaults: [config/code-server/User/settings.json](config/code-server/User/settings.json). It contains these defaults:
  - `"chat.disableAIFeatures": true` — disables built-in AI features by default.
  - `"workbench.colorTheme": "Default Dark Modern"` — default theme.
  - `"window.menuBarVisibility": "classic"` — classic menu bar visibility.
- The init logic that performs seeding and permission fixes has been moved into a dedicated script: `scripts/devbox-init-entrypoint.sh`. This script is copied into the image and invoked by the `devbox-init` service.

## Persistent home (dotfiles)

- The `coder` home directory is persisted in a named volume (`coder-home`) so user dotfiles (`.bashrc`, `.zshrc`, etc.) are editable and survive container recreation.
- On first run the init script will copy skeleton files from `/etc/skel` into `/home/coder` if they are missing.

## Applying changes to an existing instance

- If you edit a source-controlled default (for example `config/code-server/User/settings.json`) and want to reseed an existing install, you can re-run the init container to copy defaults into volumes without rebuilding the image:

```bash
docker compose run --rm devbox-init
```

- Alternatively, to apply a new image build (for example after changing `Dockerfile` or `scripts/devbox-init-entrypoint.sh`):

```bash
docker compose up -d --build
```

Note: `devbox-init` intentionally reuses the same `vibe-devbox:local` image.

## Prerequisites

- Docker Engine + Docker Compose plugin
- NVIDIA driver + NVIDIA container runtime configured for Docker
- Tailscale installed on the host machine (not in Docker)

## Host Tailscale setup (high-level)

1. Install Tailscale on your host and phone.
2. Log into the same tailnet account on both devices.
3. Verify phone can reach the host in Tailscale:
   - Example: `ping <host-tailnet-name>` from another tailnet device
   - Or open another service on the host over tailnet to confirm connectivity

## Start the stack

1. Create local env file:

   ```bash
   cp .env.example .env
   ```

2. For phone access over Tailscale, set `BIND_IP` in `.env` to your host's Tailscale IPv4:

   ```bash
   echo "BIND_IP=$(tailscale ip -4 | head -n1)" >> .env
   ```

3. Build and start:

   ```bash
   docker compose up -d --build
   ```

4. Check status:

   ```bash
   docker compose ps
   ```

## Agent config defaults

Default config files are seeded into `/home/coder/.config/agent` and linked into each tool's expected home path:

- Codex: `/home/coder/.codex/config.toml`
- aider: `/home/coder/.aider.conf.yml`
- qwen-code: `/home/coder/.qwen/settings.json`

All defaults target the internal llama.cpp endpoint:

- Base URL: `http://llm-server:8081/v1`
- API key: `dummy`
- Model: `Qwen-Coder-Next.gguf`

## Access from phone (while connected to Tailscale)

These URLs work when `BIND_IP` is set to your host's Tailscale IP (or you otherwise publish the ports to a Tailscale-reachable interface).

- code-server: `http://<host-tailnet-name>:8080`
- ttyd terminal: `http://<host-tailnet-name>:7681`
- app preview example: `http://<host-tailnet-name>:3000`

## Agent can edit and relaunch the stack (optional)

The stack repo is bind-mounted into `devbox` at `/stack`, so you can edit `docker-compose.yml`, `Dockerfile`, etc from code-server or ttyd.

To let the agent relaunch the stack without mounting the Docker socket into containers, use SSH from `devbox` to the host:

1. Enable SSH on the host (macOS: System Settings -> Remote Login).
2. In `devbox`, generate an SSH key:

   ```bash
   ssh-keygen -t ed25519 -f ~/.config/agent/id_ed25519 -N ""
   ```

3. Add the public key to the host's `~/.ssh/authorized_keys` (recommended: use a restricted user / forced command).
4. Set these in `.env` on the host:

   ```bash
   STACK_SSH_TARGET=saejin@<host-tailnet-name>
   STACK_HOST_DIR=/Users/saejin/Projects/personal/viber
   STACK_SSH_IDENTITY_FILE=/home/coder/.config/agent/id_ed25519
   ```

5. From ttyd inside `devbox`, run:

   ```bash
   stack-relaunch
   ```

## Run dev servers so preview works

Your app must listen on `0.0.0.0` in the container, not `127.0.0.1`.

- Vite:

  ```bash
  npm run dev -- --host 0.0.0.0 --port 3000
  ```

- Next.js:

  ```bash
  npm run dev -- -H 0.0.0.0 -p 3000
  ```

- Flask:

  ```bash
  flask run --host=0.0.0.0 --port=3000
  ```

## Switch agent command (bash -> codex/qwen/aider)

Set `AGENT_CMD` in `.env` and restart:

```bash
echo "AGENT_CMD=codex" >> .env
docker compose up -d
```

Other examples:

- `AGENT_CMD=qwen`
- `AGENT_CMD=qwen-code`
- `AGENT_CMD="aider --model openai/Qwen-Coder-Next.gguf"`

## Codex: local vs external models

Codex is configured with two profiles in `/home/coder/.codex/config.toml`:

- `local` (default): talks to `http://llm-server:8081/v1`
- `openai`: talks to OpenAI with `CODEX_OPENAI_API_KEY`

Examples:

- Local (default): `codex`
- Force local: `codex --profile local`
- External: `CODEX_OPENAI_API_KEY=... codex --profile openai`

## Security model

- Tailscale on the host is the primary access control layer.
- No public internet exposure is configured in this stack.
- `llm-server` is internal-only (`expose`, no host `ports`).
- No Docker socket mount is used.
- Published ports should bind to the host's Tailscale IP, not `0.0.0.0` (unless you have host firewall rules that prevent non-tailnet access).
- Host filesystem access is limited to explicit bind mounts:
  - `./models` (read-only into `llm-server`)
  - `./` (mounted into `devbox` at `/stack` for editing stack config)

## Troubleshooting

- Dev server works in container but not from phone:
  - Ensure the server binds `0.0.0.0`, not `127.0.0.1`.
  - Verify port is in `3000-3010`.
- `llama.cpp` cannot see GPU:
  - Confirm NVIDIA runtime is installed and working with Docker.
  - Check `docker compose logs llm-server` for CUDA-related startup errors.
- code-server/ttyd reachable on host but not phone:
  - Confirm phone is connected to Tailscale.
  - Verify host and phone are in the same tailnet.
  - Confirm host tailnet name/IP is correct.
