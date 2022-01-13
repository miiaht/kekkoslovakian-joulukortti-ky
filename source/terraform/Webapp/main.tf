/* **************************************************************
Kekkoslovakian Web-palvelun IaC

Moduuli määrittelee web-palvelun infran, joka sisältää:
- palvelun käyttämän tietokannan
- frontendin (Cloud Run)
- frontin liikennettä ohjaavan load balancerin (NEG / serverless)
- frontin ja backendin välissä pyyntöjä ohjaavan API:n (Api Gateway)
- backendin funktiot
- resurssien säilöntään tarkoitetut bucketit
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
  region  = var.region
  zone    = var.zone
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

  name     = "prod-kekkos-app"
  location = var.region
  project  = var.project

  template {
    spec {
      containers {
        image = "gcr.io/final-project-1-337107/kekkos-app:0.5"
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

# uudelleenohjataan http -> https
resource "google_compute_url_map" "https_redirect" {
  provider  = google-beta
  
  name            = "${var.name}-https-redirect"

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "https_redirect" {
  name   = "${var.name}-http-proxy"
  url_map          = google_compute_url_map.https_redirect.id
}

resource "google_compute_global_forwarding_rule" "https_redirect" {
  name   = "${var.name}-lb-http"

  target = google_compute_target_http_proxy.https_redirect.id
  port_range = "80"
  ip_address = google_compute_global_address.default.address
}


/***********************************************************
Rajanpinnan määrittely (API Gateway)
***********************************************************/
resource "google_api_gateway_api" "kekkos-gw" {
  provider = google-beta
  api_id = "kekkos-gw"
}

