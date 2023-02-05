packer {
  required_plugins {
     proxmox-iso = {  
       version = ">= 1.0.3"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}
variable "node" {
  description   = "the name of the node to provision the image"
  type          = string
  default       = "hostname"
}

variable "proxmox_template_name" {
  description   = "the name of the image"
  type          = string
  default       = "ubuntu2004-hostname"
}

variable "proxmox_url" {
  description   = "the url of the proxmox api"
  type    = string
  default = "https://proxmox.localdomain:8006/api2/json"
}

variable "pve_token" {
  description   = "the token to use for api access"
  type          = string
  default       = "xxxxxx-xxx-xxxx-xxx-xxxxxxxx"
  sensitive     = true
}

variable "pve_username" {
  description   = "the username to use for api access"
  type          = string
  default       = "USER@pve!packer"
  sensitive     = true
}

variable "ssh_password" {
  description   = "the passwprd to use for api access"
  type          = string
  default       = "PASSWORD"
  sensitive     = true
}

variable "ssh_keys_directory" {
  description   = "the directory containing the SSH keys to copy to the Image"
  type          = string
  default       = "/home/USER/.ssh/"
}

variable "ssh_username" {
  description   = "the username to create in the image"
  type          = string
  default       = "USERNAME"
  sensitive     = true
}

variable "ubuntu_iso_file" {
  description   = "the iso image to use for the unattended installation"
  type          = string
  default       = "ubuntu-20.04.3-live-server-amd64.iso"
}

source "proxmox-iso" "ubuntu2004" {
  bios                      = "ovmf"
  efidisk                   = "local-lvm"
  machine                   = "q35"
  boot_command              = ["<esc><esc><esc>", "set gfxpayload=keep<enter>", "linux /casper/vmlinuz ", "\"ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/\" ", "quiet autoinstall ---<enter>", "initrd /casper/initrd<enter>", "boot<enter>"]
  boot_wait                 = "5s"
  boot                      = "order=scsi0;ide2"
  scsi_controller           = "virtio-scsi-pci"
  cloud_init                = true
  cloud_init_storage_pool   = "local-lvm"
  cores                     = "2"
  cpu_type                  = "host"
  disks {
    disk_size               = "5G"
    storage_pool            = "local-lvm"
    storage_pool_type       = "lvm"
    type                    = "scsi"
  }
  http_directory            = "http"
  http_port_max             = "8123"
  http_port_min             = "8123"
  iso_file                  = "local:iso/${var.ubuntu_iso_file}"
  memory                    = 1500
  network_adapters {
    bridge = "vmbr0"
    model = "virtio"
  }
  onboot = true
  node                      = "${var.node}"
  token                     = "${var.pve_token}"
  proxmox_url               = "${var.proxmox_url}"
  insecure_skip_tls_verify  = true
  qemu_agent                = true
  ssh_password              = "${var.ssh_password}"
  ssh_timeout               = "20m"
  ssh_username              = "${var.ssh_username}"
  template_name             = "${var.proxmox_template_name}"
  unmount_iso               = true
  username                  = "${var.pve_username}"
}

build {
  sources = ["source.proxmox-iso.ubuntu2004"]

  provisioner "file" {
    destination = "/tmp/id_rsa.pub"
    source      = "${var.ssh_keys_directory}id_rsa.pub"
  }

  provisioner "shell" {
    inline = ["mkdir ${var.ssh_keys_directory}", "cat /tmp/id_rsa.pub >> ${var.ssh_keys_directory}authorized_keys", "rm /tmp/id_rsa.pub"]
  }

  provisioner "shell" {
    inline = ["echo ${var.ssh_password}' | sudo -S /usr/bin/cloud-init status --wait"]
  }

  provisioner "shell" {
    inline = ["echo ${var.ssh_password}' | sudo -S apt remove cloud-init -y", "echo ${var.ssh_password}' | sudo -S apt purge cloud-init -y", "echo ${var.ssh_password}' | sudo -S rm -rf /var/lib/cloud", "echo ${var.ssh_password}' | sudo -S rm -rf /etc/cloud", "echo ${var.ssh_password}' | sudo -S apt install cloud-init -y"]
  }

}
