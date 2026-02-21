#!/usr/bin/env bash
set -euo pipefail

target="${STACK_SSH_TARGET:-}"
host_dir="${STACK_HOST_DIR:-}"

if [ -z "$target" ] || [ -z "$host_dir" ]; then
  echo "stack-relaunch: set STACK_SSH_TARGET and STACK_HOST_DIR" >&2
  exit 2
fi

remote_cmd="${STACK_RELAUNCH_CMD:-docker compose up -d --build}"

ssh_opts=(
  -o BatchMode=yes
  -o StrictHostKeyChecking=accept-new
  -o UserKnownHostsFile="${HOME}/.config/agent/known_hosts"
)

if [ -n "${STACK_SSH_IDENTITY_FILE:-}" ]; then
  ssh_opts+=(-i "${STACK_SSH_IDENTITY_FILE}")
fi

exec ssh "${ssh_opts[@]}" "${target}" bash -lc 'cd "$1" && eval "$2"' bash "$host_dir" "$remote_cmd"
