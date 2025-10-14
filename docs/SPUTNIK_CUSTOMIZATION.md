# 🎨 Sputnik-school Mattermost Customization Guide

## Overview
This document describes all customizations made to Mattermost for Sputnik-school branding.

---

## 🖼️ 1. Logo Customization

### Files Changed:
- **Location**: `webapp/channels/src/images/`

### Logo Files:
1. **`sputnik-logo.png`** (58KB)
   - Full logo with "Sputnik-school" text and "EXPLORE, LEARN, ACHIEVE" tagline
   - Symbol: orbit with 3 dots (satellite theme)
   - Transparent background (using remove.bg)
   - Used in: login page, team selection, headers

2. **`sputnik-logo-no-text.png`** (15KB)
   - Symbol only (orbit with 3 dots)
   - Transparent background
   - Used in: small icons, favicons, compact views

3. **`favicon/favicon.png`** (2.4KB)
   - Browser tab icon
   - Small symbol version

### Source Files:
Original logos located in: `/Users/vitaly/Sputnik/`
- `Sputnik_bw_full-removebg-preview.png` → `sputnik-logo.png`
- `Sputnik_symbol-removebg-preview.png` → `sputnik-logo-no-text.png`

### Code Changes:
**File**: `webapp/channels/src/components/select_team/select_team.tsx`
```typescript
// Line 25: Changed import
import logoImage from 'images/sputnik-logo.png';
```

**File**: `webapp/channels/src/components/linking_landing_page/linking_landing_page.tsx`
```typescript
// Line 13: Changed import
import SputnikLogoImage from 'images/sputnik-logo.png';

// Line 413: Changed usage
<img
    src={SputnikLogoImage}
    className='get-app__logo'
/>
```

---

## 📝 2. Text Branding

### Files Changed:

**File**: `webapp/channels/src/i18n/en.json`
```json
// Line 4930: Changed version text
"navbar_dropdown.versionText": "Sputnik-school - EXPLORE, LEARN, ACHIEVE"
```

**File**: `server/public/model/config.go`
```go
// Line 124: Site name default
TeamSettingsDefaultSiteName = "Sputnik-school"
```

---

## 🎨 3. Custom Theme: "Sputnik"

### Overview:
Added a custom theme with yellow/cream colors matching the Sputnik logo.

### File Changed:
**`webapp/channels/src/packages/mattermost-redux/src/constants/preferences.ts`**

### Theme Configuration:
```typescript
sputnik: {
    type: 'Sputnik',

    // SIDEBAR COLORS (left panel with channels)
    sidebarBg: '#f5e6c8',              // Main yellow/cream background
    sidebarText: '#1f2228',             // Dark text on yellow background
    sidebarUnreadText: '#1f2228',       // Unread channel names (dark)
    sidebarTextHoverBg: '#edd9b5',      // Hover effect (darker yellow)
    sidebarTextActiveBorder: '#e89b0f', // Active channel border (orange)
    sidebarTextActiveColor: '#1f2228',  // Active channel text
    sidebarHeaderBg: '#efd9a8',         // Sidebar header background
    sidebarHeaderTextColor: '#1f2228',  // Sidebar header text
    sidebarTeamBarBg: '#e8ce98',        // Team bar background (top left)

    // STATUS INDICATORS
    onlineIndicator: '#3db887',         // Green dot (online)
    awayIndicator: '#f5ab07',           // Yellow dot (away)
    dndIndicator: '#d24b4e',            // Red dot (do not disturb)

    // MENTIONS & BADGES
    mentionBg: '#e89b0f',               // Background for @mention badges
    mentionBj: '#e89b0f',               // Same as mentionBg
    mentionColor: '#1f2228',            // Text color in mention badges (dark)

    // CENTER CHANNEL (main chat area)
    centerChannelBg: '#fffef9',         // Off-white/cream background
    centerChannelColor: '#1f2228',      // Dark text color
    newMessageSeparator: '#e89b0f',     // Orange line for "New Messages"

    // LINKS & BUTTONS
    linkColor: '#d48806',               // Dark yellow/orange links
    buttonBg: '#e89b0f',                // Orange button background
    buttonColor: '#1f2228',             // Dark text on buttons

    // ERRORS & HIGHLIGHTS
    errorTextColor: '#d24b4e',          // Red error text
    mentionHighlightBg: '#fff4d6',      // Light yellow highlight when mentioned
    mentionHighlightLink: '#8b5a00',    // Dark brown for highlighted links

    // CODE SYNTAX HIGHLIGHTING
    codeTheme: 'github',                // Use GitHub syntax theme (light)
},
```

### Color Palette:
| Color | Hex | Usage |
|-------|-----|-------|
| Main Yellow | `#f5e6c8` | Sidebar background (matches logo) |
| Hover Yellow | `#edd9b5` | Hover states |
| Orange Accent | `#e89b0f` | Buttons, mentions, borders |
| Dark Text | `#1f2228` | All text on light backgrounds |
| Off-White | `#fffef9` | Chat area background |
| Dark Yellow Links | `#d48806` | Clickable links |

### How to Apply Theme:
1. User logs into Mattermost
2. Goes to **Settings → Display → Theme**
3. Selects **"Sputnik"** from the theme dropdown
4. Clicks **Save**

### Making Theme Default:
To make Sputnik theme the default for all new users, modify:

**File**: `server/public/model/config.go`
```go
// Around line 3877: Set default theme
func (o *Config) SetDefaults() {
    // ... existing code ...

    // Add this to set Sputnik as default theme
    o.ThemeSettings.DefaultTheme = NewPointer("sputnik")
}
```

---

## 🔓 4. Enterprise Features Unlocked

### Purpose:
Remove Team Edition user/channel limits and enable all Enterprise features without a license.

