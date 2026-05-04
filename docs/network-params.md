# Network Parameters

Reference for the **XEQM** mainnet (relaunched 2026-05-05 on a fresh genesis). XEQM is a Monero-fork derived from the Oxen codebase, so wallet-rpc and daemon-rpc semantics match Monero/Oxen conventions — exchange integrators familiar with either should feel at home.

Authoritative protocol-level documentation:

- Tokenomics: https://xeqmlabs.gitbook.io/docs/documentation/whitepaper/tokenomics
- Service nodes: https://xeqmlabs.gitbook.io/docs/documentation/whitepaper/service-nodes-sn
- Source code: https://github.com/EquilibriaHorizon/equilibria-core

---

## Quick reference for exchange integrators

| Field | Value |
|---|---|
| Symbol | `XEQM` |
| Name | XEQM |
| Decimals | 9 (1 XEQM = 10⁹ atomic units) |
| Contract | N/A — native L1 coin |
| Network | XEQM mainnet |
| Chain type | Monero-fork, RingCT, Pulse PoS |
| Block time | 60 seconds |
| Min recommended confirmations (deposits) | 10 |
| Deposit memo support | Yes — via integrated addresses or `payment_id` |
| Withdrawal memo support | Yes — optional `payment_id` parameter on `transfer` |
| Address format | Base58, prefixed `XEQM…`, length 97 chars |
| Daemon admin RPC | `127.0.0.1:9231` (private) |
| Wallet RPC | `127.0.0.1:9234` (private) |
| Public RPC fallback | `pn-1.xeqmlabs.com:9231`, `pn-2.xeqmlabs.com:9231`, `pn-3.xeqmlabs.com:9231` |

---

## Coin

| Property | Value |
|---|---|
| Symbol | XEQM |
| Atomic unit | 1 XEQM = 10⁹ atomic units (9 decimals) |
| Premine / circulating supply | 276,786,542 XEQM (allocated at genesis) |
| Future emission | Flat block rewards from HF19+ — no halving curve |
| Consensus | Pulse PoS (HF16+, no PoW miners) |
| Privacy | Monero-derived RingCT |

## Block reward (HF19+)

| Recipient | Per block | Per day (1440 blocks) | Per year |
|---|---|---|---|
| Service Node | 8.25 XEQM | 11,880 XEQM | 4,336,200 XEQM |
| Foundation / Governance | 12.4 XEQM | 17,857 XEQM | 6,517,440 XEQM |
| **Total** | **20.65 XEQM** | **29,737 XEQM** | **~10,853,640 XEQM** |

Year-1 inflation against the genesis premine: ~3.92%. There is no halving — emission is flat at HF19 and beyond.

## Address prefixes (base58)

| Address type | Prefix (hex) | Visual prefix |
|---|---|---|
| Standard | `0x191eb4` | starts with `XEQM` |
| Integrated | `0x191eb3` | starts with `XEQM` |
| Subaddress | `0x191eb2` | starts with `XEQM` |

Standard and subaddresses are 97 base58 characters; integrated addresses are 109 chars (subaddress base + encoded `payment_id`).


## Service node parameters (HF19+)

| Field | Value |
|---|---|
| Full staking requirement | 200,000 XEQM |
| Min operator contribution (pool) | 100,000 XEQM (50% of stake) |
| Max contributors per node | 11 (1 operator + 10 community) |
| Max operator cut (pool nodes) | 10% |

> **Dual income streams** (API node functionality on top of consensus rewards) are listed as "coming soon" in the whitepaper and are NOT live as of this document.

---

## Default ports

| Port | Protocol | Service | Bind |
|---|---|---|---|
| 9230 | TCP | P2P (chain sync) | Public — must be reachable from internet |
| 9231 | TCP | Daemon admin RPC / public client RPC | Local only on operator nodes; bound publicly on `pn-*` |
| 9232 | UDP | Quorumnet (SN-to-SN consensus) | Public on service nodes |
| 9233 | TCP | Public OMQ (optional) | Public if enabled |
| 9234 | TCP | Wallet RPC | **Local only — never expose** |

> **Testnet / stagenet:** the binaries support `--testnet` and `--stagenet` flags. Active testnet seeds and ports are not currently published; for integration testing, point at a private development instance or use small sums on mainnet with a dedicated wallet.

## Seed nodes

P2P seeds, port `9230`:

- `seed-1.xeqmlabs.com:9230`
- `seed-2.xeqmlabs.com:9230`
- `seed-3.xeqmlabs.com:9230`
- `seed-4.xeqmlabs.com:9230`
- `seed-5.xeqmlabs.com:9230`

These are baked into the daemon's compiled-in seed list. New nodes will discover the network automatically.

## Public RPC nodes

JSON-RPC over HTTP on port `9231`:

- `http://pn-1.xeqmlabs.com:9231/json_rpc`
- `http://pn-2.xeqmlabs.com:9231/json_rpc`
- `http://pn-3.xeqmlabs.com:9231/json_rpc`

Use these for read-only chain queries (`get_info`, `get_block_header_by_height`, `get_transactions`) when you do not yet have a fully synced local daemon. **Never** point a wallet's `--daemon-address` at a remote node you do not control for production traffic — sync against a local `xeqm-d` you operate.

---

## Confirmation guidance

| Deposit size | Recommended confirmations | Approx. wall time |
|---|---|---|
| Small (< 100 XEQM) | 10 | ~10 min |
| Medium (100 – 1,000 XEQM) | 20 | ~20 min |
| Large (> 1,000 XEQM) | 30 | ~30 min |

Confirmations are absolute block depth, not "minutes elapsed". Pulse PoS produces blocks at a steady 60s target; reorgs deeper than 10 blocks are not expected under normal operation.

## Transaction fees

XEQM uses the standard Monero RingCT fee model. Fee depends on transaction size in bytes and a network base fee returned by the daemon's `get_fee_estimate` RPC. Wallet-rpc handles fee selection automatically when you call `transfer` with a `priority` field (`1` cheapest → `4` fastest).

A typical 1-input, 2-output RingCT transaction is roughly 1.4–2 KB and costs a few thousandths of an XEQM at default priority. Always honour `unlocked_balance >= amount + fee` before relaying.
