# PKGBUILDs-alioth

Arch-based PKGBUILDs for running [ARMtix](https://armtixlinux.org/) (Artix Linux aarch64, runit) on the Xiaomi POCO F3 / Mi 11i / Redmi K40 (codename **alioth**).

<p align="center">
  <img src="https://wiki.postmarketos.org/images/thumb/7/71/Xiaomi-alioth.png/659px-Xiaomi-alioth.png" width="300" alt="Xiaomi POCO F3 (alioth)">
</p>

---

## Device

| | |
|---|---|
| **Names** | Xiaomi POCO F3 / Mi 11i / Redmi K40 |
| **Codename** | alioth |
| **SoC** | Qualcomm Snapdragon 870 (SM8250-AC) |
| **CPU** | 1× Kryo 585 Prime (stock 3.19GHz, capped at 2.84GHz in DTS) + 3× Gold @ 2.42GHz + 4× Silver @ 1.80GHz |
| **RAM** | 6 / 8 GB LPDDR5 |
| **Storage** | 128 / 256 GB UFS 3.1 |
| **Display** | 6.67″ AMOLED 1080×2400, 120Hz, HDR10+ |
| **Architecture** | aarch64 |
| **Released** | 2021 |

## Hardware status

| Component | Status | Notes |
|-----------|--------|-------|
| Display | ✅ | 90/120Hz, samsung ams667xx01 |
| Touchscreen | ✅ | focaltech ft3658 via spi4 |
| GPU | ✅ | Adreno 650 — requires a650 + a650-zap firmware; optimized OPP table (683/587/510/400/330/205/150 MHz, explicit voltage levels) |
| WiFi | ✅ | qca6391 — requires ath11k firmware |
| Bluetooth | ✅ | qca6391 — requires qca firmware |
| NFC | ✅ | qcom,nq-nci |
| USB OTG | ✅ | pm8150b USB-C controller |
| Battery | ✅ | qcom,pm8150b-fg |
| Flash LED | ✅ | qcom,spmi-flash-led |
| IR TX | ✅ | |
| Speaker / earpiece | ✅ | cirrus,cs35l41 (i2c3 @ 0x40/0x41) |
| Microphones | 🔧 | qcom,wcd9380 — WIP |
| Sensors (accel/gyro/etc.) | ✅ | hexagonrpcd + libSSC via SDSP remoteproc |
| Haptics | 🔧 | awinic,aw8697 via i2c11 — WIP |
| GPS | ❌ | |
| Calls / SMS / Mobile data | ❌ | SDX55m modem not supported in mainline |
| Camera (main + macro) | ⚠️ | Partial — EEPROM works, sensor drivers WIP |
| Fingerprint | ❌ | |
| Proximity | ❌ | |
| HW video decode/encode | ✅ | Venus V4L2M2M at `/dev/video14`–`/dev/video15` — stable on H.264 source; crashes on HEVC source (kernel driver bug) |

Known issue: changing display brightness causes graphical artifacts.

---

## Packages

### Kernel

| Package | Description |
|---------|-------------|
| `linux-alioth-7p1-ThinLTO-5k` | Kernel 7.1.2, Clang ThinLTO, 5000mAh battery — recommended for desktop/server use |
| `linux-alioth-7p1-ThinLTO-4p52k` | Same, stock 4520mAh battery |
| `linux-alioth-7p1-Server-ThinLTO-5k` | Server variant: PREEMPT_NONE, HZ=250, full tickless, BBR, RCU offload, 5000mAh battery |
| `linux-alioth-7p1-Server-ThinLTO-4p52k` | Same, stock 4520mAh battery |
| `linux-alioth-7p1-*-headers` | Headers for each variant |
| `alioth-kernel-hooks` | Pacman hooks to rebuild initramfs and flash `boot.img` on kernel upgrade |

All variants built with `LLVM=1` (Clang + lld) targeting arm64. Based on Linux 7.1.2 stable ([rmuxnet/linux, branch alioth/7.1.2](https://github.com/rmuxnet/linux/tree/alioth/7.1.2)) with alioth-specific patches: prime CPU capped at 2.84GHz, optimized Adreno 650 OPP table, hardware video decoding, and other device enablement.

### Firmware

Split from [N1kroks/firmware-xiaomi-alioth](https://github.com/N1kroks/firmware-xiaomi-alioth):

| Package | Component |
|---------|-----------|
| `linux-firmware-alioth-adreno` | Adreno 650 GPU (a650_zap.mbn) |
| `linux-firmware-alioth-adsp` | ADSP |
| `linux-firmware-alioth-cdsp` | CDSP |
| `linux-firmware-alioth-ipa` | IPA |
| `linux-firmware-alioth-slpi` | SLPI |
| `linux-firmware-alioth-venus` | Venus video codec |
| `linux-firmware-alioth-cirrus` | CS35L41 speaker amplifier |
| `linux-firmware-alioth-focaltech` | FT3658 touchscreen |
| `linux-firmware-alioth-hexagonfs` | DSP / sensor / ACDB files |

### Device packages

| Package | Description |
|---------|-------------|
| `device-xiaomi-alioth` | udev rules, ALSA UCM2, WirePlumber config |
| `device-xiaomi-alioth-runit` | Runit service configs for hexagonrpcd, qbootctl, iio-sensor-proxy, swclock-offset |

### System utilities

| Package | Description |
|---------|-------------|
| `hexagonrpcd` / `hexagonrpcd-runit` | Qualcomm HexagonFS daemon — exposes DSP remoteproc for sensors |
| `libssc` | Qualcomm Sensor Core library (libSSC) |
| `iio-sensor-proxy-libssc` / `*-runit` | IIO sensor proxy patched for libSSC |
| `qbootctl` / `qbootctl-runit` | A/B slot boot control — marks current slot successful at boot |
| `swclock-offset` / `*-runit` | Clock offset helper for devices without a writable RTC |
| `bootmac` | Set stable MAC addresses for WiFi/BT at boot |
| `mkbootimg-alioth` | Android `mkbootimg`/`unpackbootimg` (osm0sis fork) — used to assemble `boot.img` |
| `zramen` / `zramen-runit` | zram swap manager |
| `widevine` | Widevine CDM for Chromium/Firefox (aarch64, extracted from ChromeOS lacros) |
| `libglibutil` | GLib utilities (sailfishos) |
| `libgbinder` | GLib-style binder interface |
| `python-gbinder-git` | Python bindings for libgbinder |

---

## Pacman repo

Pre-built packages are published to GitHub Releases (tag `repo`). Add to `/etc/pacman.conf`:

```ini
[alioth]
SigLevel = Optional TrustAll
Server = https://github.com/rmuxnet/PKGBUILDs-alioth/releases/download/repo
```

Then:

```sh
pacman -Sy
pacman -S linux-alioth-7p1-Server-ThinLTO-5k device-xiaomi-alioth device-xiaomi-alioth-runit
```

---

## Prebuilt rootfs

A full ARMtix runit rootfs (12 GB ext4, shrunk + compressed) is published under versioned release tags (`armtix-alioth-runit-YYYYMMDD`). It includes the kernel, device packages, firmware, NetworkManager, and mesa.

Default credentials: user `armtix`, password `armtix`. Root password `armtix`.

**Flash:**

```sh
# Boot partition
fastboot flash boot armtix-alioth-runit-YYYYMMDD-boot.img

# Or via dd from recovery
dd if=armtix-alioth-runit-YYYYMMDD-boot.img of=/dev/disk/by-partlabel/boot bs=4M
```

**Rootfs:**

```sh
# Extract to a partition labeled "armtix"
tar -xf armtix-alioth-runit-YYYYMMDD.tar.xz -C /mnt/
```

---

## Bootloader

- **Fastboot (bootloader):** hold Power + Volume Down at boot
- **Recovery:** hold Power + Volume Up at boot
- **Fastbootd:** boot into fastboot mode, then run `fastboot reboot fastboot`

Unlock bootloader first via `fastboot flashing unlock`.

**Before flashing Linux on a slot, erase its dtbo partition:**

```sh
fastboot erase dtbo_a   # if flashing slot a
fastboot erase dtbo_b   # if flashing slot b
```

Android's dtbo overlays conflict with the mainline DTS and will prevent the device from booting correctly if left in place.

---

## Build locally

```sh
git clone https://github.com/rmuxnet/PKGBUILDs-alioth
cd PKGBUILDs-alioth/linux-alioth-7p1
bash build.sh thin        # ThinLTO
bash build.sh server-thin # server-optimised ThinLTO
```

Requires Clang, lld, and standard kernel build deps. Must not run as root.

---

## CI

| Workflow | Trigger | Output |
|----------|---------|--------|
| `build-fullto.yml` | push to `linux-alioth-7p1/**`, manual | All kernel variants → `repo` release |
| `build-packages.yml` | push to any non-kernel package, manual | Extra packages → `repo` release |
| `build-bootimg.yml` | manual | `boot.img` artifact (quick, no full kernel build) |
| `build-rootfs.yml` | manual | Full rootfs tarball + boot.img → versioned release |

All workflows run on `ubuntu-24.04-arm` in an `archlinuxarm:base-devel` container.

---

## Serial UART

UART TX is below the sub-board connector on the left side of the board, next to a 0402 capacitor. Baud 115200. Ground: metal shielding.

---

## Links

- [Kernel source (rmuxnet/linux, branch alioth/7.1.2)](https://github.com/rmuxnet/linux/tree/alioth/7.1.2)
- [Firmware repo](https://github.com/N1kroks/firmware-xiaomi-alioth)
- [PostmarketOS device page](https://wiki.postmarketos.org/wiki/Xiaomi_POCO_F3_(xiaomi-alioth))
- [ARMtix Linux](https://armtixlinux.org/)
