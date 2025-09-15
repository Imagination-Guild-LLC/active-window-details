#!/bin/bash

# Active Window Details GNOME Shell Extension
# Installation and Management Script
# ===============================
#
# This script provides easy installation, status checking, uninstallation,
# and reinstallation of the Active Window Details GNOME Shell extension.
#
# Usage:
#   ./install.sh           - Install the extension
#   ./install.sh --status  - Check installation status and version
#   ./install.sh --uninstall - Remove the extension
#   ./install.sh --reinstall - Reinstall the extension (uninstall then install)
#

set -e  # Exit on any error

# Configuration
EXTENSION_UUID="active-window-details@imaginationguild.com"
EXTENSION_NAME="Active Window Details"
SOURCE_DIR="v45-46-47"
SYSTEM_INSTALL_DIR="/usr/share/gnome-shell/extensions"
USER_INSTALL_DIR="$HOME/.local/share/gnome-shell/extensions"
TARGET_DIR="$USER_INSTALL_DIR/$EXTENSION_UUID"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're running on a GNOME system
check_gnome() {
    if ! command -v gnome-shell &> /dev/null; then
        print_error "GNOME Shell not found. This extension requires GNOME Shell."
        exit 1
    fi
    
    if ! command -v gnome-extensions &> /dev/null; then
        print_error "gnome-extensions command not found. Please install gnome-shell-extensions package."
        exit 1
    fi
}

# Check if extension source exists
check_source() {
    if [[ ! -d "$SOURCE_DIR" ]]; then
        print_error "Extension source directory '$SOURCE_DIR' not found."
        print_info "Please run this script from the project root directory."
        exit 1
    fi
    
    if [[ ! -f "$SOURCE_DIR/metadata.json" ]]; then
        print_error "metadata.json not found in '$SOURCE_DIR'."
        exit 1
    fi
    
    if [[ ! -f "$SOURCE_DIR/extension.js" ]]; then
        print_error "extension.js not found in '$SOURCE_DIR'."
        exit 1
    fi
}

# Get extension version from metadata.json
get_version() {
    if [[ -f "$SOURCE_DIR/metadata.json" ]]; then
        grep '"version"' "$SOURCE_DIR/metadata.json" | sed -E 's/.*"version": *"([^"]*)",?.*$/\1/' || echo "unknown"
    else
        echo "unknown"
    fi
}

# Check if extension is installed
is_extension_installed() {
    [[ -d "$TARGET_DIR" ]] || [[ -d "$SYSTEM_INSTALL_DIR/$EXTENSION_UUID" ]]
}

# Check if extension is enabled
is_extension_enabled() {
    gnome-extensions list --enabled | grep -q "$EXTENSION_UUID" 2>/dev/null
}

# Get installed version using D-Bus (if extension is running)
get_installed_version_dbus() {
    if is_extension_enabled; then
        local version_output
        version_output=$(gdbus call --session \
            --dest org.gnome.Shell \
            --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
            --method org.gnome.Shell.Extensions.ActiveWindowDetails.getVersion 2>/dev/null || echo "")
        
        if [[ -n "$version_output" ]]; then
            # Extract version from JSON response
            echo "$version_output" | sed -E 's/.*"version": *"([^"]*)".*$/\1/' 2>/dev/null || echo "unknown"
        else
            echo "not_running"
        fi
    else
        echo "disabled"
    fi
}

# Get installed version from filesystem
get_installed_version_file() {
    local installed_metadata
    if [[ -f "$TARGET_DIR/metadata.json" ]]; then
        installed_metadata="$TARGET_DIR/metadata.json"
    elif [[ -f "$SYSTEM_INSTALL_DIR/$EXTENSION_UUID/metadata.json" ]]; then
        installed_metadata="$SYSTEM_INSTALL_DIR/$EXTENSION_UUID/metadata.json"
    else
        echo "not_installed"
        return
    fi
    
    grep '"version"' "$installed_metadata" | sed -E 's/.*"version": *"([^"]*)",?.*$/\1/' 2>/dev/null || echo "unknown"
}

