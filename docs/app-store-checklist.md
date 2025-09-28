# Чек-лист публикации Bau-Portal в App Store и Google Play

## 🎨 1. Графические материалы

### A. Иконки приложения
- [ ] **iOS**: 1024x1024 PNG (App Store)
- [ ] **iOS**: 20x20, 29x29, 40x40, 60x60 (@2x, @3x)
- [ ] **Android**: 512x512 PNG (Play Store)
- [ ] **Android**: 48x48, 72x72, 96x96, 144x144, 192x192

### B. Скриншоты
- [ ] **iOS iPhone**: 1290x2796 (6.7"), 1242x2688 (6.5"), 1242x2208 (5.5")
- [ ] **iOS iPad**: 2048x2732 (12.9"), 1668x2388 (11")
- [ ] **Android Phone**: минимум 320px, соотношение 16:9 или 9:16
- [ ] **Android Tablet**: опционально

### C. Дополнительные материалы
- [ ] **Feature Graphic** (Android): 1024x500 PNG
- [ ] **Launch Screen** (iOS): обновить в Storyboard
- [ ] **Splash Screen** (Android): обновить в drawable

## 🔐 2. Сертификаты и ключи

### A. Apple Developer
- [ ] **Apple Developer Account**: $99/год
- [ ] **App ID**: com.bauportal.mobile
- [ ] **Push Certificate** или **AuthKey**: для уведомлений
- [ ] **Provisioning Profile**: Development и Distribution
- [ ] **Distribution Certificate**: для подписи

### B. Google Play
- [ ] **Google Play Console**: $25 единоразово
- [ ] **Keystore файл**: для подписи Android APK/AAB
- [ ] **Firebase Project**: для push уведомлений
- [ ] **google-services.json**: конфигурация Firebase
- [ ] **Service Account Key**: JSON для push-proxy

## 📱 3. Настройка приложений

### A. iOS (Xcode)
- [ ] **Bundle ID**: com.bauportal.mobile
- [ ] **Display Name**: Bau-Portal
- [ ] **Version**: 1.0.0
- [ ] **Build Number**: 1
- [ ] **Team**: выбрать Developer Team
- [ ] **Capabilities**: Push Notifications, Background App Refresh
- [ ] **Icons**: заменить в Assets.xcassets
- [ ] **Launch Screen**: обновить дизайн

### B. Android (Android Studio)
- [ ] **Package Name**: com.bauportal.mobile
- [ ] **App Name**: Bau-Portal (в strings.xml)
- [ ] **Version Code**: 1
- [ ] **Version Name**: 1.0.0
- [ ] **Signing Config**: настроить keystore
- [ ] **Firebase**: добавить google-services.json
- [ ] **Icons**: заменить в mipmap-*
- [ ] **Permissions**: проверить в AndroidManifest.xml

## 🌐 4. Серверная инфраструктура

### A. Домены и SSL
- [ ] **chat.bau-portal.online**: основной сервер
- [ ] **push.bau-portal.online**: push proxy сервер
- [ ] **SSL сертификаты**: для обоих доменов
- [ ] **DNS записи**: A/CNAME записи настроены

### B. Push Proxy
- [ ] **Конфигурация**: bau-portal-push-proxy.json
- [ ] **Apple AuthKey**: размещен в ./certs/
- [ ] **Firebase Service Account**: JSON файл в ./certs/
- [ ] **Сервер запущен**: доступен по HTTPS

## 📝 5. Метаданные приложений

### A. App Store Connect
- [ ] **App Name**: Bau-Portal
- [ ] **Subtitle**: Secure Communication Platform
- [ ] **Description**: подробное описание
- [ ] **Keywords**: communication, construction, team, secure
- [ ] **Category**: Business
- [ ] **Privacy Policy**: https://bau-portal.online/privacy
- [ ] **Support URL**: https://bau-portal.online/support
- [ ] **Marketing URL**: https://bau-portal.online

### B. Google Play Console
- [ ] **App Name**: Bau-Portal
- [ ] **Short Description**: краткое описание (80 символов)
- [ ] **Full Description**: полное описание
- [ ] **Category**: Business
- [ ] **Content Rating**: получить рейтинг
- [ ] **Privacy Policy**: URL политики
- [ ] **Data Safety**: заполнить форму

## 🧪 6. Тестирование

### A. Функциональное тестирование
- [ ] **Регистрация/Вход**: работает корректно
- [ ] **Push уведомления**: приходят на устройство
- [ ] **Переключение серверов**: работает в приложении
- [ ] **Отправка сообщений**: текст, файлы, изображения
- [ ] **Каналы и команды**: создание, присоединение
- [ ] **Настройки**: профиль, уведомления, темы

### B. Техническое тестирование
- [ ] **Производительность**: быстрый запуск, плавная работа
- [ ] **Память**: нет утечек памяти
- [ ] **Батарея**: оптимальное потребление
- [ ] **Сеть**: работа при плохом соединении
- [ ] **Краши**: отсутствие критических ошибок
- [ ] **Совместимость**: разные версии iOS/Android

### C. Beta тестирование
- [ ] **TestFlight** (iOS): добавить тестеров
- [ ] **Internal Testing** (Android): закрытое тестирование
- [ ] **Feedback**: собрать отзывы тестеров
- [ ] **Bug fixes**: исправить найденные проблемы

## 📋 7. Документация

### A. Пользовательская документация
- [ ] **Privacy Policy**: политика конфиденциальности
- [ ] **Terms of Service**: условия использования
- [ ] **User Guide**: руководство пользователя
- [ ] **FAQ**: часто задаваемые вопросы
- [ ] **Support Contact**: контакты поддержки

### B. Техническая документация
- [ ] **API Documentation**: документация API
- [ ] **Server Setup**: инструкции по настройке
- [ ] **Troubleshooting**: решение проблем
- [ ] **Update Guide**: инструкции по обновлению

## 🚀 8. Процесс публикации

### A. iOS App Store
- [ ] **Archive Build**: создать в Xcode
- [ ] **Validate**: проверить архив
- [ ] **Upload**: загрузить в App Store Connect
- [ ] **Metadata**: заполнить все поля
- [ ] **Screenshots**: загрузить все размеры
- [ ] **Submit for Review**: отправить на проверку
- [ ] **Monitor Status**: отслеживать статус проверки

### B. Google Play Store
- [ ] **Build AAB**: создать App Bundle
- [ ] **Upload**: загрузить в Play Console
- [ ] **Store Listing**: заполнить описание
- [ ] **Content Rating**: получить рейтинг
- [ ] **Pricing**: настроить цену и доступность
- [ ] **Release**: опубликовать в Production

## ⏰ 9. Временные рамки

### A. Подготовка (1-2 недели)
- Создание графических материалов
- Настройка сертификатов и ключей
- Конфигурация приложений
- Подготовка серверов

### B. Тестирование (1 неделя)
- Внутреннее тестирование
- Beta тестирование
- Исправление багов
- Финальная проверка

### C. Публикация (2-7 дней)
- iOS: 24-48 часов на проверку
- Android: 1-3 дня на проверку
- Возможные доработки по замечаниям

## 💰 10. Затраты

### A. Обязательные платежи
- [ ] **Apple Developer**: $99/год
- [ ] **Google Play Console**: $25 единоразово
- [ ] **SSL сертификаты**: $50-200/год
- [ ] **Домены**: $10-50/год

### B. Опциональные затраты
- [ ] **Дизайн иконок**: $100-500
- [ ] **Скриншоты**: $200-1000
- [ ] **Копирайтинг**: $100-300
- [ ] **Тестирование**: $500-2000

## 📞 11. Контакты и поддержка

### A. Службы поддержки
- [ ] **Apple Developer Support**: для iOS вопросов
- [ ] **Google Play Support**: для Android вопросов
- [ ] **Firebase Support**: для push уведомлений
- [ ] **SSL Provider Support**: для сертификатов

### B. Внутренние контакты
- [ ] **Technical Lead**: ответственный за техническую часть
- [ ] **Design Lead**: ответственный за дизайн
- [ ] **QA Lead**: ответственный за тестирование
- [ ] **Product Manager**: общее управление проектом

---

## 🎯 Итоговый чек-лист перед публикацией

- [ ] Все графические материалы готовы
- [ ] Сертификаты и ключи настроены
- [ ] Приложения собраны и подписаны
- [ ] Серверы работают стабильно
- [ ] Push уведомления функционируют
- [ ] Тестирование завершено успешно
- [ ] Метаданные заполнены полностью
- [ ] Документация подготовлена
- [ ] Команда готова к поддержке
- [ ] Бюджет на публикацию выделен

**Готово к публикации!** 🚀
