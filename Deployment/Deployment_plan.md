# Bau-Portal - План развертывания и кастомизации

## 🎯 Обзор проекта

**Bau-Portal** - это полностью брендированное решение на базе Mattermost для безопасного общения между строительными партнерами.

### Архитектура системы:
- **Главный хаб**: `chat.bau-portal.online` - общение между партнерами
- **Отдельные инстансы**: `alpha.chat.bau-portal.online` - внутренние обсуждения партнеров
- **Push-сервер**: `push.bau-portal.online` - собственные уведомления
- **Мобильные приложения**: iOS и Android под брендом Bau-Portal

## 📱 1. Мобильное приложение "Bau-Portal"

### Основные изменения брендинга:

#### A. Конфигурационные файлы:
```json
// app.json
{
  "name": "BauPortal",
  "displayName": "Bau-Portal"
}

// package.json
{
  "name": "bau-portal-mobile",
  "version": "1.0.0",
  "description": "Bau-Portal Mobile with React Native",
  "repository": "git@github.com:bauportal/bau-portal-mobile.git",
  "author": "Bau-Portal"
}
```

#### B. Android настройки:
```xml
<!-- android/app/src/main/res/values/strings.xml -->
<string name="app_name">Bau-Portal</string>
```

#### C. Необходимые иконки:
```
Android:
- mipmap-mdpi/ic_launcher.png (48x48)
- mipmap-hdpi/ic_launcher.png (72x72)
- mipmap-xhdpi/ic_launcher.png (96x96)
- mipmap-xxhdpi/ic_launcher.png (144x144)
- mipmap-xxxhdpi/ic_launcher.png (192x192)

iOS:
- AppIcon-20@2x.png (40x40)
- AppIcon-20@3x.png (60x60)
- AppIcon-29@2x.png (58x58)
- AppIcon-29@3x.png (87x87)
- AppIcon-40@2x.png (80x80)
- AppIcon-40@3x.png (120x120)
- AppIcon-60@2x.png (120x120)
- AppIcon-60@3x.png (180x180)
- AppIcon-1024.png (1024x1024)
```

#### D. Bundle ID и Package Name:
- **iOS**: `com.bauportal.mobile`
- **Android**: `com.bauportal.mobile`

## 🔔 2. Push Proxy Server

### Конфигурация:
```json
{
    "ListenAddress":":8066",
    "ThrottlePerSec":300,
    "EnableMetrics": true,
    "ApplePushSettings":[
        {
            "Type":"apple",
            "ApplePushTopic":"com.bauportal.mobile",
            "AppleAuthKeyFile": "./certs/AuthKey_XXXXXXXXXX.p8",
            "AppleAuthKeyID": "XXXXXXXXXX",
            "AppleTeamID": "XXXXXXXXXX"
        }
    ],
    "AndroidPushSettings": [
        {
            "Type":"android",
            "ServiceFileLocation":"./certs/bau-portal-firebase-service-account.json"
        }
    ]
}
```

### Необходимые сертификаты:
1. **Apple Developer Account**:
   - App ID: `com.bauportal.mobile`
   - Push Notification Certificate
   - AuthKey_XXXXXXXXXX.p8

2. **Firebase Project**:
   - google-services.json
   - Service Account Key JSON

## 🌐 3. Веб-приложение

### Основные изменения:
```html
<!-- webapp/channels/src/root.html -->
<title>Bau-Portal</title>
<meta name='application-name' content='Bau-Portal'>
```

```javascript
// webapp/channels/webpack.config.js
new WebpackPwaManifest({
    name: 'Bau-Portal',
    short_name: 'Bau-Portal',
    description: 'Bau-Portal - Secure Communication Platform for Construction Partners'
})
```

### Файлы для кастомизации:
- Логотипы: `webapp/channels/src/images/`
- Favicon: `webapp/channels/src/images/favicon/`
- Стили: `webapp/channels/src/sass/`
- Компоненты: `webapp/channels/src/components/`

