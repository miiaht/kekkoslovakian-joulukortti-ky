
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

locals{
  metadata = (var.enable_oslogin == true ? {"enable-oslogin" : "TRUE"} : {})
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
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  direction     = "INGRESS"
  target_tags   = ["iap"]

}

### Luodaan Firewall-sääntö SSH:lle
resource "google_compute_firewall" "vpc_firewall_ssh" {
  name    = "kekkoskakkos-firewall-allow-ssh"
  network = google_compute_network.vpc_network.id

   allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]

}


### Luodaan Bastion host
resource "google_compute_instance" "bastion" {
  zone = var.zone
  name = var.instance_name

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

  service_account {
    email  = google_service_account.service_account.email
    scopes = var.scopes
  }
  
}



### Service Account
resource "google_service_account" "service_account" {
  account_id   = "service-account-id"
  display_name = "A service account that only Jane can interact with"
}

### IAM -admin oikeudet service accountille
resource "google_project_iam_member" "service_account_iam" {
  count   = length(var.service_account_iam_roles)
  project = var.project
  role    = element(var.service_account_iam_roles, count.index)
  member  = "serviceAccount:${google_service_account.service_account.email}"
}

### Annetaan IAP Tunnel User -luvat käyttäjille
resource "google_iap_tunnel_instance_iam_binding" "tunnel_user_iam" {
  zone     = var.zone
  instance = google_compute_instance.bastion.id
  role     = "roles/iap.tunnelResourceAccessor"
  members  = var.members
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
  tags         =  ["ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.vpc_subnet.id

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
  tags         =  ["ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.id
    subnetwork = google_compute_subnetwork.vpc_subnet.id
    # access_config {
    #   // Ephemeral public IP
    # }
  }
  metadata_startup_script = file("startup-script.sh")
}


# # tarkastaa luodaanko instanssi,database, user: jos deploy_db (variables.tf -tiedostossa) on false niin ei luoda, jos taas true niin luodaan

# #######################################
# #   SQL-tietokansa Kekkoslovakialle   #
# #######################################

# resource "google_sql_database_instance" "kekkoslovakia_tietokanta" {
#   count            = var.deploy_db ? 1 : 0
#   name             = "kekkoslovakia"
#   database_version = "POSTGRES_13"
#   region           = var.region

#   settings {
#     tier = "db-f1-micro" # postgresql tukee vain shared core machineja! tämä shared-core löytyy haminasta
#     ip_configuration {
#       ipv4_enabled = true
#       authorized_networks {
#         name  = "all"
#         value = "0.0.0.0/0"
#       }
#     }
#   }
# }

# ###########################################
# #   Henkiöstö-database SQL-tietokantaan   #
# ###########################################

# resource "google_sql_database" "henkilosto_database" {
#   count      = var.deploy_db ? 1 : 0
#   name       = "henkilöstö"
#   project    = var.project
#   instance   = google_sql_database_instance.kekkoslovakia_tietokanta[0].name
#   depends_on = [google_sql_database_instance.kekkoslovakia_tietokanta]
# }

# resource "google_sql_user" "henkilosto_database_user" {
#   count      = var.deploy_db ? 1 : 0
#   project    = var.project
#   name       = var.henkilosto_database_username
#   instance   = google_sql_database_instance.kekkoslovakia_tietokanta[0].name
#   password   = var.henkilosto_database_password
#   depends_on = [google_sql_database.henkilosto_database]
# }


# ###########################################
# #   Reskontra-database SQL-tietokantaan   #
# ###########################################


# resource "google_sql_database" "reskontra_database" {
#   count    = var.deploy_db ? 1 : 0
#   name     = "reskontra"
#   project  = var.project
#   instance = google_sql_database_instance.kekkoslovakia_tietokanta[0].name

#   depends_on = [google_sql_database_instance.kekkoslovakia_tietokanta]
# }

# resource "google_sql_user" "reskontra_database_user" {
#   count    = var.deploy_db ? 1 : 0
#   project  = var.project
#   name     = var.reskontra_database_username
#   instance = google_sql_database_instance.kekkoslovakia_tietokanta[0].name
#   password = var.reskontra_database_password

#   depends_on = [google_sql_database.reskontra_database]
# }

