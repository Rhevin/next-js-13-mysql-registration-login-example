#!/usr/bin/env bash
# Compare CloudLinux Shared node_modules Store vs ordinary npm installs on a canary host.
# Uses two copies of this app with the same package-lock.json.
#
# Prerequisites (root on server):
#   yum install lvemanager cl-bun --enablerepo=cloudlinux-updates-testing
#   cl-node-modules-storage enable
#   cl-node-modules-storage status   # feature_status: enabled (panel integration may still be required)
#
# Usage (from repo root):
#   ./scripts/benchmark-shared-node-modules.sh preflight
#   ./scripts/benchmark-shared-node-modules.sh run
#   ./scripts/benchmark-shared-node-modules.sh report
#   ./scripts/benchmark-shared-node-modules.sh cleanup
set -euo pipefail

HOST="${BENCHMARK_HOST:-lt-bnk-web40016.main-hosting.eu}"
SSH_PORT="${BENCHMARK_SSH_PORT:-22}"
TEST_USER="${BENCHMARK_USER:-u11004003}"
REMOTE_BASE="${BENCHMARK_REMOTE_BASE:-/home/${TEST_USER}/cl-nm-bench}"
APP_SHARED="${REMOTE_BASE}/shared-store"
APP_REGULAR="${REMOTE_BASE}/regular-npm"
NODE_BIN="${NODE_BIN:-/opt/alt/alt-nodejs24/root/bin/node}"
NPM_BIN="${NPM_BIN:-/opt/alt/alt-nodejs24/root/bin/npm}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
}

ssh_root() {
  ssh -o BatchMode=yes -o ConnectTimeout=25 -p "$SSH_PORT" "root@${HOST}" "$@"
}

ssh_user() {
  ssh_root "su -s /bin/bash - '${TEST_USER}' -c $(printf '%q' "$*")"
}

rsync_app() {
  ssh_root "mkdir -p '${REMOTE_BASE}'"
  rsync -az --delete \
    -e "ssh -o BatchMode=yes -p ${SSH_PORT}" \
    --exclude node_modules \
    --exclude .next \
    --exclude .git \
    "${REPO_ROOT}/" "root@${HOST}:${REMOTE_BASE}/source/"
}

measure_dir() {
  local label="$1"
  local path="$2"
  ssh_root "bash -s" -- "$label" "$path" <<'REMOTE'
set -euo pipefail
label="$1"
path="$2"
if [[ ! -d "$path/node_modules" ]]; then
  echo "${label}: missing node_modules at ${path}"
  exit 1
fi
apparent=$(du -sb "$path/node_modules" | awk '{print $1}')
used=$(du -s --apparent-size=0 "$path/node_modules" 2>/dev/null | awk '{print $1*1024}' || du -sb "$path/node_modules" | awk '{print $1}')
inodes=$(find "$path/node_modules" -xdev -type f 2>/dev/null | wc -l | tr -d ' ')
hardlinks=$(find "$path/node_modules" -xdev -type f -links +1 2>/dev/null | wc -l | tr -d ' ')
echo "${label}_path=${path}"
echo "${label}_apparent_bytes=${apparent}"
echo "${label}_file_count=${inodes}"
echo "${label}_multi_link_files=${hardlinks}"
REMOTE
}

cmd_preflight() {
  echo "host=${HOST} user=${TEST_USER} remote_base=${REMOTE_BASE}"
  ssh_root "bash -s" <<'REMOTE'
set -euo pipefail
command -v cl-node-modules-storage >/dev/null
command -v rpm >/dev/null
rpm -q cl-bun lvemanager >/dev/null
cl-node-modules-storage status
df -h / /home 2>/dev/null | tail -n +2
REMOTE
}

cmd_run() {
  rsync_app
  ssh_root "bash -s" -- "$TEST_USER" "$REMOTE_BASE" "$APP_SHARED" "$APP_REGULAR" "$NPM_BIN" <<'REMOTE'
set -euo pipefail
user="$1"
base="$2"
shared="$3"
regular="$4"
npm="$5"
src="${base}/source"

prepare_tree() {
  local dest="$1"
  rm -rf "$dest"
  mkdir -p "$dest"
  cp -a "${src}/." "$dest/"
  chown -R "${user}:${user}" "$dest"
}

prepare_tree "$shared"
prepare_tree "$regular"

# Shared-store path: user must not be on exclude list.
cl-node-modules-storage exclude-list --remove "$user" >/dev/null 2>&1 || true

install_as_user() {
  local dir="$1"
  su -s /bin/bash - "$user" -c "cd $(printf '%q' "$dir") && rm -rf node_modules && ${npm} ci --no-audit --no-fund"
}

echo "=== shared-store install (user not excluded) ==="
install_as_user "$shared"

# Ordinary npm path: excluded accounts bypass the shared delivery socket.
cl-node-modules-storage exclude-list --add "$user"

echo "=== regular npm install (user excluded) ==="
install_as_user "$regular"

cl-node-modules-storage exclude-list --remove "$user" >/dev/null 2>&1 || true
REMOTE

  cmd_report
}

cmd_report() {
  measure_dir shared "$APP_SHARED"
  measure_dir regular "$APP_REGULAR"
  ssh_root "cl-node-modules-storage status"
  ssh_root "bash -s" -- "$APP_SHARED" "$APP_REGULAR" <<'REMOTE'
set -euo pipefail
shared="$1"
regular="$2"
s=$(du -sb "${shared}/node_modules" | awk '{print $1}')
r=$(du -sb "${regular}/node_modules" | awk '{print $1}')
if [[ "$r" -gt 0 ]]; then
  pct=$(awk -v s="$s" -v r="$r" 'BEGIN { printf "%.2f", (1 - s/r) * 100 }')
  echo "apparent_saving_vs_regular_percent=${pct}"
  echo "apparent_saving_bytes=$(( r - s ))"
fi
REMOTE
}

cmd_cleanup() {
  ssh_root "rm -rf '${REMOTE_BASE}'"
  ssh_root "cl-node-modules-storage exclude-list --remove '${TEST_USER}'" >/dev/null 2>&1 || true
  echo "removed ${REMOTE_BASE} on ${HOST}"
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    preflight) cmd_preflight ;;
    run) cmd_run ;;
    report) cmd_report ;;
    cleanup) cmd_cleanup ;;
    -h|--help|help|"") usage ;;
    *) echo "unknown command: $cmd" >&2; usage >&2; exit 1 ;;
  esac
}

main "$@"
