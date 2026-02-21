#!/usr/bin/env bash
set -euo pipefail

cd /workspace

export HOME=/home/coder
export OPENAI_BASE_URL="${OPENAI_BASE_URL:-http://llm-server:8081/v1}"
export OPENAI_API_KEY="${OPENAI_API_KEY:-dummy}"

if [ -n "${AGENT_CMD:-}" ]; then
  exec bash -lc "$AGENT_CMD"
fi

if command -v codex >/dev/null 2>&1; then
  exec codex
fi

exec bash -l
