# Exchange Integration Guide

End-to-end integration path for exchanges and payment processors listing **XEQM**. This guide covers a production-grade single-host setup with hot wallet hardening, deposit attribution, and withdrawal flow.

For protocol-level details, the canonical references are the XEQMLabs whitepaper:

- Tokenomics: https://xeqmlabs.gitbook.io/docs/documentation/whitepaper/tokenomics
- Service nodes: https://xeqmlabs.gitbook.io/docs/documentation/whitepaper/service-nodes-sn

The on-chain semantics (RingCT, integrated addresses, subaddresses, RPC schemas) match Monero/Oxen — if you have integrated either before, the patterns translate directly.

---

## Architecture

```
       ┌─────────────────┐       ┌──────────────────┐
       │     xeqm-d      │◄──────┤     xeqm-rpc     │
       │  (node daemon)  │  RPC  │  (hot wallet)    │
       └────────┬────────┘       └─────────┬────────┘
                │                          │
          P2P 9230 (public)          HTTP 9234 (loopback)
          RPC 9231 (loopback)
                │                          │
         XEQM network              Exchange backend
```

- **`xeqm-d`** — full node daemon. Validates blocks, exposes daemon JSON-RPC on `9231`, gossips on `9230`.
- **`xeqm-rpc`** — wallet RPC server. Holds an exchange-controlled wallet, exposes wallet JSON-RPC on `9234`, talks to the local daemon over `127.0.0.1:9231`.
- **`xeqm-wallet`** — interactive CLI wallet. Used once to create the hot wallet file; not run during normal operations.

Run both services on the same host (simplest) or on two hosts inside a private network.

---

## Quick start

```bash
# 1. Get the binaries
git clone https://github.com/EquilibriaHorizon/XEQMLabs-ExchCLI.git
cd XEQMLabs-ExchCLI/bin/linux-x86_64
chmod +x xeqm-d xeqm-rpc xeqm-wallet
sha256sum -c SHA256SUMS

# 2. Start the daemon (foreground, mainnet, admin RPC bound to loopback)
./xeqm-d --rpc-admin 127.0.0.1:9231 --non-interactive

# 3. In a second shell, create the hot wallet
./xeqm-wallet --generate-new-wallet /srv/xeqm/hot-wallet --daemon-address 127.0.0.1:9231

# 4. In a third shell, start wallet-rpc
./xeqm-rpc \
    --wallet-file /srv/xeqm/hot-wallet \
    --password-file /srv/xeqm/.wallet-password \
    --rpc-bind-ip 127.0.0.1 \
    --rpc-bind-port 9234 \
    --rpc-login exchange:STRONG_RPC_PASSWORD \
    --daemon-address 127.0.0.1:9231 \
    --non-interactive
```

For systemd units suitable for production, see [`examples/systemd/`](../examples/systemd/) and [`installation.md`](installation.md).

---

## Recommended topology

- One `xeqm-d` per region, fully synced, accepting P2P on `9230` and exposing RPC on `127.0.0.1:9231`.
- One `xeqm-rpc` per hot wallet on the same host, bound to `127.0.0.1:9234`.
- Cold storage wallet(s) opened with `xeqm-wallet` on an air-gapped host. Sweep hot-wallet balance to cold daily.

**Never expose `xeqm-rpc` to the internet.** It is the spend-authority for the wallet; an unauthenticated reach equals theft.

---

## Production setup

### 1. Daemon

```bash
/usr/local/bin/xeqm-d \
    --data-dir /var/lib/xeqm \
    --log-file /var/log/xeqm/daemon.log \
    --log-level 1 \
    --rpc-admin 127.0.0.1:9231 \
    --non-interactive
```

Initial sync from genesis takes a few hours on an SSD with reasonable bandwidth. Watch progress with `examples/scripts/check-daemon.sh` or by polling `get_info`.

### 2. Hot wallet (one-time creation)

