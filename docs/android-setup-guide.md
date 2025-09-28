# Android Google Play Setup Guide для Bau-Portal

## 1. Настройка Firebase

### A. Создание проекта
```bash
1. https://console.firebase.google.com
2. Create Project → "Bau-Portal"
3. Enable Google Analytics (optional)
4. Continue
```

### B. Добавление Android App
```bash
1. Project Overview → Add app → Android
2. Package name: com.bauportal.mobile
3. App nickname: Bau-Portal
4. Debug signing certificate SHA-1: (optional)
5. Register app
```

### C. Скачивание конфигурации
```bash
1. Download google-services.json
2. Поместить в: mattermost-mobile/android/app/google-services.json
```

### D. Настройка Cloud Messaging
```bash
1. Project Settings → Cloud Messaging
2. Server key: Скопировать для push-proxy
3. Sender ID: Записать
```

## 2. Настройка Android проекта

### A. Изменение Package Name
```gradle
// android/app/build.gradle
android {
    defaultConfig {
        applicationId "com.bauportal.mobile"
        versionCode 1
        versionName "1.0.0"
        // ...
    }
}
```

### B. Настройка подписи приложения
```gradle
// android/app/build.gradle
android {
    signingConfigs {
        release {
            storeFile file('bau-portal-release-key.keystore')
            storePassword 'YOUR_STORE_PASSWORD'
            keyAlias 'bau-portal-key-alias'
            keyPassword 'YOUR_KEY_PASSWORD'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### C. Создание Keystore
```bash
cd android/app
keytool -genkey -v -keystore bau-portal-release-key.keystore -alias bau-portal-key-alias -keyalg RSA -keysize 2048 -validity 10000

# Сохранить пароли в безопасном месте!
```

### D. Обновление иконок
```bash
# Заменить файлы в:
android/app/src/main/res/mipmap-*/ic_launcher.png
android/app/src/main/res/mipmap-*/ic_launcher_round.png

# Размеры:
mipmap-mdpi: 48x48
mipmap-hdpi: 72x72
mipmap-xhdpi: 96x96
mipmap-xxhdpi: 144x144
mipmap-xxxhdpi: 192x192
```

## 3. Сборка Release APK/AAB

### A. Сборка APK
```bash
cd mattermost-mobile
./gradlew assembleRelease

# Результат: android/app/build/outputs/apk/release/app-release.apk
```

### B. Сборка App Bundle (рекомендуется)
```bash
./gradlew bundleRelease

# Результат: android/app/build/outputs/bundle/release/app-release.aab
```

### C. Проверка подписи
```bash
# Для APK:
jarsigner -verify -verbose -certs android/app/build/outputs/apk/release/app-release.apk

# Для AAB:
bundletool validate --bundle=android/app/build/outputs/bundle/release/app-release.aab
```

## 4. Настройка Google Play Console

### A. Создание аккаунта разработчика
```bash
1. https://play.google.com/console
2. Регистрация ($25 единоразово)
3. Подтверждение личности
4. Принятие соглашения
```

### B. Создание приложения
```bash
1. Create app
2. App name: Bau-Portal
3. Default language: Russian / English
4. App or game: App
5. Free or paid: Free
6. User program policies: Accept
7. Create app
```

### C. Настройка App content
```bash
1. Privacy Policy: https://bau-portal.online/privacy
2. App access: All functionality available without restrictions
3. Content rating: Fill questionnaire
4. Target audience: 18+ (Business app)
5. News app: No
6. COVID-19 contact tracing: No
7. Data safety: Fill form about data collection
```

## 5. Подготовка метаданных

### A. Store listing
```
App name: Bau-Portal
Short description: Secure communication platform for construction partners
Full description:
"Bau-Portal is a secure communication platform designed specifically for construction industry partners. 
Connect with your team, share project updates, and collaborate efficiently with advanced security features.

Features:
• Secure messaging and file sharing
• Team collaboration tools
• Push notifications
• Multi-server support
• End-to-end encryption
• Project-based channels

Perfect for construction companies, architects, contractors, and project managers who need reliable and secure communication."

App icon: 512x512 PNG
Feature graphic: 1024x500 PNG
```

### B. Screenshots
```
Phone screenshots (минимум 2, максимум 8):
- 16:9 или 9:16 aspect ratio
- Минимум 320px
- Максимум 3840px

Tablet screenshots (опционально):
- 7" tablet: минимум 320px
- 10" tablet: минимум 320px

Wear OS screenshots (если поддерживается):
- 384x384 или круглые
```

### C. Ключевые слова и категория
```
Category: Business
Tags: communication, construction, team, collaboration, secure, messaging
```

## 6. Загрузка и тестирование

### A. Upload App Bundle
```bash
1. Play Console → Your App → Release → Production
2. Create new release
3. Upload app-release.aab
4. Release name: 1.0.0
5. Release notes: "Initial release of Bau-Portal"
```

### B. Internal Testing (рекомендуется)
```bash
1. Release → Testing → Internal testing
2. Create new release
3. Upload AAB
4. Add testers (email addresses)
5. Save → Review release → Start rollout
```

### C. Closed Testing (опционально)
```bash
1. Release → Testing → Closed testing
2. Create track (Alpha/Beta)
3. Upload AAB
4. Add testers or create email list
5. Start rollout
```

## 7. Отправка на проверку

### A. Pre-launch checklist
```bash
□ App Bundle загружен
□ Store listing заполнен
□ Screenshots добавлены
□ Content rating получен
□ Privacy Policy доступна
□ Data safety заполнена
□ Target audience указана
□ App content настроен
□ Pricing & distribution настроен
```

### B. Submit for Review
```bash
1. Release → Production
2. Create new release
3. Upload final AAB
4. Release notes
5. Save → Review release
6. Start rollout to production
```

## 8. Статусы и время проверки

### A. Статусы
```
Under review → Approved → Publishing → Published
            ↓
        Rejected (если есть проблемы)
```

### B. Время проверки
```
- Первая публикация: 1-3 дня
- Обновления: несколько часов
- Если есть нарушения: может потребоваться больше времени
```

## 9. После публикации

### A. Мониторинг
```bash
1. Play Console → Statistics
2. Crash reports & ANRs
3. User feedback
4. Performance metrics
```

### B. Обновления
```bash
1. Увеличить versionCode в build.gradle
2. Обновить versionName
3. Собрать новый AAB
4. Upload в Production
5. Add release notes
6. Start rollout
```

## 10. Настройка Push Notifications

### A. Service Account Key
```bash
1. Firebase Console → Project Settings
2. Service accounts → Generate new private key
3. Download JSON file
4. Поместить в: mattermost-push-proxy/certs/bau-portal-firebase-service-account.json
```

### B. Обновление Push Proxy конфигурации
```json
{
    "AndroidPushSettings": [
        {
            "Type": "android_rn",
            "ServiceFileLocation": "./certs/bau-portal-firebase-service-account.json"
        }
    ]
}
```
