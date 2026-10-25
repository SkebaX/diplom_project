# --- Yandex Cloud ---

variable "cloud_id" {
  type        = string
  description = "ID облака Yandex Cloud"
}

variable "folder_id" {
  type        = string
  description = "ID каталога Yandex Cloud"
}

variable "sa_key_file" {
  type        = string
  default     = "yc-sa-key.json"
  description = "Путь к JSON-ключу сервисного аккаунта"
}

# --- Зоны доступности ---

variable "default_zone" {
  type    = string
  default = "ru-central1-a"
}

variable "zone_d" {
  type    = string
  default = "ru-central1-d"
}

variable "zone_e" {
  type    = string
  default = "ru-central1-e"
}

# --- Подсети ---

variable "public_subnet_d_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_subnet_d_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "public_subnet_e_cidr" {
  type    = string
  default = "10.0.3.0/24"
}

variable "private_subnet_e_cidr" {
  type    = string
  default = "10.0.4.0/24"
}

# --- Виртуальные машины ---

variable "image_family" {
  type        = string
  default     = "ubuntu-2204-lts"
  description = "Семейство ОС для загрузочных дисков"
}

variable "ssh_public_key" {
  type        = string
  description = "Публичный SSH-ключ для доступа к ВМ"
}
