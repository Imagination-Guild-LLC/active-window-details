#!/bin/bash

# =============================================================================
# Active Window Details Extension - Comprehensive Testing Script
# =============================================================================
#
# This script performs complete testing of all extension functionality including:
# - Phase 1: Core Window/Process Information (11 methods)
# - Phase 2: Application-Specific Deep Data (8 methods)
# - Extension installation and D-Bus interface validation
# - Performance testing and method count verification
#
# Usage:
#   ./test_all_phases.sh [delay_seconds]
#
# Parameters:
#   delay_seconds: Optional delay before starting tests (default: 0)
#                  Useful for switching to target application
#
# Examples:
#   ./test_all_phases.sh          # Test immediately with current window
#   ./test_all_phases.sh 5        # Wait 5 seconds before testing
#
# Expected Results:
#   - All 19 methods should return SUCCESS with meaningful data
#   - Extension should be properly installed and enabled
#   - D-Bus interface should be accessible and responsive
#
# =============================================================================

DELAY=${1:-0}
UUID="active-window-details@imaginationguild.com"
INTERFACE="org.gnome.Shell.Extensions.ActiveWindowDetails"

echo "🚀 COMPREHENSIVE EXTENSION TESTING SCRIPT"
echo "=========================================="
echo "Extension UUID: $UUID"
echo "D-Bus Interface: $INTERFACE"
echo "Delay: ${DELAY}s"
echo ""

if [ "$DELAY" -gt 0 ]; then
    echo "⏳ Waiting $DELAY seconds for window switching..."
    sleep $DELAY
    echo ""
fi

# Test function for D-Bus methods
test_method() {
    local method=$1
    local description=$2
    local phase=$3
    
    echo "🔍 Testing: $method ($description)"
    local cmd="gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.gnome.Shell.Extensions.ActiveWindowDetails.$method"
    echo "Command: $cmd"
    
    local result
    result=$(eval "$cmd" 2>&1)
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "✅ SUCCESS [$phase]: $result"
    else
        echo "❌ FAILED [$phase]: $result"
    fi
    echo ""
}

echo "📁 Extension Installation Check:"
if [ -d ~/.local/share/gnome-shell/extensions/$UUID ]; then
    echo "✅ Extension directory exists"
    echo "📂 Contents:"
    ls -la ~/.local/share/gnome-shell/extensions/$UUID
    echo ""
    echo "📏 Extension file size:"
    wc -l ~/.local/share/gnome-shell/extensions/$UUID/extension.js
else
    echo "❌ Extension directory missing"
fi
echo ""

echo "🔧 Extension Status Check:"
enabled_extensions=$(gsettings get org.gnome.shell enabled-extensions)
if [[ $enabled_extensions == *"$UUID"* ]]; then
    echo "✅ Extension is enabled in gsettings"
else
    echo "❌ Extension not enabled in gsettings"
    echo "Current enabled extensions: $enabled_extensions"
fi
echo ""

echo "🔌 D-Bus Interface Check:"
if gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.freedesktop.DBus.Introspectable.Introspect > /dev/null 2>&1; then
    echo "✅ D-Bus object is available"
    echo "📋 Available ActiveWindowDetails methods:"
    gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.freedesktop.DBus.Introspectable.Introspect 2>/dev/null | grep -o 'name="get[^"]*"' | sort -u || echo "No ActiveWindowDetails methods found"
    echo ""
    echo "📊 Method count analysis:"
    method_count=$(gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.freedesktop.DBus.Introspectable.Introspect 2>/dev/null | grep -o 'name="get[^"]*"' | wc -l)
    echo "Total methods found: $method_count"
    if [ "$method_count" -eq 11 ]; then
        echo "🎯 Expected count: Phase 1 complete (11 methods)"
    elif [ "$method_count" -eq 19 ]; then
        echo "🎯 Expected count: Phase 1 + Phase 2 complete (19 methods)"
    elif [ "$method_count" -eq 20 ]; then
        echo "🎯 Expected count: Phase 1 + Phase 2 + Phase 3 complete (20 methods)"
    else
        echo "⚠️  Unexpected count: Expected 11 (Phase 1), 19 (Phase 1+2), or 20 (Phase 1+2+3)"
    fi
else
    echo "❌ D-Bus object not available"
fi
echo ""

echo "🧪 TESTING ALL PHASE 1 METHODS (CORE FUNCTIONALITY)"
echo "===================================================="

