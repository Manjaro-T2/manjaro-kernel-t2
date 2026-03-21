# Manjaro Kernel for Macs with Apple T2 security chip
Currently experimental. Consult [t2linux wiki](https://wiki.t2linux.org) for more informations on how to install or what do/doesn't work. 

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

The repository includes a scheduled GitHub Actions workflow at `.github/workflows/update-lts-kernel.yml` that checks `https://www.kernel.org/releases.json` every Monday and opens a pull request when a newer upstream longterm release is available.

The build workflow at `.github/workflows/build.yml` also generates `version.txt` from `PKGBUILD` on every CI build, then uploads it alongside the built packages and includes it in GitHub releases.

The updater script rewrites:

- `PKGBUILD`
- `version.txt`

`version.txt` contains the current upstream kernel version as a single line, for example `6.18.16`.
