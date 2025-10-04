# 🚀 Задача: Добавление OIDC и LDAP Group Sync в Mattermost Team Edition

> **Для AI-ассистента специалиста по Go/React/Mattermost разработке**

---

## 🎯 Цель проекта

Добавить **Enterprise функции** в **Team Edition** Mattermost без использования проприетарного Enterprise кода:

1. **OIDC/OAuth2 SSO** с Keycloak
2. **LDAP Group Sync** для автоматического управления Teams
3. **Auto-create Teams** на основе LDAP групп
4. Сохранить **кастомный брендинг** Bau-Portal

---

## 📋 Текущее состояние

### Что работает:
- ✅ **Кастомная сборка** с брендингом Bau-Portal
- ✅ **Webapp** собран с кастомными логотипами
- ✅ **Server** собран для Linux ARM64 и macOS
- ✅ **PostgreSQL** интеграция работает
- ✅ **Базовый функционал** Team Edition

### Что НЕ работает:
- ❌ **SAML SSO** (требует Enterprise)
- ❌ **LDAP Group Sync** (требует Enterprise)
- ❌ **MFA** (требует Enterprise)
- ❌ **Auto-create Teams** (нет такой функции)

### Текущая сборка:
```bash
Version: 11.0.0
Build Number: dev
Build Hash: f5084f055c693a4e34bcc74beca192dfe6d5af7f
Build Enterprise Ready: false  # ❌ Enterprise функции отключены
```

---

## 🏗️ Архитектура решения

### Целевая архитектура SSO:

```
Пользователь
  ↓ 1. Открывает Mattermost
Mattermost (кастомный)
  ↓ 2. Redirect to Keycloak (OIDC)
Keycloak
  ↓ 3. Проверка в LDAP
LLDAP
  ↓ 4. OK → Return JWT token с группами
Mattermost
  ↓ 5. Auto-create аккаунт + добавить в Teams по группам
Пользователь в Mattermost
```

### Компоненты для реализации:

1. **OIDC Provider** — интеграция с Keycloak
2. **LDAP Groups Mapper** — чтение групп из токена
3. **Teams Auto-Manager** — создание/добавление в Teams
4. **User Provisioning** — создание аккаунтов

---

## 🔧 Технические требования

### Исходный код:
- **Репозиторий:** `/Users/vitaly/Development/mattermost`
- **Версия:** Форк официального Mattermost 11.0.0
- **Ветка:** `Deploy-Mattermost-accessories`
- **Кастомизации:** Брендинг Bau-Portal (логотипы, тексты)

### Команды сборки:

```bash
# Переход в директорию
cd /Users/vitaly/Development/mattermost

# Сборка webapp (с кастомным брендингом)
cd webapp && make dist

# Сборка server для разных архитектур
cd ../server
make setup-go-work                    # Настройка Go workspace
make build                           # macOS (для тестирования)
GOOS=linux GOARCH=arm64 make build   # Linux ARM64 (для сервера)

# Создание пакета
make package-prep                    # Подготовка
make package-linux                   # Создание tar.gz

# Результат:
# server/dist/mattermost-team-linux-arm64.tar.gz
```

### Зависимости:
- **Go:** 1.25+ (установлен)
- **Node.js:** 20+ (установлен)
- **PostgreSQL:** для тестирования (установлен)
- **Docker:** для контейнеризации

---

## 📝 Задачи для реализации

### Задача 1: OIDC Provider для Keycloak

**Цель:** Добавить поддержку OpenID Connect для интеграции с Keycloak

**Где реализовать:**
- `server/channels/app/oauth.go` — добавить OIDC провайдер
- `server/channels/api4/oauth.go` — API endpoints для OIDC
- `webapp/channels/src/components/login/` — кнопка "Login with Keycloak"

**Конфигурация (environment variables):**
```bash
MM_OIDCSETTINGS_ENABLE=true
MM_OIDCSETTINGS_DISCOVERY_ENDPOINT=https://auth.ceramir.online/realms/ceramir/.well-known/openid-configuration
MM_OIDCSETTINGS_CLIENT_ID=mattermost
MM_OIDCSETTINGS_CLIENT_SECRET=your_client_secret
MM_OIDCSETTINGS_SCOPES=openid,email,profile,groups
```

**Ожидаемый результат:**
- Кнопка "Login with Keycloak" на странице входа
- Redirect на Keycloak для аутентификации
- Получение JWT токена с пользовательскими данными и группами
- Auto-create аккаунта при первом входе

---

### Задача 2: LDAP Groups Mapper

**Цель:** Извлечение групп из JWT токена Keycloak и маппинг на Mattermost Teams

**Где реализовать:**
- `server/channels/app/user.go` — функция обработки OIDC callback
- `server/channels/app/team.go` — функции управления Teams
- Новый файл `server/channels/app/ldap_groups.go` — логика группового маппинга

