#!/usr/bin/env bash
# build.sh [full|thin|none|server-thin|server-full] - Clang build of linux-alioth
#
#   full          Full LTO          -> linux-alioth-FullLTO
#   thin          ThinLTO           -> linux-alioth-ThinLTO
#   none          no LTO            -> linux-alioth-NoLTO   (still Clang)
#   server-thin   ThinLTO, server   -> linux-alioth-Server-ThinLTO
#   server-full   Full LTO, server  -> linux-alioth-Server-FullLTO
#
# Server config vs normal:
#   - PREEMPT_NONE   (no preemption, max throughput)
#   - HZ=250         (lower timer freq, less overhead)
#   - NO_HZ_FULL     (full tickless)
#   - TCP BBR        (better congestion control for server)
#   - SCHED_AUTOGROUP off  (hurts server throughput)
#   - RCU_NOCB_CPU   (offload RCU callbacks)
#   - NET_SCH_FQ     (fair queue, required for BBR)
#
# Always built with Clang/lld (LLVM=1) targeting arm64.
# Patches a throwaway PKGBUILD copy so the committed one stays clean.
# Must NOT run as root (makepkg refuses).

set -euo pipefail

MODE="${1:-full}"
SERVER=0
case "$MODE" in
	full)         SUFFIX="-FullLTO";        LTO_CFG="-d LTO_NONE -e LTO_CLANG_FULL" ;;
	thin)         SUFFIX="-ThinLTO";        LTO_CFG="-d LTO_NONE -e LTO_CLANG_THIN" ;;
	none)         SUFFIX="-NoLTO";          LTO_CFG="-e LTO_NONE" ;;
	server-thin)  SUFFIX="-Server-ThinLTO"; LTO_CFG="-d LTO_NONE -e LTO_CLANG_THIN"; SERVER=1 ;;
	server-full)  SUFFIX="-Server-FullLTO"; LTO_CFG="-d LTO_NONE -e LTO_CLANG_FULL"; SERVER=1 ;;
	*) echo "usage: $0 {full|thin|none|server-thin|server-full}" >&2; exit 1 ;;
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

# Inject LTO config + olddefconfig after base config is loaded
sed -i "/> \.\/\.config/a\\
\\
  echo \"Configuring LTO mode: ${MODE}\"\\
  scripts/config --file ./.config ${LTO_CFG}\\
  make LLVM=1 ARCH=arm64 olddefconfig" "$PB"

# Inject server-specific config AFTER LTO olddefconfig so it wins
if [[ $SERVER -eq 1 ]]; then
	sed -i "/make LLVM=1 ARCH=arm64 olddefconfig/a\\
\\
  echo \"Applying server optimizations\"\\
  scripts/config --file ./.config \\\\\\
    -d HZ_1000 -e HZ_250 \\\\\\
    -d NO_HZ_IDLE -e NO_HZ_FULL \\\\\\
    -e RCU_NOCB_CPU \\\\\\
    -d PREEMPT_LAZY -e PREEMPT_NONE \\\\\\
    -d SCHED_AUTOGROUP \\\\\\
    -e TCP_CONG_BBR -d DEFAULT_WESTWOOD -e DEFAULT_BBR \\\\\\
    -e NET_SCH_FQ -e NET_SCH_FQ_CODEL \\\\\\
    -e BPF_JIT_ALWAYS_ON\\
  make LLVM=1 ARCH=arm64 olddefconfig\\
  echo \"Server config applied: HZ=250 PREEMPT_NONE BBR NO_HZ_FULL\"" "$PB"
fi

echo ">> Building Clang package: linux-alioth${SUFFIX} (LTO=${MODE}, server=${SERVER})"
[[ "$MODE" == server-full || "$MODE" == full ]] && echo ">> note: Full LTO link is slow + RAM-hungry"
makepkg -p "$PB" -f --noconfirm

echo
echo ">> Done. Packages:"
ls -1 ./*.pkg.tar.* 2>/dev/null || echo "  (none found)"
