# Description
This packer template creates a VM image of Ubuntu 20.04 LTS in Proxmox using UEFI Bios.

# Instructions
- Feed the correct variables into the packerfile 
- Adjust the http/UserData file (at least set the username and password , the latter being base4 encoded)
- run:
    packer build
