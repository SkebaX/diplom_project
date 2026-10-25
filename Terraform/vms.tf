# --- Бастион (публичная подсеть, зона D) ---

resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  hostname    = "bastion"
  zone        = var.zone_d
  platform_id = "standard-v2"
  scheduling_policy {
    preemptible = false
  }

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_d.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion_sg.id]
  }

  metadata = {
    user-data = <<-EOF
      #cloud-config
      users:
        - name: ubuntu
          groups: sudo
          shell: /bin/bash
          sudo: ALL=(ALL) NOPASSWD:ALL
          ssh_authorized_keys:
            - ${var.ssh_public_key}
    EOF
  }
}

# --- Web-сервер 1 (приватная подсеть, зона D) ---

resource "yandex_compute_instance" "web1" {
  name        = "web1"
  hostname    = "web1"
  zone        = var.zone_d
  platform_id = "standard-v2"
  scheduling_policy {
    preemptible = false
  }

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_d.id
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  metadata = {
    user-data = <<-EOF
      #cloud-config
      users:
        - name: ubuntu
          groups: sudo
          shell: /bin/bash
          sudo: ALL=(ALL) NOPASSWD:ALL
          ssh_authorized_keys:
            - ${var.ssh_public_key}
    EOF
  }
}

# --- Web-сервер 2 (приватная подсеть, зона E) ---

resource "yandex_compute_instance" "web2" {
  name        = "web2"
  hostname    = "web2"
  zone        = var.zone_e
  platform_id = "standard-v2"
  scheduling_policy {
    preemptible = false
  }

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_e.id
    security_group_ids = [yandex_vpc_security_group.web_sg.id]
  }

  metadata = {
    user-data = <<-EOF
      #cloud-config
      users:
        - name: ubuntu
          groups: sudo
          shell: /bin/bash
          sudo: ALL=(ALL) NOPASSWD:ALL
          ssh_authorized_keys:
            - ${var.ssh_public_key}
    EOF
  }
}

# --- Elasticsearch (приватная подсеть, зона D) ---

resource "yandex_compute_instance" "elasticsearch" {
  name        = "elasticsearch"
  hostname    = "elasticsearch"
  zone        = var.zone_d
  platform_id = "standard-v2"
  scheduling_policy {
    preemptible = false
  }

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_d.id
    security_group_ids = [yandex_vpc_security_group.elasticsearch_sg.id]
  }

  metadata = {
    user-data = <<-EOF
      #cloud-config
      users:
        - name: ubuntu
          groups: sudo
          shell: /bin/bash
          sudo: ALL=(ALL) NOPASSWD:ALL
          ssh_authorized_keys:
            - ${var.ssh_public_key}
    EOF
  }
}

# --- Zabbix-сервер (публичная подсеть, зона D) ---

resource "yandex_compute_instance" "zabbix" {
  name        = "zabbix"
  hostname    = "zabbix"
  zone        = var.zone_d
  platform_id = "standard-v2"
  scheduling_policy {
    preemptible = false
  }

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_d.id
    nat                = true
    security_group_ids = [
      yandex_vpc_security_group.zabbix_sg.id,
      yandex_vpc_security_group.zabbix_monitoring_sg.id,
      ]
  }

  metadata = {
    user-data = <<-EOF
      #cloud-config
      users:
        - name: ubuntu
          groups: sudo
          shell: /bin/bash
          sudo: ALL=(ALL) NOPASSWD:ALL
          ssh_authorized_keys:
            - ${var.ssh_public_key}
    EOF
  }
}

# --- Kibana (публичная подсеть, зона E) ---

resource "yandex_compute_instance" "kibana" {
  name        = "kibana"
  hostname    = "kibana"
  zone        = var.zone_d
  platform_id = "standard-v2"
  scheduling_policy {
    preemptible = false
  }

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 10
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_d.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.kibana_sg.id]
  }

  metadata = {
    user-data = <<-EOF
      #cloud-config
      users:
        - name: ubuntu
          groups: sudo
          shell: /bin/bash
          sudo: ALL=(ALL) NOPASSWD:ALL
          ssh_authorized_keys:
            - ${var.ssh_public_key}
    EOF
  }
}

# --- Образ Ubuntu (общий для всех ВМ) ---

data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}
