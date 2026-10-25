# --- Целевая группа: web1 и web2 ---

resource "yandex_alb_target_group" "web_targets" {
  name = "web-targets"

  target {
    subnet_id  = yandex_vpc_subnet.private_d.id
    ip_address = yandex_compute_instance.web1.network_interface[0].ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.private_e.id
    ip_address = yandex_compute_instance.web2.network_interface[0].ip_address
  }
}

# --- Backend-группа с health-check ---

resource "yandex_alb_backend_group" "web_backend" {
  name = "web-backend"

  http_backend {
    name                   = "web-http"
    port                   = 80
    target_group_ids       = [yandex_alb_target_group.web_targets.id]
    load_balancing_config {
      panic_threshold = 90
    }

    healthcheck {
      timeout  = "2s"
      interval = "5s"
      http_healthcheck {
        path = "/"
      }
    }
  }
}

# --- HTTP-роутер ---

resource "yandex_alb_http_router" "web_router" {
  name = "web-router"
}

resource "yandex_alb_virtual_host" "web_host" {
  name           = "web-host"
  http_router_id = yandex_alb_http_router.web_router.id

  route {
    name = "to-web"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_backend.id
      }
    }
  }
}

# --- Сам балансировщик ---

resource "yandex_alb_load_balancer" "alb" {
  name       = "web-alb"
  network_id = yandex_vpc_network.main.id
  security_group_ids = [yandex_vpc_security_group.alb_sg.id]

  allocation_policy {
    location {
      zone_id = var.zone_d
      subnet_id = yandex_vpc_subnet.public_d.id
    }
    location {
      zone_id = var.zone_e
      subnet_id = yandex_vpc_subnet.public_e.id
    }
  }

  listener {
    name = "http-listener"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web_router.id
      }
    }
  }
}
