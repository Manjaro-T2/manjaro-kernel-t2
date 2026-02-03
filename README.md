# Manjaro Kernel for Macs with Apple T2 security chip

This repository provides a Manjaro kernel package for Macs with the Apple T2 security chip.

**Current version:** Linux 6.12.44 LTS with T2 patches

It works. Consult [t2linux wiki](https://wiki.t2linux.org) for more information on how to install or what does/doesn't work.

## Important: Checksum Update Required

⚠️ **Before building, you must update the checksums in PKGBUILD for security.**

See [CHECKSUMS.md](CHECKSUMS.md) for detailed instructions on how to update the checksums.

## Building

To build the package:
```bash
# First, update checksums (requires pacman-contrib)
updpkgsums

# Then build and install
makepkg -si
```

Alternatively, if you have network access during build, you can download and verify checksums manually as described in CHECKSUMS.md.

