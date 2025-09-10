# 🚀 Mattermost Production Deploy Plan

## 📋 Цель
Развернуть Mattermost на production сервере через Kamal2, максимально приближенно к dev режиму.

## 🔍 Анализ dev режима

### Что делает `make run` в dev:
1. **start-docker** - поднимает accessories через docker-compose:
   - PostgreSQL (порт 5432)
   - Redis (порт 6379) 
   - MinIO (порты 9000, 9002)
   - Elasticsearch (порт 9200)
   - Inbucket (email для тестов)
   - OpenLDAP (опционально)

2. **run-server** - запускает Go сервер из исходников
3. **run-client** - запускает webpack dev server для фронтенда

## 🎯 Production план

### Сборка из исходников через Multi-stage Dockerfile:
```dockerfile
# Stage 1: Build webapp
FROM node:20-alpine AS webapp-builder
# Собираем React приложение из исходников

# Stage 2: Build server  
FROM golang:1.24-alpine AS server-builder
# Собираем Go сервер из исходников с помощью Make

# Stage 3: Runtime
FROM alpine:3.19
# Минимальный runtime образ с собранными бинарниками
```

### Преимущества сборки из исходников:
- ✅ **Полный контроль** над кодом и зависимостями
- ✅ **Кастомизация** - можно изменять исходники
- ✅ **Последние изменения** из master ветки
- ✅ **Оптимизация** под ARM64 архитектуру
- ✅ **Безопасность** - знаем что именно собираем

## 🔧 Kamal2 конфигурация

### deploy.yml структура:
```yaml
service: sputnik_ch
image: viandrianoff/sputnik_ch:latest

servers:
  web:
    hosts: [chat-sputnik.andranoff.online]
    options:
      memory: 2g

proxy:
  ssl: true
  host: chat-sputnik.andranoff.online
  app_port: 8065

accessories:
  db:
    image: postgres:13
    host: chat-sputnik.andranoff.online
    port: "127.0.0.1:5432:5432"  # Только localhost!
    
  redis:
    image: redis:7.4.0
    host: chat-sputnik.andranoff.online
    port: "127.0.0.1:6379:6379"  # Только localhost!
    
  elasticsearch:
    image: elasticsearch:8.9.0
    host: chat-sputnik.andranoff.online
    port: "127.0.0.1:9200:9200"  # Только localhost!
```

## 🔐 Безопасность accessories

### Важно! Порты должны быть закрыты от внешнего мира:
- ✅ `port: "127.0.0.1:5432:5432"` - правильно
- ❌ `port: "5432"` - ОПАСНО! Открыто всему миру

## 🔐 Управление секретами и переменными окружения

### Структура:
```
.kamal/
├── secrets          # Секретные данные (НЕ коммитить в git!)
└── hooks/           # Хуки деплоя (опционально)

config/
└── deploy.yml       # Публичная конфигурация
```

### 1. Секреты в `.kamal/secrets`:
```bash
# Docker Hub токен для пуша образов
KAMAL_REGISTRY_PASSWORD=$KAMAL_REGISTRY_PASSWORD

# PostgreSQL пароль для базы данных
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# Строка подключения к PostgreSQL (содержит пароль)
MM_SQLSETTINGS_DATASOURCE=$MM_SQLSETTINGS_DATASOURCE

# Hetzner S3 секретный ключ
MM_FILESETTINGS_AMAZONS3SECRETACCESSKEY=$MM_FILESETTINGS_AMAZONS3SECRETACCESSKEY

# Redis пароль (опционально)
MM_REDISSETTINGS_PASSWORD=$MM_REDISSETTINGS_PASSWORD
```

### 2. Публичные настройки в `deploy.yml`:
```yaml
env:
  clear:
    # Публичные настройки
    MM_SQLSETTINGS_DRIVERNAME: "postgres"
    MM_FILESETTINGS_DRIVERNAME: "s3"
    MM_FILESETTINGS_AMAZONS3ENDPOINT: "https://hel1.your-objectstorage.com"
    
  secret:
    # Ссылки на секреты из .kamal/secrets
    - MM_SQLSETTINGS_DATASOURCE
    - MM_FILESETTINGS_AMAZONS3SECRETACCESSKEY
    - MM_REDISSETTINGS_PASSWORD
```

### 3. Как Kamal использует секреты:
1. **Считывает** `.kamal/secrets` из локальной машины
2. **Подставляет** значения в переменные окружения контейнера
3. **Не передает** секреты через Docker registry
4. **Безопасно** инжектирует в runtime

### 4. Настройка переменных окружения:

