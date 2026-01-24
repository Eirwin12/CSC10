# Makefile voor Linux Kernel Module
# Voor cross-compilatie voor DE1-SoC ARM platform

# Kernel module naam
obj-m := key_led_driver.o

# Kernel source directory (pas aan naar jouw kernel source locatie)
# Voor native compilation op DE1-SoC:
KDIR := /lib/modules/$(shell uname -r)/build

# Voor cross-compilation (uncomment en pas aan):
# ARCH := arm
# CROSS_COMPILE := arm-linux-gnueabihf-
# KDIR := /path/to/linux-socfpga

# Huidige directory
PWD := $(shell pwd)

# Default target: build kernel module
all:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

# Clean build artifacts
clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
	rm -f test_key_led test_async_key

# Install module (vereist root privileges)
install:
	$(MAKE) -C $(KDIR) M=$(PWD) modules_install
	depmod -a

# Load module
load:
	sudo insmod key_led_driver.ko

# Unload module
unload:
	sudo rmmod key_led_driver

# View kernel log
log:
	dmesg | tail -20

# Build user space test programs
test: test_key_led test_async_key

test_key_led: test_key_led.c
	$(CROSS_COMPILE)gcc -o test_key_led test_key_led.c -Wall

test_async_key: test_async_key.c
	$(CROSS_COMPILE)gcc -o test_async_key test_async_key.c -Wall

.PHONY: all clean install load unload log test
