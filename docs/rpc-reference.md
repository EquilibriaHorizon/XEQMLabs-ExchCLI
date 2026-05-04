# RPC Reference

XEQM inherits its RPC surface from the Monero/Oxen lineage. Method names, parameters, and response shapes match Monero's wallet-rpc and monerod-rpc — the canonical Monero docs apply verbatim. This document lists the calls most relevant to exchange and payment-processor integration.

- **Daemon JSON-RPC:** `http://127.0.0.1:9231/json_rpc` (loopback on operator nodes; bound publicly on `pn-*.xeqmlabs.com:9231` for read-only fallback queries)
- **Wallet JSON-RPC:** `http://127.0.0.1:9234/json_rpc` (**loopback only — never expose**)
- **Auth:** HTTP Digest when `--rpc-login user:pass` is set on either daemon or wallet-rpc

All amounts are in **atomic units**. 1 XEQM = 1,000,000,000 (10⁹) atomic units.

Upstream references:

- Monero wallet RPC: https://docs.getmonero.org/rpc-library/wallet-rpc/
- Monero daemon RPC: https://docs.getmonero.org/rpc-library/monerod-rpc/

---

## Daemon methods (xeqm-d, port 9231)

### get_info

Chain tip, peer count, sync status, network type.

```json
{"jsonrpc":"2.0","id":"0","method":"get_info"}
```

Key response fields: `height`, `target_height`, `difficulty`, `tx_count`, `incoming_connections_count`, `outgoing_connections_count`, `synchronized`, `nettype`, `hard_fork`, `pulse`, `target` (block-time target), `staking_requirement`, `version`.

### get_block_header_by_height

```json
{"jsonrpc":"2.0","id":"0","method":"get_block_header_by_height","params":{"height":12345}}
```

### get_block_header_by_hash

```json
{"jsonrpc":"2.0","id":"0","method":"get_block_header_by_hash","params":{"hash":"<block-hash>"}}
```

### get_transactions

Use the legacy `/get_transactions` endpoint (not JSON-RPC) for tx lookup:

```bash
curl http://127.0.0.1:9231/get_transactions \
    -H 'Content-Type: application/json' \
    -d '{"txs_hashes":["<tx_hash>"],"decode_as_json":true}'
```

### get_fee_estimate

```json
{"jsonrpc":"2.0","id":"0","method":"get_fee_estimate"}
```

Returns `fee` (per-byte base fee in atomic units) and `quantization_mask`.

---

## Wallet methods (xeqm-rpc, port 9234)

### open_wallet

Open an existing wallet file in the wallet-rpc's `--wallet-dir`.

```json
{"jsonrpc":"2.0","id":"0","method":"open_wallet",
 "params":{"filename":"hot-wallet","password":"..."}}
```

### close_wallet

```json
{"jsonrpc":"2.0","id":"0","method":"close_wallet"}
```

### create_wallet

```json
{"jsonrpc":"2.0","id":"0","method":"create_wallet",
 "params":{"filename":"new-wallet","password":"...","language":"English"}}
```

### get_height

```json
{"jsonrpc":"2.0","id":"0","method":"get_height"}
```

Returns the wallet's processed block height. Compare against `get_info.height` on the daemon to detect lag.

### get_balance

```json
{"jsonrpc":"2.0","id":"0","method":"get_balance","params":{"account_index":0}}
```

Returns:

- `balance` — total atomic units owned by the account
- `unlocked_balance` — atomic units currently spendable
- `per_subaddress` — array with per-subaddress breakdown when `"all_accounts":false` and you pass `"address_indices":[...]`

Only `unlocked_balance` is spendable. Newly received transfers lock for 10 blocks.

### get_address

List subaddresses for an account.

```json
{"jsonrpc":"2.0","id":"0","method":"get_address",
 "params":{"account_index":0,"address_index":[0,1,2]}}
```

### create_address

Generate a new subaddress (use one per user for deposit attribution).

```json
{"jsonrpc":"2.0","id":"0","method":"create_address",
 "params":{"account_index":0,"label":"user:12345"}}
```

Response:

```json
{"result":{"address":"XEQM...","address_index":1}}
```

### make_integrated_address

Generate an integrated address that bundles a `payment_id` with the primary address.

```json
{"jsonrpc":"2.0","id":"0","method":"make_integrated_address","params":{}}
```

Response includes `integrated_address` (109 chars) and `payment_id` (16 hex chars).

### validate_address

```json
{"jsonrpc":"2.0","id":"0","method":"validate_address",
 "params":{"address":"XEQM...","any_net_type":false}}
```

Returns `valid`, `integrated`, `subaddress`, `nettype`, `openalias_address`. Reject withdrawal targets where `valid` is `false`.

### get_transfers

Get incoming/outgoing/pool transfers.

```json
{"jsonrpc":"2.0","id":"0","method":"get_transfers",
 "params":{"in":true,"out":true,"pending":true,"pool":true,"account_index":0}}
```

Filter by subaddress with `"subaddr_indices":[1,2,3]`. Each returned transfer has:

- `tx_hash`, `amount`, `fee`, `confirmations`, `unlock_time`
- `subaddr_index.minor` — the subaddress that received (incoming)
- `payment_id` — `0000000000000000` if not used
- `address` — the receiving address (incoming) or destination (outgoing)
- `timestamp`, `height`

### get_transfer_by_txid

```json
{"jsonrpc":"2.0","id":"0","method":"get_transfer_by_txid",
 "params":{"txid":"<tx_hash>","account_index":0}}
```

Use this to confirm finality of a withdrawal you submitted.

### transfer

Send XEQM to one or more destinations.

```json
{"jsonrpc":"2.0","id":"0","method":"transfer",
 "params":{
    "destinations":[{"amount":1000000000,"address":"XEQM..."}],
    "account_index":0,
    "priority":1,
    "get_tx_key":true,
    "do_not_relay":false
 }}
```

Priority: `0`=default, `1`=unimportant (cheapest), `2`=normal, `3`=elevated, `4`=priority.

Response includes `tx_hash`, `tx_key`, `amount`, `fee`. Save `tx_key` — it's required for `get_tx_proof`.

### sweep_all

Send all unlocked balance from one account to a destination (e.g. nightly cold-storage sweep).

```json
{"jsonrpc":"2.0","id":"0","method":"sweep_all",
 "params":{"address":"XEQM...","account_index":0,"priority":2,"get_tx_keys":true}}
```

### get_tx_key / check_tx_key / get_tx_proof / check_tx_proof

Generate and verify spend proofs without revealing the wallet seed. Standard Monero semantics.

### refresh

Force a rescan against the daemon.

```json
{"jsonrpc":"2.0","id":"0","method":"refresh","params":{"start_height":0}}
```

### store

Persist the wallet's in-memory state to disk. Call after a batch of `transfer`s to checkpoint.

```json
{"jsonrpc":"2.0","id":"0","method":"store"}
```

### stop_wallet

Graceful shutdown of the wallet-rpc process.

```json
{"jsonrpc":"2.0","id":"0","method":"stop_wallet"}
```

---

## Auth example

With `--rpc-login exchange:SECRET`:

```bash
curl -u exchange:SECRET --digest \
    http://127.0.0.1:9234/json_rpc \
    -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","id":"0","method":"get_balance","params":{"account_index":0}}'
```

The wallet-rpc requires HTTP Digest, not Basic. `curl --digest` and most language HTTP clients negotiate it transparently.
