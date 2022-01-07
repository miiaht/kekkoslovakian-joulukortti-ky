variable "project" {}

variable "credentials_file" {}

variable "members" {}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

### NETWORKING
variable "vpc_name" {
  default = "kekkoskakkos-vpc"
}
variable "subnet_name" {
  default = "kekkoskakkos-subnet"
}

variable "private_name" {
  default = "kekkoskakkos-priva-ip-block"
}

variable "firewall_name_iap" {
  default = "kekkoskakkos-firewall-allow-iap"
}

variable "firewall_name_ssh" {
  default = "kekkoskakkos-firewall-allow-ssh"
}

variable "firewall_name_sql" {
  default = "sql"
}

# Tietokannan databasejen tunnarit

# variable "user" {}
# variable "password" {}

variable "henkilosto_database_username" {}
variable "henkilosto_database_password" {}

variable "reskontra_database_username" {}
variable "reskontra_database_password" {}

# variable "deploy_db" {
#   description = "Whether to deploy a Cloud SQL database or not."
#   type        = bool
#   default     = false
# }

variable "instance_name" {
  default     = "bastion-host"
  description = "The name of the bastion instance"
}

variable "machine_type" {
  default = "f1-micro"
}

variable "image" {
  description = "GCE image on which to base the Bastion"
  default     = "gce-uefi-images/centos-7"
}

variable "enable_oslogin" {
  description = "Enable OS Login for SSH access"
  default     = true
}

variable "service_account_iam_roles" {
  type = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
    "roles/compute.loadBalancerAdmin",
    "roles/compute.instanceAdmin.v1",
  ]
  description = "List of IAM roles to assign to the service account."
}

variable "scopes" {
  default = ["https://www.googleapis.com/auth/cloud-platform"]
}