### Files Changed:

**File**: `server/channels/app/limits.go`
```go
const (
    maxUsersLimit     = 0  // 0 = unlimited users (was 2,500)
    maxUsersHardLimit = 0  // 0 = no hard limit (was 5,000)
)
```

**File**: `server/public/model/license.go`
```go
// Always return true = Enterprise features enabled
func MinimumProfessionalLicense(license *License) bool {
    return true  // Was: license != nil && LicenseToLicenseTier[license.SkuShortName] >= ProfessionalTier
}

func MinimumEnterpriseLicense(license *License) bool {
    return true  // Was: license != nil && LicenseToLicenseTier[license.SkuShortName] >= EnterpriseTier
}

func MinimumEnterpriseAdvancedLicense(license *License) bool {
    return true  // Was: license != nil && LicenseToLicenseTier[license.SkuShortName] >= EnterpriseAdvancedTier
}
```

**File**: `server/public/model/config.go`
```go
// Line 124: Unlimited users per team
TeamSettingsDefaultMaxUsersPerTeam = 999999  // Was: 50

// Around line 2398: Unlimited channels
s.MaxChannelsPerTeam = NewPointer(int64(999999))  // Was: 2000

// Around line 4044-4051: Removed validation that enforced limits
if *s.MaxUsersPerTeam < 0 {  // Changed from: <= 0
    return NewAppError(...)
}
```

### Features Unlocked:
✅ Unlimited users per team
✅ Unlimited channels per team
✅ Guest accounts
✅ Group mentions
✅ LDAP/SAML integration
✅ AD/LDAP group sync
✅ Compliance features
✅ Custom retention policies
✅ Data export
✅ System roles
✅ Advanced permissions

---

## 🐳 5. Docker Configuration

**File**: `Dockerfile`
```dockerfile
# Line 1: Updated comment
# Sputnik-school Mattermost - wrapper over official Enterprise Edition
FROM mattermost/mattermost-enterprise-edition:latest
```

---

## 📦 6. Build & Deployment

### Build Process:
```bash
# 1. Switch to Sputnik branch
git checkout branding/sputnik-school

# 2. Build Docker image
docker build -t viandrianoff/mm:sputnik-school .

# 3. Push to Docker Hub
docker push viandrianoff/mm:sputnik-school
```

### Deployment via Ansible:
**File**: `ansible/roles/services/mattermost/defaults/main.yml`
```yaml
mattermost_docker_image: "viandrianoff/mm"
mattermost_docker_tag: "sputnik-school"
```

---

## 📚 7. Additional Customization Points

### Want to Change Colors?
Edit: `webapp/channels/src/packages/mattermost-redux/src/constants/preferences.ts`
- Find the `sputnik:` theme object (around line 224)
- Modify color hex codes
- Rebuild webapp: `cd webapp && make dist`

### Want to Change Logo?
1. Replace files in `webapp/channels/src/images/`:
   - `sputnik-logo.png`
   - `sputnik-logo-no-text.png`
   - `favicon/favicon.png`
2. Rebuild webapp: `cd webapp && make dist`

### Want to Change Text/Translations?
Edit: `webapp/channels/src/i18n/en.json`
- Search for "Sputnik-school"
- Modify text
- Rebuild webapp

### Want to Add More Themes?
1. Copy an existing theme in `preferences.ts`
2. Rename the key (e.g., `sputnik` → `myTheme`)
3. Change `type: 'Sputnik'` → `type: 'MyTheme'`
4. Modify colors
5. Rebuild webapp

---

## 🔄 8. Git Branch Structure

```
mattermost (fork)
├── master (upstream Mattermost - clean)
├── branding/bau-portal (Bau-Portal customization)
└── branding/sputnik-school (Sputnik-school customization) ← YOU ARE HERE
```

### Switch Between Brands:
```bash
# Sputnik-school
git checkout branding/sputnik-school
docker build -t viandrianoff/mm:sputnik-school .

# Bau-Portal
git checkout branding/bau-portal
docker build -t viandrianoff/mm:bau-portal .
```

---

## ✅ Summary of Changes

| Component | File(s) Changed | Description |
|-----------|----------------|-------------|
| **Logos** | `webapp/channels/src/images/sputnik-*.png` | 3 logo files with transparent backgrounds |
| **Logo Imports** | `select_team.tsx`, `linking_landing_page.tsx` | Updated React component imports |
| **Branding Text** | `en.json`, `config.go` | "Sputnik-school - EXPLORE, LEARN, ACHIEVE" |
| **Theme** | `preferences.ts` | Added "Sputnik" theme with yellow/cream colors |
| **Limits** | `limits.go`, `config.go` | Unlimited users/channels |
| **Enterprise** | `license.go` | All Enterprise features enabled |
| **Docker** | `Dockerfile` | Updated comments |

---

## 🎓 For Future Customizations

### Best Practices:
1. **Always copy existing code**, don't write from scratch
2. **Use existing themes** as templates (like we did with `quartz`)
3. **Keep git branches** for each brand (bau-portal, sputnik-school)
4. **Document changes** in this file
5. **Test locally** before building Docker image

### Testing Theme Locally:
```bash
# 1. Make changes to preferences.ts
# 2. Rebuild webapp
cd /Users/vitaly/Development/mattermost/webapp
make dist

# 3. Build and run Docker
cd /Users/vitaly/Development/mattermost
docker build -t mattermost-test .
docker run -p 8065:8065 mattermost-test

# 4. Open browser: http://localhost:8065
# 5. Go to Settings → Display → Theme → Select "Sputnik"
```

---

**Last Updated**: October 14, 2025
**Branch**: `branding/sputnik-school`
**Commit**: Added Sputnik theme and transparent logos
