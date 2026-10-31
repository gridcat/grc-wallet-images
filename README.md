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

Versioned image tags (`:vX.Y.Z`, `:vX.Y.Z-testnet`) follow the git
tags on this repo, and the git tags follow the daemon version:
`mainnet-v5.5.1.0-83` publishes `:v5.5.1.0-83`. Mainnet and testnet
are released independently, and the publish workflow strips the
network prefix from the image tag.

### What's inside

Every build also gets a tag that names both bundled versions,
`:v<daemon>-tui<tui>`, such as `:v5.5.1.0-83-tui1.13.1` or
`:v5.5.1.11-1-tui1.13.1-testnet`. It has the same digest as
`:latest`, so the registry's tag list tells you what `:latest`
contains before you pull.

After pulling, the versions are in the image labels:

```sh
docker inspect ghcr.io/gridcat/grc-wallet:latest \
  --format '{{index .Config.Labels "club.gridcoin.daemon.version"}} {{index .Config.Labels "club.gridcoin.tui.version"}}'
```

and in the first lines of the container log:

```
[INIT] gridcoinresearchd 5.5.1.0-83~ubuntu24.04.1, gridcoinresearch-tui 1.13.1
```

## Layout

```
mainnet/Dockerfile           — Ubuntu 24.04 + ppa:gridcoin/gridcoin-stable
mainnet/entrypoint.sh        — config init + exec gridcoinresearchd
testnet/Dockerfile           — Ubuntu 24.04 + ppa:gridcoin/gridcoin-testnet
testnet/entrypoint.sh        — config init + exec gridcointestnetd -testnet
.github/workflows/publish.yml — build + push to both registries + chain stamp
.github/workflows/check-daemon.yml — daily PPA check, auto-release + re-publish
```

Mainnet and testnet are split into sibling directories so each can pin
its own daemon version without dragging the other along. The TUI
version comes in as the `TUI_VERSION` build-arg, so a new TUI release
invalidates only that layer.

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
in the foreground. Gridcoin keeps one conf per network: mainnet's is
`gridcoinresearch.conf` at the data dir root, testnet's is
`testnet/gridcoinresearch.conf`.

The bundled TUI keeps its settings in `.config/gridcoinresearch-tui/`
inside the same data dir, so they survive pulling a new image or
recreating the container.

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
  flavours (base-image updates). No stamp, no README re-sync. Only
  tagged releases are anchored.
- **Manual / dispatch** (`workflow_dispatch`) → on a branch, same as
  the weekly run; on a `mainnet-v*` / `testnet-v*` tag, same as that
  tag push. Every `gridcoinresearch-tui` release dispatches it on
  `master`, so a new TUI lands in `:latest` within minutes.

Every run bundles the latest `gridcoinresearch-tui` release and also
publishes the `:v<daemon>-tui<tui>` tag.

`.github/workflows/check-daemon.yml` checks both PPAs once a day
(04:17 UTC). To check right away, run "Release new daemon versions"
from the Actions tab. When a PPA has a newer daemon, the workflow
bumps `GRC_DAEMON_VERSION` in that network's Dockerfile, commits to
`master`, tags `<network>-v<version>`, and dispatches the publish
workflow on that tag. If the PPA rebuilds the same version and only
the `~ubuntu…` suffix changes, the tag gets `-r2`, then `-r3`, and so
on.

The check also looks at recent release tags and dispatches any whose
image is missing from either registry. A build moves `:latest` only
when its network directory still matches `master`, so a slow run
can't roll `:latest` back.

GHCR auth uses the workflow's `GITHUB_TOKEN` automatically. Docker
Hub auth needs two repository secrets:

- `DOCKERHUB_USERNAME`: Docker Hub login (`gridcat`).
- `DOCKERHUB_TOKEN`: Docker Hub PAT with read/write/delete on
  `gridcat/grc-wallet`.

## Bumping daemon versions

`check-daemon.yml` releases new PPA versions on its own (see CI). To
release by hand, for example to pin an older daemon, edit `ARG GRC_DAEMON_VERSION` in
the relevant Dockerfile, commit, and tag with the network prefix:

```sh
make release-mainnet VERSION=5.5.1.0-83
make release-testnet VERSION=5.5.1.11-1
```

The matching job rebuilds and publishes that flavour only. The image
tag drops the network prefix: `:v5.5.1.0-83` (mainnet) or
`:v5.5.1.11-1-testnet`.

Local builds need the TUI version as a build-arg:

```sh
docker build --build-arg TUI_VERSION=v1.13.1 ./mainnet
```

## Credits

The entrypoint script's config-bootstrapping pattern (random RPC creds
via env, RPC access wiring with `rpcport` and `rpcallowip`,
append-if-missing into `gridcoinresearch.conf`, `[INIT]` log prefix)
is derived from
[hdavid0510/docker-gridcoinresearchd](https://github.com/hdavid0510/docker-gridcoinresearchd).
This project trims it to a daemon-only image (no BOINC, no
supervisord), splits mainnet and testnet into sibling Dockerfiles,
and adds the TUI bundling + chain-stamped manifest digest workflow.
