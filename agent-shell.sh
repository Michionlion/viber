#!/usr/bin/env bash
set -euo pipefail

cd /workspace

export HOME=/home/coder
export OPENAI_BASE_URL="${OPENAI_BASE_URL:-http://llm-server:8081/v1}"
export OPENAI_API_KEY="${OPENAI_API_KEY:-dummy}"
export OPENAI_MODEL="${OPENAI_MODEL:-Qwen-Coder-Next.gguf}"
export AIDER_MODEL="${AIDER_MODEL:-openai/${OPENAI_MODEL}}"
export QWEN_CODE_MODEL="${QWEN_CODE_MODEL:-${OPENAI_MODEL}}"

mkdir -p "${HOME}/.codex" "${HOME}/.qwen"

if [ -f "${HOME}/.config/agent/codex/config.toml" ]; then
  ln -sf "${HOME}/.config/agent/codex/config.toml" "${HOME}/.codex/config.toml"
fi

if [ -f "${HOME}/.config/agent/qwen/settings.json" ]; then
  ln -sf "${HOME}/.config/agent/qwen/settings.json" "${HOME}/.qwen/settings.json"
fi

if [ -f "${HOME}/.config/agent/qwen/.env" ]; then
  ln -sf "${HOME}/.config/agent/qwen/.env" "${HOME}/.qwen/.env"
fi

if [ -f "${HOME}/.config/agent/aider/.aider.conf.yml" ]; then
  ln -sf "${HOME}/.config/agent/aider/.aider.conf.yml" "${HOME}/.aider.conf.yml"
fi

if [ -n "${AGENT_CMD:-}" ]; then
  exec bash -lc "$AGENT_CMD"
fi

if command -v codex >/dev/null 2>&1; then
  exec codex
fi

exec bash -l
