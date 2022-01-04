variable "project" {}

variable "credentials_file" {}

# Default location placeholders:
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

variable "deploy_db" {
  description = "Whether to deploy a Cloud SQL database or not."
  type        = bool
  default     = false
}


#####################
# bastion variables #
#####################

variable "network" {
  description = "Self link for the network on which the Bastion should live"
}

variable "subnet" {
  description = "Self link for the subnet on which the Bastion should live. Can be private when using IAP"
}

variable "subnet_project" {
  description = "Project where the subnet exists, if different than the bastion project"
  default     = ""
}

variable "instance_name" {
  default     = "bastion"
  description = "The name of the bastion instance"
}
variable "machine_type" {
  default = "f1-micro"
}
variable "service_account_name" {
  default     = "bastion"
  description = "The name of the service account instance"
}

# variable "startup_script" {
#   default     = ""
#   description = "Render a startup script with a template."
# }
variable "scopes" {
  default = ["https://www.googleapis.com/auth/cloud-platform"]
}

variable "image" {
  description = "GCE image on which to base the Bastion"
  default     = "gce-uefi-images/centos-7"
}

variable "shielded_vm" {
  description = "Must use a supported image if true"
  default     = true
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
  ]
  description = "List of IAM roles to assign to the service account."
}

variable "additional_service_account_iam_roles" {
  default     = []
  description = "Additional Service account roles on top of the standard logging and monitoring roles"
}