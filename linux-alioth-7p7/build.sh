#!/usr/bin/env bash
# build.sh [thin|server-thin] - Clang ThinLTO build of linux-alioth
#
#   thin          ThinLTO           -> linux-alioth-ThinLTO-{5k|4p52k}
#   server-thin   ThinLTO, server   -> linux-alioth-Server-ThinLTO-{5k|4p52k}
#
# Battery variant (env var, default 5000):
#   BATTERY=5000   5000mAh aftermarket  -> suffix -5k
#   BATTERY=4520   stock 4520mAh        -> suffix -4p52k
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

MODE="${1:-thin}"
BATTERY="${BATTERY:-5000}"
SERVER=0

case "$MODE" in
	thin)         SUFFIX="-ThinLTO";        LTO_CFG="-d LTO_NONE -e LTO_CLANG_THIN" ;;
	server-thin)  SUFFIX="-Server-ThinLTO"; LTO_CFG="-d LTO_NONE -e LTO_CLANG_THIN"; SERVER=1 ;;
	*) echo "usage: $0 {thin|server-thin}" >&2; exit 1 ;;
esac

case "$BATTERY" in
	5000) BAT_UAH=5000000; BAT_UWH=19000000; BAT_SUFFIX="-5k" ;;
	4520) BAT_UAH=4520000; BAT_UWH=17500000; BAT_SUFFIX="-4p52k" ;;
	*) echo "error: BATTERY must be 5000 or 4520" >&2; exit 1 ;;
esac

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

if [[ $EUID -eq 0 ]]; then
	echo "error: do not run as root - makepkg refuses" >&2
	exit 1
fi

for t in clang ld.lld llvm-ar makepkg patch; do
	command -v "$t" >/dev/null || { echo "error: missing $t" >&2; exit 1; }
done

export LLVM=1
export ARCH=arm64

FULL_SUFFIX="${SUFFIX}${BAT_SUFFIX}"
PB="PKGBUILD.${MODE}.${BATTERY}"
cp PKGBUILD "$PB"
trap 'rm -f "$PB"' EXIT

sed -i "s/^pkgbase=linux-alioth-7p7\$/pkgbase=linux-alioth-7p7${FULL_SUFFIX}/" "$PB"

# Inject LTO config + battery localversion + optional patch into prepare()
sed -i "/> \.\/\.config/a\\
\\
  echo \"Configuring LTO mode: ${MODE}\"\\
  scripts/config --file ./.config ${LTO_CFG}\\
  make LLVM=1 ARCH=arm64 olddefconfig\\
\\
  echo \"Battery: ${BATTERY}mAh (${BAT_UAH} uAh)\"\\
  patch -p1 < \"\${srcdir}/0001-battery-5k.patch\"" "$PB"

# For 4520 (stock), revert the patch values back after applying
if [[ "$BATTERY" == "4520" ]]; then
	sed -i "/patch -p1.*battery-5k/a\\
  sed -i 's/charge-full-design-microamp-hours = <5000000>/charge-full-design-microamp-hours = <4520000>/' arch/arm64/boot/dts/qcom/sm8250-xiaomi-alioth.dts\\
  sed -i 's/energy-full-design-microwatt-hours = <19000000>/energy-full-design-microwatt-hours = <17500000>/' arch/arm64/boot/dts/qcom/sm8250-xiaomi-alioth.dts" "$PB"
fi

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

echo ">> Building: linux-alioth${FULL_SUFFIX} (LTO=${MODE}, battery=${BATTERY}mAh)"
makepkg -p "$PB" -f --noconfirm

echo
echo ">> Done. Packages:"
ls -1 ./*.pkg.tar.* 2>/dev/null || echo "  (none found)"
