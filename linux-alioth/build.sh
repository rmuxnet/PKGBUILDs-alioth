#!/usr/bin/env bash
# build.sh [full|thin|none] - Clang build of linux-alioth
#
#   full   Full LTO   -> linux-alioth-FullLTO
#   thin   ThinLTO    -> linux-alioth-ThinLTO
#   none   no LTO     -> linux-alioth-NoLTO   (still Clang)
#
# Always built with Clang/lld (LLVM=1) targeting arm64.
# Patches a throwaway PKGBUILD copy so the committed one stays clean.
# Must NOT run as root (makepkg refuses).

set -euo pipefail

MODE="${1:-full}"
case "$MODE" in
	full) SUFFIX="-FullLTO"; LTO_CFG="-d LTO_NONE -e LTO_CLANG_FULL" ;;
	thin) SUFFIX="-ThinLTO"; LTO_CFG="-d LTO_NONE -e LTO_CLANG_THIN" ;;
	none) SUFFIX="-NoLTO";   LTO_CFG="-e LTO_NONE" ;;
	*) echo "usage: $0 {full|thin|none}" >&2; exit 1 ;;
esac

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

if [[ $EUID -eq 0 ]]; then
	echo "error: do not run as root - makepkg refuses" >&2
	exit 1
fi

for t in clang ld.lld llvm-ar makepkg; do
	command -v "$t" >/dev/null || { echo "error: missing $t" >&2; exit 1; }
done

export LLVM=1
export ARCH=arm64

PB="PKGBUILD.${MODE}"
cp PKGBUILD "$PB"
trap 'rm -f "$PB"' EXIT

sed -i "s/^pkgbase=linux-alioth\$/pkgbase=linux-alioth${SUFFIX}/" "$PB"

sed -i "/> \.\/\.config/a\\
\\
  echo \"Configuring LTO mode: ${MODE}\"\\
  scripts/config --file ./.config ${LTO_CFG}\\
  make LLVM=1 ARCH=arm64 olddefconfig" "$PB"

echo ">> Building Clang package: linux-alioth${SUFFIX} (LTO=${MODE})"
[[ "$MODE" == full ]] && echo ">> note: Full LTO link is slow + RAM-hungry"
makepkg -p "$PB" -f --noconfirm

echo
echo ">> Done. Packages:"
ls -1 ./*.pkg.tar.* 2>/dev/null || echo "  (none found)"
