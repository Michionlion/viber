#!/bin/bash
set -euo pipefail

coder_uid="$(id -u coder)"
coder_gid="$(id -g coder)"

mkdir -p \
  /workspace \
  /home/coder \
  /home/coder/.config/code-server \
  /home/coder/.config/agent \
  /home/coder/.local \
  /home/coder/.local/share/code-server/User \
  /home/coder/.codex \
  /home/coder/.qwen

if [ ! -f /home/coder/.bashrc ]; then
  if [ -f /etc/skel/.bashrc ]; then
    cp /etc/skel/.bashrc /home/coder/.bashrc
  else
    touch /home/coder/.bashrc
  fi
fi

if [ ! -f /home/coder/.bash_profile ] && [ -f /etc/skel/.bash_profile ]; then
  cp /etc/skel/.bash_profile /home/coder/.bash_profile
fi

if [ ! -f /home/coder/.bash_logout ] && [ -f /etc/skel/.bash_logout ]; then
  cp /etc/skel/.bash_logout /home/coder/.bash_logout
fi

if [ ! -f /home/coder/.config/code-server/config.yaml ] && [ -f /opt/devbox-defaults/code-server/config.yaml ]; then
  cp /opt/devbox-defaults/code-server/config.yaml /home/coder/.config/code-server/config.yaml
fi

if [ ! -f /home/coder/.local/share/code-server/User/settings.json ] && [ -f /opt/devbox-defaults/code-server/User/settings.json ]; then
  cp /opt/devbox-defaults/code-server/User/settings.json /home/coder/.local/share/code-server/User/settings.json
fi

if [ -d /opt/devbox-defaults/agent ]; then
  if [ -z "$(ls -A /home/coder/.config/agent 2>/dev/null)" ]; then
    cp -r /opt/devbox-defaults/agent/. /home/coder/.config/agent/
  fi
fi

ln -sf /home/coder/.config/agent/codex/config.toml /home/coder/.codex/config.toml || true
ln -sf /home/coder/.config/agent/qwen/settings.json /home/coder/.qwen/settings.json || true
ln -sf /home/coder/.config/agent/qwen/.env /home/coder/.qwen/.env || true
ln -sf /home/coder/.config/agent/aider/.aider.conf.yml /home/coder/.aider.conf.yml || true

chown -R "${coder_uid}:${coder_gid}" /workspace /home/coder
chmod 0775 /workspace
chmod 0700 /home/coder /home/coder/.config /home/coder/.config/agent /home/coder/.local
chmod 0700 /home/coder/.config/code-server