## 🐳 4. Docker Compose конфигурация

### Полная система:
```yaml
version: '3.8'

services:
  # Bau-Portal Web Application
  bau-portal-web:
    build: .
    environment:
      - MM_SERVICESETTINGS_SITEURL=https://chat.bau-portal.online
      - MM_TEAMSETTINGS_SITENAME=Bau-Portal
      - MM_TEAMSETTINGS_ENABLECUSTOMBRAND=true
      - MM_EMAILSETTINGS_PUSHNOTIFICATIONSERVER=https://push.bau-portal.online
    ports:
      - "8065:8065"

  # Bau-Portal Push Proxy
  bau-portal-push-proxy:
    build: ./mattermost-push-proxy
    ports:
      - "8066:8066"

  # PostgreSQL Database
  postgres-bau:
    image: postgres:13
    environment:
      - POSTGRES_DB=bauportal_db
      - POSTGRES_USER=bauportal

  # Nginx Reverse Proxy
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
```

## 🔧 5. Nginx конфигурация

### Основные домены:
```nginx
# chat.bau-portal.online - основное веб-приложение
server {
    listen 443 ssl http2;
    server_name chat.bau-portal.online;
    
    location / {
        proxy_pass http://bau-portal-web:8065;
    }
}

# push.bau-portal.online - push proxy
server {
    listen 443 ssl http2;
    server_name push.bau-portal.online;
    
    location / {
        proxy_pass http://bau-portal-push-proxy:8066;
    }
}
```

## 🏗️ 6. Официальная сборка для Production

### ⚠️ ВАЖНО: Используйте ТОЛЬКО официальные команды Mattermost!

### Шаг 1: Официальная сборка
```bash
# SSL сертификаты для доменов
mkdir -p certs/ssl
# Получить сертификаты для:
# - chat.bau-portal.online
# - push.bau-portal.online

# Сертификаты для мобильных приложений
mkdir -p certs
# Разместить:
# - AuthKey_XXXXXXXXXX.p8 (Apple)
# - bau-portal-firebase-service-account.json (Firebase)
```

### Шаг 2: Сборка мобильного приложения
```bash
cd mattermost-mobile

# Установка зависимостей
npm install

# iOS
cd ios && pod install && cd ..
npm run build:ios

# Android
npm run build:android
```

### Шаг 3: Настройка Push Proxy
```bash
cd mattermost-push-proxy

# Копирование конфигурации
cp config/bau-portal-push-proxy.json config/config.json

# Сборка
make build

# Тестирование
./bin/mattermost-push-proxy -config=config/config.json
```

### Шаг 4: Сборка веб-приложения
```bash
# Веб-приложение
cd webapp/channels
npm install
npm run build

# Сервер
cd ../../server
make build
```

### Шаг 5: Развертывание
```bash
# Запуск системы
docker-compose -f docker-compose.bau-portal.yml up -d

# Проверка статуса
docker-compose -f docker-compose.bau-portal.yml ps

# Просмотр логов
docker-compose -f docker-compose.bau-portal.yml logs -f
```

### Шаг 6: Автоматизация
```bash
# Использование скрипта сборки
./scripts/build-bau-portal.sh

# С мобильными приложениями
./scripts/build-bau-portal.sh --mobile ios
./scripts/build-bau-portal.sh --mobile android
```

## 📱 7. Публикация в App Store и Google Play

### iOS App Store:
1. **Настройка в Xcode**:
   - Bundle ID: `com.bauportal.mobile`
   - Иконки: `ios/Mattermost/Images.xcassets/AppIcon.appiconset/`
   - Push Notifications Capability

2. **Архивирование**:
   - Product → Archive в Xcode
   - Upload to App Store Connect

### Google Play:
1. **Настройка Android**:
   - Application ID: `com.bauportal.mobile`
   - Firebase: `android/app/google-services.json`

