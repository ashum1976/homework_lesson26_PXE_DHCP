#!/bin/bash

echo Install PXE server
yum -y --nogpgcheck install epel-release
#yum -y install dhcp-server
yum -y --nogpgcheck install dhcp
yum -y --nogpgcheck install tftp-server
yum -y --nogpgcheck install nfs-utils
firewall-cmd --add-service=tftp
# disable selinux or permissive
setenforce 0
#

cat >/etc/dhcp/dhcpd.conf <<EOF
option space pxelinux;
option pxelinux.magic code 208 = string;
option pxelinux.configfile code 209 = text;
option pxelinux.pathprefix code 210 = text;
option pxelinux.reboottime code 211 = unsigned integer 32;
option architecture-type code 93 = unsigned integer 16;

subnet 10.0.0.0 netmask 255.255.255.0 {
	#option routers 10.0.0.254;
	range 10.0.0.100 10.0.0.120;

	class "pxeclients" {
	  match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
	  next-server 10.0.0.20;

	  if option architecture-type = 00:07 {
	    filename "uefi/shim.efi";
	    } else {
	    filename "pxelinux/pxelinux.0";
	  }
	}
}
EOF
systemctl start dhcpd

systemctl start tftp.service
yum -y --nogpgcheck install syslinux-tftpboot.noarch
mkdir /var/lib/tftpboot/pxelinux
cp /var/lib/tftpboot/pxelinux.0 /var/lib/tftpboot/pxelinux
cp  /var/lib/tftpboot/menu.c32 /var/lib/tftpboot/pxelinux
cp  /var/lib/tftpboot/vesamenu.c32 /var/lib/tftpboot/pxelinux
cp  /var/lib/tftpboot/chain.c32 /var/lib/tftpboot/pxelinux

mkdir /var/lib/tftpboot/pxelinux/pxelinux.cfg

cat >/var/lib/tftpboot/pxelinux/pxelinux.cfg/default <<EOF
#default menu
default menu
prompt 0
timeout 600

MENU TITLE PXE Linux setup

LABEL linux8
  menu label ^Install system linux8
  kernel images/CentOS-8.3/vmlinuz
  # append initrd=images/CentOS-8.3/initrd.img inst.repo=nfs:10.0.0.20:/mnt/centos8-install inst.text
  append initrd=images/CentOS-8.3/initrd.img inst.repo=nfs:10.0.0.20:/mnt/centos8-install
# LABEL linux7
#   menu label ^Install system linux7
#   kernel images/CentOS-7/vmlinuz
#   append initrd=images/CentOS-7/initrd.img inst.repo=nfs:10.0.0.20:/mnt/centos7-install
LABEL linux-auto
  menu label ^Auto install system
  menu default
  kernel images/CentOS-8.3/vmlinuz
  append initrd=images/CentOS-8.3/initrd.img inst.ks=nfs:10.0.0.20:/home/vagrant/cfg/ks.cfg inst.repo=nfs:10.0.0.20:/mnt/centos8-install
LABEL vesa
  menu label Install system with ^basic video driver
  kernel images/CentOS-8.3/vmlinuz
  append initrd=images/CentOS-8.3/initrd.img ip=dhcp inst.xdriver=vesa nomodeset
LABEL rescue
  menu label ^Rescue installed system
  kernel images/CentOS-8.3/vmlinuz
  append initrd=images/CentOS-8.3/initrd.img rescue
LABEL local
  menu label Boot from ^local drive
  kernel chain.c32
  append hd0 0
  timeout 150

EOF

mkdir -p /var/lib/tftpboot/pxelinux/images/CentOS-7/
mkdir -p /var/lib/tftpboot/pxelinux/images/CentOS-8.3/

#Centos 7 images
# curl -O http://ftp.mgts.by/pub/CentOS/7/os/x86_64/images/pxeboot/initrd.img
# curl -O http://ftp.mgts.by/pub/CentOS/7/os/x86_64/images/pxeboot/vmlinuz

#Centos 8 images
curl -O http://ftp.mgts.by/pub/CentOS/8.3.2011/BaseOS/x86_64/os/images/pxeboot/initrd.img
curl -O http://ftp.mgts.by/pub/CentOS/8.3.2011/BaseOS/x86_64/os/images/pxeboot/vmlinuz

#cp {vmlinuz,initrd.img} /var/lib/tftpboot/pxelinux/images/CentOS-7
cp {vmlinuz,initrd.img} /var/lib/tftpboot/pxelinux/images/CentOS-8.3



mkdir boot_centos8
mkdir boot_centos7

#curl -o ./boot_centos7/boot.iso http://ftp.mgts.by/pub/CentOS/7/os/x86_64/images/boot.iso
curl -o ./boot_centos8/boot.iso http://ftp.mgts.by/pub/CentOS/8.3.2011/isos/x86_64/CentOS-8.3.2011-x86_64-minimal.iso
#curl -o ./boot_centos8/boot.iso http://ftp.mgts.by/pub/CentOS/8.3.2011/BaseOS/x86_64/os/images/boot.iso

mkdir /mnt/centos7-install
mkdir /mnt/centos8-install

#mount -t iso9660 ./boot_centos7/boot.iso /mnt/centos7-install
mount -t iso9660 ./boot_centos8/boot.iso /mnt/centos8-install

echo '/mnt/centos7-install *(ro)' > /etc/exports
echo '/mnt/centos8-install *(ro)' >> /etc/exports

#systemctl restart nfs-server.service

# Setup NFS auto install
#


#autoinstall(){
# to speedup replace URL with closest mirror
#mkdir /mnt/centos8-autoinstall
#mount -t iso9660 ./boot_centos8/boot.iso /mnt/centos8-autoinstall
#echo '/mnt/centos8-autoinstall *(ro)' >> /etc/exports
mkdir /home/vagrant/cfg
cat > /home/vagrant/cfg/ks.cfg <<EOF
#version=RHEL8
ignoredisk --only-use=sda
autopart --type=lvm
# Partition clearing information
clearpart --all --initlabel --drives=sda
# Use graphical install
graphical
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8
#repo
#url --url=http://ftp.mgts.by/pub/CentOS/8.2.2004/BaseOS/x86_64/os/

# Network information
network  --bootproto=dhcp --device=enp0s3 --ipv6=auto --activate
network  --bootproto=dhcp --device=enp0s8 --onboot=off --ipv6=auto --activate
network  --hostname=localhost.localdomain
# Root password (vagrant)
rootpw --iscrypted $6$kLYLyaL31l.gEmVw$uysemokgLKlf4r.JCgIURZJCzZ17emd3yoN9HMx6AD1RN3lQYyupGmDSPSwtPbnCYwArprYl7oCEPtwUvCNWi1
# Run the Setup Agent on first boot
firstboot --enable
# Do not configure the X Window System
skipx
# System services
services --enabled="chronyd"
# System timezone
timezone America/New_York --isUtc
user --groups=wheel --name=testuser --password=$6$wfUf3TF52CeS9Gpv$puNkd6APMSLL5P2ThPTLcgfac5GLHXr0kN1zDcQ2Ej/LNn7gw5twhwmSWvlMcCZNR0PlYsOmIujR395AeLLA81 --iscrypted --gecos="Test User Vagrant"

%packages
@^minimal-environment
kexec-tools
@network-server
@system-tools
@development
@graphical-admin-tools
@headless-management

%end

%addon com_redhat_kdump --disable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end

EOF
echo '/home/vagrant/cfg *(ro)' >> /etc/exports
  systemctl restart nfs-server.service
#}
# uncomment to enable automatic installation
#autoinstall