# Install extension
install_extension() {
    print_info "Installing $EXTENSION_NAME..."
    
    # Create user extensions directory if it doesn't exist
    if [[ ! -d "$USER_INSTALL_DIR" ]]; then
        print_info "Creating user extensions directory..."
        mkdir -p "$USER_INSTALL_DIR"
    fi
    
    # Remove existing installation if present
    if is_extension_installed; then
        print_info "Removing existing installation..."
        rm -rf "$TARGET_DIR" 2>/dev/null || true
        sudo rm -rf "$SYSTEM_INSTALL_DIR/$EXTENSION_UUID" 2>/dev/null || true
    fi
    
    # Copy extension files
    print_info "Copying extension files to $TARGET_DIR..."
    cp -r "$SOURCE_DIR" "$TARGET_DIR"
    
    # Set proper permissions
    chmod -R 755 "$TARGET_DIR"
    
    # Enable the extension
    print_info "Enabling extension..."
    if gnome-extensions enable "$EXTENSION_UUID" 2>/dev/null; then
        print_success "Extension enabled successfully"
    else
        print_warning "Extension installed but could not be enabled automatically"
        print_info "You may need to restart GNOME Shell (Alt+F2, type 'r', press Enter)"
        print_info "Or log out and back in, then enable manually"
    fi
    
    # Wait a moment for D-Bus to be ready
    sleep 2
    
    # Test the installation
    print_info "Testing installation..."
    local version=$(get_installed_version_dbus)
    if [[ "$version" != "disabled" ]] && [[ "$version" != "not_running" ]]; then
        print_success "Installation successful! Extension is running version $version"
    else
        print_warning "Extension installed but may not be running properly"
        print_info "Try restarting GNOME Shell: Alt+F2, type 'r', press Enter"
    fi
}

# Uninstall extension
uninstall_extension() {
    print_info "Uninstalling $EXTENSION_NAME..."
    
    # Disable extension first
    if is_extension_enabled; then
        print_info "Disabling extension..."
        gnome-extensions disable "$EXTENSION_UUID" 2>/dev/null || print_warning "Could not disable extension"
    fi
    
    # Remove extension files
    local removed=false
    if [[ -d "$TARGET_DIR" ]]; then
        print_info "Removing user installation from $TARGET_DIR..."
        rm -rf "$TARGET_DIR"
        removed=true
    fi
    
    if [[ -d "$SYSTEM_INSTALL_DIR/$EXTENSION_UUID" ]]; then
        print_info "Removing system installation from $SYSTEM_INSTALL_DIR/$EXTENSION_UUID..."
        if sudo rm -rf "$SYSTEM_INSTALL_DIR/$EXTENSION_UUID" 2>/dev/null; then
            removed=true
        else
            print_warning "Could not remove system installation (may require manual removal)"
        fi
    fi
    
    if $removed; then
        print_success "Extension files removed successfully"
        
        # Force GNOME Shell to refresh its extension cache
        print_info "Refreshing GNOME Shell extension cache..."
        if command -v gdbus &> /dev/null; then
            # Try to refresh the extension list via D-Bus
            gdbus call --session \
                --dest org.gnome.Shell \
                --object-path /org/gnome/Shell \
                --method org.gnome.Shell.Eval "Main.extensionManager.scanForExtensions();" &>/dev/null || true
        fi
        
        # Verify the extension is no longer listed
        sleep 1
        if gnome-extensions list 2>/dev/null | grep -q "$EXTENSION_UUID"; then
            print_warning "Extension may still appear in extension list until GNOME Shell is restarted"
            print_info "To complete the uninstallation:"
            print_info "  Option 1: Restart GNOME Shell (Alt+F2, type 'r', press Enter)"
            print_info "  Option 2: Log out and back in"
            print_info "  Option 3: Reboot the system"
        else
            print_success "Extension completely uninstalled and removed from extension list"
        fi
    else
        print_warning "Extension was not found or already uninstalled"
    fi
}

