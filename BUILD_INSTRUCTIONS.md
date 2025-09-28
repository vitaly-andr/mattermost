# 🏗️ Инструкция по сборке Bau-Portal

## ⚠️ ВАЖНО: Используйте ТОЛЬКО официальные команды Mattermost!

Предыдущие попытки с кастомными docker-compose и скриптами были **неправильными**. 

## 🎯 Правильный способ сборки

### 1. Официальная сборка
```bash
# Запустите официальный скрипт сборки:
./scripts/build-production.sh
```

### 2. Что делает скрипт:
- ✅ Проверяет зависимости (Go, Node.js, Make)
- ✅ Собирает webapp через `make dist` (официально)
- ✅ Собирает server через `make build-linux` (официально)  
- ✅ Создает дистрибутив через `make package-linux` (официально)
- ✅ Кастомизирует конфигурацию для Bau-Portal
- ✅ Создает Docker образ (опционально)

### 3. Результат:
```
server/dist/mattermost-team-linux-amd64.tar.gz  # Готовый пакет
server/dist/mattermost/                         # Распакованная версия  
bau-portal:latest                               # Docker образ
```

### 4. Развертывание:
```bash
# Прямое развертывание:
tar -xzf server/dist/mattermost-team-linux-amd64.tar.gz
cd mattermost
./bin/mattermost

# Или Docker:
docker run -p 8065:8065 bau-portal:latest
```

## 📚 Дополнительная документация:

- `docs/official-build-guide.md` - Подробная инструкция
- `docs/ios-setup-guide.md` - Настройка iOS приложения
- `docs/android-setup-guide.md` - Настройка Android приложения
- `docs/app-store-checklist.md` - Чек-лист публикации

## 🚫 НЕ используйте:

- ❌ Кастомные docker-compose файлы
- ❌ Самодельные скрипты сборки
- ❌ Неофициальные Dockerfile

**Используйте только официальные команды Mattermost!**
