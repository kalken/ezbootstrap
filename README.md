# Bootstrap Tools
This is a method for bootstraping and setting up machines, based on basic shell scripting. The idea is to show how to write a script (chroot.sh) that configures a complete setup. The provided chroot.sh is how i setup my rasberry pi server, up to the point where i need to copy backup files to continue. The config file is meant to be used for variables that could be changed when setting up different machines. When you need a new variable, just add it to the config file and it will be available to the script when you run it with the provided instructions.

## Generate a manual (based on config)
A specific manual can be created based on a config file
./manual.sh -c my.config

