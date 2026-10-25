resource "yandex_vpc_network" "main" {
  name = "diplom-net"
}

# --- Публичные подсети (Zabbix, Kibana, ALB) ---

resource "yandex_vpc_subnet" "public_d" {
  name           = "public-d"
  zone           = var.zone_d
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.public_subnet_d_cidr]
}

resource "yandex_vpc_subnet" "public_e" {
  name           = "public-e"
  zone           = var.zone_e
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.public_subnet_e_cidr]
}

# --- NAT-шлюз: исходящий интернет для приватного контура ---

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"

  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private_route" {
  name       = "private-route"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

# --- Приватные подсети (web1, web2, Elasticsearch) ---

resource "yandex_vpc_subnet" "private_d" {
  name           = "private-d"
  zone           = var.zone_d
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.private_subnet_d_cidr]
  route_table_id = yandex_vpc_route_table.private_route.id
}

resource "yandex_vpc_subnet" "private_e" {
  name           = "private-e"
  zone           = var.zone_e
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.private_subnet_e_cidr]
  route_table_id = yandex_vpc_route_table.private_route.id
}
