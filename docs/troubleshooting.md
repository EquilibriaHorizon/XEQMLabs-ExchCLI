# Troubleshooting

## Daemon won't start / "address already in use"

Port `9230` (P2P) or `9231` (admin RPC) is held by another process. Find and stop it:

```bash
sudo ss -tulpn | grep -E '9230|9231|9232|9234'
```

If a stale `xeqm-d` is running, stop it cleanly:

```bash
xeqm-d exit
# or, last resort
pkill -f xeqm-d
```

## Daemon stuck syncing

Check peer count:

```bash
curl -s http://127.0.0.1:9231/json_rpc -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","id":"0","method":"get_info"}' | jq
```

If `outgoing_connections_count` is 0, your host can't reach any peers. Verify the seeds are reachable:

```bash
for h in seed-1 seed-2 seed-3 seed-4 seed-5; do
    nc -zv ${h}.xeqmlabs.com 9230
done
```

If outbound 9230 is firewalled, open it. Until peers appear, you can manually pin a known good node:

```bash
xeqm-d --add-priority-node seed-1.xeqmlabs.com:9230
```

## Wallet-RPC: "Failed to connect to daemon"

`--daemon-address` doesn't match the daemon's actual RPC bind. Defaults:

- Mainnet daemon RPC: `127.0.0.1:9231`
- Mainnet wallet RPC: `127.0.0.1:9234`

Make sure the daemon is running and reachable:

```bash
curl -s http://127.0.0.1:9231/json_rpc \
    -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","id":"0","method":"get_info"}' | jq '.result | {height,synchronized,nettype}'
```

## Wallet-RPC: "daemon is busy"

The daemon is still syncing. Either wait for it to catch up, or temporarily point at a public node for chain queries:

```bash
xeqm-rpc --daemon-address pn-1.xeqmlabs.com:9231 --trusted-daemon ...
```

For production, **always** sync against a daemon you operate. Public nodes are a fallback for development and read-only operations.

## Transfer fails with "not enough unlocked money"

Funds exist but are still locked. Compare `balance` and `unlocked_balance`:

```bash
curl -s -u exchange:SECRET --digest http://127.0.0.1:9234/json_rpc \
    -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","id":"0","method":"get_balance","params":{"account_index":0}}' | jq
```

`unlocked_balance` must be `>= amount + fee`. Each incoming transfer locks for 10 blocks (~10 minutes).

## "Height mismatch" or reorg warnings

Minor reorgs at the chain tip are normal. If persistent, check your daemon's clock:

```bash
timedatectl status
```

NTP drift greater than a few seconds causes peers to reject your blocks.

## systemd service won't start

```bash
journalctl -u xeqm-daemon -n 100 --no-pager
journalctl -u xeqm-wallet-rpc -n 100 --no-pager
```

Common causes:

- `User=xeqm` doesn't exist — `sudo useradd -r -s /bin/false xeqm`
- `/var/lib/xeqm` not writable — `sudo chown -R xeqm:xeqm /var/lib/xeqm /var/log/xeqm`
- Binary not at `/usr/local/bin/xeqm-d` — adjust `ExecStart=` in the unit file or install the binary there
- Wallet RPC unit's placeholder `--rpc-login exchange:REPLACE_ME` not replaced — `sudo systemctl edit xeqm-wallet-rpc` and override the line

## Binary permission denied

```bash
chmod +x bin/linux-x86_64/xeqm-d bin/linux-x86_64/xeqm-rpc bin/linux-x86_64/xeqm-wallet
```

## Verifying a download

```bash
cd bin/linux-x86_64
sha256sum -c SHA256SUMS
```

All three lines must report `OK`. On mismatch, **re-download** — do not run the binary.

## Wallet-RPC keeps respawning

Run it under systemd or an init manager that restarts on exit, but the typical cause is auth: if `--rpc-login` is set on the server but the client uses Basic instead of Digest, the server closes the connection. Check that your client passes `--digest` (curl) or sets the equivalent in your HTTP library.

## Still stuck?

Open an issue:

- This repo: https://github.com/EquilibriaHorizon/XEQMLabs-ExchCLI/issues
- Source code: https://github.com/EquilibriaHorizon/equilibria-core/issues

Include: distro + version, kernel (`uname -a`), binary version (`xeqm-d --version`, `xeqm-rpc --version`), a scrubbed log excerpt, and the exact command you ran.
