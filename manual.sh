#!/bin/bash
set -u

mydir=$(dirname "$0")

_config=""
while getopts c: flag
do
    case "${flag}" in
        c) _config=${OPTARG};;
    esac
done

test -f "$_config" || { echo "make your own config from config-template and supply it: -c path/to/my/config"; exit 0; }
source $_config

echo
echo "### LOCAL PREPARATION ###"
echo "# create a key for use with initramfs unlock"
echo "dd if=/dev/random bs=1024 count=4 of=$_luks_key"
echo "# WARNING: Don't run dd command after encrypting a luks partiton with it, as the key for unlocking will be overwritten."
echo
echo "### REMOTE PREPARATION ###"
echo "# enable ssh key login for your own sanity." 
echo "# make a ssh-key-pair. Copy public key to your server. it should be in the file ~/.ssh/authorized_keys"
echo
echo "# luksformat target device with key"
echo "cat $_luks_key | ssh $_user@$_host sudo cryptsetup luksFormat $_root_dev --label $_root_label --key-file=-"
echo
echo "# open luksencrypted device with key"
echo "cat $_luks_key | ssh $_user@$_host sudo cryptsetup luksOpen $_root_dev $_root_label --key-file=-"
echo
echo "# format target device"
echo "ssh $_user@$_host sudo mkfs.ext4 /dev/mapper/$_root_label"
echo
echo "ps. also make sure that the boostrap command is installed on the machine."
echo
echo "### INSTALLATION ###"
echo ""
echo "# stage 0 bootstrap.sh (mount drives and boostrap)"
echo "( cat bootstrap.sh $_config; echo stage_0 ) | $_service $_user@$_host sudo /bin/bash -"
echo 
echo "# stage 1 chroot.sh (chroot setup)"
echo "( cat chroot.sh $_config; echo stage_0 ) | $_service $_user@$_host sudo $_chroot $_root_dir /bin/bash -"
echo 
echo "# stage 2 bootstrap.sh (cleanup and umount drives)"
echo "( cat bootstrap.sh $_config; echo stage_1 ) | $_service $_user@$_host sudo /bin/bash -"

echo 
echo "# If something goes wrong or you just want to mount or unmount a drive later you can."
echo "# Mounting: ( cat bootstrap.sh $_config; echo bootstrap.mount ) | $_service $_user@$_host sudo /bin/bash -"
echo "# Unmounting: ( cat bootstrap.sh $_config; echo bootstrap.umount ) | $_service $_user@$_host sudo /bin/bash -"

