
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
  provider                = google-beta
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

# #alla olevan kanssa ping ei toimi. SSH yhteys toimii kyllä ilman tai tämän kanssa
# ### Luodaan Firewall-sääntö SSH:lle
# resource "google_compute_firewall" "vpc_firewall_ssh" {
#   name    = "kekkoskakkos-firewall-allow-ssh"
#   network = google_compute_network.vpc_network.id

#    allow {
#     protocol = "icmp"
#   }

#   allow {
#     protocol = "tcp"
#     ports    = ["22"]
#   }

#   source_ranges = ["0.0.0.0/0"]
#   target_tags   = ["ssh"]

# }


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
#   Henkilöstöhallinta-VM-instanssi   #
####################################

resource "google_compute_instance" "henkilosto_instanssi" {
  name         = "henkilostohallinta"
  machine_type = "f1-micro"
  tags         =  ["iap"]

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

# ### IAP-lupa henkilosto-instanssille
# resource "google_iap_tunnel_instance_iam_binding" "tunnel_user_iam_hlo" {
#   zone     = var.zone
#   instance = google_compute_instance.henkilosto_instanssi.id
#   role     = "roles/iap.tunnelResourceAccessor"
#   members  = var.members
# }

# ############################
# #  Reskontra-VM-instanssi  #
# ############################

# resource "google_compute_instance" "reskontra_instanssi" {
#   name         = "reskontra"
#   machine_type = "f1-micro"
#   tags         =  ["iap"]

#   boot_disk {
#     initialize_params {
#       image = "debian-cloud/debian-9"
#     }
#   }

#   network_interface {
#     network = google_compute_network.vpc_network.id
#     subnetwork = google_compute_subnetwork.vpc_subnet.id
#     # access_config {
#     #   // Ephemeral public IP
#     # }
#   }
#   metadata_startup_script = file("startup-script.sh")
# }

# ### IAP-lupa reskontra-instanssille
# resource "google_iap_tunnel_instance_iam_binding" "tunnel_user_iam_res" {
#   zone     = var.zone
#   instance = google_compute_instance.reskontra_instanssi.id
#   role     = "roles/iap.tunnelResourceAccessor"
#   members  = var.members
# }

# ### Private IP -säännöt SQL:lle

# resource "google_compute_global_address" "private_ip_address" {
#   provider      = google-beta
#   name          = "private-ip-address"
#   purpose       = "VPC_PEERING"
#   address_type  = "INTERNAL"
#   prefix_length = 16
#   network       = google_compute_network.vpc_network.id
# }

# resource "google_service_networking_connection" "private_vpc_connection" {
#   provider                = google-beta
#   network                 = google_compute_network.vpc_network.id
#   service                 = "servicenetworking.googleapis.com"
#   reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
# } 

# #######################################
# #   SQL-tietokanta Kekkoslovakialle   #
# #######################################

# resource "google_sql_database_instance" "kekkoslovakia_sql_instanssi" {
#   provider         = google-beta
#   name             = "kekkoslovakia"
#   database_version = "POSTGRES_13"
#   region           = var.region


#   depends_on = [google_service_networking_connection.private_vpc_connection]

#   settings {
#     tier = "db-f1-micro"
#     disk_size = 10

#     ip_configuration {
#       ipv4_enabled    = false
#       private_network = google_compute_network.vpc_network.id
#     }
#   }
# }

# ###########################################
# #   Henkiöstö-database SQL-tietokantaan   #
# ###########################################

# resource "google_sql_database" "henkilosto_database" {
#   name       = "henkilosto"
#   instance   = google_sql_database_instance.kekkoslovakia_sql_instanssi.id
# }

# resource "google_sql_user" "henkilosto_database_user" {
#   name       = var.henkilosto_database_username
#   instance   = google_sql_database_instance.kekkoslovakia_sql_instanssi.id
#   password   = var.henkilosto_database_password
# }


# ###########################################
# #   Reskontra-database SQL-tietokantaan   #
# ###########################################


# resource "google_sql_database" "reskontra_database" {
#   name     = "reskontra"
#   instance = google_sql_database_instance.kekkoslovakia_sql_instanssi.id
# }

# resource "google_sql_user" "reskontra_database_user" {
#   name     = var.reskontra_database_username
#   instance = google_sql_database_instance.kekkoslovakia_sql_instanssi.id
#   password = var.reskontra_database_password
# }