```bash
xeqm-wallet --generate-new-wallet /srv/xeqm/hot-wallet --daemon-address 127.0.0.1:9231
```

You will be prompted for a password and shown a 25-word seed. **Write the seed down offline.** Without it, the wallet cannot be restored.

Save the wallet password in a root-owned file:

```bash
echo 'YOUR_STRONG_PASSWORD' | sudo tee /srv/xeqm/.wallet-password
sudo chmod 600 /srv/xeqm/.wallet-password
```

### 3. Wallet RPC

```bash
/usr/local/bin/xeqm-rpc \
    --wallet-file /srv/xeqm/hot-wallet \
    --password-file /srv/xeqm/.wallet-password \
    --rpc-bind-ip 127.0.0.1 \
    --rpc-bind-port 9234 \
    --rpc-login exchange:STRONG_RPC_PASSWORD \
    --daemon-address 127.0.0.1:9231 \
    --log-file /var/log/xeqm/wallet-rpc.log \
    --log-level 1 \
    --non-interactive
```

Generate a strong random `STRONG_RPC_PASSWORD` (32+ chars). Authentication is HTTP Digest.

---

## Monitoring sync progress

```bash
curl -s http://127.0.0.1:9231/json_rpc \
    -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","id":"0","method":"get_info"}' \
| jq '{height,target_height,synchronized,outgoing_connections_count,nettype}'
```

Treat the daemon as ready when:

- `synchronized` is `true`, **and**
- `target_height == 0` or `height >= target_height`, **and**
- `outgoing_connections_count >= 4`

If you do not have a local sync yet, query a public node:

```bash
curl -s http://pn-1.xeqmlabs.com:9231/json_rpc \
    -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","id":"0","method":"get_info"}'
```

---

## Deposit flow

### A. Generate a deposit address per user

Two patterns are supported. Pick **one** and stick with it.

**Pattern 1 — subaddress per user (recommended):**

```bash
curl http://127.0.0.1:9234/json_rpc \
    -u exchange:STRONG_RPC_PASSWORD --digest \
    -H 'Content-Type: application/json' \
    -d '{
        "jsonrpc":"2.0","id":"0","method":"create_address",
        "params":{"account_index":0,"label":"user:12345"}
    }'
```

Response:

```json
{"result":{"address":"XEQM...","address_index":1}}
```

Store `address` and `address_index` against the user. The `subaddr_index.minor` field on incoming transfers maps back to `address_index`.

**Pattern 2 — single primary address + integrated `payment_id`:**

```bash
curl http://127.0.0.1:9234/json_rpc \
    -u exchange:STRONG_RPC_PASSWORD --digest \
    -H 'Content-Type: application/json' \
    -d '{
        "jsonrpc":"2.0","id":"0","method":"make_integrated_address",
        "params":{}
    }'
```

Response includes `integrated_address` (109 chars, share with user) and `payment_id` (16 hex chars, store against the user). Match incoming transfers by their `payment_id` field.

> **Choose one.** Mixing subaddresses and integrated addresses in the same wallet works but complicates accounting. Subaddresses are the modern default and what we recommend.

### B. Address validation

Before accepting an outbound destination, validate the address client-side:

| Type | Length | Regex |
|---|---|---|
| Standard | 97 | `^XEQM[1-9A-HJ-NP-Za-km-z]{93}$` |
| Subaddress | 97 | `^XEQM[1-9A-HJ-NP-Za-km-z]{93}$` |
| Integrated | 109 | `^XEQM[1-9A-HJ-NP-Za-km-z]{105}$` |

Then call `validate_address` on the wallet-rpc to verify the checksum:

```bash
curl http://127.0.0.1:9234/json_rpc \
    -u exchange:STRONG_RPC_PASSWORD --digest \
    -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","id":"0","method":"validate_address",
         "params":{"address":"XEQM...","any_net_type":false}}'
```

Reject if `result.valid` is `false`.

### C. Poll for incoming transfers

