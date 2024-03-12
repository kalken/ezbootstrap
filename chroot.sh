set -u

DEBIAN_FRONTEND=noninteractive

restore () {
    if test -f "$1.default"; then
        cp -v "$1".default "$1"
    else
        cp -v "$1" "$1.default"
    fi
}

sanity () {
    #chroot verify
    if [ "$(stat -c %d:%i /)" != "$(stat -c %d:%i /proc/1/root/.)" ]; then
        echo "We are chrooted!"
    else
        echo "We are not chrooted. Aborting"
        exit 1
    fi
}

/etc/apt/sources.list () {
cat > $FUNCNAME << EOF
deb http://ftp.se.debian.org/debian bookworm main contrib non-free non-free-firmware
deb-src http://ftp.se.debian.org/debian bookworm main contrib non-free non-free-firmware

deb http://ftp.se.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb-src http://ftp.se.debian.org/debian bookworm-updates main contrib non-free non-free-firmware

deb http://ftp.se.debian.org/debian bookworm-backports main contrib non-free non-free-firmware
deb-src http://ftp.se.debian.org/debian bookworm-backports main contrib non-free non-free-firmware

deb http://security.debian.org/ bookworm-security/updates main contrib non-free non-free-firmware
deb-src http://security.debian.org/ bookworm-security/updates main contrib non-free non-free-firmware
EOF
echo "created $FUNCNAME"
}

/etc/locale.gen () {
    restore $FUNCNAME
    for name in $_locales; do
        sed -i "/^# $name/s/^# //" $FUNCNAME
    done
    echo "edited $FUNCNAME"
}

/etc/localtime () {
    ln -fs "/usr/share/zoneinfo/$_timezone" $FUNCNAME
    echo "created $FUNCNAME"
}

/etc/apt/apt.conf.d/50unattended-upgrades () {
cat > $FUNCNAME << EOF
// apt-cache policy to check available parameters
// unattended-upgrades -d to manually run

Unattended-Upgrade::Origins-Pattern {
    "n=bookworm";
    "n=bookworm-updates";
    "n=bookworm-security";
    "n=bookworm-backports";
};

// Python regular expressions, matching packages to exclude from upgrading
Unattended-Upgrade::Package-Blacklist {
};
//Unattended-Upgrade::Automatic-Reboot "true";
//Unattended-Upgrade::Automatic-Reboot-Time "06:00";
EOF
echo "created $FUNCNAME"
}

/etc/crypttab () {
cat > $FUNCNAME << EOF
$_root_label LABEL="$_root_label" none luks
EOF
echo "created $FUNCNAME"
}

/etc/fstab () {
cat > $FUNCNAME << EOF
proc /proc proc defaults 0 0
LABEL="$_boot_label" /boot/firmware vfat defaults 0 2
/dev/mapper/$_root_label / ext4 defaults,noatime 0 1
EOF
echo "created $FUNCNAME"
}

/etc/machine-id () {
    if test ! -z $_machine_id; then
        echo "$_machine_id" > "$FUNCNAME"
        echo "created $FUNCNAME"
        echo "$_machine_id" > /var/lib/dbus/machine-id
        echo "created /var/lib/dbus/machine-id"
    fi
}

/etc/hosts () {
cat > $FUNCNAME << EOF
127.0.0.1       localhost $_hostname
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOF
echo "created $FUNCNAME"
}

/etc/default/keyboard () {
cat > $FUNCNAME << EOF
XKBMODEL="pc105"
XKBLAYOUT="$_keyboard"
BACKSPACE="guess"
XKBVARIANT=""
XKBOPTIONS=""
EOF
echo "created $FUNCNAME"
}

/etc/systemd/network/lan.network () {
cat > $FUNCNAME << EOF
[Match]
Name=eth0

[Network]
Address=192.168.0.2/24
VLAN=wan


[IPv6AcceptRA]
UseGateway=no

[Route]
Gateway=192.168.0.1
Table=internal

[Route]
Destination=192.168.0.0/24
PreferredSource=192.168.0.2
Table=internal

[RoutingPolicyRule]
From=192.168.0.0/24
Table=internal
EOF
echo "created $FUNCNAME"
}

/etc/systemd/network/wan.netdev () {
cat > $FUNCNAME << EOF
[NetDev]
Name=wan
Kind=vlan

[VLAN]
Id=2
EOF
echo "created $FUNCNAME"
}

/etc/systemd/network/wan.network () {
cat > $FUNCNAME << EOF
[Match]
Name=wan

[Network]
DHCP=yes

# ipv6 settings
IPv6PrivacyExtensions=yes

# The below setting is optional, to also assign an address in the delegated prefix
# to the upstream interface. If not necessary, then comment out the line below and
# the [DHCPPrefixDelegation] section.
DHCPPrefixDelegation=yes

# If the upstream network provides Router Advertisement with Managed bit set,
# then comment out the line below and WithoutRA= setting in the [DHCPv6] section.
#IPv6AcceptRA=no

#[DHCPv6]
#WithoutRA=solicit

[DHCPPrefixDelegation]
UplinkInterface=:self
SubnetId=0
Announce=no

[DHCPv6]
PrefixDelegationHint=::/56
EOF
echo "created $FUNCNAME"
}

