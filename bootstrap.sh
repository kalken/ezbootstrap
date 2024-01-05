#!/bin/bash
set -u

bootstrap.root.mount () {
    test -b "/dev/mapper/$_root_label" || { echo "drive is not unlocked!"; exit 1;}
    test -d "$_root_dir" || mkdir -v "$_root_dir"
    mountpoint "$_root_dir" || mount -v "/dev/mapper/$_root_label" "$_root_dir"

}
bootstrap.boot.mount () {
    test -d "$_boot_dir" || mkdir -v -p "$_boot_dir"
    mountpoint "$_boot_dir" || mount -v "$_boot_dev" "$_boot_dir"
}

bootstrap.chroot.umount () {
    for name in proc sys dev/pts dev run; do
        mountpoint "$_root_dir/$name" && umount -v "$_root_dir/$name"
    done
}

bootstrap.root.umount () {
    mountpoint "$_root_dir" && umount -v "$_root_dir"
}

bootstrap.boot.umount () {
    mountpoint "$_boot_dir" && umount -v "$_boot_dir"
}
bootstrap.bootstrap () {
    "$_bootstrap" --arch "$_bootstrap_arch" "$_bootstrap_release" "$_root_dir" "$_bootstrap_source"
}

bootstrap.chroot.mount () {
    for name in proc sys dev dev/pts run; do
        mountpoint "$_root_dir/$name" || mount -v --bind "/$name" "$_root_dir/$name" 
    done
}

bootstrap.mount () {
    bootstrap.root.mount
    bootstrap.boot.mount
    bootstrap.chroot.mount
}

bootstrap.umount () {
    bootstrap.chroot.umount
    bootstrap.boot.umount
    bootstrap.root.umount
}

# workflow

stage_0 () {
    bootstrap.root.mount
    bootstrap.bootstrap
    bootstrap.boot.mount
    bootstrap.chroot.mount
    echo "ready for chroot scripts!"
}

stage_1 () {
    bootstrap.umount
}
