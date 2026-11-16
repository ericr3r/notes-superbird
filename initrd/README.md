# USB-boot debug initrd (Linux 7.0.2 / mainline)

This Buildroot `BR2_EXTERNAL` builds a kernel + a RAM cpio initrd that you load
over USB (burn mode) with `pyamlboot`/`amlogic_device.py`. It gives you a shell
over USB networking so you can debug a kernel that won't boot from eMMC, without
touching the eMMC rootfs.

## What it builds

As of the 7.0.2 upgrade this builds the **same kernel** as
`nerves_system_superbird`, so you are debugging the real failure:

- Linux **7.0.2** (`BR2_LINUX_KERNEL_CUSTOM_VERSION_VALUE`), same as nerves.
- Patches: `nerves_system_superbird/linux/` (the 25 superbird patches + the
  base-DTS patch `0026`).
- Config: arm64 `defconfig` + `nerves_system_superbird/kernel/superbird*.cfg`
  fragments + `configs/initrd-debug.cfg` (this project).
- Device tree: in-tree `amlogic/meson-g12a-superbird` (added by patch `0026`),
  plus the `watchdog.dts` / `usb-host.dts` overlays from nerves for parity.

The initrd itself (busybox + openssh + g_ether) is built from
`rootfs_overlay/` and boots entirely from RAM.

### Cross-repo dependency (important)

The defconfig references the nerves system via relative paths:

```
${BR2_EXTERNAL_SUPERBIRD_INITRD_PATH}/../../nerves_system_superbird/...
```

This assumes `notes-superbird/` and `nerves_system_superbird/` are checked out
as **siblings** under a common parent (as in this workspace,
`/home/eric/projects/nerves/`). If your layout differs, adjust those paths in
`configs/superbird_initrd_defconfig`.

`config_linux_20240729` is the old 6.6 kernel config and is no longer used.

## Build

```sh
make           # downloads Buildroot 2026.08.1, configures, builds
```

The Buildroot version is pinned in the top-level `Makefile` to match
`nerves_system_br` (1.35.3 -> Buildroot 2026.08.1). After a version bump you may
need a one-time `make -C _build olddefconfig` to migrate renamed symbols; the
internal toolchain's `BR2_GCC_VERSION` may also be re-defaulted by olddefconfig,
which is fine for building 7.0.2.

## Boot it over USB

Put the device in burn mode (unplug, hold buttons 1 + 4, plug USB), then:

```sh
make boot
# == python ./amlogic_device.py --initrd ./initrd/env_initrd.txt \
#      ./_build/output/images/Image \
#      ./_build/output/images/rootfs.cpio.uboot \
#      ./_build/output/images/meson-g12a-superbird.dtb
```

`env_initrd.txt` boots with `console=ttyAML0,115200n8 keep_bootcon
ignore_loglevel` so that, if you do have serial on the pads, you see everything;
over USB you get the shell regardless.

## Debugging the eMMC boot failure once you have a shell

SSH in over USB (`ssh superbird@172.16.42.2`, password `superbird`) and inspect
the real boot path, which this RAM boot bypassed:

```sh
dmesg | grep -iE 'mmc|squashfs|root|panic|Call trace'   # driver / rootfs errors
cat /proc/partitions                                    # is eMMC mmcblk2 or mmcblk0?
cat /proc/cmdline
# Try mounting the real rootfs the way the image would:
mount -t squashfs -o ro /dev/mmcblk2p2 /mnt && echo OK || dmesg | tail
unsquashfs -s /dev/mmcblk2p2                             # what compression is it?
```

The two most likely upgrade culprits this isolates:
- eMMC enumerating as `mmcblk0` instead of `mmcblk2` (the `mmc2 = &sd_emmc_c`
  alias pin in patch `0026` should keep it `mmcblk2` - confirm here).
- squashfs compression the kernel can't decompress (the fragments enable
  gzip/lz4/zstd but **not** xz).
