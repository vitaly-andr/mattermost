#!/bin/bash

# Bitwarden Auto-unlock with Touch ID
# This script uses macOS Keychain to store master password and Touch ID for access

echo "🔐 Bitwarden Auto-unlock with Touch ID"

# Check if Bitwarden CLI is installed
if ! command -v bw &> /dev/null; then
    echo "❌ Bitwarden CLI not installed. Run: brew install bitwarden-cli"
    exit 1
fi

# Check current status
STATUS=$(bw status 2>/dev/null | jq -r .status 2>/dev/null || echo "error")

case $STATUS in
    "unlocked")
        echo "✅ Bitwarden already unlocked!"
        echo "🔑 Use existing BW_SESSION variable"
        if [ -n "$BW_SESSION" ]; then
            echo "Session already set in environment"
        else
            echo "⚠️ BW_SESSION not set, need to unlock again"
        fi
        exit 0
        ;;
    "locked"|"unauthenticated")
        echo "🔓 Unlocking Bitwarden..."
        ;;
    *)
        echo "❌ Error checking Bitwarden status"
        exit 1
        ;;
esac

# Get master password from Keychain (Touch ID prompt)
echo "👆 Touch ID required to access master password..."
MASTER_PWD=$(security find-generic-password -a "bitwarden" -s "bw-master" -w 2>/dev/null)

if [ -z "$MASTER_PWD" ]; then
    echo "❌ Master password not found in Keychain"
    echo "💡 Run: security add-generic-password -a 'bitwarden' -s 'bw-master' -w 'your-master-password'"
    exit 1
fi

# Login if needed
if [ "$STATUS" = "unauthenticated" ]; then
    echo "🔐 Logging in to Bitwarden..."
    echo "$MASTER_PWD" | bw login vitaly.reg@andrianoff.online --raw > /dev/null
    if [ $? -ne 0 ]; then
        echo "❌ Login failed"
        exit 1
    fi
fi

# Unlock vault and get session
echo "🔓 Getting session key..."
export BW_SESSION=$(echo "$MASTER_PWD" | bw unlock --raw 2>/dev/null)

if [ -n "$BW_SESSION" ]; then
    echo "✅ Bitwarden successfully unlocked!"
    echo "🚀 Ready to use with Kamal"
    echo ""
    echo "💡 Run this to set session in current shell:"
    echo "export BW_SESSION=\"$BW_SESSION\""
else
    echo "❌ Failed to unlock Bitwarden"
    exit 1
fi