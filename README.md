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
