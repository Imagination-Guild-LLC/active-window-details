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

# Check if extension is installed (files exist)
is_extension_files_exist() {
    [[ -d "$TARGET_DIR" ]] || [[ -d "$SYSTEM_INSTALL_DIR/$EXTENSION_UUID" ]]
}

# Check if extension is registered with GNOME Shell
is_extension_registered() {
    if command -v gnome-extensions &> /dev/null; then
        gnome-extensions list 2>/dev/null | grep -q "$EXTENSION_UUID"
    else
        # Fallback to file-based check if gnome-extensions not available
        is_extension_files_exist
    fi
}

# Check if extension is installed (either files exist OR registered with GNOME)
is_extension_installed() {
    is_extension_files_exist || is_extension_registered
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
        print_info "Existing installation detected - cleaning up first..."
        uninstall_extension
        sleep 1  # Brief pause after uninstall
    fi
    
    # Copy extension files
    print_info "Copying extension files to $TARGET_DIR..."
    cp -r "$SOURCE_DIR" "$TARGET_DIR"
    
    # Set proper permissions
    chmod -R 755 "$TARGET_DIR"
    
    # Enable the extension
    print_info "Enabling extension..."
    local enable_attempts=0
    local max_enable_attempts=3
    local enabled=false
    
    while [[ $enable_attempts -lt $max_enable_attempts ]]; do
        ((enable_attempts++))
        print_info "Enable attempt $enable_attempts/$max_enable_attempts..."
        
        if gnome-extensions enable "$EXTENSION_UUID" 2>/dev/null; then
            print_info "Enable command succeeded, checking status..."
            sleep 1
            
            if is_extension_enabled; then
                print_success "Extension enabled successfully"
                enabled=true
                break
            else
                print_info "Enable command succeeded but extension not showing as enabled yet..."
            fi
        else
            print_info "Enable command failed"
        fi
        
        if [[ $enable_attempts -lt $max_enable_attempts ]]; then
            print_info "Waiting 2 seconds before retry..."
            sleep 2
        fi
    done
    
    if ! $enabled; then
        print_warning "Extension installed but could not be enabled automatically"
        print_info "The extension files are installed correctly but enabling failed."
        print_info "To enable the extension:"
        print_info "  1. Restart GNOME Shell (Alt+F2, type 'r', press Enter)"
        print_info "  2. Then manually enable: gnome-extensions enable $EXTENSION_UUID"
        print_info "  3. Or use GNOME Extensions app to enable it"
    fi
    
    # Wait a moment for D-Bus to be ready
    sleep 2
    
    # Test the installation
    print_info "Testing installation..."
    local version=$(get_installed_version_dbus)
    local final_enabled=$(is_extension_enabled && echo "yes" || echo "no")
    
    if [[ "$version" != "disabled" ]] && [[ "$version" != "not_running" ]]; then
        print_success "Installation successful! Extension is running version $version"
    elif [[ "$final_enabled" == "yes" ]]; then
        print_success "Extension is installed and enabled, but D-Bus interface may need a moment"
        print_info "Extension should be working. If not, try: Alt+F2, type 'r', press Enter"
    else
        print_warning "Extension installed but not enabled or running"
        print_info "To complete the installation:"
        print_info "  1. Restart GNOME Shell: Alt+F2, type 'r', press Enter"
        print_info "  2. Then enable: ./install.sh --enable"
        print_info "  3. Or manually: gnome-extensions enable $EXTENSION_UUID"
    fi
}