2. **Сборка**:
   ```bash
   ./gradlew assembleRelease  # APK
   ./gradlew bundleRelease    # App Bundle
   ```

## 🏗️ 8. Федеративная архитектура

### Структура для партнеров:
```
chat.bau-portal.online (Главный хаб)
├── Команда "Bau-Portal Hub"
│   ├── #general (общие объявления)
│   ├── #partnerships (обсуждения партнерств)
│   └── Участники: представители всех компаний

alpha.chat.bau-portal.online (Партнер А)
├── Команда "Alpha Corp"
│   ├── #general (внутренние обсуждения)
│   ├── #development (разработка)
│   └── #finance (финансы)
└── Полная изоляция данных

beta.chat.bau-portal.online (Партнер Б)
├── Команда "Beta Corp"
│   └── Аналогичная структура
└── Полная изоляция данных
```

### Преимущества:
- ✅ **100% приватность** - отдельные базы данных
- ✅ **Доверие партнеров** - они контролируют свои данные
- ✅ **Единое приложение** - переключение между серверами
- ✅ **Масштабируемость** - легко добавлять партнеров

## 📋 9. Чек-лист готовности

### Графические материалы:
- [ ] Логотип Bau-Portal (SVG, PNG)
- [ ] Иконки приложения (все размеры)
- [ ] Favicon для веб-сайта
- [ ] Splash screen для мобильных

### Сертификаты и ключи:
- [ ] SSL сертификаты для доменов
- [ ] Apple Developer Certificate
- [ ] Firebase Service Account Key
- [ ] Push Notification certificates

### Домены и DNS:
- [ ] chat.bau-portal.online → веб-приложение
- [ ] push.bau-portal.online → push proxy
- [ ] *.chat.bau-portal.online → партнерские инстансы

### Тестирование:
- [ ] Веб-приложение в браузере
- [ ] Push уведомления (iOS/Android)
- [ ] Мобильные приложения
- [ ] Переключение между серверами
- [ ] Федеративная архитектура

## 🔧 10. Команды управления

### Основные команды:
```bash
# Полная сборка системы
./scripts/build-bau-portal.sh

# Сборка с мобильными приложениями
./scripts/build-bau-portal.sh --mobile ios
./scripts/build-bau-portal.sh --mobile android

# Управление сервисами
docker-compose -f docker-compose.bau-portal.yml up -d    # Запуск
docker-compose -f docker-compose.bau-portal.yml down     # Остановка
docker-compose -f docker-compose.bau-portal.yml ps       # Статус
docker-compose -f docker-compose.bau-portal.yml logs -f  # Логи

# Обновление системы
git pull
./scripts/build-bau-portal.sh
docker-compose -f docker-compose.bau-portal.yml restart
```

### Мониторинг:
```bash
# Проверка доступности
curl -I https://chat.bau-portal.online
curl -I https://push.bau-portal.online

# Проверка push-сервера
curl -X POST https://push.bau-portal.online/api/v1/send \
  -H "Content-Type: application/json" \
  -d '{"test": true}'

# Логи в реальном времени
docker-compose -f docker-compose.bau-portal.yml logs -f bau-portal-web
docker-compose -f docker-compose.bau-portal.yml logs -f bau-portal-push-proxy
```

## 🎯 11. Следующие шаги

1. **Создать графические материалы** (логотипы, иконки)
2. **Получить необходимые сертификаты** (SSL, Apple, Firebase)
3. **Настроить DNS записи** для доменов
4. **Протестировать систему** локально
5. **Развернуть на продакшн сервере**
6. **Подготовить мобильные приложения** к публикации
7. **Создать документацию** для партнеров
8. **Настроить мониторинг** и резервное копирование

---

**Результат**: Полностью брендированная система Bau-Portal с мобильными приложениями, собственными push-уведомлениями и федеративной архитектурой для безопасного общения строительных партнеров.