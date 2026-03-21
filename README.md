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

## GitHub CI

The repository includes a scheduled GitHub Actions workflow at `.github/workflows/update-edge-kernel.yml` that checks `https://www.kernel.org/releases.json` every Monday and opens a pull request when a newer upstream stable release is available.

The build workflow at `.github/workflows/build.yml` publishes the latest edge packages to the moving tag `latest-edge` and also creates a fixed version tag without dots, for example `6199`.