# Luodaan config
resource "google_api_gateway_api_config" "kekkos-gw" {
  provider = google-beta
  api = google_api_gateway_api.kekkos-gw.api_id
  api_config_id = "config"

  openapi_documents {
    document {
      path = "spec.yaml"
      contents = filebase64("../../api/kekkos-api.yaml")
    }
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Luodaan gateway
resource "google_api_gateway_gateway" "kekkos-gw" {
  provider = google-beta
  api_config = google_api_gateway_api_config.kekkos-gw.id
  gateway_id = "kekkos-gw"
}



/***********************************************************
Cloud Functions -funktiot
ja funktioiden vaatima infra
***********************************************************/

### Luodaan ämpäri, zipit ja funktiot
# Access control bucketille
resource "google_storage_bucket_access_control" "public_rule" {
  bucket = google_storage_bucket.bucket.name
  role   = "OWNER"
  entity = "allUsers"
}

# Ämpäri jossa koodit funktioille
resource "google_storage_bucket" "bucket" {
  provider = google
  name     = "kekkos-koodit"
  location = "US"
}

### Funktiot

# delete_one
# --------------------------------------------------------------------
resource "google_storage_bucket_object" "zip_1" {
  provider  = google
  name      = "prod_delete_one"
  bucket    = google_storage_bucket.bucket.name
  source    = "../../backend/functions/delete_one/delete_one.zip"
}

# Luo funktio zipissä olevasta koodista
resource "google_cloudfunctions_function" "func_1" {
  provider    = google
  name        = "prod_delete_one"
  description = "poistaa vuoden vanhat kortit"
  runtime     = "python39"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.zip_1.name
  trigger_http          = true
  entry_point           = "delete"
  environment_variables = {
    PROJECT_ID = var.project
  }
}


# excel_to_db
# --------------------------------------------------------------------
resource "google_storage_bucket_object" "zip_2" {
  provider  = google
  name      = "prod_excel_to_db"
  bucket    = google_storage_bucket.bucket.name
  source    = "../../backend/functions/excel_to_db/excel_to_db.zip"
}

# Luo funktio zipissä olevasta koodista
resource "google_cloudfunctions_function" "func_2" {
  provider    = google
  name        = "prod_excel_to_db"
  description = "lisää csv:n sisällön tietokantaan"
  runtime     = "python39"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.zip_2.name
  trigger_http          = true
  entry_point           = "excel_feed"
  environment_variables = {
    PROJECT_ID = var.project
  }
}


# get_all
# --------------------------------------------------------------------
resource "google_storage_bucket_object" "zip_3" {
  provider  = google
  name      = "prod_get_all"
  bucket    = google_storage_bucket.bucket.name
  source    = "../../backend/functions/get_all/get_all.zip"
}

# Luo funktio zipissä olevasta koodista
resource "google_cloudfunctions_function" "func_3" {
  provider    = google
  name        = "prod_get_all"
  description = "Hakee kaikki kortit tietokannasta"
  runtime     = "python39"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.zip_3.name
  trigger_http          = true
  entry_point           = "get_all"
  environment_variables = {
    PROJECT_ID = var.project
  }
}


# get_one
# --------------------------------------------------------------------
resource "google_storage_bucket_object" "zip_4" {
  provider  = google
  name      = "prod_get_one"
  bucket    = google_storage_bucket.bucket.name
  source    = "../../backend/functions/get_one/get_one.zip"
}

# Luo funktio zipissä olevasta koodista
resource "google_cloudfunctions_function" "func_4" {
  provider    = google
  name        = "prod_get_one"
  description = "muodostaa kortin käyttäjälle"
  runtime     = "python39"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.zip_4.name
  trigger_http          = true
  entry_point           = "get_one"
  environment_variables = {
    PROJECT_ID = var.project
  }
}


# postcard
# --------------------------------------------------------------------
resource "google_storage_bucket_object" "zip_5" {
  provider  = google
  name      = "prod_postcard"
  bucket    = google_storage_bucket.bucket.name
  source    = "../../backend/functions/postcard/postcard.zip"
}

# Luo funktio zipissä olevasta koodista
resource "google_cloudfunctions_function" "func_5" {
  provider    = google
  name        = "prod_postcard"
  description = "lisää joulukortin tietokantaan"
  runtime     = "python39"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.zip_5.name
  trigger_http          = true
  entry_point           = "postcard"
  environment_variables = {
    PROJECT_ID = var.project
  }
}


# return_images
# --------------------------------------------------------------------
resource "google_storage_bucket_object" "zip_6" {
  provider  = google
  name      = "prod_return_images"
  bucket    = google_storage_bucket.bucket.name
  source    = "../../backend/functions/return_images/return_images.zip"
}

# Luo funktio zipissä olevasta koodista
resource "google_cloudfunctions_function" "func_6" {
  provider    = google
  name        = "prod_return_images"
  description = "palauttaa kaikki käytössä olevat kuvat (png)"
  runtime     = "python39"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.zip_6.name
  trigger_http          = true
  entry_point           = "return_images"
  environment_variables = {
    bucket = var.bucket
  }
}


# avataan pääsy funktioihin
resource "google_cloudfunctions_function_iam_member" "invoker_1" {
  provider       = google
  cloud_function = google_cloudfunctions_function.func_1.name
  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

resource "google_cloudfunctions_function_iam_member" "invoker_2" {
  provider       = google
  cloud_function = google_cloudfunctions_function.func_2.name
  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

resource "google_cloudfunctions_function_iam_member" "invoker_3" {
  provider       = google
  cloud_function = google_cloudfunctions_function.func_3.name
  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

resource "google_cloudfunctions_function_iam_member" "invoker_4" {
  provider       = google
  cloud_function = google_cloudfunctions_function.func_4.name
  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

resource "google_cloudfunctions_function_iam_member" "invoker_5" {
  provider       = google
  cloud_function = google_cloudfunctions_function.func_5.name
  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

resource "google_cloudfunctions_function_iam_member" "invoker_6" {
  provider       = google
  cloud_function = google_cloudfunctions_function.func_6.name
  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}