# Show extension status
show_status() {
    local source_version=$(get_version)
    local installed_version_file=$(get_installed_version_file)
    local installed_version_dbus=$(get_installed_version_dbus)
    local is_installed=$(is_extension_installed && echo "yes" || echo "no")
    local is_enabled=$(is_extension_enabled && echo "yes" || echo "no")
    
    echo "========================================="
    echo "  $EXTENSION_NAME - Status Report"
    echo "========================================="
    echo
    echo "Source Information:"
    echo "  Directory: $SOURCE_DIR"
    echo "  Version: $source_version"
    echo
    echo "Installation Status:"
    echo "  Installed: $is_installed"
    if [[ "$is_installed" == "yes" ]]; then
        echo "  Location: $(is_extension_installed && ([[ -d "$TARGET_DIR" ]] && echo "User (~/.local)" || echo "System (/usr/share)"))"
        echo "  File Version: $installed_version_file"
    fi
    echo
    echo "Runtime Status:"
    echo "  Enabled: $is_enabled"
    if [[ "$is_enabled" == "yes" ]]; then
        echo "  Running Version: $installed_version_dbus"
        echo "  D-Bus Interface: $(test "$installed_version_dbus" != "not_running" && echo "Available" || echo "Not Available")"
    fi
    echo
    
    # Version comparison
    if [[ "$is_installed" == "yes" && "$source_version" != "unknown" && "$installed_version_file" != "unknown" ]]; then
        if [[ "$source_version" == "$installed_version_file" ]]; then
            print_success "Installed version matches source version"
        else
            print_warning "Version mismatch - Source: $source_version, Installed: $installed_version_file"
            print_info "Consider running: ./install.sh --reinstall"
        fi
    fi
    
    # D-Bus test
    if [[ "$is_enabled" == "yes" && "$installed_version_dbus" != "not_running" ]]; then
        echo
        print_info "Testing D-Bus interface..."
        local test_output
        test_output=$(gdbus call --session \
            --dest org.gnome.Shell \
            --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
            --method org.gnome.Shell.Extensions.ActiveWindowDetails.getWinFocusData 2>/dev/null || echo "ERROR")
        
        if [[ "$test_output" != "ERROR" ]]; then
            print_success "D-Bus interface is working correctly"
        else
            print_warning "D-Bus interface test failed"
        fi
    fi
    
    echo "========================================="
}

# Reinstall extension
reinstall_extension() {
    print_info "Reinstalling $EXTENSION_NAME..."
    
    # Check current status
    if is_extension_installed; then
        print_info "Extension is currently installed - uninstalling first..."
        uninstall_extension
        sleep 1  # Brief pause between uninstall and install
    else
        print_info "Extension not currently installed - proceeding with fresh installation..."
    fi
    
    # Install
    install_extension
}

# Main script logic
main() {
    print_info "Active Window Details Extension Installer"
    print_info "=========================================="
    
    # Check prerequisites
    check_gnome
    check_source
    
    # Parse command line arguments
    case "${1:-}" in
        "--status")
            show_status
            ;;
        "--uninstall")
            uninstall_extension
            ;;
        "--reinstall")
            reinstall_extension
            ;;
        "")
            install_extension
            ;;
        "--help" | "-h")
            echo "Usage: $0 [OPTION]"
            echo
            echo "Options:"
            echo "  (no option)    Install the extension"
            echo "  --status       Show installation status and version information"
            echo "  --uninstall    Remove the extension"
            echo "  --reinstall    Uninstall then reinstall the extension"
            echo "  --help, -h     Show this help message"
            echo
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            print_info "Use --help to see available options"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"