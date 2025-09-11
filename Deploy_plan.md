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

etup### 8. Автоматизация с Touch ID (создан скрипт):

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

### Минимальные требования (полный стек + SSO):
- **RAM**: 10GB (Mattermost 2GB + PostgreSQL 1GB + Redis 512MB + Elasticsearch 2GB + Prometheus 1GB + Grafana 512MB + Loki 512MB + Promtail 256MB + Keycloak 1GB + система 1GB)
- **CPU**: 2 cores
- **Диск**: 20GB + место для данных
- **Сеть**: Стабильное соединение

YtkmpzPf,snm3432!### Hetzner CAX21 (ARM64):
- 4 vCPU, 8GB RAM, 80GB NVMe
- €8.21/месяц
- ✅ Достаточно для наших нужд

## 🚀 Поэтапный план деплоя

### 🎯 Этап 1: Базовый Mattermost (ТЕКУЩИЙ)
**Цель:** Запустить основные сервисы и проверить работу

**Сервисы:**
- ✅ Mattermost (основное приложение)
- ✅ PostgreSQL (база данных)
- ✅ Redis (кэширование)
- ✅ Elasticsearch (поиск)

**Команды:**
```bash
# Подготовка
source scripts/bw-unlock.sh
kamal setup

# Деплой базовых сервисов
kamal deploy

# Проверка
curl https://chat-sputnik.andranoff.online/api/v4/system/ping
```

**Проверка работы:**
1. [ ] Mattermost открывается в браузере
2. [ ] Создание первого администратора работает
3. [ ] Поиск по сообщениям работает
4. [ ] Загрузка файлов в Hetzner S3 работает

---

### 📊 Этап 2: Мониторинг (СЛЕДУЮЩИЙ)
**Цель:** Добавить Prometheus + Grafana для мониторинга

**Как включить:**
```bash
# 1. Раскомментировать в config/deploy.yml:
# prometheus, grafana, loki, promtail

# 2. Обновить конфигурацию
kamal app boot --reboot  # Перезапуск с новой конфигурацией
```

**Доступ к мониторингу:**
- Grafana: через Cloudflare Tunnel (настроим)
- Prometheus: через Cloudflare Tunnel (настроим)

**Проверка работы:**
1. [ ] Grafana открывается (admin + безопасный пароль)
2. [ ] Дашборды Mattermost загружаются
3. [ ] Prometheus собирает метрики
4. [ ] Loki собирает логи

---

### 🔑 Этап 3: SSO с Keycloak (ФИНАЛЬНЫЙ)
**Цель:** Добавить корпоративную аутентификацию

**Как включить:**
```bash
# 1. Раскомментировать keycloak в config/deploy.yml
# 2. Добавить KEYCLOAK_ADMIN_PASSWORD в secrets
# 3. Обновить конфигурацию
kamal app boot --reboot

# 4. Настроить Keycloak через веб-интерфейс
# 5. Добавить OpenID настройки в Mattermost
```

**Настройка SSO:**
1. [ ] Создать Realm "andrianoff-corp"
2. [ ] Создать группы пользователей
3. [ ] Настроить клиент для Mattermost
4. [ ] Включить OpenID Connect в Mattermost
5. [ ] Протестировать "Login with Company Account"

---

### 🔄 Как переключаться между этапами:

#### **Включение сервисов:**
```bash
# Раскомментировать нужные accessories в config/deploy.yml
# Добавить секреты в .kamal/secrets (если нужно)
kamal app boot --reboot
```

#### **Отключение сервисов:**
```bash
# Закомментировать accessories в config/deploy.yml  
kamal app boot --reboot
```

#### **Обновление конфигурации:**
```bash
# После изменений в deploy.yml
kamal deploy  # Полный редеплой
# или
kamal app boot --reboot  # Только перезапуск с новой конфигурацией
```

### 💾 Ресурсы по этапам:

| Этап | Сервисы | RAM | Hetzner |
|------|---------|-----|---------|
| 1 | Базовый | ~6GB | CAX21 (8GB) ✅ |
| 2 | +Мониторинг | ~8GB | CAX21 (8GB) ⚠️ |
| 3 | +SSO | ~9GB | CAX31 (16GB) ✅ |

## 🔑 Keycloak SSO - настройка корпоративной аутентификации

### Зачем нужен Keycloak для вашей инфраструктуры:
**Ваши сервисы:**
- 💬 **Mattermost** - корпоративный чат
- 📁 **Seafile** - файловое хранилище
- 📧 **Mailcow** - почтовый сервер  
- 🛒 **Интернет-магазин** - с Devise (Ruby/Rails)
- 🌐 **Админка сайта** - управление

**Проблема без SSO:** каждый сервис = отдельный логин/пароль
**Решение с Keycloak:** один логин для всех сервисов

### Пошаговая настройка Keycloak:

