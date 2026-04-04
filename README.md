# Manjaro Kernel for Macs with Apple T2 security chip
It works. Consult [t2linux wiki](https://wiki.t2linux.org) for more informations on how to install or what do/doesn't work.
## Local build

Build the packages from the repository root with:

```bash
./build.sh
```

This runs `makepkg -sfc` by default. Additional arguments are passed through to `makepkg`, so you can override the defaults when needed:

```bash
./build.sh --syncdeps --cleanbuild
```

## Kernel update automation

For manual local automation, run:

```bash
./scripts/weekly_edge_update.sh
```

This fast-forwards the local `edge` branch from `origin`, checks `https://www.kernel.org/releases.json`, updates `PKGBUILD` when a newer stable kernel exists, and creates a local commit automatically. Set `EDGE_UPDATE_AUTO_PUSH=1` if you also want it to push after committing.

For desktop autostart-based weekly checks, copy the launcher into your session autostart directory:

```bash
mkdir -p ~/.config/autostart
cp autostart/manjaro-t2-edge-update.desktop ~/.config/autostart/
```

The autostart launcher runs on login, but `scripts/weekly_edge_update_autostart.sh` only performs the update on Sundays and only once per day.

## Package builds

Package builds still run in GitHub Actions from [.github/workflows/build.yml](/home/rishon/Projects/T2Linux/manjaro-t2-kernel-edge/.github/workflows/build.yml) on pushes to the `edge` branch and on manual dispatch.