**Логика:**
```go
// Псевдокод
func ProcessOIDCGroups(user *model.User, groups []string) error {
    for _, groupName := range groups {
        teamName := mapGroupToTeam(groupName) // sales -> Sales Team
        team := findOrCreateTeam(teamName)
        addUserToTeam(user, team)
    }
}
```

**Конфигурация:**
```bash
MM_LDAPGROUPSYNC_ENABLE=true
MM_LDAPGROUPSYNC_AUTOCREATE_TEAMS=true
MM_LDAPGROUPSYNC_GROUP_MAPPING=sales:Sales Team,developers:Dev Team
```

**Ожидаемый результат:**
- Группы из Keycloak JWT автоматически создают Teams
- Пользователи добавляются в Teams на основе групп
- Синхронизация при каждом входе

---

### Задача 3: Teams Auto-Manager

**Цель:** Автоматическое создание и управление Teams на основе LDAP групп

**Где реализовать:**
- `server/channels/app/team.go` — расширить функции создания Teams
- `server/channels/api4/team.go` — API для автоматического управления
- Новый файл `server/channels/app/team_provisioning.go`

**Функции:**
```go
func AutoCreateTeamFromGroup(groupName string) (*model.Team, error)
func SyncUserTeamMembership(user *model.User, groups []string) error
func RemoveUserFromTeams(user *model.User, removedGroups []string) error
```

**Конфигурация:**
```bash
MM_TEAMPROVISIONING_ENABLE=true
MM_TEAMPROVISIONING_NAMING_PATTERN={group} Team  # sales -> Sales Team
MM_TEAMPROVISIONING_DEFAULT_TYPE=O              # Open team
MM_TEAMPROVISIONING_AUTO_REMOVE=true           # Удалять из Teams при удалении из группы
```

---

### Задача 4: User Provisioning Enhancement

**Цель:** Улучшить создание пользователей при первом OIDC входе

**Где реализовать:**
- `server/channels/app/user.go` — функция `CreateOAuthUser`
- `server/channels/app/oauth.go` — обработка OIDC callback

**Дополнительные атрибуты из Keycloak:**
```go
type OIDCUser struct {
    Email       string   `json:"email"`
    FirstName   string   `json:"given_name"`
    LastName    string   `json:"family_name"`
    Username    string   `json:"preferred_username"`
    Groups      []string `json:"groups"`
    Roles       []string `json:"roles"`
    Department  string   `json:"department"`
    Position    string   `json:"position"`
}
```

---

## 🔧 Детальная реализация

### 1. Добавление OIDC провайдера

**Файл:** `server/channels/app/oauth.go`

```go
// Добавить новый провайдер
const (
    SERVICE_KEYCLOAK = "keycloak"
)

func (a *App) AuthorizeOAuthUser(service, code, state, redirectUri string) (*model.User, error) {
    switch service {
    case SERVICE_KEYCLOAK:
        return a.AuthorizeKeycloakUser(code, state, redirectUri)
    // ... existing providers
    }
}

func (a *App) AuthorizeKeycloakUser(code, state, redirectUri string) (*model.User, error) {
    // Реализация OIDC flow с Keycloak
    // 1. Exchange code for token
    // 2. Verify JWT token
    // 3. Extract user info and groups
    // 4. Create or update user
    // 5. Process group membership
}
```

### 2. Конфигурация OIDC

**Файл:** `server/public/model/config.go`

```go
type ServiceSettings struct {
    // ... existing fields
    KeycloakSettings *KeycloakSettings
}

type KeycloakSettings struct {
    Enable           *bool   `json:"enable"`
    DiscoveryEndpoint *string `json:"discovery_endpoint"`
    ClientId         *string `json:"client_id"`
    ClientSecret     *string `json:"client_secret"`
    Scopes           *string `json:"scopes"`
    UserApiEndpoint  *string `json:"user_api_endpoint"`
    AuthEndpoint     *string `json:"auth_endpoint"`
    TokenEndpoint    *string `json:"token_endpoint"`
}
```

### 3. Frontend интеграция

**Файл:** `webapp/channels/src/components/login/login.tsx`

```tsx
// Добавить кнопку OIDC
const handleKeycloakLogin = () => {
    window.location.href = `/oauth/keycloak/login?redirect_to=${redirectTo}`;
};

<button 
    onClick={handleKeycloakLogin}
    className="btn btn-primary"
>
    Login with Keycloak
</button>
```

### 4. API Endpoints

**Файл:** `server/channels/api4/oauth.go`

```go
func (api *API) InitOAuth() {
    // ... existing routes
    api.BaseRoutes.OAuth.Handle("/keycloak/login", api.APIHandler(loginWithKeycloak)).Methods("GET")
    api.BaseRoutes.OAuth.Handle("/keycloak/callback", api.APIHandler(keycloakCallback)).Methods("GET")
}
```

