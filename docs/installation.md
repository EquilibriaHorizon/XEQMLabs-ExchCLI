# Installation

## System requirements

- Linux x86_64 (Ubuntu 22.04+, Debian 12+, RHEL 9+ — any glibc 2.35+ distribution)
- 4 GB RAM minimum, 8 GB recommended
- 50 GB disk for the chain; SSD strongly recommended
- Outbound TCP on port `9230` (P2P)
- Inbound TCP on `9230` optional but improves connectivity

## 1. Download

**Option A — clone the repo:**

```bash
git clone https://github.com/EquilibriaHorizon/XEQMLabs-ExchCLI.git
cd XEQMLabs-ExchCLI/bin/linux-x86_64
```

**Option B — release tarball:**

```bash
curl -LO https://github.com/EquilibriaHorizon/XEQMLabs-ExchCLI/releases/latest/download/xeqm-cli-linux-x86_64.tar.gz
curl -LO https://github.com/EquilibriaHorizon/XEQMLabs-ExchCLI/releases/latest/download/SHA256SUMS
sha256sum -c SHA256SUMS
tar -xzf xeqm-cli-linux-x86_64.tar.gz
cd xeqm-cli-*-linux-x86_64
```

## 2. Verify checksums

```bash
cd bin/linux-x86_64
sha256sum -c SHA256SUMS
```

All three lines should report `OK`. If any mismatch, **stop** — re-download, do not run the binary.

## 3. Make executable

```bash
chmod +x xeqm-d xeqm-rpc xeqm-wallet
```

Optionally place them on `$PATH`:

```bash
sudo install -m 755 xeqm-d xeqm-rpc xeqm-wallet /usr/local/bin/
```

## 4. First daemon run

```bash
./xeqm-d
```

The daemon stores the chain under `~/.xeqm/` by default. Initial sync from genesis takes a few hours over reasonable bandwidth and SSD.

To run detached:

```bash
./xeqm-d --detach --log-file ~/.xeqm/xeqm-d.log
```

Stop it cleanly:

```bash
./xeqm-d exit
```

## 5. Create a wallet

```bash
./xeqm-wallet --generate-new-wallet ~/xeqm-wallets/main
```

You will be prompted for a password and shown a 25-word seed. **Write the seed down offline.** Without it, the wallet cannot be restored.

## 6. Run wallet-rpc (for integrations)

```bash
./xeqm-rpc \
    --wallet-file ~/xeqm-wallets/main \
    --password-file ~/.xeqm/wallet-password \
    --rpc-bind-ip 127.0.0.1 \
    --rpc-bind-port 9234 \
    --disable-rpc-login \
    --daemon-address 127.0.0.1:9231 \
    --log-file ~/.xeqm/wallet-rpc.log
```

**Security:** bind RPC to `127.0.0.1` unless you are certain the interface is firewalled. `--disable-rpc-login` is appropriate only when the RPC port is unreachable from outside the host. For production, swap it for `--rpc-login user:STRONG_PASSWORD`.

See [exchange-integration.md](exchange-integration.md) for production-grade setup with authentication, hot/cold wallet split, and deposit attribution.

---

## systemd service

For long-running servers, use the unit files in [`examples/systemd/`](../examples/systemd/):

```bash
sudo useradd -r -s /bin/false xeqm
sudo mkdir -p /var/lib/xeqm /var/log/xeqm /srv/xeqm /etc/xeqm
sudo chown -R xeqm:xeqm /var/lib/xeqm /var/log/xeqm /srv/xeqm

sudo install -m 755 bin/linux-x86_64/xeqm-d bin/linux-x86_64/xeqm-rpc bin/linux-x86_64/xeqm-wallet /usr/local/bin/
sudo install -m 644 examples/configs/xeqm-d.conf /etc/xeqm/xeqm-d.conf
sudo install -m 644 examples/systemd/xeqm-daemon.service /etc/systemd/system/
sudo install -m 644 examples/systemd/xeqm-wallet-rpc.service /etc/systemd/system/

sudo systemctl daemon-reload
sudo systemctl enable --now xeqm-daemon
# Edit the wallet-rpc unit to set --wallet-file, --password-file, --rpc-login first:
sudo systemctl edit xeqm-wallet-rpc
sudo systemctl enable --now xeqm-wallet-rpc
```

Check status:

```bash
systemctl status xeqm-daemon xeqm-wallet-rpc
journalctl -u xeqm-daemon -f
```
