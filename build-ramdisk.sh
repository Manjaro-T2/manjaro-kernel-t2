#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: ./build-ramdisk.sh [options] [-- makepkg-args...]

Build the kernel package inside a tmpfs-backed workspace to minimize SSD writes.

Options:
  -m, --mount-point PATH  Tmpfs mount point. Default: /mnt/kernel-ram
  -s, --size SIZE         Tmpfs size passed to mount. Default: 24G
  -j, --jobs N            MAKEFLAGS job count. Default: 8
  -o, --output-dir PATH   Where built packages are copied after success.
                          Default: ./ramdisk-packages
      --keep-mount        Leave the tmpfs mounted after the build
  -h, --help              Show this help

Examples:
  ./build-ramdisk.sh
  ./build-ramdisk.sh --size 20G --jobs 6 -- --cleanbuild --syncdeps
EOF
}

mount_point="/mnt/kernel-ram"
tmpfs_size="24G"
jobs="8"
output_dir="${repo_root}/ramdisk-packages"
keep_mount=0
declare -a makepkg_args=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--mount-point)
      mount_point="$2"
      shift 2
      ;;
    -s|--size)
      tmpfs_size="$2"
      shift 2
      ;;
    -j|--jobs)
      jobs="$2"
      shift 2
      ;;
    -o|--output-dir)
      output_dir="$2"
      shift 2
      ;;
    --keep-mount)
      keep_mount=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      makepkg_args=("$@")
      break
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ ${#makepkg_args[@]} -eq 0 ]]; then
  makepkg_args=(--syncdeps --cleanbuild)
fi

if ! command -v makepkg >/dev/null 2>&1; then
  echo "error: makepkg is required but was not found in PATH" >&2
  exit 1
fi

if ! command -v rsync >/dev/null 2>&1; then
  echo "error: rsync is required but was not found in PATH" >&2
  exit 1
fi

if ! command -v mountpoint >/dev/null 2>&1; then
  echo "error: mountpoint is required but was not found in PATH" >&2
  exit 1
fi

sudo_cmd=()
if [[ ${EUID} -ne 0 ]]; then
  sudo_cmd=(sudo)
fi

workspace="${mount_point}/repo"
build_dir="${mount_point}/build"
src_dir="${mount_point}/src"
pkg_dir="${mount_point}/pkg"
log_dir="${mount_point}/logs"
mounted_here=0

cleanup() {
  local status=$?

  if (( keep_mount == 0 )) && (( mounted_here == 1 )) && mountpoint -q "${mount_point}"; then
    "${sudo_cmd[@]}" umount "${mount_point}"
  fi

  exit "${status}"
}

trap cleanup EXIT

mkdir -p "${output_dir}"
"${sudo_cmd[@]}" mkdir -p "${mount_point}"

if mountpoint -q "${mount_point}"; then
  echo "Using existing mount at ${mount_point}"
else
  echo "Mounting tmpfs at ${mount_point} (size=${tmpfs_size})"
  "${sudo_cmd[@]}" mount -t tmpfs -o "size=${tmpfs_size},mode=1777" tmpfs "${mount_point}"
  mounted_here=1
fi

mkdir -p "${workspace}" "${build_dir}" "${src_dir}" "${pkg_dir}" "${log_dir}"

echo "Copying repository into tmpfs workspace..."
rsync -a --delete \
  --exclude '.git' \
  --exclude 'ramdisk-packages' \
  --exclude 'src' \
  --exclude 'pkg' \
  --exclude '*.pkg.tar.*' \
  --exclude '*.pkg.tar.*.sig' \
  --exclude '*.src.tar.*' \
  --exclude '*.src.tar.*.sig' \
  "${repo_root}/" "${workspace}/"

echo "Building in RAM..."
(
  cd "${workspace}"
  env \
    BUILDDIR="${build_dir}" \
    SRCDEST="${src_dir}" \
    PKGDEST="${pkg_dir}" \
    LOGDEST="${log_dir}" \
    MAKEFLAGS="-j${jobs}" \
    makepkg "${makepkg_args[@]}"
)

echo "Copying packages back to ${output_dir}..."
rsync -a "${pkg_dir}/" "${output_dir}/"

echo "Build complete."
echo "Packages: ${output_dir}"
if (( keep_mount == 1 )); then
  echo "Tmpfs kept mounted at ${mount_point}"
fi
