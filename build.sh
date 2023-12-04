#!/bin/bash

# Set variables
LFS=/mnt/lfs
LFS_TGT=$(uname -m)-lfs-linux-gnu
LC_ALL=POSIX
LFS_THIS_SCRIPT=$(readlink -f "${BASH_SOURCE[0]}")

# Create the LFS directory
sudo mkdir -pv $LFS
sudo chown -v $USER $LFS

# Download essential files
wget http://www.linuxfromscratch.org/lfs/view/stable/wget-list
wget --input-file=wget-list --continue --directory-prefix=$LFS/sources

# Extract sources
cd $LFS/sources
while read -r line; do
  tar -xf $line
done < wget-list

# Create the tools directory
mkdir -v $LFS/tools
ln -sv $LFS/tools /

# Set up environment variables
cat << EOF >> ~/.bashrc
export LFS=$LFS
export LC_ALL=$LC_ALL
export LFS_TGT=$LFS_TGT
export PATH=/tools/bin:/bin:/usr/bin
EOF

source ~/.bashrc

# Build and install cross-compilation tools
cd $LFS/sources
tar -xf binutils-2.36.1.tar.xz
cd binutils-2.36.1
mkdir -v build
cd build
../configure --prefix=/tools            \
             --with-sysroot=$LFS        \
             --with-lib-path=/tools/lib \
             --target=$LFS_TGT          \
             --disable-nls              \
             --disable-werror
make
make install

# Continue with building the temporary tools

# Lightweight alternatives example: Use zlib instead of libarchive
cd $LFS/sources
tar -xf zlib-1.2.11.tar.gz
cd zlib-1.2.11
./configure --prefix=/tools
make
make install

# Continue with other temporary tools and final system components

# Build and install GCC
cd $LFS/sources
tar -xf gcc-10.3.0.tar.xz
cd gcc-10.3.0
contrib/download_prerequisites
mkdir -v build
cd build
../configure --target=$LFS_TGT --prefix=/tools \
             --with-glibc-version=2.11 --with-sysroot=$LFS \
             --with-newlib --without-headers --enable-initfini-array \
             --disable-nls --disable-shared --disable-multilib
make
make install

# Continue with other final system components

# Configure and install the Linux kernel
cd $LFS/sources
tar -xf linux-5.10.17.tar.xz
cd linux-5.10.17
make mrproper
make ARCH=$LFS_TGT headers_check
make ARCH=$LFS_TGT INSTALL_HDR_PATH=dest headers_install
cp -rv dest/include/* /tools/include

# Continue with other kernel configuration and installation steps

# Install lightweight alternatives (e.g., toybox, sinit, dwm, etc.)

# Lightweight alternatives example: Use toybox instead of coreutils
cd $LFS/sources
tar -xf toybox-0.8.5.tar.bz2
cd toybox-0.8.5
make defconfig
make
make CONFIG_PREFIX=/ install

# Lightweight alternatives example: Use sinit as a simple init system
cd $LFS/sources
git clone https://git.suckless.org/sinit
cd sinit
make
make install

# Lightweight alternatives example: Use dwm as a window manager
cd $LFS/sources
git clone https://git.suckless.org/dwm
cd dwm
make
make install

# Continue with other lightweight alternatives

# Install and configure GRUB bootloader
cd $LFS/sources
tar -xf grub-2.06.tar.xz
cd grub-2.06
./configure --prefix=/usr
make
make install

# Configure GRUB
cat << EOF > $LFS/boot/grub/grub.cfg
set default=0
set timeout=5

menuentry "LFS" {
    set root=(hd0,1)
    linux /vmlinuz root=/dev/sda1
}
EOF

# Install GRUB to the MBR (replace /dev/sda with your actual disk)
grub-install /dev/sda

# Install GRUB modules
grub-mkconfig -o /boot/grub/grub.cfg

# Set up system configuration, user accounts, etc.

# Finalize the installation
echo "LFS system build completed!"
echo "Reboot the system to start the newly installed LFS system."
