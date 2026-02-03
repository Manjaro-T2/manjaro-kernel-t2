# Checksum Update Instructions

The PKGBUILD currently has placeholder 'SKIP' values for the kernel source checksums.
These need to be updated before building for security verification.

## How to Update Checksums

### Option 1: Using updpkgsums (Recommended)
If you have the `pacman-contrib` package installed:
```bash
updpkgsums
```

This will automatically download the sources and calculate the correct SHA256 checksums.

### Option 2: Manual Calculation
Download the sources and calculate checksums manually:
```bash
# Download the kernel tarball
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.12.tar.xz

# Download the patch
wget https://www.kernel.org/pub/linux/kernel/v6.x/patch-6.12.44.xz

# Calculate checksums
sha256sum linux-6.12.tar.xz
sha256sum patch-6.12.44.xz
```

### Option 3: Use Official Checksums
Download the official checksums from kernel.org:
```bash
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/sha256sums.asc
grep "linux-6.12.tar.xz" sha256sums.asc
grep "patch-6.12.44.xz" sha256sums.asc
```

## Required Checksums

Update the `sha256sums` array in PKGBUILD with:
1. SHA256 for `linux-6.12.tar.xz`
2. SHA256 for `patch-6.12.44.xz`
3. SHA256 for `config` (already present: `e0205327d435f519ecb7947c5544a8ec75b02e8327748323f61c3dc5fa096fd9`)
4. `SKIP` for git patches (already present)

## Security Note

Using 'SKIP' for checksums bypasses integrity verification and is a security risk.
Always update checksums before building packages for production use.
