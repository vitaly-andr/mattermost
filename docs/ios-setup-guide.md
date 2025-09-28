# iOS App Store Setup Guide для Bau-Portal

## 1. Настройка проекта в Xcode

### A. Основные настройки
```bash
# Открыть проект
cd /Users/vitaly/Development/mattermost/mattermost-mobile/ios
open Mattermost.xcworkspace
```

### B. Изменение Bundle Identifier
1. Select project "Mattermost" в Navigator
2. Target "Mattermost" → General
3. Bundle Identifier: `com.bauportal.mobile`
4. Display Name: `Bau-Portal`
5. Version: `1.0.0`
6. Build: `1`

### C. Настройка Team и Signing
1. Signing & Capabilities
2. Team: Выберите вашу команду разработчика
3. Provisioning Profile: Automatic / Manual
4. Signing Certificate: iOS Distribution

### D. Добавление Capabilities
1. + Capability
2. Push Notifications ✅
3. Background App Refresh ✅
4. App Groups (если нужно) ✅

### E. Настройка иконок
1. Assets.xcassets → AppIcon
2. Заменить все размеры иконок:
   - 20x20, 29x29, 40x40, 60x60 (@2x, @3x)
   - 1024x1024 (App Store)

### F. Настройка Launch Screen
1. LaunchScreen.storyboard
2. Заменить логотип Mattermost на Bau-Portal
3. Изменить цвета и текст

## 2. Сборка для App Store

### A. Archive Build
```bash
# В Xcode:
1. Product → Scheme → Edit Scheme
2. Run → Build Configuration → Release
3. Archive → Build Configuration → Release
4. Product → Archive
```

### B. Validate Archive
```bash
# В Organizer:
1. Archives → Select your archive
2. Validate App
3. Выберите Distribution Certificate
4. Выберите Provisioning Profile
5. Wait for validation
```

### C. Upload to App Store Connect
```bash
# В Organizer:
1. Distribute App
2. App Store Connect
3. Upload
4. Select Distribution Certificate
5. Upload
```

## 3. Настройка в App Store Connect

### A. Создание приложения
```
1. https://appstoreconnect.apple.com
2. My Apps → + → New App
3. Platform: iOS
4. Name: Bau-Portal
5. Primary Language: Russian / English
6. Bundle ID: com.bauportal.mobile
7. SKU: bau-portal-ios
```

### B. Заполнение метаданных
```
App Information:
- Name: Bau-Portal
- Subtitle: Secure Communication Platform
- Category: Business / Productivity
- Content Rights: No

Pricing:
- Price: Free
- Availability: All countries

App Privacy:
- Privacy Policy URL: https://bau-portal.online/privacy
- User Privacy Choices URL: (optional)
```

### C. Подготовка скриншотов
```
Размеры для iPhone:
- 6.7" Display (iPhone 14 Pro Max): 1290 x 2796
- 6.5" Display (iPhone 11 Pro Max): 1242 x 2688
- 5.5" Display (iPhone 8 Plus): 1242 x 2208

Размеры для iPad:
- 12.9" Display (iPad Pro): 2048 x 2732
- 11" Display (iPad Pro): 1668 x 2388
```

### D. App Review Information
```
Contact Information:
- First Name: [Ваше имя]
- Last Name: [Ваша фамилия]
- Phone: [Ваш телефон]
- Email: [Ваш email]

Demo Account (если нужно):
- Username: demo@bau-portal.online
- Password: [демо пароль]

Notes:
"Bau-Portal is a secure communication platform for construction partners. 
The app connects to chat.bau-portal.online server and requires user registration."
```

## 4. Отправка на проверку

### A. Финальная проверка
```bash
# Checklist:
□ Все метаданные заполнены
□ Скриншоты загружены (все размеры)
□ Описание приложения написано
□ Ключевые слова добавлены
□ Иконка приложения установлена
□ Build загружен и обработан
□ Privacy Policy доступна
□ Тестовый аккаунт создан (если нужно)
```

### B. Submit for Review
```bash
1. App Store Connect → Your App
2. iOS App → [Version] → Submit for Review
3. Export Compliance: No (если не используете шифрование)
4. Content Rights: No
5. Advertising Identifier: No (если не используете рекламу)
6. Submit
```

## 5. Статусы проверки

```
Waiting For Review → In Review → Pending Developer Release → Ready for Sale
                              ↓
                         Rejected (если есть проблемы)
```

### Время проверки: 24-48 часов

## 6. После одобрения

### A. Release Options
```
1. Automatic Release: Сразу после одобрения
2. Manual Release: Вы контролируете время релиза
3. Scheduled Release: Релиз в определенное время
```

### B. Мониторинг
```
1. App Store Connect → Analytics
2. Crash Reports
3. User Reviews
4. Download Statistics
```
