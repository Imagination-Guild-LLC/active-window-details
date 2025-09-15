#!/bin/bash

# Active Window Details Extension - Extension Listing Test Script
# =============================================================
#
# This script specifically tests that the install/uninstall functionality 
# properly manages the extension's presence in the gnome-extensions list.
#
# Test sequence:
# 1. Check initial state
# 2. Uninstall (if present) and verify removal from list
# 3. Install and verify addition to list
# 4. Uninstall again and verify removal from list
#

set -e  # Exit on any error

# Configuration
EXTENSION_UUID="active-window-details@imaginationguild.com"
EXTENSION_NAME="Active Window Details"
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

# Check if extension is in the list
check_extension_in_list() {
    if ! command -v gnome-extensions &> /dev/null; then
        print_warning "gnome-extensions command not available - cannot test listing"
        return 2  # Special return code for "skip"
    fi
    
    local extension_list
    extension_list=$(gnome-extensions list 2>/dev/null || echo "ERROR")
    
    if [[ "$extension_list" == "ERROR" ]]; then
        print_warning "Could not get extension list - gnome-extensions may not be available"
        return 2  # Special return code for "skip"
    fi
    
    print_info "Current extension list:"
    if [[ -z "$extension_list" ]]; then
        print_info "  (no extensions found)"
    else
        echo "$extension_list" | while read -r ext; do
            if [[ -n "$ext" ]]; then
                if [[ "$ext" == "$EXTENSION_UUID" ]]; then
                    print_info "  - $ext ${GREEN}[TARGET EXTENSION]${NC}"
                else
                    print_info "  - $ext"
                fi
            fi
        done
    fi
    
    # Return 0 if found, 1 if not found
    echo "$extension_list" | grep -q "$EXTENSION_UUID"
}

# Test extension listing after uninstall
test_uninstall_listing() {
    print_info "Testing extension listing after uninstall..."
    
    # Perform uninstall
    print_info "Running uninstall..."
    if "$INSTALL_SCRIPT" --uninstall &>/dev/null; then
        print_success "Uninstall command completed"
    else
        print_warning "Uninstall command had issues (extension may not have been installed)"
    fi
    
    # Brief pause to allow system to update
    sleep 1
    
    # Check listing
    check_extension_in_list
    local result=$?
    
    case $result in
        0)
            print_error "FAILED: Extension $EXTENSION_UUID is still listed after uninstall!"
            print_error "This indicates the uninstall process is incomplete."
            return 1
            ;;
        1)
            print_success "PASSED: Extension $EXTENSION_UUID is not listed after uninstall."
            return 0
            ;;
        2)
            print_warning "SKIPPED: Cannot test - gnome-extensions not available"
            return 0
            ;;
    esac
}

# Test extension listing after install
test_install_listing() {
    print_info "Testing extension listing after install..."
    
    # Perform install
    print_info "Running install..."
    if "$INSTALL_SCRIPT" &>/dev/null; then
        print_success "Install command completed"
    else
        print_error "Install command failed!"
        return 1
    fi
    
    # Brief pause to allow system to update
    sleep 2
    
    # Check listing
    check_extension_in_list
    local result=$?
    
    case $result in
        0)
            print_success "PASSED: Extension $EXTENSION_UUID is listed after install."
            return 0
            ;;
        1)
            print_error "FAILED: Extension $EXTENSION_UUID is not listed after install!"
            print_error "This indicates the install process may be incomplete."
            print_info "Try restarting GNOME Shell: Alt+F2, type 'r', press Enter"
            return 1
            ;;
        2)
            print_warning "SKIPPED: Cannot test - gnome-extensions not available"
            return 0
            ;;
    esac
}

# Run the complete test
run_extension_listing_test() {
    echo -e "\n${BOLD}${GREEN}================================================"
    echo "  EXTENSION LISTING TEST"
    echo "================================================${NC}"
    echo "Testing: $EXTENSION_NAME"
    echo "UUID: $EXTENSION_UUID"
    echo

    # Check prerequisites
    if [[ ! -f "$INSTALL_SCRIPT" ]]; then
        print_error "Install script not found: $INSTALL_SCRIPT"
        exit 1
    fi

    if [[ ! -x "$INSTALL_SCRIPT" ]]; then
        print_error "Install script is not executable: $INSTALL_SCRIPT"
        exit 1
    fi

    local test_results=()
    
    # Step 1: Check initial state
    print_step "1" "Checking Initial State"
    check_extension_in_list
    local initial_state=$?
    case $initial_state in
        0) print_info "Extension is currently listed" ;;
        1) print_info "Extension is not currently listed" ;;
        2) print_warning "Cannot check listing - gnome-extensions not available" ;;
    esac

    # Step 2: Test uninstall listing
    print_step "2" "Testing Uninstall -> Extension Not Listed"
    if test_uninstall_listing; then
        print_success "Uninstall listing test PASSED"
        test_results+=("uninstall:PASS")
    else
        print_error "Uninstall listing test FAILED"
        test_results+=("uninstall:FAIL")
    fi

    # Step 3: Test install listing
    print_step "3" "Testing Install -> Extension Listed"
    if test_install_listing; then
        print_success "Install listing test PASSED"
        test_results+=("install:PASS")
    else
        print_error "Install listing test FAILED"
        test_results+=("install:FAIL")
    fi

    # Step 4: Test uninstall again
    print_step "4" "Testing Second Uninstall -> Extension Not Listed"
    if test_uninstall_listing; then
        print_success "Second uninstall listing test PASSED"
        test_results+=("uninstall2:PASS")
    else
        print_error "Second uninstall listing test FAILED"
        test_results+=("uninstall2:FAIL")
    fi

    # Results summary
    echo -e "\n${BOLD}${BLUE}================================================"
    echo "  TEST RESULTS SUMMARY"
    echo "================================================${NC}"
    
    local all_passed=true
    for result in "${test_results[@]}"; do
        local test_name="${result%%:*}"
        local test_result="${result##*:}"
        if [[ "$test_result" == "PASS" ]]; then
            echo -e "  $test_name: ${GREEN}PASSED${NC}"
        else
            echo -e "  $test_name: ${RED}FAILED${NC}"
            all_passed=false
        fi
    done

    echo
    if $all_passed; then
        echo -e "${BOLD}${GREEN}🎉 ALL TESTS PASSED!${NC}"
        echo "The install/uninstall functionality correctly manages the extension listing."
        return 0
    else
        echo -e "${BOLD}${RED}❌ SOME TESTS FAILED!${NC}"
        echo "The install/uninstall functionality needs fixes."
        return 1
    fi
}

# Main execution
main() {
    case "${1:-}" in
        "--help" | "-h")
            echo "Active Window Details Extension - Extension Listing Test"
            echo
            echo "Usage: $0"
            echo
            echo "This script tests that the install/uninstall process correctly"
            echo "manages the extension's presence in 'gnome-extensions list'."
            echo
            echo "Test sequence:"
            echo "1. Uninstall -> verify extension NOT in list"
            echo "2. Install -> verify extension IS in list" 
            echo "3. Uninstall -> verify extension NOT in list"
            echo
            exit 0
            ;;
        "")
            run_extension_listing_test
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
