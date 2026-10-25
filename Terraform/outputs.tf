# --- Публичные IP (для подключения из интернета) ---

output "bastion_external_ip" {
  description = "Публичный IP бастиона"
  value       = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
}

output "zabbix_external_ip" {
  description = "Публичный IP Zabbix-сервера"
  value       = yandex_compute_instance.zabbix.network_interface[0].nat_ip_address
}

output "kibana_external_ip" {
  description = "Публичный IP Kibana"
  value       = yandex_compute_instance.kibana.network_interface[0].nat_ip_address
}

# --- Внутренние IP (для Ansible и межмашинного трафика) ---

output "bastion_internal_ip" {
  description = "Внутренний IP бастиона"
  value       = yandex_compute_instance.bastion.network_interface[0].ip_address
}

output "web1_internal_ip" {
  description = "Внутренний IP web1"
  value       = yandex_compute_instance.web1.network_interface[0].ip_address
}

output "web2_internal_ip" {
  description = "Внутренний IP web2"
  value       = yandex_compute_instance.web2.network_interface[0].ip_address
}

output "elasticsearch_internal_ip" {
  description = "Внутренний IP Elasticsearch"
  value       = yandex_compute_instance.elasticsearch.network_interface[0].ip_address
}

output "zabbix_internal_ip" {
  description = "Внутренний IP Zabbix-сервера"
  value       = yandex_compute_instance.zabbix.network_interface[0].ip_address
}

output "kibana_internal_ip" {
  description = "Внутренний IP Kibana"
  value       = yandex_compute_instance.kibana.network_interface[0].ip_address
}

# --- Балансировщик ---

output "alb_public_ip" {
  description = "Публичный IP балансировщика"
  value       = yandex_alb_load_balancer.alb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}
