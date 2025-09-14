#!/bin/bash

# test_configuration.sh
# =====================
# 
# Test script for Active Window Details Extension Configuration
# This script helps verify that the configuration UI is properly set up
# and accessible through the GNOME Extension Manager.

set -e

echo "=========================================="
echo "Active Window Details Configuration Test"
echo "=========================================="
echo

# Check if the extension directory exists
EXTENSION_DIR="$HOME/.local/share/gnome-shell/extensions/active-window-details@imaginationguild.com"
SYSTEM_DIR="/usr/share/gnome-shell/extensions/active-window-details@imaginationguild.com"

echo "1. Checking Extension Installation..."
if [ -d "$EXTENSION_DIR" ]; then
    echo "✅ Extension found in user directory: $EXTENSION_DIR"
    INSTALL_DIR="$EXTENSION_DIR"
elif [ -d "$SYSTEM_DIR" ]; then
    echo "✅ Extension found in system directory: $SYSTEM_DIR"
    INSTALL_DIR="$SYSTEM_DIR"
else
    echo "❌ Extension not found. Please install first:"
    echo "   cp -r v45-46-47/ ~/.local/share/gnome-shell/extensions/active-window-details@imaginationguild.com/"
    exit 1
fi

echo

# Check required files for configuration
echo "2. Checking Configuration Files..."

# Check metadata.json
if [ -f "$INSTALL_DIR/metadata.json" ]; then
    echo "✅ metadata.json found"
    if grep -q "settings-schema" "$INSTALL_DIR/metadata.json"; then
        echo "✅ settings-schema configured in metadata.json"
    else
        echo "❌ settings-schema missing in metadata.json"
        exit 1
    fi
else
    echo "❌ metadata.json not found"
    exit 1
fi

# Check prefs.js
if [ -f "$INSTALL_DIR/prefs.js" ]; then
    echo "✅ prefs.js found"
else
    echo "❌ prefs.js not found"
    exit 1
fi

# Check schema files
if [ -d "$INSTALL_DIR/schemas" ]; then
    echo "✅ schemas directory found"
    if [ -f "$INSTALL_DIR/schemas/org.gnome.shell.extensions.active-window-details.gschema.xml" ]; then
        echo "✅ Schema XML file found"
    else
        echo "❌ Schema XML file not found"
        exit 1
    fi
    
    if [ -f "$INSTALL_DIR/schemas/gschemas.compiled" ]; then
        echo "✅ Compiled schema found"
    else
        echo "❌ Compiled schema not found"
        exit 1
    fi
else
    echo "❌ schemas directory not found"
    exit 1
fi

echo

# Check extension status
echo "3. Checking Extension Status..."
if gnome-extensions list --enabled | grep -q "active-window-details@imaginationguild.com"; then
    echo "✅ Extension is enabled"
else
    echo "⚠️  Extension is not enabled. Enabling now..."
    gnome-extensions enable active-window-details@imaginationguild.com
    if [ $? -eq 0 ]; then
        echo "✅ Extension enabled successfully"
    else
        echo "❌ Failed to enable extension"
        exit 1
    fi
fi

echo

# Verify extension functionality
echo "4. Testing Extension Functionality..."
if gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.gnome.Shell.Extensions.ActiveWindowDetails.getWinFocusData > /dev/null 2>&1; then
    echo "✅ Extension D-Bus interface is working"
else
    echo "❌ Extension D-Bus interface is not responding"
    echo "   Try restarting the extension or reloading GNOME Shell"
    exit 1
fi

echo

# Instructions for testing configuration UI
echo "5. Configuration UI Testing Instructions..."
echo "=========================================="
echo
echo "To test the configuration UI:"
echo "1. Open 'Extension Manager' (gnome-extensions-app)"
echo "2. Find 'Active Window Details' in the list"
echo "3. Click the gear/settings icon next to the extension"
echo "4. You should see the About page with:"
echo "   - Extension information and version"
echo "   - Key features description"
echo "   - Imagination Guild LLC company information"
echo "   - Homepage button that opens https://github.com/Imagination-Guild-LLC"
echo "   - Attribution to original Evertrack project"
echo "   - Source code repository link"
echo "   - D-Bus interface and performance information"
echo "   - License information"
echo
echo "✅ All configuration files are properly set up!"
echo
echo "Alternative test command:"
echo "gnome-extensions prefs active-window-details@imaginationguild.com"
echo

# Show current extension info
echo "6. Current Extension Information..."
gnome-extensions info active-window-details@imaginationguild.com

echo
echo "Configuration test completed successfully! 🎉"
echo "The extension should now show a gear icon in Extension Manager."
