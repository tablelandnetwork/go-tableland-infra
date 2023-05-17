resource "google_compute_health_check" "health_check" {
  project = var.gcp_project
  name    = "switch-health-check"
  http_health_check {
    port         = 8080
    request_path = "/api/v1/health"
  }
}

resource "google_compute_global_address" "switch_global_address" {
  name = "switch-global-address"
}

resource "google_compute_backend_service" "switch_backend_service" {
  project               = var.gcp_project
  name                  = "switch-backend-service"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTP"
  timeout_sec           = 30
  health_checks = [
    google_compute_health_check.health_check.id
  ]
  dynamic "backend" {
    for_each = var.instance_group_blue
    content {
      group           = backend.value.instance_group
      balancing_mode  = "UTILIZATION"
      capacity_scaler = backend.value.base_instance_name == "${var.active_stack}-instance-${var.app_version_blue}" ? 1 : 0
    }
  }
  dynamic "backend" {
    for_each = var.instance_group_green
    content {
      group           = backend.value.instance_group
      balancing_mode  = "UTILIZATION"
      capacity_scaler = backend.value.base_instance_name == "${var.active_stack}-instance-${var.app_version_green}" ? 1 : 0
    }
  }
  session_affinity = "NONE"
  enable_cdn       = false
}

resource "google_compute_url_map" "switch_url_map" {
  project         = var.gcp_project
  name            = "switch-url-map"
  default_service = google_compute_backend_service.switch_backend_service.self_link
}

resource "google_compute_target_http_proxy" "switch_http_proxy" {
  project = var.gcp_project
  name    = "switch-http-proxy"
  url_map = google_compute_url_map.switch_url_map.self_link
}

resource "google_compute_global_forwarding_rule" "switch_forwarding_rule" {
  project               = var.gcp_project
  name                  = "switch-forwarding-rule"
  target                = google_compute_target_http_proxy.switch_http_proxy.self_link
  port_range            = "8080"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  ip_address            = google_compute_global_address.switch_global_address.address
}