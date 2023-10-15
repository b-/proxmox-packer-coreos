packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.0"
      source = "github.com/hashicorp/proxmox"
    }
  }
}

source "proxmox-iso" "coreos" {
  // proxmox configuration
  insecure_skip_tls_verify = true
  node = "macpro"
  username = "b@ibeep.com@authentik!packer"
  token = "proxmox_token_goes_here"
  proxmox_url = "https://dn42.macpro.pve.ibeep.com:8006/api2/json"

  # Commands packer enters to boot and start the auto install
  boot_wait = "2s"
  boot_command = [
    "<spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait>",
    "<tab><wait>",
    "<down><down><end>",
    " ignition.config.url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/installer.ign",
    "<enter>"
  ]

  # This supplies our installer ignition file
  http_directory = "config"

  # This supplies our template ignition file
  additional_iso_files {
    cd_files = ["./config/template.ign", "./config/dummy.file"]
    iso_storage_pool = "zssd-files"
    unmount = true
  }

  # CoreOS does not support CloudInit
  cloud_init = false
  qemu_agent = true

  scsi_controller = "virtio-scsi-pci"

  cpu_type = "host"
  cores = "2"
  memory = "2048"
  os = "l26"

  vga {
    type = "qxl"
    memory = "16"
  }

  network_adapters {
    model = "virtio"
    bridge = "vmbr0"
    vlan_tag = "12"
  }

  disks {
    disk_size = "45G"
    storage_pool = "zssd"
    type = "virtio"
  }

  iso_file = "zssd-files:iso/fedora-coreos-38.20230918.3.2-live.x86_64.iso"
  unmount_iso = true
  template_name = "coreos-38.20230918.3.2"
  template_description = "Fedora CoreOS"

  ssh_username = "core"
  ssh_private_key_file = "~/.ssh/id_ed25519"
  ssh_timeout = "20m"
}

build {
  sources = ["source.proxmox-iso.coreos"]

  provisioner "shell" {
    inline = [
      "sudo mkdir /tmp/iso",
      "sudo mount /dev/sr1 /tmp/iso -o ro",
      "sudo coreos-installer install /dev/vda --ignition-file /tmp/iso/template.ign",
      # Packer's shutdown command doesn't seem to work, likely because we run qemu-guest-agent
      # inside a docker container.
      # This will shutdown the VM after 1 minute, which is less than the duration that Packer
      # waits for its shutdown command to complete, so it works out.
      "sudo shutdown -h +1"
    ]
  }
}
