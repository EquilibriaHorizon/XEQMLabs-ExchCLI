#!/usr/bin/env bash
# start-wallet-rpc.sh — launch xeqm-rpc against a local daemon.
#
# Required environment:
#   XEQM_WALLET_FILE   — path to the wallet file (e.g. /srv/xeqm/hot-wallet)
#   XEQM_WALLET_PWFILE — path to a chmod 600 file containing the wallet password
#   XEQM_RPC_LOGIN     — "user:strong_random_password" for HTTP Digest auth
#
# Optional:
#   XEQM_RPC_PORT      — wallet RPC port (default 9234)
#   XEQM_RPC_BIND_IP   — bind address (default 127.0.0.1; do NOT change unless firewalled)
#   XEQM_DAEMON_ADDR   — daemon RPC address (default 127.0.0.1:9231)
#   XEQM_LOG_FILE      — log file (default ${HOME}/.xeqm/wallet-rpc.log)
set -euo pipefail

BIN="${XEQM_RPC_BIN:-xeqm-rpc}"
RPC_PORT="${XEQM_RPC_PORT:-9234}"
RPC_BIND_IP="${XEQM_RPC_BIND_IP:-127.0.0.1}"
DAEMON_ADDR="${XEQM_DAEMON_ADDR:-127.0.0.1:9231}"
LOG_FILE="${XEQM_LOG_FILE:-${HOME}/.xeqm/wallet-rpc.log}"

: "${XEQM_WALLET_FILE:?set XEQM_WALLET_FILE to the wallet path}"
: "${XEQM_WALLET_PWFILE:?set XEQM_WALLET_PWFILE to a chmod 600 password file}"
: "${XEQM_RPC_LOGIN:?set XEQM_RPC_LOGIN to user:password (HTTP Digest)}"

if [ ! -f "${XEQM_WALLET_FILE}" ]; then
    echo "Wallet file not found: ${XEQM_WALLET_FILE}" >&2
    exit 1
fi

if [ ! -f "${XEQM_WALLET_PWFILE}" ]; then
    echo "Password file not found: ${XEQM_WALLET_PWFILE}" >&2
    exit 1
fi

mkdir -p "$(dirname "${LOG_FILE}")"

exec "${BIN}" \
    --wallet-file "${XEQM_WALLET_FILE}" \
    --password-file "${XEQM_WALLET_PWFILE}" \
    --rpc-bind-ip "${RPC_BIND_IP}" \
    --rpc-bind-port "${RPC_PORT}" \
    --rpc-login "${XEQM_RPC_LOGIN}" \
    --daemon-address "${DAEMON_ADDR}" \
    --log-file "${LOG_FILE}" \
    --log-level 1 \
    --non-interactive
