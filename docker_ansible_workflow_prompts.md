# Docker Ansible Workflow Prompts

## Session Summary
This document captures the prompts and workflow for running Ansible playbooks in a Docker container environment for firmware building.

## Initial Setup Prompts

### 1. Container Architecture Understanding
```
This playbook gets run from within an docker container that's preconfigured to support ansible in a specific configuration.

The key points to be aware of are as follows:

1) there are two different containers- 1 container that has ansible host depencies installed and which can access a directory of playbook repositories in /home/pi/Playbooks. A second container exists running apt-cacher-ng for saving on file downloads for repetitive installations of software using apt-get.

2) For this particular playbook, the "Instant Community Wifi Portal" directory we're editing is exposed to the docker container directly- so any changes you make in the local system's file system will get extended into the container.

3) You can list the running docker containers from the native operating system using standard docker ps commands.

4) You will attach to the docker container using a command: 
docker exec -it AnsibleFWC bash

5) You can then ping around for a raspberry pi waiting for receiving the firmware image using a command:
ping ansibledest.local

6) If the host is online, you can copy an ssh key to the device using a command:
ssh-copy-id pi@ansibledest.local 

The password is changedefaultpwd3331333

7) after you've copied the credential over, you can use ansible to push playbooks to the device. I want you to cd into the /home/pi/Playbooks/Instant_Community_Wifi_Portal directory from within the docker container

8) once you're there, you're ready to run the playbook with ansible-playbook run.yml
```

### 2. Workflow Commands
```
Start with the docker ps
```

## Error Investigation Prompts

### 3. Error Analysis Request
```
Ok- We have an error. I want you to analyze the error. You can ssh into ansibledest.local to look at logs to try and investigate why this command fails. In my experience- just restarting the playbook at this task resolves the issue- but maybe you can help diagnose why this happens on the first pass of this playbook. do you understand what you can do?
```

### 4. Error Correction
```
No- the error was related to an iptables command
```

## Session Commands Executed

### Container Setup
```bash
# Check running containers
docker ps

# Attach to Ansible container
docker exec -it AnsibleFWC bash

# Verify target device connectivity
ping -c 4 ansibledest.local

# Copy SSH credentials (already installed)
ssh-copy-id pi@ansibledest.local

# Navigate to playbook directory
cd /home/pi/Playbooks/Instant_Community_Wifi_Portal

# List playbook contents
ls -la

# Run the playbook
ansible-playbook run.yml
```

## Error Encountered

### NetworkManager Command Error
```
Error: invalid field 'NAME'; allowed fields: 6lowpan,802-11-olpc-mesh,802-11-wireless,802-11-wireless-security,802-1x,802-3-ethernet,adsl,bluetooth,bond,bond-port,bridge,bridge-port,cdma,connection,dcb,dummy,ethtool,generic,gsm,hostname,infiniband,ip-tunnel,ipv4,ipv6,loopback,macsec,macvlan,match,ovs-bridge,ovs-dpdk,ovs-external-ids,ovs-interface,ovs-other-config,ovs-patch,ovs-port,ppp,pppoe,proxy,serial,sriov,tc,team,team-port,tun,user,veth,vlan,vpn,vrf,vxlan,wifi-p2p,wimax,wireguard,wpan
```

## Key Insights

1. **Container Architecture**: Two containers - AnsibleFWC for playbook execution and apt-cacher-ng for package caching
2. **File System Mapping**: Direct exposure of playbook directory to container
3. **Target Device**: Raspberry Pi at `ansibledest.local` (192.168.6.106)
4. **SSH Access**: Pre-configured, no password needed
5. **Common Issue**: NetworkManager command errors that resolve on restart

## Future Investigation Points

1. **Error Root Cause**: Why NetworkManager commands fail on first pass
2. **Log Analysis**: SSH into target device to examine logs
3. **Timing Issues**: Investigate if this is a service initialization problem
4. **MDC Rules**: Generate rules for this Docker-based Ansible workflow

## Next Steps for Iteration

1. Complete error investigation
2. Generate MDC rules for Docker Ansible workflow
3. Create debugging procedures for common playbook errors
4. Document best practices for container-based firmware development 