variable "gcp_project" {
  description = "GCP Project ID"
}

variable "gcp_region" {
  description = "GCP Region"
}

variable "gcp_zone" {
  description = "GCP Zone"
}

variable "active_stack" {
  description = "The active stack for the third load balancer to forward traffic to. Set to 'blue' or 'green'."
  default     = "blue"
}

variable "deployment" {
  description = "Boolean to tell if it is deployment"
}

variable "credentials_file" {
  type = string
}

variable "blue_version" {
  description = "Version of the app (commit hash)"
}

variable "green_version" {
  description = "Version of the app (commit hash)"
}