#!/usr/bin/env bash
# Ping the local daemon and report sync status.
set -euo pipefail

HOST="${XEQM_DAEMON_HOST:-127.0.0.1}"
PORT="${XEQM_DAEMON_PORT:-9231}"

response=$(curl -sS "http://${HOST}:${PORT}/json_rpc" \
    -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","id":"0","method":"get_info"}')

height=$(echo "$response" | grep -oP '"height":\s*\K[0-9]+' | head -1)
target=$(echo "$response" | grep -oP '"target_height":\s*\K[0-9]+' | head -1)
synced=$(echo "$response" | grep -oP '"synchronized":\s*\K(true|false)' | head -1)
peers=$(echo "$response" | grep -oP '"outgoing_connections_count":\s*\K[0-9]+' | head -1)

echo "height:  $height"
echo "target:  $target"
echo "synced:  $synced"
echo "peers:   $peers"

[[ "$synced" == "true" ]] || { echo "NOT SYNCED"; exit 1; }
