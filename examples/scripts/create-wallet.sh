#!/usr/bin/env bash
# create-wallet.sh — interactive wrapper around xeqm-wallet --generate-new-wallet.
#
# Walks the user through:
#   1. Picking a destination path
#   2. Setting a strong password
#   3. Recording the 25-word seed (offline!)
#
# After creation, the wallet file lives at ${WALLET_DIR}/${WALLET_NAME}{,.keys,.address.txt}.
set -euo pipefail

BIN="${XEQM_WALLET_BIN:-xeqm-wallet}"
WALLET_DIR="${XEQM_WALLET_DIR:-${HOME}/xeqm-wallets}"
WALLET_NAME="${1:-main}"
DAEMON="${XEQM_DAEMON_ADDR:-127.0.0.1:9231}"

if [ -z "${WALLET_NAME}" ]; then
    echo "Usage: $0 <wallet-name>" >&2
    exit 1
fi

mkdir -p "${WALLET_DIR}"

if [ -e "${WALLET_DIR}/${WALLET_NAME}" ] || [ -e "${WALLET_DIR}/${WALLET_NAME}.keys" ]; then
    echo "Wallet already exists at ${WALLET_DIR}/${WALLET_NAME} — refusing to overwrite." >&2
    exit 1
fi

cat <<EOF
Creating wallet: ${WALLET_DIR}/${WALLET_NAME}
Daemon:          ${DAEMON}

You will be prompted for a password TWICE. Pick something strong (32+ chars).
After confirmation, the wallet will display a 25-word mnemonic seed.

>>> WRITE THE SEED DOWN ON PAPER, OFFLINE. <<<

Without the seed, the wallet cannot be restored if the file is lost or corrupted.

Press Enter to continue, or Ctrl+C to abort.
EOF
read -r _

exec "${BIN}" \
    --generate-new-wallet "${WALLET_DIR}/${WALLET_NAME}" \
    --daemon-address "${DAEMON}"
