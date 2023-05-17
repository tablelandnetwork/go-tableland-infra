resource "google_storage_bucket" "bucket" {
  name     = "grafana_db_bucket"
  location = "US"
}

resource "google_storage_bucket_object" "object" {
  name   = "grafana.db"
  bucket = google_storage_bucket.bucket.name
  source = "grafana.db"
}

resource "google_secret_manager_secret" "env_validator" {
  secret_id = "env_validator"

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret" "env_grafana" {
  secret_id = "env_grafana"

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret" "env_healthbot" {
  secret_id = "env_healthbot"

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "env_validator_version" {
  secret      = google_secret_manager_secret.env_validator.id
  secret_data = file("./.env_validator")

}

resource "google_secret_manager_secret_version" "env_grafana_version" {
  secret      = google_secret_manager_secret.env_grafana.id
  secret_data = file("./.env_grafana")

}

resource "google_secret_manager_secret_version" "env_healthbot_version" {
  secret      = google_secret_manager_secret.env_healthbot.id
  secret_data = file("./.env_healthbot")

}

resource "google_compute_instance_template" "instance_template" {
  name         = "${var.stack_name}-instance-template-${var.app_version}"
  machine_type = "n1-standard-1"

  disk {
    auto_delete  = true
    boot         = true
    device_name  = "persistent-disk-0"
    mode         = "READ_WRITE"
    source_image = "ubuntu-minimal-2204-jammy-v20230428"
    type         = "PERSISTENT"
  }

  metadata_startup_script = templatefile("./bootstrap.tpl", {
    validator_secret_id = google_secret_manager_secret.env_validator.secret_id
    grafana_secret_id   = google_secret_manager_secret.env_grafana.secret_id
    healthbot_secret_id = google_secret_manager_secret.env_healthbot.secret_id
    TBLENV              = "staging" // TODO: Add new variable environment
  })


  network_interface {
    network = "default"
    access_config {
      # Ephemeral IP
    }
  }
  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    provisioning_model  = "STANDARD"
  }
  tags = ["load-balanced-backend", "http-server", "https-server", "http-8080"]

  service_account {
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  # NOTE: the name of this resource must be unique for eveey update;
  #       this is why we have a app_version in the name; this way
  #       new resource has a different name vs old one and both can
  #       exists at the same time
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_instance_group_manager" "instance_group_manager" {
  name               = "${var.stack_name}-instance-group-manager-${var.app_version}"
  base_instance_name = "${var.stack_name}-instance-${var.app_version}"
  zone               = var.gcp_zone

  named_port {
    name = "http"
    port = 80
  }

  version {
    instance_template = google_compute_instance_template.instance_template.self_link
  }

  target_size = 1

  # NOTE: the name of this resource must be unique for eveey update;
  #       this is why we have a app_version in the name; this way
  #       new resource has a different name vs old one and both can
  #       exists at the same time
  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_global_address" "global_address" {
  name = "${var.stack_name}-global-address"
}

resource "google_compute_health_check" "health_check" {
  name = "${var.stack_name}-health-check"
  http_health_check {
    port         = 8080
    request_path = "/api/v1/health"
  }
}

resource "google_compute_backend_service" "backend_service" {
  name                  = "${var.stack_name}-backend-service"
  health_checks         = [google_compute_health_check.health_check.self_link]
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_instance_group_manager.instance_group_manager.instance_group
  }

  session_affinity = "NONE"
  enable_cdn       = false
}

resource "google_compute_url_map" "url_map" {
  name = "${var.stack_name}-url-map"

  default_service = google_compute_backend_service.backend_service.self_link
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${var.stack_name}-http-proxy"
  url_map = google_compute_url_map.url_map.self_link
}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name                  = "${var.stack_name}-forwarding-rule"
  target                = google_compute_target_http_proxy.http_proxy.self_link
  port_range            = "8080"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.global_address.address
}

output "instance_group_manager" {
  value = google_compute_instance_group_manager.instance_group_manager
}