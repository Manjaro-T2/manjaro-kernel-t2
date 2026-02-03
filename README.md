# Manjaro Kernel for Macs with Apple T2 security chip

This repository provides a Manjaro kernel package for Macs with the Apple T2 security chip.

**Current version:** Linux 6.12.44 LTS with T2 patches

It works. Consult [t2linux wiki](https://wiki.t2linux.org) for more information on how to install or what does/doesn't work.

## Building

To build the package, you'll need to update the checksums first:
```bash
updpkgsums
makepkg -si
```

Or if you have network access during build, the checksums marked as 'SKIP' will be verified during the build process.