# Uninstall extension
uninstall_extension() {
    print_info "Uninstalling $EXTENSION_NAME..."
    
    # Check if extension is registered (even if files are missing)
    local is_registered=$(is_extension_registered && echo "true" || echo "false")
    local has_files=$(is_extension_files_exist && echo "true" || echo "false")
    
    print_info "Extension state: registered=$is_registered, files=$has_files"
    
    # Disable extension first
    if is_extension_enabled; then
        print_info "Disabling extension..."
        gnome-extensions disable "$EXTENSION_UUID" 2>/dev/null || print_warning "Could not disable extension"
        sleep 1  # Give GNOME time to disable
    fi
    
    # Remove extension files from all possible locations
    local removed=false
    
    # Check user installation directory
    if [[ -d "$TARGET_DIR" ]]; then
        print_info "Removing user installation from $TARGET_DIR..."
        rm -rf "$TARGET_DIR"
        removed=true
    fi
    
    # Check system installation directory
    if [[ -d "$SYSTEM_INSTALL_DIR/$EXTENSION_UUID" ]]; then
        print_info "Removing system installation from $SYSTEM_INSTALL_DIR/$EXTENSION_UUID..."
        if sudo rm -rf "$SYSTEM_INSTALL_DIR/$EXTENSION_UUID" 2>/dev/null; then
            removed=true
        else
            print_warning "Could not remove system installation (may require manual removal)"
        fi
    fi
    
    # Look for extension in other possible locations
    print_info "Searching for extension files in other locations..."
    local other_locations=$(find /home /usr -name "$EXTENSION_UUID" -type d 2>/dev/null | grep -E "(gnome-shell|extensions)" || true)
    if [[ -n "$other_locations" ]]; then
        print_info "Found extension in additional locations:"
        echo "$other_locations"
        echo "$other_locations" | while read -r location; do
            if [[ -n "$location" && -d "$location" ]]; then
                print_info "Removing from $location..."
                if [[ "$location" =~ ^/home ]]; then
                    rm -rf "$location" 2>/dev/null || print_warning "Could not remove $location"
                else
                    sudo rm -rf "$location" 2>/dev/null || print_warning "Could not remove $location (may need manual removal)"
                fi
                removed=true
            fi
        done
    fi
    
    # Force GNOME Shell to refresh its extension cache and registry
    print_info "Refreshing GNOME Shell extension cache..."
    if command -v gdbus &> /dev/null; then
        # Multiple approaches to refresh the extension system
        gdbus call --session \
            --dest org.gnome.Shell \
            --object-path /org/gnome/Shell \
            --method org.gnome.Shell.Eval "Main.extensionManager.scanForExtensions();" &>/dev/null || true
        
        # Also try to reload the extension system
        gdbus call --session \
            --dest org.gnome.Shell \
            --object-path /org/gnome/Shell \
            --method org.gnome.Shell.Eval "Main.extensionManager._loadExtensions();" &>/dev/null || true
            
        # Force a full reload of the extension system
        gdbus call --session \
            --dest org.gnome.Shell \
            --object-path /org/gnome/Shell \
            --method org.gnome.Shell.Eval "Main.extensionManager.reloadExtension(imports.misc.extensionUtils.extensions['$EXTENSION_UUID']);" &>/dev/null || true
    fi
    
    # Clear any cached extension data
    local cache_dirs=(
        "$HOME/.cache/gnome-shell/extensions"
        "$HOME/.local/share/gnome-shell/extensions-cache"
        "/tmp/.gnome-shell-extensions"
    )
    
    for cache_dir in "${cache_dirs[@]}"; do
        if [[ -d "$cache_dir" ]]; then
            print_info "Clearing extension cache from $cache_dir..."
            rm -rf "$cache_dir/$EXTENSION_UUID"* 2>/dev/null || true
        fi
    done
    
    # Wait for changes to take effect
    sleep 2
    
    # Verify the extension is no longer listed
    local still_listed=false
    if command -v gnome-extensions &> /dev/null; then
        if gnome-extensions list 2>/dev/null | grep -q "$EXTENSION_UUID"; then
            still_listed=true
        fi
    fi
    
    if [[ "$removed" == "true" ]] || [[ "$is_registered" == "true" ]]; then
        if $still_listed; then
            print_warning "Extension still appears in extension list - manual GNOME Shell restart required"
            print_info "The extension files have been removed, but GNOME Shell cache needs refresh."
            print_info "To complete the uninstallation, choose one option:"
            print_info "  Option 1: Restart GNOME Shell (Alt+F2, type 'r', press Enter)"
            print_info "  Option 2: Log out and back in"
            print_info "  Option 3: Reboot the system"
            print_info ""
            print_info "After restart, run: gnome-extensions list"
            print_info "The extension should no longer appear in the list."
        else
            print_success "Extension completely uninstalled and removed from extension list"
        fi
    else
        print_warning "Extension was not found in expected locations"
        if $still_listed; then
            print_warning "However, extension still appears in GNOME list - may need manual cleanup"
            print_info "Try restarting GNOME Shell: Alt+F2, type 'r', press Enter"
        fi
    fi
}