Every ~60 seconds (one block):

```bash
curl http://127.0.0.1:9234/json_rpc \
    -u exchange:STRONG_RPC_PASSWORD --digest \
    -H 'Content-Type: application/json' \
    -d '{
        "jsonrpc":"2.0","id":"0","method":"get_transfers",
        "params":{"in":true,"account_index":0}
    }'
```

Each entry contains:

- `tx_hash` — chain ID for the deposit
- `amount` — atomic units (divide by 10⁹ for XEQM)
- `confirmations` — block depth since inclusion
- `subaddr_index.minor` — the subaddress index (matches the `address_index` you stored at create time)
- `payment_id` — set if Pattern 2 was used; `0000000000000000` otherwise

**Confirmation policy:** credit when `confirmations >= 10` for normal deposits, `>= 30` for amounts above your large-deposit threshold.

A reference poller is provided at [`examples/scripts/poll-deposits.sh`](../examples/scripts/poll-deposits.sh).

---

## Withdrawal flow

```bash
curl http://127.0.0.1:9234/json_rpc \
    -u exchange:STRONG_RPC_PASSWORD --digest \
    -H 'Content-Type: application/json' \
    -d '{
        "jsonrpc":"2.0","id":"0","method":"transfer",
        "params":{
            "destinations":[{"amount":1000000000,"address":"XEQM..."}],
            "account_index":0,
            "priority":1,
            "get_tx_key":true
        }
    }'
```

`amount` is in atomic units (`1_000_000_000` = 1 XEQM). The response includes:

- `tx_hash` — record this against the withdrawal request
- `fee` — atomic units deducted on top of `amount`
- `tx_key` — store this; it lets you generate spend proofs later via `get_tx_proof`
- `multisig_txset` / `unsigned_txset` — empty for single-sig wallets

For destinations that are **integrated addresses**, do not pass a separate `payment_id` — it is encoded in the address. For destinations that are standard addresses, pass `"payment_id":"<16-hex-chars>"` only if the receiving party explicitly requested one.

Wait until the daemon includes `tx_hash` in a block (poll `get_transactions` or `get_transfer_by_txid`) before marking the withdrawal as final.

---

## Operational checklist

- [ ] Daemon synced to current tip (`get_info.synchronized == true`)
- [ ] Wallet-rpc bound to `127.0.0.1:9234` only
- [ ] `--rpc-login` set with a 32+ character random password
- [ ] Wallet password file is `chmod 600`, owned by the service user
- [ ] systemd units running both services with `Restart=always` (see [`examples/systemd/`](../examples/systemd/))
- [ ] Log rotation configured for `/var/log/xeqm/`
- [ ] Hot wallet drained to cold storage daily
- [ ] Deposit confirmations: 10 minimum, 30 for large deposits
- [ ] Address validation enforced for both deposits (regex check) and withdrawals (`validate_address` RPC)
- [ ] Monitoring on daemon height — alert if stalled > 10 minutes
- [ ] Withdrawal `tx_key` stored alongside the txid for proof-of-payment

---

## Test on stagenet first

XEQM ships with `--stagenet` and `--testnet` modes. To smoke-test integration without spending real coins:

```bash
xeqm-d --stagenet --rpc-admin 127.0.0.1:11023 ...
xeqm-rpc --stagenet --rpc-bind-port 11024 --daemon-address 127.0.0.1:11023 ...
```

Stagenet faucet availability is community-driven; reach out via the source repo's issue tracker if you need test funds.

---

## Getting help

- Source code & issues: https://github.com/EquilibriaHorizon/equilibria-core/issues
- This repo's issues: https://github.com/EquilibriaHorizon/XEQMLabs-ExchCLI/issues
- Project site: https://xeqmlabs.com

When reporting a problem, include:

- Daemon version: `xeqm-d --version`
- Wallet-rpc version: `xeqm-rpc --version`
- A scrubbed log excerpt covering the failure window
- Exact command and flags you ran