#### Вариант A: Через файл .env (локально):
```bash
# .env (НЕ коммитить в git!)
export KAMAL_REGISTRY_PASSWORD="dckr_pat_your_docker_token"
export POSTGRES_PASSWORD="$(openssl rand -base64 32)"
export MM_SQLSETTINGS_DATASOURCE="postgres://mattermost:${POSTGRES_PASSWORD}@db:5432/mattermost?sslmode=disable&connect_timeout=10"
export MM_FILESETTINGS_AMAZONS3SECRETACCESSKEY="EBNUyzf9RV1TIChZLynNIJOPPfERZMaxw50xsIFF"
export MM_REDISSETTINGS_PASSWORD="$(openssl rand -base64 16)"

# Загрузка:
source .env
kamal deploy
```

#### Вариант B: Через Bitwarden (проверено работает!):

**1. Подготовка Bitwarden:**
```bash
# Установка CLI (если еще не установлен)
brew install bitwarden-cli

# Авторизация (один раз)
bw login vitaly.reg@andrianoff.online
# Введите мастер-пароль и OTP код из email

# Получение session key (каждый раз при работе)
# Вариант A: Автоматически в переменную
export BW_SESSION=$(bw unlock --raw)
# Введите мастер-пароль

# Вариант B: Вручную
bw unlock --raw
# Скопируйте полученный session key:
# Ra/FZHSYmyu2k1SjguBJPki89zxknpiATk4BKNWSqfEIyCARYYO1xuGw0ZCho+40iLrpTjYAT1LqXVnFVNIWzg==
export BW_SESSION="полученный-session-key"

# Проверка статуса
bw status  # Должен показать "unlocked"
```

**2. Структура записей в Bitwarden:**
Создавайте записи типа **Login** с такими именами:
- `Hetzner S3 Secret sputnikgel` - для S3 секретного ключа
- `PostgreSQL Mattermost` - для пароля БД  
- `Docker Registry Token` - для Docker Hub токена

**3. В `.kamal/secrets`:**
```bash
# Получение секретов из Bitwarden
SECRETS=$(kamal secrets fetch --adapter bitwarden --account vitaly.reg@andrianoff.online "Hetzner S3 Secret sputnikgel")
MM_FILESETTINGS_AMAZONS3SECRETACCESSKEY=$(kamal secrets extract "Hetzner S3 Secret sputnikgel" $SECRETS)

# Для каждого секрета отдельно
POSTGRES_SECRETS=$(kamal secrets fetch --adapter bitwarden --account vitaly.reg@andrianoff.online "PostgreSQL Mattermost")
POSTGRES_PASSWORD=$(kamal secrets extract "PostgreSQL Mattermost" $POSTGRES_SECRETS)

DOCKER_SECRETS=$(kamal secrets fetch --adapter bitwarden --account vitaly.reg@andrianoff.online "Docker Registry Token")
KAMAL_REGISTRY_PASSWORD=$(kamal secrets extract "Docker Registry Token" $DOCKER_SECRETS)
```

**4. Правила именования:**
- ✅ Используйте **точные имена** записей из Bitwarden
- ✅ Тип записи: **Login** (Username/Password)
- ✅ Password содержит нужное значение
- ❌ НЕ используйте папки в команде fetch (пока не работает)
- ❌ НЕ используйте пробелы в переменных окружения

#### Вариант C: Прямо в shell:
```bash
export POSTGRES_PASSWORD="secure-password-123"
export MM_FILESETTINGS_AMAZONS3SECRETACCESSKEY="secret-key"
kamal deploy
```

### 5. Поддерживаемые менеджеры паролей:
- **1Password** - `--adapter 1password`
- **Bitwarden** - `--adapter bitwarden` 
- **LastPass** - `--adapter lastpass`

### 6. Troubleshooting Bitwarden + Kamal:

**Проблема**: `Failed to login to and unlock Bitwarden`
```bash
# Решение: Проверить авторизацию
bw status
bw login vitaly.reg@andrianoff.online
export BW_SESSION="your-session-key"
```

**Проблема**: `Could not read [folder] from Bitwarden`
```bash
# Решение: НЕ используйте --from параметр, указывайте точное имя записи
kamal secrets fetch --adapter bitwarden --account vitaly.reg@andrianoff.online "Exact Record Name"
```

**Проблема**: `JSON::ParserError: unexpected character`
```bash
# Решение: Проблема с экранированием, используйте переменную
SECRETS=$(kamal secrets fetch ...)
SECRET_VALUE=$(kamal secrets extract "Record Name" $SECRETS)
```

