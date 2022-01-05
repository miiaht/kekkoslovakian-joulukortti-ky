terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.5.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project
  region      = var.region
  zone        = var.zone
}

### Luodaan VPC-yhteys

resource "google_compute_network" "vpc_network" {
  name                    = "kekkoskakkos-vpc"
  auto_create_subnetworks = false
}

### Luodaan Subnet

resource "google_compute_subnetwork" "vpc_subnet" {
  name          = "kekkoskakkos-subnet"
  ip_cidr_range = "10.0.0.0/9"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

### Luodaan Firewall-sääntö IAP:lle

resource "google_compute_firewall" "vpc_firewall" {
  name    = "kekkoskakkos-firewall-allow-iap"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  direction     = "INGRESS"
  target_tags   = ["iap"]

}

### Luodaan Bastion host

resource "google_compute_instance" "bastion" {
  zone = var.zone
  name = "bastion-host"

  machine_type = var.machine_type

  tags = ["iap"]

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.vpc_subnet.id
  }

}

### Annetaan IAP Tunnel User -luvat käyttäjille

resource "google_iap_tunnel_instance_iam_binding" "tunnel_user_iam" {
  zone     = var.zone
  instance = google_compute_instance.bastion.id
  role     = "roles/iap.tunnelResourceAccessor"
  members  = var.members
}