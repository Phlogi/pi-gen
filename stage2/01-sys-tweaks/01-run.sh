#!/bin/bash -e

install -d				"${ROOTFS_DIR}/etc/systemd/system/rc-local.service.d"
install -m 644 files/ttyoutput.conf	"${ROOTFS_DIR}/etc/systemd/system/rc-local.service.d/"

install -m 644 files/50raspi		"${ROOTFS_DIR}/etc/apt/apt.conf.d/"

install -m 644 files/console-setup   	"${ROOTFS_DIR}/etc/default/"

install -m 755 files/rc.local		"${ROOTFS_DIR}/etc/"

install -m 755 files/resizefs_hook	"${ROOTFS_DIR}/etc/initramfs-tools/hooks/"
install -m 755 files/resizefs_premount  "${ROOTFS_DIR}/etc/initramfs-tools/scripts/local-premount/"

on_chroot << EOF
systemctl disable hwclock.sh
systemctl disable nfs-common
systemctl disable rpcbind
if [ "${ENABLE_SSH}" == "1" ]; then
	systemctl enable ssh
else
	systemctl disable ssh
fi
systemctl enable regenerate_ssh_host_keys
EOF

if [ "${USE_QEMU}" = "1" ]; then
	echo "enter QEMU mode"
	install -m 644 files/90-qemu.rules "${ROOTFS_DIR}/etc/udev/rules.d/"
	on_chroot << EOF
sed -i 's/^initramfs /#initramfs /' /boot/config.txt
EOF
	echo "leaving QEMU mode"
fi

on_chroot <<EOF
for GRP in input spi i2c gpio; do
	groupadd -f -r "\$GRP"
done
for GRP in adm dialout cdrom audio users sudo video games plugdev input gpio spi i2c netdev; do
  adduser $FIRST_USER_NAME \$GRP
done
EOF

on_chroot << EOF
setupcon --force --save-only -v
EOF

on_chroot << EOF
usermod --pass='*' root
EOF

# crate initramfs for each kernel type
echo "Building initramfs..."
for modules_dir in $(find ${ROOTFS_DIR}/lib/modules/ -mindepth 1 -maxdepth 1 -type d); do
	modules_name=$(basename "${modules_dir}")
	initrd_name=$(echo initrd"${modules_name}" | sed -E "s/[[:digit:]]*\.[[:digit:]]*\.[[:digit:]]*//g" | sed -E "s/\+//" | sed -E "s/-v//")
on_chroot << EOF
mkinitramfs -o /boot/"${initrd_name}" "${modules_name}";
EOF
done

ls -l ${ROOTFS_DIR}/boot/initrd*
ls -l ${ROOTFS_DIR}/boot/kernel*

rm -f "${ROOTFS_DIR}/etc/ssh/"ssh_host_*_key*