### 7. Безопасность:
- ✅ `.kamal/secrets` в `.gitignore`
- ✅ Секреты только на локальной машине
- ✅ Передача через защищенный канал SSH
- ✅ Интеграция с Bitwarden CLI
- ✅ Session key временный (истекает)
- ❌ Никогда не коммитить секреты в git
- ❌ Не логировать секретные значения
- ❌ Не сохранять BW_SESSION в файлы

### 8. Автоматизация с Touch ID (создан скрипт):

**Скрипт `scripts/bw-unlock.sh`:**
- ✅ **Создан** и готов к использованию
- ✅ **Touch ID** для доступа к мастер-паролю из Keychain
- ✅ **Автоматическая** авторизация и разблокировка
- ✅ **Проверка статуса** Bitwarden перед действиями

**Использование:**
```bash
# Разблокировка с Touch ID (если нужно)
source scripts/bw-unlock.sh

# Теперь можно работать с Kamal
kamal secrets fetch --adapter bitwarden --account vitaly.reg@andrianoff.online "Hetzner S3 Secret sputnikgel"
kamal deploy
```

**Что делает скрипт:**
1. Проверяет статус Bitwarden CLI
2. Если заблокирован - запрашивает Touch ID для доступа к Keychain
3. Получает мастер-пароль из Keychain
4. Автоматически разблокирует Bitwarden
5. Устанавливает BW_SESSION для текущей сессии

## 📦 Хранилище файлов

### Варианты:
1. **MinIO контейнер** - бесплатно, но нужно администрировать
2. **Hetzner Object Storage** (настоящий S3) - €4.90/мес за 1TB

### Рекомендация: Hetzner Object Storage
**Преимущества:**
- ✅ Управляемый сервис - не нужно администрировать
- ✅ Автоматические бэкапы и репликация
- ✅ Высокая доступность
- ✅ S3-совместимый API
- ✅ Дешевле AWS S3

**Настройки:**
- Endpoint: `https://hel1.your-objectstorage.com`
- Bucket: `sputnikgel`
- Access Key: `IWFYQARQMCQXUTB3ETY6`
- Secret Key: `EBNUyzf9RV1TIChZLynNIJOPPfERZMaxw50xsIFF`

## 🗄️ База данных

### PostgreSQL конфигурация:
```yaml
accessories:
  db:
    image: postgres:13
    host: chat-sputnik.andranoff.online
    port: "127.0.0.1:5432:5432"
    options:
      memory: 1g
    env:
      clear:
        POSTGRES_DB: mattermost
        POSTGRES_USER: mattermost
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data
```

## 🔍 Поиск

### Elasticsearch конфигурация:
```yaml
accessories:
  elasticsearch:
    image: elasticsearch:8.9.0
    host: chat-sputnik.andranoff.online
    port: "127.0.0.1:9200:9200"
    options:
      memory: 2g
    env:
      clear:
        discovery.type: single-node
        xpack.security.enabled: "false"
        ES_JAVA_OPTS: "-Xms1g -Xmx1g"
    directories:
      - data:/usr/share/elasticsearch/data
```

### Redis конфигурация:
```yaml
accessories:
  redis:
    image: redis:7.4.0
    host: chat-sputnik.andranoff.online
    port: "127.0.0.1:6379:6379"
    options:
      memory: 512m
    directories:
      - data:/data
    cmd: redis-server --appendonly yes
```

## ⚙️ Конфигурация Mattermost

### Где настраивается Mattermost в production:

#### 1. Переменные окружения (рекомендуется):
```yaml
# В deploy.yml
env:
  clear:
    # База данных
    MM_SQLSETTINGS_DRIVERNAME: "postgres"
    MM_SQLSETTINGS_DATASOURCE: "postgres://mattermost:password@db:5432/mattermost?sslmode=disable"
    
    # Файловое хранилище (Hetzner S3)
    MM_FILESETTINGS_DRIVERNAME: "s3"
    MM_FILESETTINGS_AMAZONS3ENDPOINT: "https://hel1.your-objectstorage.com"
    MM_FILESETTINGS_AMAZONS3BUCKET: "sputnikgel"
    MM_FILESETTINGS_AMAZONS3ACCESSKEYID: "IWFYQARQMCQXUTB3ETY6"
    MM_FILESETTINGS_AMAZONS3SSL: "true"
    
    # Redis кэш
    MM_REDISSETTINGS_ADDRESS: "redis:6379"
    MM_REDISSETTINGS_ENABLE: "true"
    
    # Elasticsearch поиск
    MM_ELASTICSEARCHSETTINGS_CONNECTIONURL: "http://elasticsearch:9200"
    MM_ELASTICSEARCHSETTINGS_ENABLE: "true"
    
    # Сервер настройки
    MM_SERVICESETTINGS_SITEURL: "https://chat-sputnik.andranoff.online"
    MM_SERVICESETTINGS_LISTENADDRESS: ":8065"
```

