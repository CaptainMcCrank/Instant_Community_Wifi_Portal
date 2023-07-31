# Instant Community Wifi Portal
by Patrick McCanna

## Overview
The firmware will turn a Raspberry Pi into a wifi access point that will broadcast a network labeled “JoinMe.”

Users who connect to the network are forwarded to a captive portal hosted on the device. The captive portal app is a local communicty image board.

The board supports anonymous image posting & is based off the code from https://tokumei.co/. The design is an implementation of some interesting plan-9 inspired tooling called Werc. The licensing is public. It has a more inviting design than the 4chan futaba image boards.

When neighbors are attached to the network, they don’t get access to the Internet. They do get private access to whatever local community resources you insert.

In my implementation, I modified the entry tokumei page to include a link to a static directory of files. You can now host a private library of mp3 files, pdfs, zines and other culture for sharing with your neighbors.

Run an offgrid wifi community network that hosts a bulletin board and a shared library.

Create local community without logging off completely. It’s off the Internet and only accessible if you stop and connect to it when you’re in range. No Internet Trolls- only your local neighbors. No advertisers. No centralized control. I hope it will help you connect with people in your proximity.


##Prerequisites


##Build Overview

This playbook can be used to orcestrate the configuration of a Rasperry pi using Ansible.  

If you do not have a preexisting Ansible deployment, you can use my Builderhotspot firmware on an existing raspberry or you can use a  my Docker-based solution which can be run on a workstaion on the same network as the target pi.  

If you're struggling to decide- ask yourself how many Pi's you possess?  If you have several, you don't need to worry about troubleshooting your home network with the BuilderHotspot.  

If you have very few PI's for development, you'll probably want to use the docker container solution on a system on your target pi's LAN.



1. Acquire hardware

### Acquire hardware
The Instant Community Wifi Portal depends on the following list of hardware:

| Quantity   | Device   |   
| :-------------| :-------------|
| 1 | [Raspberry Pi Mod 3 or Raspberry pi 4](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/) 
| 1 | [16 GB (or greater) Class 10 Ultra Micro SD](https://www.amazon.com/Sandisk-Ultra-Micro-UHS-I-Adapter/dp/B073K14CVB/ref=sr_1_sc_1?s=electronics&ie=UTF8&qid=1532625085&sr=1-1-spell&keywords=16+gb+micro+sdcard)|
| 1 | [Power Supply for Pi 3](https://www.amazon.com/Raspberry-Supply-Certified-Compatible-Adapter/dp/B075XMTQJC/ref=sr_1_5?s=electronics&ie=UTF8&qid=1532625410&sr=1-5&keywords=USB+charger+for+raspberry+pi) |


