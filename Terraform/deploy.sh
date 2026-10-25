#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Пути и переменные
BASTION_IP=$(terraform output -raw bastion_external_ip)
SSH_KEY="$HOME/.ssh/diplom_key"
SSH_OPTS="-i $SSH_KEY -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

if [ -z "$BASTION_IP" ]; then
    echo "Ошибка: пустой IP бастиона. Проверь terraform apply и output." >&2
    exit 1
fi

# Очистка known_hosts для чистого старта
ssh-keygen -R "$BASTION_IP" 2>/dev/null || true

echo "=== Бастион: $BASTION_IP ==="

# Ожидание SSH (надёжная проверка)
echo "=== Ожидание SSH ==="
for i in $(seq 1 60); do
    if ssh $SSH_OPTS -o ConnectTimeout=5 -o BatchMode=yes ubuntu@"$BASTION_IP" exit 2>/dev/null; then
    echo "SSH доступен (попытка $i)"
    break
    fi
    echo "Попытка $i/60 — ждём..."
    sleep 10
done

if ! ssh $SSH_OPTS -o ConnectTimeout=5 -o BatchMode=yes ubuntu@"$BASTION_IP" exit 2>/dev/null; then
    echo "=== SSH НЕДОСТУПЕН после 60 попыток ===" >&2
    exit 1
fi

# Установка зависимостей (один раз, с ожиданием dpkg lock)
echo "=== Установка зависимостей на бастионе ==="
ssh $SSH_OPTS ubuntu@"$BASTION_IP" "
    set -euo pipefail
    while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo 'Ждём освобождения dpkg lock...'
    sleep 2
    done
    sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends sshpass python3-pymysql ansible
"

# Проверка наличия коллекций
echo "=== Проверка наличия коллекций ==="
if ssh $SSH_OPTS ubuntu@"$BASTION_IP" "
    ansible-galaxy collection list | grep -q '^community.mysql' && \
    ansible-galaxy collection list | grep -q '^community.zabbix' && \
    ansible-galaxy collection list | grep -q '^community.general'
"; then
    echo "Коллекции уже установлены на бастионе — пропускаем скачивание."
else
    echo "Коллекции не найдены — пробуем установить."
    GALAXY_OK=false
    for i in 1 2 3; do
    if timeout 90 ssh $SSH_OPTS -o ConnectTimeout=10 ubuntu@"$BASTION_IP" \
        "ansible-galaxy collection install community.mysql community.zabbix community.general" 2>&1 | tee /tmp/galaxy_install.log; then
        if ! grep -q "ERROR" /tmp/galaxy_install.log; then
        GALAXY_OK=true
        echo "Коллекции установлены (попытка $i)."
        break
        fi
    fi
    echo "Попытка $i/3 — Galaxy недоступен..."
    sleep 10
    done

    if [ "$GALAXY_OK" = false ]; then
    echo "=== Galaxy недоступен. Используем локальное скачивание ==="
    COLLECTIONS_DIR="/tmp/ansible-collections-local"
    mkdir -p "$COLLECTIONS_DIR"
    # Скачиваем локально на машине, где запускается deploy.sh
    (cd "$COLLECTIONS_DIR" && ansible-galaxy collection install \
        community.mysql community.zabbix community.general -p . --force) || {
        echo "Не удалось скачать коллекции локально — проверь сеть и ansible-galaxy." >&2
        exit 1
    }

    echo "=== Копирование коллекций на бастион ==="
    ssh $SSH_OPTS ubuntu@"$BASTION_IP" "mkdir -p ~/.ansible/collections/ansible_collections"
    scp $SSH_OPTS -r "$COLLECTIONS_DIR/ansible_collections/"* \
        ubuntu@"$BASTION_IP":~/.ansible/collections/ansible_collections/
    fi
fi

# Подготовка директорий
ssh $SSH_OPTS ubuntu@"$BASTION_IP" "mkdir -p ~/ansible ~/.ssh"

# Копирование ключа
echo "=== Копирование SSH-ключа на бастион ==="
scp $SSH_OPTS "$SSH_KEY" ubuntu@"$BASTION_IP":~/.ssh/diplom_key
ssh $SSH_OPTS ubuntu@"$BASTION_IP" "chmod 600 ~/.ssh/diplom_key"

# Копирование Ansible-файлов
echo "=== Копирование файлов на бастион ==="
# Важно: inventory.yml должен использовать FQDN .ru-central1.internal, не IP
scp $SSH_OPTS -r \
    ../ansible/ansible.cfg \
    ../ansible/inventory.yml \
    ../ansible/site.yml \
    ../ansible/roles \
    ubuntu@"$BASTION_IP":~/ansible/

# Настройка окружения
echo "=== Настройка окружения на бастионе ==="
ssh $SSH_OPTS ubuntu@"$BASTION_IP" "
    cat >> ~/.bashrc <<'EOF'
export ANSIBLE_HOST_KEY_CHECKING=False
export ANSIBLE_RETRY_FILES_ENABLED=False
export ANSIBLE_COLLECTIONS_PATH=~/.ansible/collections
EOF
"

# Запуск Ansible
echo "=== Запуск Ansible ==="
ssh $SSH_OPTS -o ServerAliveInterval=30 -o ServerAliveCountMax=3 \
    ubuntu@"$BASTION_IP" "cd ~/ansible && ansible-playbook site.yml"

echo "=== Готово ==="
