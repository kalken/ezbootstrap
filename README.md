# Why make this?

There are many distributions, managing systems and platforms out there. Most of them are just high level frameworks, that behind the scenes do their thing using common terminal commands. I wanted to find a method of boostraping machines without the need for third party tools. It should be reliable, easy to use, and easy to extend to whatever the future requires.

# Advantages

* No external dependencies
* Syntax is the same in script and in a real terminal
* Works on all platforms that supports the POSIX Standard
* Can do anything that a computer can do
* No need to write modules for extending functionality

# How to use it
This is a method for bootstraping and setting up machines, based on basic shell scripting. The idea is to show how to write a script (chroot.sh) that configures a complete setup. The provided chroot.sh is how i setup my rasberry pi server, up to the point where i need to copy backup files to continue. The config file is meant to be used for variables that could be changed when setting up different machines. When you need a new variable, just add it to the config file and it will be available to the script when you run it with the provided instructions.

There are 3 files involved in this.

## config.example
Use this file as a template to make a customized configuration for your machine. Any new wariable you add to any of the scripts should also be added to this configuration file, to tell future users that this is an important option that needs to be defined. Copy the customized configuration to something else e.g mymachine.config and use that to call the manual, to get a description of how to run everything.

## bootstrap.sh
A script for Mounting and preparing chroot environment, boostraping (the provided script is using deboostrap to install debian ). The script can also be used to unmount the drive when its all done.

## chroot.sh
Complete setup can be customized. Use this script as a template to make your installation unique to what you want it to do. There is also a posibility to have a chroot.sh as a standard template for setting up a general os, and another scripts that customizes a unique setup of some program or service.

## Generate a manual (based on config)
A specific manual can be created based on a config file
./manual.sh -c my.config

# Good Rules to follow when writing these scripts

* Everything should be written i functions (e.g if you run the script without calling a function nothing should happen)
* Separate workflow functions that define exactly what to do in what stage
* Keep the installation of packages in the workflow functions, and use the functions to configure services, or making files
* For customizing a file, use the filename path as the name for the function. Doing this then calling $FUNCNAME inside the function will generate a string to the file, which can be used when working with the file 
* Write chroot.sh so it can be run multiple times. Using restore function (to always keep the original file) should make this relativly easy


