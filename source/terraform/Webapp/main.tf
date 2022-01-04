/***********************************************************
Kekkoslovakian Web-palvelun IaC
***********************************************************/

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  credentials = file(var.credentials_file)
  
  project = var.project
  region = var.region
  zone   = var.zone
}


/***********************************************************
Tietokanta joulukorteille:
***********************************************************/

# TESTITIETOKANTA ------------------------------------------
resource "google_sql_database_instance" "master" {
  name             = "kekkos-database"
  database_version = "POSTGRES_13"
  region           = var.region

  settings {
    # tietokantainstanssin "tier"
    tier = "db-f1-micro"
  }
  
  # deletion_protection = true
}

resource "google_sql_database" "database" {
  name     = "testi-database"
  instance = google_sql_database_instance.master.name
}

resource "google_sql_user" "users" {
  name = var.sql_name
  instance = google_sql_database_instance.master.name
  password = var.sql_password
}
# ------------------------------------------- TESTITIETOKANTA



# ------------------------------------------------------------
# Tuotantotietokanta
# ------------------------------------------------------------

# luo vpc tietokannan priva-IP:tä varten
resource "google_compute_network" "private_network" {
  provider = google-beta

  project = var.project
  name = "kekkosslovakian-webapp"
  auto_create_subnetworks = false
}

# luo aliverkko edelliseen
resource "google_compute_subnetwork" "public-subnetwork" {
  provider = google-beta

  name = "kekkosweb-sub-1"
  ip_cidr_range = "10.0.0.0/24"
  region = var.region
  network = google_compute_network.private_network.name
}

# allokoi private ip osoitteet vpc:hen 
resource "google_compute_global_address" "private_ip_address" {
  provider = google-beta

  name         = "private-ip"
  purpose      = "VPC_PEERING"
  address_type = "INTERNAL"
  ip_version   = "IPV4"
  prefix_length = 24
  network       = google_compute_network.private_network.id
}

# luo privaatti vpc-yhteys
resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta

  network                 = google_compute_network.private_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# tietokantainstanssi
resource "google_sql_database_instance" "instance" {
  provider = google-beta

  name             = "kekkos-priva-db"
  region           = var.region
  database_version = "POSTGRES_13"

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.private_network.id
    }
  }
}

# joulukorttien tietokanta
resource "google_sql_database" "joulukortti-database" {
  name     = "joulukortit"
  instance = google_sql_database_instance.instance.name
}

# käyttäjät
resource "google_sql_user" "db-users" {
  name = var.sql_name
  instance = google_sql_database_instance.instance.name
  password = var.sql_password
}