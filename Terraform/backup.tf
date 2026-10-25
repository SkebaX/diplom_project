# --- Снапшот-расписание: ежедневный бэкап дисков всех ВМ, хранение 7 дней ---

resource "yandex_compute_snapshot_schedule" "daily_backup" {
  name        = "daily-backup"
  description = "Ежедневный снапшот дисков всех ВМ, хранение 7 дней"

  schedule_policy {
    expression = "0 12 * * ?"
  }

  retention_period = "168h"

  snapshot_spec {
    description = "Ежедневный бэкап диска ВМ"
  }

  disk_ids = [
    yandex_compute_instance.bastion.boot_disk[0].disk_id,
    yandex_compute_instance.web1.boot_disk[0].disk_id,
    yandex_compute_instance.web2.boot_disk[0].disk_id,
    yandex_compute_instance.elasticsearch.boot_disk[0].disk_id,
    yandex_compute_instance.zabbix.boot_disk[0].disk_id,
    yandex_compute_instance.kibana.boot_disk[0].disk_id,
  ]
}
