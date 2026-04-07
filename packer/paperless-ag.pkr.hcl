packer {
  required_plugins {
    digitalocean = {
      version = ">= 1.1.0"
      source  = "github.com/digitalocean/digitalocean"
    }
  }
}

variable "do_api_token" {
  type      = string
  sensitive = true
  default   = env("DIGITALOCEAN_API_TOKEN")
}

source "digitalocean" "paperless-ag" {
  api_token    = var.do_api_token
  image        = "ubuntu-24-04-x64"
  region       = "nyc1"
  size         = "s-2vcpu-4gb"
  ssh_username = "root"
  snapshot_name            = "paperless-ag-{{timestamp}}"
  snapshot_timeout         = "60m"
  snapshot_regions_no_wait = true
  snapshot_regions         = [
    "nyc1", "nyc3", "sfo3", "ams3", "sgp1",
    "lon1", "fra1", "tor1", "blr1", "syd1"
  ]
}

build {
  sources = ["source.digitalocean.paperless-ag"]

  # Upload application files
  provisioner "file" {
    source      = "../one-click"
    destination = "/tmp/one-click"
  }

  provisioner "file" {
    source      = "docker-compose.pull.yml"
    destination = "/tmp/docker-compose.pull.yml"
  }

  # Run provisioning script
  provisioner "shell" {
    script = "provision.sh"
  }

  # Clean up uploaded files
  provisioner "shell" {
    inline = ["rm -rf /tmp/one-click /tmp/docker-compose.pull.yml"]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}
