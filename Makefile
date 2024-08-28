BUILDROOT_VERSION = 2024.05.1
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
	ln -sf buildroot-$(BUILDROOT_VERSION) $(BUILDROOT_DIR)

# Copy the defconfig before running certain targets
.PHONY: preconfig
preconfig: $(BUILDROOT_DIR) $(BR2_DEFCONFIG)
	@echo "Copying defconfig..."
	$(MAKE) -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(BR2_EXTERNAL) BR2_DEFCONFIG=$(BR2_DEFCONFIG) defconfig

build: preconfig
	$(MAKE) -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(PROJECT_DIR)


boot: 
	python ./amlogic_device.py --initrd ./initrd/env_initrd.txt ./_build/output/images/Image ./_build/output/images/rootfs.cpio.uboot  ./_build/output/images/meson-g12a-superbird.dtb
