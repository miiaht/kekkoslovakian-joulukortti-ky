variable "project" {}

variable "credentials_file" {}

variable "members" {}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

variable "members" {}

# Tietokannan databasejen tunnarit
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
  default = true
}

variable "service_account_iam_roles" {
  type = list(string)
  default = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
    "roles/monitoring.viewer",
  ]
  description = "List of IAM roles to assign to the service account."
}

variable "scopes" {
  default = ["https://www.googleapis.com/auth/cloud-platform"]
}