# Show extension status
show_status() {
    local source_version=$(get_version)
    local installed_version_file=$(get_installed_version_file)
    local installed_version_dbus=$(get_installed_version_dbus)
    local is_installed=$(is_extension_installed && echo "yes" || echo "no")
    local files_exist=$(is_extension_files_exist && echo "yes" || echo "no")
    local is_registered=$(is_extension_registered && echo "yes" || echo "no")
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
    echo "  Files Exist: $files_exist"
    echo "  GNOME Registered: $is_registered"
    echo "  Overall Status: $is_installed"
    if [[ "$files_exist" == "yes" ]]; then
        echo "  Location: $([[ -d "$TARGET_DIR" ]] && echo "User (~/.local)" || echo "System (/usr/share)")"
        echo "  File Version: $installed_version_file"
    fi
    if [[ "$files_exist" == "no" && "$is_registered" == "yes" ]]; then
        echo "  ⚠️  WARNING: Extension is registered but files are missing!"
        echo "      This indicates a broken installation that needs cleanup."
    fi
    echo
    echo "Runtime Status:"
    echo "  Enabled: $is_enabled"
    if [[ "$is_enabled" == "yes" ]]; then
        echo "  Running Version: $installed_version_dbus"
        echo "  D-Bus Interface: $(test "$installed_version_dbus" != "not_running" && echo "Available" || echo "Not Available")"
    elif [[ "$is_installed" == "yes" && "$is_enabled" == "no" ]]; then
        echo "  ⚠️  Extension is installed but not enabled!"
        echo "      To enable: ./install.sh --enable"
        echo "      Or manually: gnome-extensions enable $EXTENSION_UUID"
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
        "--force-uninstall")
            print_warning "Force uninstalling - will search entire system for extension files"
            EXTENSION_UUID="$EXTENSION_UUID" INSTALL_SCRIPT="$0" bash -c '
                find /home /usr /var -name "*active-window-details*" -o -name "*imaginationguild.com*" 2>/dev/null | while read -r path; do
                    if [[ -n "$path" && -e "$path" ]]; then
                        echo "Found: $path"
                        if [[ "$path" =~ ^/home ]]; then
                            rm -rf "$path" 2>/dev/null && echo "  Removed: $path" || echo "  Failed to remove: $path"
                        else
                            sudo rm -rf "$path" 2>/dev/null && echo "  Removed: $path" || echo "  Failed to remove: $path"
                        fi
                    fi
                done
                
                # Also force GNOME Shell restart recommendation
                echo ""
                echo "Force uninstall completed. Please restart GNOME Shell:"
                echo "  Alt+F2, type '\''r'\'', press Enter"
                echo "  Or log out and back in"
            '
            ;;
        "--reinstall")
            reinstall_extension
            ;;
        "")
            install_extension
            ;;
        "--enable")
            print_info "Manually enabling extension..."
            if gnome-extensions enable "$EXTENSION_UUID" 2>/dev/null; then
                print_success "Extension enabled"
                sleep 1
                if is_extension_enabled; then
                    print_success "Extension is now enabled and active"
                else
                    print_warning "Enable command succeeded but extension may not be active yet"
                    print_info "Try restarting GNOME Shell: Alt+F2, type 'r', press Enter"
                fi
            else
                print_error "Failed to enable extension"
                print_info "Make sure the extension is installed first: ./install.sh"
            fi
            ;;
        "--help" | "-h")
            echo "Usage: $0 [OPTION]"
            echo
            echo "Options:"
            echo "  (no option)        Install the extension"
            echo "  --status           Show installation status and version information"
            echo "  --enable           Manually enable the extension"
            echo "  --uninstall        Remove the extension"
            echo "  --force-uninstall  Thoroughly search and remove all extension files"
            echo "  --reinstall        Uninstall then reinstall the extension"
            echo "  --help, -h         Show this help message"
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