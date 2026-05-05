# XEQMLabs CLI

Official command-line suite for the **XEQM** cryptocurrency network. Contains the node daemon (`xeqm-d`), wallet RPC server (`xeqm-rpc`), and interactive wallet (`xeqm-wallet`).

Intended for exchanges, payment processors, service operators, and advanced users running XEQM infrastructure on Linux servers.

- **Source code:** https://github.com/EquilibriaHorizon/equilibria-core
- **Project site:** https://xeqmlabs.com
- **Whitepaper:** https://xeqmlabs.gitbook.io/docs/documentation/whitepaper
- **GUI wallet:** https://github.com/DomXEQ/XEQMLabs-GUI
- **License:** BSD-3-Clause

---

## Contents

| Binary | Purpose |
|---|---|
| `xeqm-d` | Full node daemon. Validates blocks, syncs the chain, exposes JSON-RPC. |
| `xeqm-rpc` | Headless wallet RPC server. The integration target for exchanges. |
| `xeqm-wallet` | Interactive wallet shell for manual operations (create / restore / send). |

Prebuilt Linux x86_64 binaries live in [`bin/linux-x86_64/`](bin/linux-x86_64/) with a [`SHA256SUMS`](bin/linux-x86_64/SHA256SUMS) manifest. Binaries are extracted from the official Docker image `ghcr.io/equilibriahorizon/equilibria-node:latest` and refreshed on demand by the `update-binaries.yml` workflow.

---

## Quick start

```bash
git clone https://github.com/EquilibriaHorizon/XEQMLabs-ExchCLI.git
cd XEQMLabs-ExchCLI/bin/linux-x86_64
chmod +x xeqm-d xeqm-rpc xeqm-wallet
sha256sum -c SHA256SUMS

# Run the daemon (admin RPC bound to loopback)
./xeqm-d --rpc-admin 127.0.0.1:9231 --non-interactive

# In another shell, create a wallet
./xeqm-wallet --generate-new-wallet ~/xeqm-wallets/main --daemon-address 127.0.0.1:9231

# In a third shell, start wallet-rpc on 9234
./xeqm-rpc \
    --wallet-file ~/xeqm-wallets/main \
    --rpc-bind-ip 127.0.0.1 \
    --rpc-bind-port 9234 \
    --rpc-login exchange:STRONG_PASSWORD \
    --daemon-address 127.0.0.1:9231
```

See [`docs/installation.md`](docs/installation.md) for full setup, [`docs/exchange-integration.md`](docs/exchange-integration.md) for the integration walkthrough.

---

## Network parameters

| Parameter | Value |
|---|---|
| Symbol / decimals | XEQM / 9 (1 XEQM = 10⁹ atomic units) |
| Block time | 60 seconds |
| Consensus | Pulse PoS (HF16+) |
| Per-block reward (HF19+) | 8.25 SN + 12.4 governance = 20.65 XEQM |
| Premine / circulating supply | 276,786,542 XEQM |
| Min recommended deposit confirmations | 10 |
| P2P port | `9230` (public) |
| Daemon admin RPC | `9231` (loopback on operator nodes) |
| Quorumnet (UDP, SN-only) | `9232` |
| Wallet RPC | `9234` (loopback only) |

**Seed nodes:** `seed-1.xeqmlabs.com` through `seed-5.xeqmlabs.com` on port `9230`.

**Public RPC:** `pn-1.xeqmlabs.com:9231`, `pn-2.xeqmlabs.com:9231`, `pn-3.xeqmlabs.com:9231` (read-only fallback for chain queries).

Full reference: [`docs/network-params.md`](docs/network-params.md).

---

## Documentation

- [Installation](docs/installation.md) — system requirements, setup, systemd
- [Exchange integration](docs/exchange-integration.md) — production-grade RPC walkthrough
- [RPC reference](docs/rpc-reference.md) — daemon and wallet JSON-RPC methods
- [Network parameters](docs/network-params.md) — ports, seeds, tokenomics, hard fork schedule
- [Troubleshooting](docs/troubleshooting.md) — common operational issues

---

## Verifying downloads

From a release tarball:

```bash
sha256sum -c SHA256SUMS
```

From the in-repo binaries:

```bash
cd bin/linux-x86_64
sha256sum -c SHA256SUMS
```

All three lines must report `OK`.

---

## Building from source

These binaries are built from [equilibria-core](https://github.com/EquilibriaHorizon/equilibria-core). To reproduce:

```bash
git clone --recursive https://github.com/EquilibriaHorizon/equilibria-core.git
cd equilibria-core
make -j$(nproc) release-static
# Binaries land in build/release/bin/
```

Compare resulting hashes against [`bin/linux-x86_64/SHA256SUMS`](bin/linux-x86_64/SHA256SUMS) to verify reproducibility.

---

## Releases

Tagged releases (`v*`) are built by GitHub Actions and published to the [Releases page](https://github.com/EquilibriaHorizon/XEQMLabs-ExchCLI/releases). Each release tarball bundles the three binaries plus `SHA256SUMS`, docs, and example systemd units.

---

## License

BSD-3-Clause. See [LICENSE](LICENSE).

Derived from the Monero and Loki/Oxen projects. Original copyright notices retained.

---

## Reporting issues

- Distribution / packaging issues: https://github.com/EquilibriaHorizon/XEQMLabs-ExchCLI/issues
- Protocol / source code issues: https://github.com/EquilibriaHorizon/equilibria-core/issues
