
# Alustetaan Terraform
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.3.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project
  region      = var.region
  zone        = var.zone
}

provider "google-beta" {
  credentials = file(var.credentials_file)
  project     = var.project
  region      = var.region
  zone        = var.zone
}


### OS-Login
locals {
  metadata = (var.enable_oslogin == true ? { "enable-oslogin" : "TRUE" } : {})
}

##############
# Networking #
##############

### VPC-yhteys
resource "google_compute_network" "vpc_network" {
  provider                = google-beta
  name                    = var.vpc_name
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = false
}

### Subnet
resource "google_compute_subnetwork" "vpc_subnet" {
  name          = var.subnet_name
  region        = var.region
  network       = google_compute_network.vpc_network.id
  ip_cidr_range = "10.0.0.0/16"
}

### Blockillinen priva IP-osoitteita
resource "google_compute_global_address" "vpc_private_ip_block" {
  name          = var.private_name
  network       = google_compute_network.vpc_network.self_link
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  ip_version    = "IPV4"
  prefix_length = 20

}

### Priva service access instanssien kommunikoimiseen sisäisessä verkossa
resource "google_service_networking_connection" "vpc_private_connection" {
  network                 = google_compute_network.vpc_network.self_link
  reserved_peering_ranges = [google_compute_global_address.vpc_private_ip_block.name]
  service                 = "servicenetworking.googleapis.com"
}

### Firewall-sääntö IAP:lle
resource "google_compute_firewall" "vpc_firewall" {
  name    = var.firewall_name_iap
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "443", "80"]
  }

  source_ranges = ["35.235.240.0/20"]
  direction     = "INGRESS"
  target_tags   = ["iap"]
}

### Luodaan Firewall-sääntö SSH:lle
resource "google_compute_firewall" "vpc_firewall_ssh" {
  name      = var.firewall_name_ssh
  network   = google_compute_network.vpc_network.id
  direction = "INGRESS"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Ei ehkä tarvita ?
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["ssh"]
}

