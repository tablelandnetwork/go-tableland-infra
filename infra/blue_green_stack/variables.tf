variable "gcp_project" {
  description = "GCP Project ID"
}

variable "gcp_region" {
  description = "GCP Region"
}

variable "gcp_zone" {
  description = "GCP Zone"
}

variable "stack_name" {
  description = "Stack name: blue or green"
}

variable "app_version" {
  description = "Version of the app (commit hash)"
}