# Phase 1 - Core Window/Process Information
test_method "getWinFocusData" "Focused window title" "PHASE1"
test_method "getWinPID" "Process ID of focused window" "PHASE1"
test_method "getWinClass" "Window class/application name" "PHASE1"
test_method "getWinRole" "Window role information" "PHASE1"
test_method "getProcessName" "Process executable name" "PHASE1"
test_method "getProcessPath" "Full executable path" "PHASE1"
test_method "getProcessCmdline" "Command line arguments" "PHASE1"
test_method "getProcessCwd" "Process working directory" "PHASE1"
test_method "getWinGeometry" "Window geometry (JSON)" "PHASE1"
test_method "getWinWorkspace" "Workspace information (JSON)" "PHASE1"
test_method "getProcessParent" "Parent process ID" "PHASE1"

echo "🧪 TESTING ALL PHASE 2 METHODS (APPLICATION-SPECIFIC)"
echo "======================================================"

# Phase 2 - Application-Specific Deep Data
test_method "getBrowserUrl" "Browser URL extraction" "PHASE2"
test_method "getBrowserTabInfo" "Browser tab information" "PHASE2"
test_method "getIdeProject" "IDE project detection" "PHASE2"
test_method "getIdeActiveFile" "IDE active file detection" "PHASE2"
test_method "getTerminalCommand" "Terminal command context" "PHASE2"
test_method "getFileManagerPath" "File manager current path" "PHASE2"
test_method "getDocumentPath" "Document path detection" "PHASE2"
test_method "getAppContext" "Unified application context" "PHASE2"

echo "🧪 TESTING PHASE 3 METHOD (COMPREHENSIVE DATA COLLECTION)"
echo "=========================================================="

# Phase 3 - Comprehensive Data Collection
test_method "getAllWindowData" "Complete window and process data collection" "PHASE3"

echo "🏁 COMPREHENSIVE TESTING COMPLETE!"
echo "=================================="
echo ""
echo "📊 SUMMARY OF FUNCTIONALITY:"
echo ""
echo "✅ Phase 1 - Core Window/Process Information (11 methods):"
echo "   - Basic window properties (title, class, role, geometry)"
echo "   - Process information (name, path, command line, working dir)"
echo "   - System context (workspace, parent process)"
echo ""
echo "🚀 Phase 2 - Application-Specific Deep Data (8 methods):"
echo "   - Browser: URL extraction from window titles"
echo "   - IDE: Project detection and active file identification"
echo "   - Terminal: Working directory and shell context"
echo "   - File Manager: Current directory paths"
echo "   - Documents: Document file path detection"
echo "   - Unified Context: Automatic app type detection"
echo ""
echo "🎯 EXPECTED RESULTS:"
echo "   - With Cursor IDE: Should detect project path, active file"
echo "   - With Browser: Should extract URLs/page titles when possible"
echo "   - With Terminal: Should show working directories"
echo "   - With File Manager: Should detect current paths"
echo ""
echo "📋 TROUBLESHOOTING:"
echo "   - If Phase 1 methods fail: Extension not loaded properly"
echo "   - If Phase 2 methods fail: D-Bus interface cache issue"
echo "   - If mixed results: Partial cache refresh"
echo ""
echo "🔧 System Information:"
echo "Current GNOME Shell version: $(gnome-shell --version)"
echo "Extension directory: ~/.local/share/gnome-shell/extensions/$UUID"
echo "Test completed at: $(date)"

# Performance test
echo ""
echo "⚡ PERFORMANCE TEST:"
echo "==================="
echo "Testing response times for key methods..."

start_time=$(date +%s%N)
gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.gnome.Shell.Extensions.ActiveWindowDetails.getWinFocusData > /dev/null 2>&1
end_time=$(date +%s%N)
duration=$((($end_time - $start_time) / 1000000))
echo "getWinFocusData response time: ${duration}ms"

if gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.gnome.Shell.Extensions.ActiveWindowDetails.getAppContext > /dev/null 2>&1; then
    start_time=$(date +%s%N)
    gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.gnome.Shell.Extensions.ActiveWindowDetails.getAppContext > /dev/null 2>&1
    end_time=$(date +%s%N)
    duration=$((($end_time - $start_time) / 1000000))
    echo "getAppContext response time: ${duration}ms"
else
    echo "getAppContext not available (Phase 2 not loaded)"
fi
