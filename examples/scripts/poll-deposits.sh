#!/usr/bin/env bash
# Poll wallet-rpc for incoming transfers. Prints one line per deposit.
# Requires jq. Credentials read from env.
set -euo pipefail

HOST="${XEQM_WALLET_HOST:-127.0.0.1}"
PORT="${XEQM_WALLET_PORT:-9234}"
USER="${XEQM_WALLET_USER:-exchange}"
PASS="${XEQM_WALLET_PASS:?set XEQM_WALLET_PASS}"
ACCOUNT="${XEQM_ACCOUNT:-0}"

curl -sS -u "${USER}:${PASS}" --digest \
    "http://${HOST}:${PORT}/json_rpc" \
    -H 'Content-Type: application/json' \
    -d "{\"jsonrpc\":\"2.0\",\"id\":\"0\",\"method\":\"get_transfers\",\"params\":{\"in\":true,\"account_index\":${ACCOUNT}}}" \
| jq -r '.result.in[]? | [.tx_hash, .amount, .confirmations, .subaddr_index.minor, .address] | @tsv'
