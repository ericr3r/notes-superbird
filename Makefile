# Keep this in lockstep with nerves_system_br used by nerves_system_superbird
# (nerves_system_br 1.35.3 -> Buildroot 2026.08.1) so the debug kernel is built
# the same way as the real image.
BUILDROOT_VERSION = 2026.08.1
BUILDROOT_ARCHIVE = buildroot-$(BUILDROOT_VERSION).tar.gz
BUILDROOT_URL = https://buildroot.org/downloads/$(BUILDROOT_ARCHIVE)
PROJECT_DIR = $(CURDIR)/initrd/
BR2_EXTERNAL = $(PROJECT_DIR)
DEFCONFIG = superbird_initrd_defconfig
BR2_DEFCONFIG = $(BR2_EXTERNAL)/configs/$(DEFCONFIG)
BUILDROOT_DIR = _build

all: build

$(BUILDROOT_ARCHIVE):
	@echo "Downloading Buildroot..."
	wget $(BUILDROOT_URL)

$(BUILDROOT_DIR): $(BUILDROOT_ARCHIVE)
	@echo "Extracting Buildroot..."
	tar -xzf $(BUILDROOT_ARCHIVE)

# Copy the defconfig before running certain targets
.PHONY: preconfig
preconfig: $(BUILDROOT_DIR) $(BR2_DEFCONFIG)
	@echo "Copying defconfig..."
	ln -sf buildroot-$(BUILDROOT_VERSION) $(BUILDROOT_DIR)
	$(MAKE) -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(BR2_EXTERNAL) BR2_DEFCONFIG=$(BR2_DEFCONFIG) defconfig

.PHONY: build
build: preconfig
	$(MAKE) -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(PROJECT_DIR)


boot: 
	python ./amlogic_device.py --initrd ./initrd/env_initrd.txt ./_build/output/images/Image ./_build/output/images/rootfs.cpio.uboot  ./_build/output/images/meson-g12a-superbird.dtb