### Private IP -säännöt SQL:lle
resource "google_compute_global_address" "private_ip_address" {
  provider      = google-beta
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

### Priva VPC-yhteys
resource "google_service_networking_connection" "private_vpc_connection" {
  provider                = google-beta
  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

### Router  
resource "google_compute_router" "router" {
  name    = "kekkoskakkos-router"
  network = google_compute_network.vpc_network.id

  bgp {
    asn = 64514
  }
}

### NAT   
resource "google_compute_router_nat" "nat" {
  name                               = "kekkoskakkos-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}


#####################
### VM-instanssit ###
#####################

### Bastion host
resource "google_compute_instance" "bastion" {
  zone         = var.zone
  name         = var.instance_name
  machine_type = var.machine_type
  tags         = ["iap"]
  boot_disk {
    initialize_params {
      image = var.image
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.vpc_subnet.id
    access_config {
      // Ephemeral public IP
    }
  }
  service_account {
    email  = google_service_account.service_account.email
    scopes = var.scopes
  }
}


### IAP-lupa bastioniin
resource "google_iap_tunnel_instance_iam_binding" "tunnel_user_iam" {
  zone     = var.zone
  instance = google_compute_instance.bastion.id
  role     = "roles/iap.tunnelResourceAccessor"
  members  = var.members
}

### Henkilöstöhallinta
resource "google_compute_instance" "henkilosto_instanssi" {
  name         = "henkilostohallinta"
  machine_type = "f1-micro"
  tags         = ["ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.vpc_subnet.id

    # access_config {
    #   // Ephemeral public IP
    # }
  }
  resource_policies = [
    google_compute_resource_policy.daily.id,
  ]
  metadata_startup_script = file("startup-script.sh")
  service_account {
    email  = google_service_account.service_account.email
    scopes = var.scopes
  }
}

### IAP-lupa henkilosto-instanssiin
resource "google_iap_tunnel_instance_iam_binding" "tunnel_user_iam_hlo" {
  zone     = var.zone
  instance = google_compute_instance.henkilosto_instanssi.id
  role     = "roles/iap.tunnelResourceAccessor"
  members  = var.members
}

### Reskontra
resource "google_compute_instance" "reskontra_instanssi" {
  name         = "reskontra"
  machine_type = "f1-micro"
  tags         = ["ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network    = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.vpc_subnet.id
    # access_config {
    #   // Ephemeral public IP
    # }
  }
  resource_policies = [
    google_compute_resource_policy.daily.id,
    ]
  metadata_startup_script = file("startup-script.sh")

  service_account {
    email  = google_service_account.service_account.email
    scopes = var.scopes
  }
}

### IAP-lupa reskontra-instanssiin
resource "google_iap_tunnel_instance_iam_binding" "tunnel_user_iam_res" {
  zone     = var.zone
  instance = google_compute_instance.reskontra_instanssi.id
  role     = "roles/iap.tunnelResourceAccessor"
  members  = var.members
}

### Automaattiset päivitykset instansseihin
resource "google_os_config_patch_deployment" "instanssi_patch" {
  patch_deployment_id = "instanssi-patch-deploy"

  instance_filter {
    #Kaikki kerralla?
    all = true
  }

  patch_config {
    yum {
      security = true
      minimal  = true
    }
  }

  recurring_schedule {
    time_zone {
      id = "Europe/Helsinki"
    }

    time_of_day {
      hours   = 23
      minutes = 59
      seconds = 59
    }

    #kuukauden viimeinen sunnuntai
    monthly {
      week_day_of_month {
        week_ordinal = -1
        day_of_week  = "SUNDAY"
      }
    }
  }
}


####################
# Service Accounts #
####################

### Service Account 
resource "google_service_account" "service_account" {
  account_id   = "kekkoskakkos-service-account"
  display_name = "A service account that only Kekkonen can interact with"
}

### IAM -admin oikeudet service accountille
resource "google_project_iam_member" "service_account_iam" {
  count   = length(var.service_account_iam_roles)
  project = var.project
  role    = element(var.service_account_iam_roles, count.index)
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

#######################################
#   SQL-tietokanta Kekkoslovakialle   #
#######################################

### Kekkoslovakia db-instanssi
resource "google_sql_database_instance" "kekkoslovakia_sql_instanssi" {
  provider         = google-beta
  name             = "kekkoslovakia"
  database_version = "POSTGRES_13"
  region           = var.region

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = "db-f1-micro"
    availability_type = "REGIONAL"
    disk_size         = 10

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc_network.self_link
    }
  }
}

### Henkiöstö-database
resource "google_sql_database" "henkilosto_database" {
  name     = "henkilosto"
  instance = google_sql_database_instance.kekkoslovakia_sql_instanssi.id
}

### Henkilöstö-db käyttäjä
resource "google_sql_user" "henkilosto_database_user" {
  name     = var.henkilosto_database_username
  instance = google_sql_database_instance.kekkoslovakia_sql_instanssi.id
  password = var.henkilosto_database_password
}

### Reskontra-database
resource "google_sql_database" "reskontra_database" {
  name     = "reskontra"
  instance = google_sql_database_instance.kekkoslovakia_sql_instanssi.id
}

### Reskontra-db käyttäjä
resource "google_sql_user" "reskontra_database_user" {
  name     = var.reskontra_database_username
  instance = google_sql_database_instance.kekkoslovakia_sql_instanssi.id
  password = var.reskontra_database_password
}

### ajastin instansseille
resource "google_compute_resource_policy" "daily" {
  name   = "policy"
  region = "us-central1"
  description = "Start and stop instances"
  instance_schedule_policy {
    vm_start_schedule {
      schedule = "0 6 * * *"
    }
    vm_stop_schedule {
      schedule = "0 2 * * *"
    }
    time_zone = "Europe/Helsinki"
  }
}