#### 2. Файл config.json (альтернатива):
```json
{
  "SqlSettings": {
    "DriverName": "postgres",
    "DataSource": "postgres://mattermost:password@db:5432/mattermost?sslmode=disable"
  },
  "FileSettings": {
    "DriverName": "s3",
    "AmazonS3Endpoint": "https://hel1.your-objectstorage.com",
    "AmazonS3Bucket": "sputnikgel",
    "AmazonS3AccessKeyId": "IWFYQARQMCQXUTB3ETY6",
    "AmazonS3SSL": true
  }
}
```

#### 3. Приоритет конфигурации:
1. **Переменные окружения** (высший приоритет)
2. Файл config.json
3. Значения по умолчанию

### Важные переменные для production:
```bash
# Безопасность
MM_SERVICESETTINGS_ENABLELOCALMODE=false
MM_SERVICESETTINGS_ENABLEDEVELOPER=false

# Команды и регистрация
MM_TEAMSETTINGS_ENABLEUSERCREATION=true
MM_TEAMSETTINGS_ENABLEOPENSERVER=false

# Email (опционально)
MM_EMAILSETTINGS_ENABLE=false

# Логирование
MM_LOGSETTINGS_ENABLECONSOLE=true
MM_LOGSETTINGS_CONSOLELEVEL=INFO
```

## 💾 Ресурсы сервера

### Минимальные требования:
- **RAM**: 6GB (Mattermost 2GB + PostgreSQL 1GB + Redis 512MB + Elasticsearch 2GB + система 512MB)
- **CPU**: 2 cores
- **Диск**: 20GB + место для данных
- **Сеть**: Стабильное соединение

YtkmpzPf,snm3432!### Hetzner CAX21 (ARM64):
- 4 vCPU, 8GB RAM, 80GB NVMe
- €8.21/месяц
- ✅ Достаточно для наших нужд

## 🚀 План выполнения

### Этап 1: Подготовка
1. [ ] Создать Multi-stage Dockerfile для сборки из исходников
2. [ ] Настроить Kamal2 конфигурацию с accessories
3. [ ] Настроить секреты и переменные окружения
4. [ ] Проверить доступ к Hetzner Object Storage

### Этап 2: Локальное тестирование
1. [ ] Собрать Docker образ из исходников локально
2. [ ] Протестировать accessories (PostgreSQL, Redis, Elasticsearch)
3. [ ] Проверить подключение к Hetzner S3
4. [ ] Проверить сборку webapp и server

### Этап 3: Деплой
1. [ ] `kamal setup` - первоначальная настройка
2. [ ] `kamal deploy` - деплой приложения
3. [ ] Настроить SSL сертификаты
4. [ ] Создать первого администратора

### Этап 4: Мониторинг
1. [ ] Настроить логи
2. [ ] Проверить health checks
3. [ ] Настроить бэкапы
4. [ ] Мониторинг ресурсов

## 🔄 Обновления

### Процесс обновления:
1. Обновить исходники: `git pull`
2. Пересобрать образ: `docker build`
3. Деплой: `kamal deploy`
4. Откат при проблемах: `kamal rollback`

## 📝 Заметки

### Процесс сборки:
1. **Webapp**: Node.js сборка React приложения
2. **Server**: Go сборка сервера с помощью Make
3. **Runtime**: Копирование в минимальный Alpine образ
4. **Optimization**: Мультистейдж сборка для минимального размера

### Особенности:
- ✅ **Быстрая сборка** - параллельные этапы
- ✅ **Минимальный размер** - только runtime зависимости
- ❌ **Время сборки** - дольше чем готовый образ
- ❌ **Зависимости** - нужны Node.js и Go для сборки

## 🎯 Финальная архитектура

```
Internet → Cloudflare Tunnel → Kamal Proxy → Mattermost Container
                                    ↓
                          ┌─────────────────────┐
                          │    Accessories      │
                          │  (localhost only)   │
                          ├─────────────────────┤
                          │ PostgreSQL :5432    │
                          │ Redis :6379         │
                          │ Elasticsearch :9200 │
                          └─────────────────────┘
                                    ↓
                         Hetzner Object Storage (S3)
                         https://hel1.your-objectstorage.com
```

Этот план обеспечивает:
- 🔒 **Безопасность** - accessories закрыты от внешнего мира
- 🚀 **Производительность** - Elasticsearch для быстрого поиска
- 💰 **Экономичность** - Hetzner Object Storage управляемый сервис
- 🔄 **Масштабируемость** - легко добавить серверы
- 🛠️ **Управляемость** - простые команды Kamal для деплоя