/etc/nftables.conf () {
cat > $FUNCNAME << EOF
#!/usr/sbin/nft -f

define lan = eth0
define wan = wan
define vpn = wg0

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority filter; policy drop

        # allow established/related connections
        ct state {established, related} accept

        # early drop of invalid connections
        ct state invalid drop

        # allow icmp
        meta l4proto ipv6-icmp accept
		meta l4proto icmp accept

        # allow ipv6 dhcp
        udp dport dhcpv6-client accept

        # allow from loopback
        iifname lo accept

        # allow from lan
        ip saddr 192.168.0.0/24 iifname \$lan accept

        # allow from lan
        iifname \$lan tcp dport ssh ct state new meter case-ssh { ip saddr limit rate 20/hour } counter accept
        iifname \$lan tcp dport 2022 ct state new meter case-et { ip saddr limit rate 20/hour } counter accept

        # everything else
        reject with icmp type port-unreachable
        reject with icmpv6 type port-unreachable
    }
    chain forward {
        type filter hook forward priority filter; policy drop
        ct state established,related accept
    }
}
EOF
echo "created $FUNCNAME"
}

/etc/systemd/networkd.conf () {
    restore $FUNCNAME
    sed -i '/#RouteTable=/a RouteTable=internal:400' "$FUNCNAME"
    echo "edited $FUNCNAME"
}

/etc/iproute2/rt_tables.d/tables.conf () {
    echo "400 internal" > $FUNCNAME 
    echo "created $FUNCNAME"
}

/etc/dropbear/initramfs/authorized_keys () {
    echo "$_ssh_public_key" > "$FUNCNAME"
}

/etc/initramfs-tools/modules () {
    restore $FUNCNAME
    echo -e "vfat\nfat\nnls_cp437\nnls_iso8859_1\nnls_ascii" >> "$FUNCNAME"
    echo "edited $FUNCNAME"
}

/etc/default/raspi-firmware () {
    restore $FUNCNAME
    sed -i '/#CONSOLES="auto"/a CONSOLES="tty0"' "$FUNCNAME"
    echo "edited $FUNCNAME"
}

/etc/default/raspi-extra-cmdline () {
    echo -e "cryptopts=target=$_root_label,source=LABEL=$_root_label,luks" > "$FUNCNAME"
    echo "created $FUNCNAME"
}

/etc/sudoers.d/users () {
cat > $FUNCNAME << EOF
$_user ALL=(ALL) NOPASSWD:ALL
EOF
echo "created $FUNCNAME"
}

/etc/ssh/sshd_config () {
    restore $FUNCNAME
    sed -i '/#PasswordAuthentication yes/a PasswordAuthentication no' "$FUNCNAME"
    echo "Disabled password logins in $FUNCNAME"
}

/home () {
# add user
id $_user > /dev/null 2>&1 || useradd $_user -m -s /usr/bin/zsh
# login and config user
su - $_user -s /bin/bash << EOF
   test -d .ssh || mkdir -m 700 .ssh
   echo "$_ssh_public_key" > .ssh/authorized_keys
   test -d .ezsh || git clone https://github.com/kalken/ezsh .ezsh
   test -f .zshrc || ln -s .ezsh/zshrc .zshrc
EOF
echo "configured /home/$_user"
}

#work flow

function stage_0 {
    sanity

    /etc/apt/sources.list
    apt-get update

    apt-get -y install locales
    /etc/locale.gen
    locale-gen

    hostnamectl set-hostname $_hostname
    
    /etc/localtime
    apt-get -y install systemd-timesyncd
    
    apt-get -y install unattended-upgrades
    /etc/apt/apt.conf.d/50unattended-upgrades
    
    /etc/crypttab
    /etc/fstab
    /etc/machine-id
    /etc/hosts
    /etc/default/keyboard
    
    /etc/systemd/network/lan.network
    /etc/systemd/network/wan.netdev
    /etc/systemd/network/wan.network
    /etc/nftables.conf
    systemctl enable nftables
    
    /etc/systemd/networkd.conf
    /etc/iproute2/rt_tables.d/tables.conf

    systemctl enable systemd-networkd
    systemctl disable networking
    
    apt-get -y install systemd-resolved
    
    apt-get -y install dropbear-initramfs
    /etc/dropbear/initramfs/authorized_keys
    /etc/initramfs-tools/modules

    apt-get -y install raspi-firmware
    /etc/default/raspi-firmware
    /etc/default/raspi-extra-cmdline
  
    apt-get -y install linux-image-$_arch

    apt-get -y install zsh git
    /home
    
    apt-get -y install sudo
    /etc/sudoers.d/users

    apt-get -y install openssh-server
    /etc/ssh/sshd_config

    apt-get -y install $_packages_optional
}