---

## 🧪 Тестирование

### Локальное тестирование:

```bash
# 1. Запуск PostgreSQL
brew services start postgresql@14

# 2. Создание тестовой БД
createdb mattermost_test
createuser mmuser

# 3. Запуск Mattermost
cd /Users/vitaly/Development/mattermost/server
./bin/darwin_amd64/mattermost

# 4. Открыть http://localhost:8065
# 5. Проверить наличие кнопки "Login with Keycloak"
```

### Тестирование на сервере:

```bash
# 1. Сборка ARM64 пакета
cd /Users/vitaly/Development/mattermost/server
GOOS=linux GOARCH=arm64 make build
make package-linux

# 2. Результат: dist/mattermost-team-linux-arm64.tar.gz
# 3. Деплой через Ansible роль
```

---

## 📊 Интеграция с существующей архитектурой

### Keycloak Realm Configuration:

**Client ID:** `mattermost`
**Client Type:** `confidential`
**Valid Redirect URIs:** `https://chat.ceramir.online/oauth/keycloak/callback`
**Scopes:** `openid`, `email`, `profile`, `groups`

**Client Scopes Mappers:**
```yaml
groups:
  - Name: groups
  - Mapper Type: Group Membership
  - Token Claim Name: groups
  - Full group path: OFF
  - Add to ID token: ON
  - Add to access token: ON
  - Add to userinfo: ON
```

### LDAP Groups в Keycloak:

**LDAP Federation настроен на:**
- **Server:** ldap://37.27.89.160:3890
- **Base DN:** dc=ceramir,dc=online
- **Groups DN:** ou=groups,dc=ceramir,dc=online

**Группы в LLDAP:**
- `sales` → Mattermost Team "Sales Team"
- `developers` → Mattermost Team "Dev Team"
- `admins` → Mattermost Team "Admins" + System Admin role

---

## 🔒 Требования безопасности

1. **JWT Verification:** Проверка подписи токенов Keycloak
2. **HTTPS Only:** Все OIDC endpoints только через HTTPS
3. **State Parameter:** Защита от CSRF атак
4. **Scope Validation:** Проверка разрешённых scopes
5. **User Validation:** Проверка email verification в Keycloak

---

## 📚 Ресурсы и документация

