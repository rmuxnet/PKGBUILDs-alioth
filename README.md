# PKGBUILDs-alioth

Arch-based PKGBUILDs for running [ARMtix](https://armtixlinux.org/) (Artix Linux aarch64, runit) on the Xiaomi POCO F3 / Redmi K40 / Mi 11X (codename **alioth**).

<p align="center">
  <img src="https://wiki.postmarketos.org/images/thumb/7/71/Xiaomi-alioth.png/659px-Xiaomi-alioth.png" width="300" alt="Xiaomi POCO F3 (alioth)">
</p>

## Device specifications

<table>
    <tbody>
        <tr>
            <td>Basic</td>
            <td colspan="3">Spec Sheet</td>
        </tr>
        <tr>
            <td>Model</td>
            <td>Redmi K40</td>
            <td>POCO F3</td>
            <td>Xiaomi Mi 11X</td>
        </tr>
        <tr>
            <td>Codename</td>
            <td colspan="3">alioth</td>
        </tr>
        <tr>
            <td>Released</td>
            <td>March 2021</td>
            <td>March 2021</td>
            <td>April 2021</td>
        </tr>
        <tr>
            <td>SoC</td>
            <td colspan="3">Qualcomm SM8250-AC Snapdragon 870 5G (7 nm)</td>
        </tr>
        <tr>
            <td>CPU</td>
            <td colspan="3">Octa-core (1x3.2 GHz Kryo 585 &amp; 3x2.42 GHz Kryo 585 &amp; 4x1.80 GHz Kryo 585). The prime core is capped at 2.84 GHz in the mainline DTS.</td>
        </tr>
        <tr>
            <td>GPU</td>
            <td colspan="3">Adreno 650</td>
        </tr>
        <tr>
            <td>Memory</td>
            <td>128GB 6GB RAM, 128GB 8GB RAM, 256GB 8GB RAM, 256GB 12GB RAM</td>
            <td>128GB 6GB RAM, 128GB 8GB RAM, 256GB 8GB RAM</td>
            <td>128GB 6GB RAM, 128GB 8GB RAM</td>
        </tr>
        <tr>
            <td>Memory type</td>
            <td colspan="3">LPDDR5 RAM, UFS 3.1 storage</td>
        </tr>
        <tr>
            <td>Shipped Android Version</td>
            <td colspan="3">Android 11 (MIUI 12)</td>
        </tr>
        <tr>
            <td>Battery</td>
            <td colspan="3">Li-Po 4520 mAh, non-removable, 33W wired</td>
        </tr>
        <tr>
            <td>Display</td>
            <td colspan="3">6.67", 1080 x 2400 pixels, 20:9 ratio (~395 ppi density), AMOLED, 120Hz, HDR10+, 1300 nits (peak)</td>
        </tr>
        <tr>
            <td>Camera (Wide)</td>
            <td colspan="3">48 MP, f/1.8, 26mm (wide), 1/2.0", 0.8&micro;m, PDAF (Sony IMX582)</td>
        </tr>
        <tr>
            <td>Camera (Ultrawide)</td>
            <td colspan="3">8 MP, f/2.2, 119&deg; (ultrawide) (Sony IMX355)</td>
        </tr>
        <tr>
            <td>Camera (Macro)</td>
            <td colspan="3">5 MP, f/2.4, 50mm (macro), AF (Samsung S5K5E9)</td>
        </tr>
        <tr>
            <td>Camera (Front)</td>
            <td colspan="3">20 MP, f/2.5, (wide), 1/3.4", 0.8&micro;m (Samsung S5K3T2)</td>
        </tr>
        <tr>
            <td>Audio</td>
            <td colspan="3">Stereo speakers (2x Cirrus Logic CS35L41), no headphone jack</td>
        </tr>
    </tbody>
</table>

## Hardware status

| Component | Status | Notes |
|-----------|--------|-------|
| Display | OK | 90/120Hz, samsung ams667xx01 |
| Touchscreen | OK | focaltech,ft8756 on spi4 |
| GPU | OK | Adreno 650 - requires a650 + a650-zap firmware; optimized OPP table (683/587/510/400/330/205/150 MHz, explicit voltage levels) |
| WiFi | OK | qca6391 (ath11k reports QCA6390 hw2.0) - requires ath11k firmware |
| Bluetooth | Partial | qca6391 - requires qca firmware. hci0 comes up. bluetoothd is not set up and the MAC address is random. Pairing is not tested. |
| NFC | OK | nxp,pn553 on i2c1 at 0x28 (nxp-nci driver). Tested on kernel 7.1.7: `nfc0` powers up, polls, detects ISO14443-A targets, and exchanges ISO-DEP APDUs. There is no neard package, so there are no userspace NFC tools. Card emulation is not supported: the kernel NFC core only supports NFC-DEP in target mode. The antenna is at the top of the back, near the cameras. |
| USB OTG | OK | pm8150b USB-C controller. Host mode tested with a USB hub. |
| Battery | Partial | PMIC fuel gauge qcom,pm8150b-fg. Charging works from a computer USB port (5 V). A USB PD wall charger does not charge. No fast charge. |
| Flash LED | OK | qcom,spmi-flash-led, LED class device `white:flash` |
| IR TX | OK | ir-spi-led on spi2. Tested with `ir-ctl`. Send NEC codes with `ir-ctl -S nec:0xff00`. |
| Speaker / earpiece | Partial | cirrus,cs35l41 on i2c3, fed by Tertiary TDM from the ADSP. Stereo playback works: 0x40 drives the top speaker (left, also the earpiece), 0x41 drives the bottom speaker (right). It needs kernel fixes (q6afe TDM sync/delay, sm8250 TDM hw_params, CS35L41 PLL clock) that are not in the packaged kernel yet. The amplifiers run without Cirrus speaker protection firmware, so keep the volume moderate. No EQ yet. Earpiece for calls is not set up. |
| Microphones | Not working | qcom,wcd9380. The codec is not enabled in the device tree. |
| Sensors (accel/gyro/etc.) | Broken | hexagonrpcd + libSSC via SDSP remoteproc. On kernel 7.1.7, `monitor-sensor` finds no sensors and the SLPI remoteproc logs repeated handover messages. Under investigation. |
| Haptics | OK | awinic,aw8697 on i2c11 at 0x5a. The in-tree `aw86927` driver supports it (kernel 7.1.7). It is a force feedback input device named `aw86927-haptics` (FF_RUMBLE). Test it with `fftest` on its `/dev/input/eventX` node. |
| GPS | N/A | GNSS is in the SDX55m modem |
| Calls / SMS / Mobile data | N/A | SDX55m modem not supported in mainline |
| Camera | OK | All 4 cameras capture on kernel 7.1.7 through camss: main sony,imx582 (48MP), ultrawide sony,imx355 (8MP), macro samsung,s5k5e9 (5MP), front samsung,s5k3t2 (20MP). Main camera autofocus: dongwoon,dw9800 VCM. libcamera tuning and auto exposure are not done yet. |
| Fingerprint | N/A | Side-mounted fpc,fpc1020. It needs the Qualcomm TEE. |
| Proximity | N/A | Ultrasound proximity (Elliptic) on the audio DSP |
| HW video decode/encode | OK | Venus V4L2M2M at `/dev/video14`-`/dev/video15` - stable on H.264 source; crashes on HEVC source (kernel driver bug) |

Known issue: changing display brightness causes graphical artifacts.

## Packages

### Kernel

| Package | Description |
|---------|-------------|
| `linux-alioth-7p7-ThinLTO-5k` | Kernel 7.1.7, Clang ThinLTO, 5000mAh battery - recommended for desktop use |
| `linux-alioth-7p7-ThinLTO-4p52k` | Same, stock 4520mAh battery |
| `linux-alioth-7p7-Server-ThinLTO-5k` | Server variant: PREEMPT_NONE, HZ=250, full tickless, BBR, RCU offload, 5000mAh battery |
| `linux-alioth-7p7-Server-ThinLTO-4p52k` | Same, stock 4520mAh battery |
| `linux-alioth-7p7-*-headers` | Headers for each variant |
| `linux-alioth-7p1-*` | Older kernel 7.1.2 packages, same variants |
| `alioth-kernel-hooks` | Pacman hooks to rebuild initramfs and flash `boot.img` on kernel upgrade |

All variants built with `LLVM=1` (Clang + lld) targeting arm64. Based on Linux 7.1.7 stable ([rmuxnet/linux, branch alioth/7.1.7](https://github.com/rmuxnet/linux/tree/alioth/7.1.7)) with alioth-specific patches: prime CPU capped at 2.84GHz, optimized Adreno 650 OPP table, hardware video decoding, and other device enablement.

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
| `device-xiaomi-alioth` | udev rules; pulls in `audio-xiaomi-alioth` |
| `audio-xiaomi-alioth` | ALSA UCM2 (speaker and microphone routing), WirePlumber config |
| `device-xiaomi-alioth-runit` | Runit service configs for hexagonrpcd, qbootctl, iio-sensor-proxy, swclock-offset |

### System utilities

| Package | Description |
|---------|-------------|
| `hexagonrpcd` / `hexagonrpcd-runit` | Qualcomm HexagonFS daemon - exposes DSP remoteproc for sensors |
| `libssc` | Qualcomm Sensor Core library (libSSC) |
| `iio-sensor-proxy-libssc` / `*-runit` | IIO sensor proxy patched for libSSC |
| `qbootctl` / `qbootctl-runit` | A/B slot boot control - marks current slot successful at boot |
| `swclock-offset` / `*-runit` | Clock offset helper for devices without a writable RTC |
| `bootmac` | Set stable MAC addresses for WiFi/BT at boot |
| `mkbootimg-alioth` | Android `mkbootimg`/`unpackbootimg` (osm0sis fork) - used to assemble `boot.img` |
| `zramen` / `zramen-runit` | zram swap manager |
| `widevine` | Widevine CDM for Chromium/Firefox (aarch64, extracted from ChromeOS lacros) |
| `libglibutil` | GLib utilities (sailfishos) |
| `libgbinder` | GLib-style binder interface |
| `python-gbinder-git` | Python bindings for libgbinder |

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
pacman -S linux-alioth-7p7-Server-ThinLTO-5k device-xiaomi-alioth device-xiaomi-alioth-runit
```

## Prebuilt rootfs

A full ARMtix runit rootfs (12 GB ext4, shrunk + compressed) is published under versioned release tags (`armtix-alioth-runit-YYYYMMDD`). It includes the kernel, device packages, firmware, NetworkManager, and mesa.

Default credentials: user `armtix`, password `armtix`. Root password `armtix`.

Flash the boot partition:

```sh
fastboot flash boot armtix-alioth-runit-YYYYMMDD-boot.img
```

Or via dd from recovery:

```sh
dd if=armtix-alioth-runit-YYYYMMDD-boot.img of=/dev/disk/by-partlabel/boot bs=4M
```

Extract the rootfs to a partition labeled "armtix":

```sh
tar -xf armtix-alioth-runit-YYYYMMDD.tar.xz -C /mnt/
```

## Bootloader

- **Fastboot (bootloader):** hold Power + Volume Down at boot
- **Recovery:** hold Power + Volume Up at boot
- **Fastbootd:** boot into fastboot mode, then run `fastboot reboot fastboot`

Unlock bootloader first via `fastboot flashing unlock`.

Before flashing Linux on a slot, erase its dtbo partition:

```sh
fastboot erase dtbo_a   # if flashing slot a
fastboot erase dtbo_b   # if flashing slot b
```

Android's dtbo overlays conflict with the mainline DTS and will prevent the device from booting correctly if left in place.

## Build locally

```sh
git clone https://github.com/rmuxnet/PKGBUILDs-alioth
cd PKGBUILDs-alioth/linux-alioth-7p7
bash build.sh thin        # ThinLTO
bash build.sh server-thin # server-optimised ThinLTO
```

Requires Clang, lld, and standard kernel build deps. Must not run as root.

## CI

| Workflow | Trigger | Output |
|----------|---------|--------|
| `build-fullto.yml` | push to `linux-alioth-7p1/**` or `linux-alioth-7p7/**`, manual | All kernel variants -> `repo` release |
| `build-packages.yml` | push to any non-kernel package, manual | Extra packages -> `repo` release |
| `build-bootimg.yml` | manual | `boot.img` artifact (quick, no full kernel build) |
| `build-rootfs.yml` | manual | Full rootfs tarball + boot.img -> versioned release |

All workflows run on `ubuntu-24.04-arm` in an `archlinuxarm:base-devel` container.

## Serial UART

UART TX is below the sub-board connector on the left side of the board, next to a 0402 capacitor. Baud 115200. Ground: metal shielding.

## Links

- [Kernel source (rmuxnet/linux, branch alioth/7.1.7)](https://github.com/rmuxnet/linux/tree/alioth/7.1.7)
- [Firmware repo](https://github.com/N1kroks/firmware-xiaomi-alioth)
- [PostmarketOS device page](https://wiki.postmarketos.org/wiki/Xiaomi_POCO_F3_(xiaomi-alioth))
- [ARMtix Linux](https://armtixlinux.org/)
