# projektin yleiset muuttujat:
variable "project" {}
variable "credentials_file" {}
variable "region" { default = "us-central1" }
variable "zone" { default = "us-central1-c" }

# webapp-tietokannan yhteysmuuttujat:
variable "sql_name" {}
variable "sql_password" {}

# webappin load balancerin muuttujat:
variable "name" { default = "kekkos-lb" }
variable "domain" {}

# kuva-bucket
variable "bucket" {}