### Mattermost API:
- [OAuth2 Provider Documentation](https://developers.mattermost.com/integrate/admin-guide/admin-oauth2/)
- [Plugin API Reference](https://developers.mattermost.com/extend/plugins/server/reference/)
- [User Management API](https://api.mattermost.com/#tag/users)
- [Team Management API](https://api.mattermost.com/#tag/teams)

### Keycloak Integration:
- [Keycloak OIDC Documentation](https://www.keycloak.org/docs/latest/securing_apps/#_oidc)
- [JWT Token Format](https://www.keycloak.org/docs/latest/securing_apps/#token-exchange)

### Go Libraries:
- `github.com/coreos/go-oidc/v3/oidc` — OIDC client
- `github.com/golang-jwt/jwt/v4` — JWT parsing
- `github.com/go-ldap/ldap/v3` — LDAP client (если нужен)

---

## 🛠️ Команды для разработки

### Подготовка среды:
```bash
cd /Users/vitaly/Development/mattermost

# Установка зависимостей
go mod tidy

# Настройка workspace
cd server && make setup-go-work
```

### Разработка:
```bash
# Сборка только сервера (быстрая итерация)
cd server
go build -o bin/mattermost ./cmd/mattermost

# Полная сборка с webapp
make build

# Тестирование
go test ./channels/app -v -run TestOIDC
```

### Сборка для продакшена:
```bash
# Webapp
cd webapp && make dist

# Server Linux ARM64 (для сервера Hetzner)
cd ../server
GOOS=linux GOARCH=arm64 make build

# Создание пакета
make package-prep
make package-linux

# Результат: server/dist/mattermost-team-linux-arm64.tar.gz
```

### Docker образ:
```bash
# Сборка кастомного образа
docker build -t bau-portal/mattermost:latest .

# Тестирование
docker run -p 8065:8065 \
  -e MM_SERVICESETTINGS_SITEURL=http://localhost:8065 \
  -e MM_SQLSETTINGS_DRIVERNAME=postgres \
  -e MM_SQLSETTINGS_DATASOURCE="postgres://user:pass@host/db" \
  bau-portal/mattermost:latest
```

---

## 🎯 Приоритеты реализации

### Фаза 1: Базовый OIDC (критично)
1. Добавить OIDC провайдер в backend
2. Добавить кнопку входа в frontend
3. Реализовать callback обработку
4. Тестирование с Keycloak

### Фаза 2: Groups Integration
1. Извлечение групп из JWT токена
2. Маппинг групп на Teams
3. Auto-create Teams
4. Синхронизация членства

### Фаза 3: Advanced Features
1. Role mapping (groups → system roles)
2. Channel auto-assignment
3. User deprovisioning
4. Audit logging

---

## 🔍 Исследование существующего кода

### OAuth провайдеры в Mattermost:
```bash
# Поиск существующих OAuth провайдеров
grep -r "SERVICE_" server/channels/app/oauth.go
grep -r "OAuth" server/channels/app/ | grep -i "google\|office365\|gitlab"
```

### LDAP код (Team Edition):
```bash
# Поиск LDAP функций
grep -r "LDAP" server/channels/app/ | grep -v "_test.go"
grep -r "ldap" server/public/model/config.go
```

### Существующие API endpoints:
```bash
# OAuth endpoints
grep -r "/oauth/" server/channels/api4/
grep -r "oauth" server/channels/web/
```

---

## 📋 Конфигурационный файл

### Environment Variables для OIDC:

```bash
# OIDC Settings
export MM_OIDCSETTINGS_ENABLE=true
export MM_OIDCSETTINGS_DISCOVERY_ENDPOINT="https://auth.ceramir.online/realms/ceramir/.well-known/openid-configuration"
export MM_OIDCSETTINGS_CLIENT_ID="mattermost"
export MM_OIDCSETTINGS_CLIENT_SECRET="your_secret_here"
export MM_OIDCSETTINGS_SCOPES="openid email profile groups"
export MM_OIDCSETTINGS_USER_API_ENDPOINT="https://auth.ceramir.online/realms/ceramir/protocol/openid-connect/userinfo"
export MM_OIDCSETTINGS_AUTH_ENDPOINT="https://auth.ceramir.online/realms/ceramir/protocol/openid-connect/auth"
export MM_OIDCSETTINGS_TOKEN_ENDPOINT="https://auth.ceramir.online/realms/ceramir/protocol/openid-connect/token"

# Groups Sync Settings
export MM_LDAPGROUPSYNC_ENABLE=true
export MM_LDAPGROUPSYNC_AUTOCREATE_TEAMS=true
export MM_LDAPGROUPSYNC_GROUP_CLAIM="groups"
export MM_LDAPGROUPSYNC_TEAM_NAME_TEMPLATE="{group} Team"
export MM_LDAPGROUPSYNC_ADMIN_GROUPS="admins"

# Team Provisioning
export MM_TEAMPROVISIONING_ENABLE=true
export MM_TEAMPROVISIONING_DEFAULT_TYPE="O"  # Open
export MM_TEAMPROVISIONING_AUTO_REMOVE=true
```

---

## 🎨 Сохранение брендинга

### Кастомизации Bau-Portal:

**Логотипы:**
- `webapp/channels/src/images/bau-portal-logo.svg` ✅ Создан
- `webapp/channels/src/images/bau-portal-logo-no-text.svg` ✅ Создан

**Компоненты:**
- `webapp/channels/src/components/widgets/icons/mattermost_logo.tsx` ✅ Изменён
- Тексты интерфейса в `webapp/channels/src/i18n/en.json` ✅ Изменены

**При добавлении OIDC сохранить:**
- Логотип на странице входа
- Название "Bau-Portal" вместо "Mattermost"
- Кастомные цвета и стили

---

## 🚀 Ожидаемый результат

### После реализации:

**Функциональность:**
- ✅ **Single Sign-On** через Keycloak
- ✅ **Auto-create аккаунтов** при первом входе
- ✅ **Auto-create Teams** на основе LDAP групп
- ✅ **Синхронизация групп** при каждом входе
- ✅ **Кастомный брендинг** Bau-Portal

**Workflow пользователя:**
1. Открывает https://chat.ceramir.online
2. Нажимает "Login with Keycloak"
3. Вводит пароль в Keycloak
4. Автоматически попадает в Mattermost
5. Автоматически добавляется в Teams по группам LDAP

**Управление:**
- Администратор создаёт пользователей в LLDAP
- Добавляет в группы (sales, developers, admins)
- Mattermost автоматически создаёт Teams и добавляет пользователей

---

## 📞 Контакты и поддержка

**Проект:** Bau-Portal.online  
**Репозиторий:** `/Users/vitaly/Development/mattermost`  
**Ветка:** `Deploy-Mattermost-accessories`  
**Архитектор:** Vitaly Andrianov  

**Интеграция с:**
- **Keycloak:** https://auth.ceramir.online
- **LLDAP:** https://ldap.ceramir.online  
- **MailCow:** https://mail.ceramir.online
- **oCIS:** https://files.ceramir.online

---

**Дата создания:** 5 октября 2025  
**Версия:** 1.0  
**Статус:** Готов к реализации
