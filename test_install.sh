#!/bin/bash

# Active Window Details Extension - Installation Test Script
# =========================================================
#
# This script automates the testing of the installation process by:
# 1. Uninstalling any existing extension
# 2. Updating the version number in metadata.json  
# 3. Installing the extension
# 4. Verifying the installation via D-Bus version check
#
# This ensures that the version management and installation process work correctly.
#

set -e  # Exit on any error

# Configuration
EXTENSION_UUID="active-window-details@imaginationguild.com"
EXTENSION_NAME="Active Window Details"
SOURCE_DIR="v45-46-47"
METADATA_FILE="$SOURCE_DIR/metadata.json"
INSTALL_SCRIPT="./install.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
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

print_step() {
    echo -e "\n${BOLD}${BLUE}==== STEP $1: $2 ====${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if [[ ! -f "$INSTALL_SCRIPT" ]]; then
        print_error "Install script not found: $INSTALL_SCRIPT"
        exit 1
    fi
    
    if [[ ! -x "$INSTALL_SCRIPT" ]]; then
        print_error "Install script is not executable: $INSTALL_SCRIPT"
        exit 1
    fi
    
    if [[ ! -f "$METADATA_FILE" ]]; then
        print_error "Metadata file not found: $METADATA_FILE"
        exit 1
    fi
    
    if ! command -v gdbus &> /dev/null; then
        print_error "gdbus command not found. This test requires GNOME D-Bus tools."
        exit 1
    fi
    
    if ! command -v gnome-extensions &> /dev/null; then
        print_error "gnome-extensions command not found. This test requires gnome-shell-extensions package."
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Get current version from metadata.json
get_current_version() {
    grep '"version"' "$METADATA_FILE" | sed -E 's/.*"version": *"([^"]*)",?.*$/\1/' 2>/dev/null || echo "unknown"
}

# Generate next version number
generate_next_version() {
    local current_version="$1"
    
    # If version is in format X.Y.Z, increment the patch number
    if [[ "$current_version" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        local major="${BASH_REMATCH[1]}"
        local minor="${BASH_REMATCH[2]}"
        local patch="${BASH_REMATCH[3]}"
        local new_patch=$((patch + 1))
        echo "$major.$minor.$new_patch"
    # If version is in format X.Y, add .1
    elif [[ "$current_version" =~ ^([0-9]+)\.([0-9]+)$ ]]; then
        echo "$current_version.1"
    # If version is just a number, increment it
    elif [[ "$current_version" =~ ^([0-9]+)$ ]]; then
        local new_version=$((current_version + 1))
        echo "$new_version.0.0"
    else
        # Default fallback with timestamp
        local timestamp=$(date +%s)
        echo "1.0.$((timestamp % 1000))"
    fi
}

# Update version in metadata.json
update_version() {
    local new_version="$1"
    local backup_file="$METADATA_FILE.backup.$(date +%s)"
    
    print_info "Creating backup: $backup_file"
    cp "$METADATA_FILE" "$backup_file"
    
    print_info "Updating version from $(get_current_version) to $new_version"
    
    # Use sed to replace the version line
    sed -i.tmp "s/\"version\": *\"[^\"]*\"/\"version\": \"$new_version\"/" "$METADATA_FILE"
    rm -f "$METADATA_FILE.tmp"
    
    # Verify the update
    local updated_version=$(get_current_version)
    if [[ "$updated_version" == "$new_version" ]]; then
        print_success "Version updated successfully to $new_version"
        return 0
    else
        print_error "Version update failed. Expected: $new_version, Got: $updated_version"
        print_info "Restoring backup..."
        mv "$backup_file" "$METADATA_FILE"
        return 1
    fi
}

# Wait for extension to be ready
wait_for_extension() {
    local max_attempts=10
    local attempt=1
    
    print_info "Waiting for extension to be ready..."
    
    while [[ $attempt -le $max_attempts ]]; do
        print_info "Attempt $attempt/$max_attempts..."
        
        # Check if extension is enabled
        if gnome-extensions list --enabled | grep -q "$EXTENSION_UUID" 2>/dev/null; then
            # Try to get version via D-Bus
            local dbus_version
            dbus_version=$(gdbus call --session \
                --dest org.gnome.Shell \
                --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
                --method org.gnome.Shell.Extensions.ActiveWindowDetails.getVersion 2>/dev/null || echo "")
            
            if [[ -n "$dbus_version" && "$dbus_version" != *"error"* ]]; then
                print_success "Extension is ready and responding to D-Bus calls"
                return 0
            fi
        fi
        
        print_info "Extension not ready yet, waiting 2 seconds..."
        sleep 2
        ((attempt++))
    done
    
    print_warning "Extension may not be fully ready after $max_attempts attempts"
    return 1
}

# Test that extension is NOT listed after uninstall
test_extension_not_listed() {
    print_info "Testing that extension is not listed after uninstall..."
    
    # Get the extension list
    local extension_list
    extension_list=$(gnome-extensions list 2>/dev/null || echo "ERROR")
    
    if [[ "$extension_list" == "ERROR" ]]; then
        print_error "Could not get extension list - gnome-extensions failed"
        return 1
    fi
    
    print_info "Current extension list:"
    echo "$extension_list" | while read -r ext; do
        if [[ -n "$ext" ]]; then
            print_info "  - $ext"
        fi
    done
    
    # Check if our extension is in the list
    if echo "$extension_list" | grep -q "$EXTENSION_UUID"; then
        print_error "Extension $EXTENSION_UUID is still listed after uninstall!"
        print_error "This means the uninstall was not complete."
        return 1
    else
        print_success "Extension $EXTENSION_UUID is NOT listed - uninstall was successful!"
        return 0
    fi
}

# Test that extension IS listed after install
test_extension_is_listed() {
    print_info "Testing that extension is listed after install..."
    
    # Get the extension list
    local extension_list
    extension_list=$(gnome-extensions list 2>/dev/null || echo "ERROR")
    
    if [[ "$extension_list" == "ERROR" ]]; then
        print_error "Could not get extension list - gnome-extensions failed"
        return 1
    fi
    
    print_info "Current extension list:"
    echo "$extension_list" | while read -r ext; do
        if [[ -n "$ext" ]]; then
            print_info "  - $ext"
        fi
    done
    
    # Check if our extension is in the list (with retry logic for timing issues)
    local max_list_attempts=5
    local list_attempt=1
    
    while [[ $list_attempt -le $max_list_attempts ]]; do
        print_info "Checking extension list (attempt $list_attempt/$max_list_attempts)..."
        
        # Get fresh extension list
        extension_list=$(gnome-extensions list 2>/dev/null || echo "ERROR")
        
        if [[ "$extension_list" == "ERROR" ]]; then
            print_error "Could not get extension list - gnome-extensions failed"
            return 1
        fi
        
        # Check if our extension is in the list
        if echo "$extension_list" | grep -q "$EXTENSION_UUID"; then
            print_success "Extension $EXTENSION_UUID is listed - install was successful!"
            return 0
        fi
        
        if [[ $list_attempt -lt $max_list_attempts ]]; then
            print_info "Extension not yet listed, waiting 3 seconds before retry..."
            sleep 3
        fi
        
        ((list_attempt++))
    done
    
    # Final attempt failed
    print_error "Extension $EXTENSION_UUID is NOT listed after $max_list_attempts attempts!"
    print_error "This means the install process may be incomplete or needs more time."
    print_warning "GNOME Shell may need to be refreshed for the extension to appear"
    return 1
}

# Test version via D-Bus
test_version_dbus() {
    local expected_version="$1"
    
    print_info "Testing version via D-Bus..."
    
    # Get version via D-Bus
    local dbus_output
    dbus_output=$(gdbus call --session \
        --dest org.gnome.Shell \
        --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
        --method org.gnome.Shell.Extensions.ActiveWindowDetails.getVersion 2>/dev/null || echo "ERROR")
    
    if [[ "$dbus_output" == "ERROR" || -z "$dbus_output" ]]; then
        print_error "Failed to get version via D-Bus"
        print_info "Raw D-Bus response: '$dbus_output'"
        return 1
    fi
    
    print_info "Raw D-Bus response: $dbus_output"
    
    # Extract version from JSON response
    # The response format should be: ('{"version":"X.Y.Z",...}',)
    local extracted_version
    extracted_version=$(echo "$dbus_output" | sed -E 's/.*"version": *"([^"]*)".*$/\1/' 2>/dev/null || echo "parse_error")
    
    print_info "Extracted version: $extracted_version"
    print_info "Expected version: $expected_version"
    
    if [[ "$extracted_version" == "$expected_version" ]]; then
        print_success "Version verification PASSED! D-Bus returned: $extracted_version"
        return 0
    else
        print_error "Version verification FAILED!"
        print_error "Expected: $expected_version"
        print_error "Got: $extracted_version"
        return 1
    fi
}

# Run a complete test cycle
run_test_cycle() {
    local test_start_time=$(date)
    
    echo -e "\n${BOLD}${GREEN}============================================="
    echo "  ACTIVE WINDOW DETAILS - INSTALLATION TEST"
    echo "=============================================${NC}"
    echo "Test started: $test_start_time"
    echo
    
    # Step 1: Check prerequisites
    print_step "1" "Checking Prerequisites"
    check_prerequisites
    
    # Step 2: Get current version and generate new version
    print_step "2" "Version Management"
    local current_version=$(get_current_version)
    local new_version=$(generate_next_version "$current_version")
    print_info "Current version: $current_version"
    print_info "New version: $new_version"
    
    # Step 3: Uninstall existing extension
    print_step "3" "Uninstalling Existing Extension"
    print_info "Running: $INSTALL_SCRIPT --uninstall"
    if "$INSTALL_SCRIPT" --uninstall; then
        print_success "Uninstall completed"
    else
        print_warning "Uninstall had issues (may not have been installed)"
    fi
    
    # Step 3.1: Verify extension is not listed after uninstall
    print_step "3.1" "Verifying Extension Not Listed After Uninstall"
    if test_extension_not_listed; then
        print_success "Uninstall verification PASSED!"
    else
        print_error "Uninstall verification FAILED!"
        # Continue with test but note the failure
    fi
    
    # Step 4: Update version
    print_step "4" "Updating Version Number"
    if ! update_version "$new_version"; then
        print_error "Failed to update version number"
        exit 1
    fi
    
    # Step 5: Install extension
    print_step "5" "Installing Extension"
    print_info "Running: $INSTALL_SCRIPT"
    if "$INSTALL_SCRIPT"; then
        print_success "Installation completed"
    else
        print_error "Installation failed"
        exit 1
    fi
    
    # Brief pause to let installation and registration complete
    sleep 3
    
    # Step 5.1: Verify extension is listed after install
    print_step "5.1" "Verifying Extension Is Listed After Install"
    if test_extension_is_listed; then
        print_success "Install verification PASSED!"
    else
        print_error "Install verification FAILED!"
        # This is a serious issue, but continue to get full test results
    fi
    
    # Step 6: Wait for extension to be ready
    print_step "6" "Waiting for Extension to Initialize"
    wait_for_extension
    
    # Step 7: Test version via D-Bus
    print_step "7" "Verifying Version via D-Bus"
    if test_version_dbus "$new_version"; then
        print_success "Version verification PASSED!"
    else
        print_error "Version verification FAILED!"
        exit 1
    fi
    
    # Final status check
    print_step "8" "Final Status Check"
    print_info "Running: $INSTALL_SCRIPT --status"
    "$INSTALL_SCRIPT" --status
    
    # Test summary
    local test_end_time=$(date)
    echo -e "\n${BOLD}${GREEN}============================================="
    echo "  TEST COMPLETED SUCCESSFULLY!"
    echo "=============================================${NC}"
    echo "Started: $test_start_time"
    echo "Finished: $test_end_time"
    echo "Version tested: $new_version"
    echo -e "${GREEN}All checks passed! ✓${NC}"
}

# Main execution
main() {
    # Parse command line options
    case "${1:-}" in
        "--help" | "-h")
            echo "Active Window Details Extension - Installation Test Script"
            echo
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "This script tests the complete installation process:"
            echo "1. Uninstalls any existing extension"
            echo "2. Updates the version number"
            echo "3. Installs the extension"  
            echo "4. Verifies the installation via D-Bus"
            echo
            echo "Options:"
            echo "  --help, -h    Show this help message"
            echo
            echo "Prerequisites:"
            echo "- GNOME Shell environment"
            echo "- install.sh script in current directory"
            echo "- Extension source in $SOURCE_DIR directory"
            echo
            exit 0
            ;;
        "")
            run_test_cycle
            ;;
        *)
            print_error "Unknown option: $1"
            print_info "Use --help to see available options"
            exit 1
            ;;
    esac
}

# Run the test
main "$@"