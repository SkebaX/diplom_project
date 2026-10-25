# --- Отдельная SG: источник мониторинга (вешается на zabbix-сервер) ---

resource "yandex_vpc_security_group" "zabbix_monitoring_sg" {
  name       = "zabbix-monitoring-sg"
  network_id = yandex_vpc_network.main.id
}

# --- Бастион: только SSH ---

resource "yandex_vpc_security_group" "bastion_sg" {
  name       = "bastion-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol          = "TCP"
    description       = "SSH от админа"
    port              = 22
    v4_cidr_blocks    = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "TCP"
    description       = "Zabbix agent от Zabbix-сервера"
    port              = 10050
    security_group_id = yandex_vpc_security_group.zabbix_monitoring_sg.id
  }

  egress {
    protocol       = "TCP"
    description    = "SSH к внутренним ВМ"
    port           = 22
    v4_cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    protocol       = "ANY"
    description    = "Исходящий интернет"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Web-серверы ---

resource "yandex_vpc_security_group" "web_sg" {
  name       = "web-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol          = "TCP"
    description       = "HTTP от балансировщика"
    port              = 80
    security_group_id = yandex_vpc_security_group.alb_sg.id
  }

  ingress {
    protocol          = "TCP"
    description       = "SSH от бастиона"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion_sg.id
  }

  ingress {
    protocol          = "TCP"
    description       = "Zabbix agent от Zabbix-сервера"
    port              = 10050
    security_group_id = yandex_vpc_security_group.zabbix_monitoring_sg.id
  }

  egress {
    protocol       = "ANY"
    description    = "Исходящий трафик"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Elasticsearch ---

resource "yandex_vpc_security_group" "elasticsearch_sg" {
  name       = "elasticsearch-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol          = "TCP"
    description       = "HTTP API 9200 от Kibana"
    port              = 9200
    security_group_id = yandex_vpc_security_group.kibana_sg.id
  }

  ingress {
    protocol          = "TCP"
    description       = "HTTP API 9200 от web (filebeat)"
    port              = 9200
    security_group_id = yandex_vpc_security_group.web_sg.id
  }

  ingress {
    protocol          = "TCP"
    description       = "SSH от бастиона"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion_sg.id
  }

  ingress {
    protocol          = "TCP"
    description       = "Zabbix agent от Zabbix-сервера"
    port              = 10050
    security_group_id = yandex_vpc_security_group.zabbix_monitoring_sg.id
  }

  egress {
    protocol       = "ANY"
    description    = "Исходящий трафик"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Zabbix-сервер ---

resource "yandex_vpc_security_group" "zabbix_sg" {
  name       = "zabbix-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "Веб-интерфейс Zabbix"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "Веб-интерфейс Zabbix по HTTPS"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "TCP"
    description       = "SSH от бастиона"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion_sg.id
  }

  ingress {
    protocol       = "TCP"
    description    = "Active checks от агентов"
    port           = 10051
    v4_cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    protocol       = "ANY"
    description    = "Исходящий трафик"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Kibana ---

resource "yandex_vpc_security_group" "kibana_sg" {
  name       = "kibana-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "Веб-интерфейс Kibana"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "TCP"
    description       = "SSH от бастиона"
    port              = 22
    security_group_id = yandex_vpc_security_group.bastion_sg.id
  }

  ingress {
    protocol          = "TCP"
    description       = "Zabbix agent от Zabbix-сервера"
    port              = 10050
    security_group_id = yandex_vpc_security_group.zabbix_monitoring_sg.id
  }

  egress {
    protocol       = "ANY"
    description    = "Исходящий трафик"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Балансировщик нагрузки (ALB) ---

resource "yandex_vpc_security_group" "alb_sg" {
  name       = "alb-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    description    = "HTTP от интернета"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS от интернета"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "Health-check от ALB"
    port           = 80
    v4_cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    protocol       = "ANY"
    description    = "Трафик к web-серверам"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["10.0.0.0/16"]
  }
}
