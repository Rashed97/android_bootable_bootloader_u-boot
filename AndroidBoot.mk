#
# Copyright (C) 2018 Team Codefire
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#
# Android makefile to build bootloader as a part of Android Build
#
# Configuration
# =============
#
# These config vars are usually set in BoardConfig.mk:
#   TARGET_BOOTLOADER_CONFIG               = Bootloader defconfig
#   TARGET_BOOTLOADER_ARCH                 = Bootloader arch
#
ifneq ($(TARGET_NO_BOOTLOADER),true)

UBOOT_SRC := bootable/bootloader/u-boot
UBOOT_OUT := $(TARGET_OUT_INTERMEDIATES)/UBOOT_OBJ

TARGET_BOOTLOADER_ARCH := $(strip $(TARGET_BOOTLOADER_ARCH))
ifeq ($(TARGET_BOOTLOADER_ARCH),)
BOOTLOADER_ARCH := $(TARGET_ARCH)
else
BOOTLOADER_ARCH := $(TARGET_BOOTLOADER_ARCH)
endif


ifeq ($(BOOTLOADER_ARCH),arm64)
BOOTLOADER_TOOLCHAIN_ARCH := aarch64
BOOTLOADER_TOOLCHAIN_PREFIX := aarch64-linux-android-
else ifeq ($(BOOTLOADER_ARCH),arm)
BOOTLOADER_TOOLCHAIN_ARCH := arm
BOOTLOADER_TOOLCHAIN_PREFIX := arm-linux-androideabi-
endif
BOOTLOADER_TOOLCHAIN_VERSION := 4.9

BOOTLOADER_TOOLCHAIN_PATH := $(ANDROID_BUILD_TOP)/prebuilts/gcc/$(HOST_OS)-x86/$(BOOTLOADER_TOOLCHAIN_ARCH)/$(BOOTLOADER_TOOLCHAIN_PREFIX)$(BOOTLOADER_TOOLCHAIN_VERSION)/bin/$(BOOTLOADER_TOOLCHAIN_PREFIX)

ifneq ($(USE_CCACHE),)
    # Detect if the system already has ccache installed to use instead of the prebuilt
    ccache := $(shell which ccache)

    ifeq ($(ccache),)
        ccache := $(ANDROID_BUILD_TOP)/prebuilts/misc/$(HOST_PREBUILT_TAG)/ccache/ccache
       	# Check that the executable is here.
        ccache := $(strip $(wildcard $(ccache)))
    endif
endif

BOOTLOADER_CROSS_COMPILE := CROSS_COMPILE="$(ccache) $(BOOTLOADER_TOOLCHAIN_PATH)"
ccache =

UBOOT_CLEAN:
	$(hide) rm -f $(TARGET_UBOOT_BIN)
	$(hide) rm -rf $(UBOOT_OUT)

$(UBOOT_OUT):
	mkdir -p $(UBOOT_OUT)

BOOTLOADER_CONFIG := $(BOOTLOADER_OUT)/.config
$(BOOTLOADER_CONFIG): $(UBOOT_CLEAN) | $(UBOOT_OUT)
	$(MAKE) -C $(UBOOT_SRC) O=$(UBOOT_OUT) ARCH=$(BOOTLOADER_ARCH) $(BOOTLOADER_CROSS_COMPILE) $(TARGET_BOOTLOADER_CONFIG)

TARGET_UBOOT_BIN := $(UBOOT_OUT)/u-boot.bin
$(TARGET_UBOOT_BIN): $(BOOTLOADER_CONFIG)
	$(MAKE) -C $(UBOOT_SRC) O=$(UBOOT_OUT) $(BOOTLOADER_CROSS_COMPILE) u-boot.bin

INSTALLED_BOOTLOADER_TARGET := $(PRODUCT_OUT)/u-boot.bin
file := $(INSTALLED_BOOTLOADER_TARGET)
ALL_PREBUILT += $(file)
$(file) : $(TARGET_UBOOT_BIN) | $(ACP)
        $(transform-prebuilt-to-target)

ALL_PREBUILT += $(INSTALLED_BOOTLOADER_TARGET)

.PHONY: bootloader
bootloader: $(INSTALLED_BOOTLOADER_TARGET)

endif # TARGET_NO_BOOTLOADER
