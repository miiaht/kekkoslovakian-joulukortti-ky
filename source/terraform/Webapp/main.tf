/* **************************************************************
Kekkoslovakian Web-palvelun IaC

Moduuli määrittelee web-palvelun infran, joka sisältää:
- palvelun käyttämän tietokannan
- frontendin (Cloud Run)
- frontin liikennettä ohjaavan load balancerin (NEG / serverless)
- frontin ja backendin välissä pyyntöjä ohjaavan API:n (Api Gateway)
- etc.
************************************************************** */

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


/***********************************************************
Frontend:
***********************************************************/

# Cloud Run container, jossa frontend:
resource "google_cloud_run_service" "default" {
  provider  = google-beta

  name     = "fronttitesti-1"
  location = var.region
  project  = var.project

  template {
    spec {
      containers {
        image = "gcr.io/final-project-1-337107/kekkos-app:0.2"
        ports {
          container_port = 5000
        }
      }
    }
  }
}

resource "google_cloud_run_service_iam_member" "member" {
  location = google_cloud_run_service.default.location
  project  = google_cloud_run_service.default.project
  service  = google_cloud_run_service.default.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}


/***********************************************************
Frontendin load balancer:
***********************************************************/

# varataan load balancerille globaali ip
resource "google_compute_global_address" "default" {
  name = "${var.name}-address"
}

# luodaan managed SSL-sertti
resource "google_compute_managed_ssl_certificate" "default" {
  provider = google-beta

  name = "${var.name}-cert"
  managed {
    domains = ["${var.domain}"]
  }
}

# luodaan network endpoint group (NEG)
resource "google_compute_region_network_endpoint_group" "cloudrun_neg" {
  provider              = google-beta

  name                  = "${var.name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  
  cloud_run {
    service = google_cloud_run_service.default.name
  }
}

# load balancerin backend
# TODO: lisää Clour Armor
# HUOM: NEG-backend ei tarvii heath checkiä
resource "google_compute_backend_service" "default" {
  provider  = google-beta

  name      = "${var.name}-backend"

  protocol  = "HTTP"
  port_name = "http"
  timeout_sec = 30

  backend {
    group = google_compute_region_network_endpoint_group.cloudrun_neg.id
  }
}

# URL-map: liikenne ohjataan backendiin
resource "google_compute_url_map" "default" {
  name            = "${var.name}-urlmap"

  default_service = google_compute_backend_service.default.id
}

# HTTPS-proxy -> URL-map
resource "google_compute_target_https_proxy" "default" {
  name   = "${var.name}-https-proxy"

  url_map          = google_compute_url_map.default.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.default.id
  ]
}

# Forwarding rule: IP -> HTTPS-proxy
resource "google_compute_global_forwarding_rule" "default" {
  name   = "${var.name}-lb"

  target = google_compute_target_https_proxy.default.id
  port_range = "443"
  ip_address = google_compute_global_address.default.address
}