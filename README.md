# grc-wallet-images

Builds and publishes Docker images for `gridcoinresearchd` (mainnet)
and `gridcointestnetd` (testnet). Each image bundles the latest
[`gridcoinresearch-tui`](https://github.com/gridcat/gridcoinresearch-tui)
release so operators can `docker exec -it grc_wallet gridcoinresearch-tui`
into a running container without an extra binary fetch.

## Images

Mirrored to two registries. Pick whichever is closer: the digest is
identical.

| Image | mainnet tag | testnet tag |
|---|---|---|
| GitHub Container Registry | `ghcr.io/gridcat/grc-wallet:latest` | `ghcr.io/gridcat/grc-wallet:latest-testnet` |
| Docker Hub | `gridcat/grc-wallet:latest` | `gridcat/grc-wallet:latest-testnet` |

Versioned image tags (`:vX.Y.Z`, `:vX.Y.Z-testnet`) follow git tags
on this repo. Mainnet and testnet ship on independent version
timelines — the source git tags carry a network prefix (`mainnet-v*` /
`testnet-v*`); the prefix is stripped before publishing.

## Layout

```
mainnet/Dockerfile           — Ubuntu 24.04 + ppa:gridcoin/gridcoin-stable
mainnet/entrypoint.sh        — config init + exec gridcoinresearchd
testnet/Dockerfile           — Ubuntu 24.04 + ppa:gridcoin/gridcoin-testnet
testnet/entrypoint.sh        — config init + exec gridcointestnetd
.github/workflows/publish.yml — build + push to both registries + chain stamp
```

Mainnet and testnet are split into sibling directories so each can pin
its own daemon version without dragging the other along. Both
Dockerfiles use a `releases/latest` cache-buster on the TUI fetch, so
Docker invalidates the layer when a new TUI release ships.

## Runtime contract

Operators provide a bind-mounted data dir for the chain state and
optional credentials via env:

```yaml
grc_wallet:
  image: ghcr.io/gridcat/grc-wallet:latest
  expose:
    - 47812   # mainnet RPC
    - 32750   # mainnet p2p
  volumes:
    - ./grc-wallet-data:/root/.GridcoinResearch/
  environment:
    - GRC_USERNAME=...        # optional; entrypoint generates a random
    - GRC_PASSWD=...          # 32-char string per field if unset
  restart: always
```

On first start the entrypoint generates a random `rpcuser` /
`rpcpassword` (or uses whatever the env supplies), writes them along
with `rpcport`, `rpcallowip=*`, and a bootstrap addnodes list into
`gridcoinresearch.conf` if those keys aren't already there (so an
operator-supplied conf survives untouched), then `exec`s the daemon
in the foreground.

## CI

GitHub Actions (`.github/workflows/publish.yml`) builds on:

- **Mainnet tag push** matching `mainnet-v*` → builds mainnet only,
  publishes `:<vX.Y.Z>` and `:latest` to both registries, syncs this
  README to the Docker Hub repository description, and stamps the
  published manifest digest on the Gridcoin chain (permalink at
  `https://stamp.gridcoin.club/hashes/<digest>`).
- **Testnet tag push** matching `testnet-v*` → builds testnet only,
  publishes `:<vX.Y.Z>-testnet` and `:latest-testnet`, stamps the
  digest. README sync is skipped (mainnet covers it).
- **Weekly schedule** (Sundays 03:00 UTC) → republishes both `:latest`
  flavours so a new TUI release lands on the next run. No stamp, no
  README re-sync. Only tagged releases are anchored.
- **Manual** (`workflow_dispatch`) → same shape as the weekly run.
  Use the Run workflow button when a new TUI release lands and you
  don't want to wait for Sunday.

GHCR auth uses the workflow's `GITHUB_TOKEN` automatically. Docker
Hub auth needs two repository secrets:

- `DOCKERHUB_USERNAME`: Docker Hub login (`gridcat`).
- `DOCKERHUB_TOKEN`: Docker Hub PAT with read/write/delete on
  `gridcat/grc-wallet`.

## Bumping daemon versions

Edit the `apt-get install` pin in the relevant Dockerfile, commit, and
tag with the network prefix:

```sh
# mainnet bump
git tag mainnet-v0.2.0
git push origin mainnet-v0.2.0

# testnet bump (independent timeline)
git tag testnet-v0.5.3
git push origin testnet-v0.5.3
```

The matching job rebuilds and publishes that flavour only. The
network prefix is stripped before publishing — the image tag is
`:v0.2.0` (mainnet) or `:v0.5.3-testnet`, never with `mainnet-` /
`testnet-` in the image tag itself.

## Credits

The entrypoint script's config-bootstrapping pattern (random RPC creds
via env, RPC access wiring with `rpcport` and `rpcallowip`,
append-if-missing into `gridcoinresearch.conf`, `[INIT]` log prefix)
is derived from
[hdavid0510/docker-gridcoinresearchd](https://github.com/hdavid0510/docker-gridcoinresearchd).
This project trims it to a daemon-only image (no BOINC, no
supervisord), splits mainnet and testnet into sibling Dockerfiles,
and adds the TUI bundling + chain-stamped manifest digest workflow.