#### Этап 1: Создание Realm (5 минут)
1. Откройте Keycloak Admin: `http://localhost:8081` (admin/безопасный_пароль)
2. Создайте новый Realm: **"andrianoff-corp"**
3. Настройте базовые параметры:
   - Display name: "Andrianoff Corporation"
   - Frontend URL: "https://auth.andrianoff.online"

#### Этап 2: Создание групп (5 минут)
```
Groups → Create:
├── "Shop Admins" - администраторы магазина
├── "Developers" - разработчики  
├── "Support" - поддержка
├── "Managers" - менеджеры
└── "Users" - обычные пользователи
```

#### Этап 3: Создание пользователей (10 минут)
```
Users → Add User:
┌─────────────────────────────┐
│ Username: vitaly            │
│ Email: vitaly@andrianoff.online │
│ First Name: Vitaly          │
│ Last Name: Andrianov        │
│ Groups: [Shop Admins, Developers] │
└─────────────────────────────┘

Credentials → Set Password:
- Password: secure_password_123
- Temporary: No
```

#### Этап 4: Настройка клиентов для каждого сервиса (по 5 минут):

**Mattermost Client:**
```
Clients → Create Client:
├── Client ID: mattermost
├── Protocol: openid-connect
├── Root URL: https://chat-sputnik.andranoff.online
├── Valid redirect URIs: https://chat-sputnik.andranoff.online/*
├── Web origins: https://chat-sputnik.andranoff.online
└── Access Type: confidential
```

**Seafile Client:**
```
Clients → Create Client:
├── Client ID: seafile
├── Protocol: openid-connect  
├── Root URL: https://files.andrianoff.online
├── Valid redirect URIs: https://files.andrianoff.online/oauth/callback/
└── Access Type: confidential
```

**Shop Admin Client:**
```
Clients → Create Client:
├── Client ID: shop-admin
├── Protocol: openid-connect
├── Root URL: https://shop.andrianoff.online
├── Valid redirect URIs: https://shop.andrianoff.online/auth/keycloak/callback
└── Access Type: confidential
```

### Интеграция с сервисами:

#### Mattermost (добавить в deploy.yml):
```yaml
# OpenID Connect настройки
MM_OPENIDSETTINGS_ENABLE: "true"
MM_OPENIDSETTINGS_ID: "mattermost"
MM_OPENIDSETTINGS_SECRET: "client-secret-from-keycloak"
MM_OPENIDSETTINGS_DISCOVERYENDPOINT: "https://auth.andrianoff.online/realms/andrianoff-corp/.well-known/openid_configuration"
MM_OPENIDSETTINGS_BUTTONTEXT: "Login with Company Account"
MM_OPENIDSETTINGS_BUTTONCOLOR: "#0066cc"
```

#### Seafile (в seahub_settings.py):
```python
ENABLE_OAUTH = True
OAUTH_PROVIDER_DOMAIN = 'auth.andrianoff.online'
OAUTH_CLIENT_ID = 'seafile'
OAUTH_CLIENT_SECRET = 'client-secret-from-keycloak'
OAUTH_AUTHORIZATION_URL = 'https://auth.andrianoff.online/realms/andrianoff-corp/protocol/openid-connect/auth'
OAUTH_TOKEN_URL = 'https://auth.andrianoff.online/realms/andrianoff-corp/protocol/openid-connect/token'
OAUTH_USER_INFO_URL = 'https://auth.andrianoff.online/realms/andrianoff-corp/protocol/openid-connect/userinfo'
```

#### Rails Devise (в вашем магазине):
```ruby
# Gemfile
gem 'omniauth'
gem 'omniauth-keycloak'
gem 'omniauth-rails_csrf_protection'

# config/initializers/devise.rb
config.omniauth :keycloak_openid,
  'shop-admin',
  'client-secret-from-keycloak',
  client_options: {
    site: 'https://auth.andrianoff.online',
    realm: 'andrianoff-corp'
  }

# routes.rb
devise_for :users, controllers: { 
  omniauth_callbacks: 'users/omniauth_callbacks' 
}
```

### Заведение новых пользователей:

#### Способ 1: Через Keycloak Admin (рекомендуется)
1. Откройте Keycloak Admin Console
2. Users → Add User
3. Заполните данные + назначьте группы
4. Set Password → установите пароль
5. Пользователь сразу может логиниться во все сервисы

#### Способ 2: Самостоятельная регистрация
```
Keycloak Settings → Login:
├── User registration: ON
├── Email verification: ON  
├── Forgot password: ON
└── Remember me: ON
```
Пользователи могут сами регистрироваться на auth.andrianoff.online

#### Способ 3: Приглашения
```
Keycloak → Users → Actions → Send Email:
- Invite user with temporary password
- User must change password on first login
```

### Управление доступом:
```
Изменить группу пользователя в Keycloak:
├── Добавить в "Shop Admins" → получает доступ к админке
├── Убрать из "Developers" → теряет доступ к разработке
└── Деактивировать → теряет доступ везде
```

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
