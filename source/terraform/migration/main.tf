# Alustetaan Terraform

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.3.0"
    }
  }
}

provider "google" {
  #credentials = file(var.credentials_file)
  project = var.project
  region  = var.region
  zone    = var.zone
}

provider "google-beta" {
  #credentials = file(var.credentials_file)
  project = var.project
  region  = var.region
  zone    = var.zone
}

############################
#   IAP with bastion host  #
############################


locals {
  metadata = (var.enable_oslogin == true ? { "enable-oslogin" : "TRUE" } : {})
}

resource "google_service_account" "bastion" {
  account_id   = var.service_account_name
  display_name = var.service_account_name
}

resource "google_project_iam_member" "service_account" {
  count   = length(var.service_account_iam_roles)
  project = var.project
  role    = element(var.service_account_iam_roles, count.index)
  member  = "serviceAccount:${google_service_account.bastion.email}"
}

resource "google_project_iam_member" "additional_service_account" {
  count   = length(var.additional_service_account_iam_roles)
  project = var.project
  role    = element(var.additional_service_account_iam_roles, count.index)
  member  = "serviceAccount:${google_service_account.bastion.email}"
}

#########################
#   Bastion-instanssi   #
#########################

resource "google_compute_instance" "bastion" {
  project = var.project
  zone    = var.zone
  name    = var.instance_name

  machine_type = var.machine_type

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_private_bastion.id
    #subnetwork_project = var.subnet_project
  }

  service_account {
    email  = google_service_account.bastion.email
    scopes = var.scopes
  }

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  #scratch_disk {}
  metadata_startup_script = file("startup-script.sh")

  shielded_instance_config {
    enable_secure_boot = (var.shielded_vm == true ? true : false)
  }
}

# Allow SSHing into machines tagged "allow-ssh"
resource "google_compute_firewall" "allow_ssh" {
  project = var.project
  name    = "allow-iap-ssh"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

# Allow SSH only from IAP
  source_ranges           = ["35.235.240.0/20"]
  target_service_accounts = [google_service_account.bastion.email]
}

########################
# Firewall-rule for IAP#
########################
resource "google_compute_firewall" "allow_iap_bastion" {
  project = var.project
  name    = "allow-iap-bastion"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Allow SSH only from IAP
  source_ranges           = ["35.235.240.0/20"]
  target_service_accounts = [google_service_account.bastion.email]
}




############################
#   VPC-Network - Private  #
############################

resource "google_compute_network" "vpc_network" {
  name                    = "kekkoskakkos-network-private"
  auto_create_subnetworks = false
}


########################
#   Subnet - Private   #
########################

resource "google_compute_subnetwork" "subnet_private_bastion" {
  name          = "kekkoskakkos-sub-private"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc_network.id

  secondary_ip_range {
    range_name    = "tf-test-secondary-range-update1"
    ip_cidr_range = "192.168.10.0/24"
  }
}

##########################
#   Subnet - Private 2   #
##########################

# resource "google_compute_subnetwork" "subnet_public" {
#   name          = "kekkoskakkos-sub-public"
#   ip_cidr_range = "10.2.0.0/16"
#   region        = var.region
#   network       = google_compute_network.vpc_network.id

#   secondary_ip_range {
#     range_name    = "tf-test-secondary-range-update1"
#     ip_cidr_range = "192.168.10.0/24"
#   }
# }

###########################
#   Firewall - Allow SSH  #
###########################

resource "google_compute_firewall" "firewall_allow_ssh" {
  name    = "kekkoskakkos-fw-allow-ssh"
  network = google_compute_network.vpc_network.id

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

#############
#   Router  #
#############

resource "google_compute_router" "router" {
  name       = "kekkoskakkos-router"
  network    = google_compute_network.vpc_network.id

  bgp {
    asn = 64514
  }
}

###########
#   NAT   #
###########

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


####################################
#   Henkilöstöhallinta-instanssi   #
####################################

resource "google_compute_instance" "henkilosto_instanssi" {
  name         = "henkilostohallinta"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet_private_bastion.id

    # access_config {
    #   // Ephemeral public IP
    # }
  }
  metadata_startup_script = file("startup-script.sh")
}


###########################
#   Reskontra-instanssi   #
###########################

resource "google_compute_instance" "reskontra_instanssi" {
  name         = "reskontra"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.subnet_private_bastion.id
    # access_config {
    #   // Ephemeral public IP
    # }
  }
  metadata_startup_script = file("startup-script.sh")
}


# tarkastaa luodaanko instanssi,database, user: jos deploy_db (variables.tf -tiedostossa) on false niin ei luoda, jos taas true niin luodaan

#######################################
#   SQL-tietokansa Kekkoslovakialle   #
#######################################

resource "google_sql_database_instance" "kekkoslovakia_tietokanta" {
  count            = var.deploy_db ? 1 : 0
  name             = "kekkoslovakia"
  database_version = "POSTGRES_13"
  region           = var.region

  settings {
    tier = "db-f1-micro" # postgresql tukee vain shared core machineja! tämä shared-core löytyy haminasta
    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        name  = "all"
        value = "0.0.0.0/0"
      }
    }
  }
}

###########################################
#   Henkiöstö-database SQL-tietokantaan   #
###########################################

resource "google_sql_database" "henkilosto_database" {
  count      = var.deploy_db ? 1 : 0
  name       = "henkilöstö"
  project    = var.project
  instance   = google_sql_database_instance.kekkoslovakia_tietokanta[0].name
  depends_on = [google_sql_database_instance.kekkoslovakia_tietokanta]
}

resource "google_sql_user" "henkilosto_database_user" {
  count      = var.deploy_db ? 1 : 0
  project    = var.project
  name       = var.henkilosto_database_username
  instance   = google_sql_database_instance.kekkoslovakia_tietokanta[0].name
  password   = var.henkilosto_database_password
  depends_on = [google_sql_database.henkilosto_database]
}


###########################################
#   Reskontra-database SQL-tietokantaan   #
###########################################


resource "google_sql_database" "reskontra_database" {
  count    = var.deploy_db ? 1 : 0
  name     = "reskontra"
  project  = var.project
  instance = google_sql_database_instance.kekkoslovakia_tietokanta[0].name

  depends_on = [google_sql_database_instance.kekkoslovakia_tietokanta]
}

resource "google_sql_user" "reskontra_database_user" {
  count    = var.deploy_db ? 1 : 0
  project  = var.project
  name     = var.reskontra_database_username
  instance = google_sql_database_instance.kekkoslovakia_tietokanta[0].name
  password = var.reskontra_database_password

  depends_on = [google_sql_database.reskontra_database]
}

