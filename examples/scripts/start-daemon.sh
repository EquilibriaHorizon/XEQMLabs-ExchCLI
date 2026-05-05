#!/usr/bin/env bash
# start-daemon.sh — launch xeqm-d with sensible defaults for an exchange / service operator.
#
# By default the admin RPC is bound to 127.0.0.1:9231 (private). To run a public
# RPC node, export XEQM_PUBLIC_RPC=1 and the script will bind 0.0.0.0:9231.
# This script does NOT enable --service-node — exchanges run plain nodes.
set -euo pipefail

BIN="${XEQM_DAEMON_BIN:-xeqm-d}"
DATA_DIR="${XEQM_DATA_DIR:-${HOME}/.xeqm}"
LOG_FILE="${XEQM_DAEMON_LOG:-${DATA_DIR}/xeqm-d.log}"
RPC_PORT="${XEQM_DAEMON_RPC_PORT:-9231}"
P2P_PORT="${XEQM_P2P_PORT:-9230}"

if [ "${XEQM_PUBLIC_RPC:-0}" = "1" ]; then
    RPC_ADMIN="0.0.0.0:${RPC_PORT}"
    EXTRA_FLAGS="--public-node --confirm-external-bind"
else
    RPC_ADMIN="127.0.0.1:${RPC_PORT}"
    EXTRA_FLAGS=""
fi

mkdir -p "${DATA_DIR}"

exec "${BIN}" \
    --data-dir "${DATA_DIR}" \
    --log-file "${LOG_FILE}" \
    --log-level 1 \
    --p2p-bind-ip 0.0.0.0 \
    --p2p-bind-port "${P2P_PORT}" \
    --rpc-admin "${RPC_ADMIN}" \
    --out-peers 64 \
    --in-peers 32 \
    --non-interactive \
    ${EXTRA_FLAGS}
