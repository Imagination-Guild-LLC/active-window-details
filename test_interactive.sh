#!/bin/bash

# =============================================================================
# Active Window Details Extension - Interactive Testing Script
# =============================================================================
#
# This script provides guided testing of application-specific context detection
# by prompting the user to switch between different types of applications.
#
# Features:
# - Guided application switching with user prompts
# - Real-time testing across different app types (browser, IDE, terminal, etc.)
# - Application-specific context validation
# - Performance measurement and extension status verification
#
# Application Types Tested:
# - Browser: URL extraction and browser type identification
# - IDE: Project path detection and active file identification
# - Terminal: Working directory and shell context
# - File Manager: Current directory path extraction
# - Document Viewer: Document path and type detection
#
# Usage:
#   ./test_interactive.sh
#
# Instructions:
#   1. Script will prompt you to switch to different applications
#   2. Press Enter when ready, or 's' to skip that application type
#   3. Script waits 3 seconds after each switch for window focus to settle
#   4. Results show both success/failure and extracted context data
#
# Expected Results:
#   - Correct application type detection for each window
#   - Meaningful context extraction (URLs, project paths, etc.)
#   - JSON formatted responses with rich metadata
#   - Fast response times (typically <50ms per method)
#
# =============================================================================

UUID="active-window-details@imaginationguild.com"
INTERFACE="org.gnome.Shell.Extensions.ActiveWindowDetails"

echo "🚀 INTERACTIVE EXTENSION TESTING SCRIPT"
echo "========================================"
echo "Extension UUID: $UUID"
echo "D-Bus Interface: $INTERFACE"
echo ""

# Test function for D-Bus methods
test_method() {
    local method=$1
    local description=$2
    local phase=$3
    
    echo "🔍 Testing: $method ($description)"
    local cmd="gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.gnome.Shell.Extensions.ActiveWindowDetails.$method"
    
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

# Prompt user to switch applications
prompt_switch() {
    local app_type=$1
    local instructions=$2
    
    echo ""
    echo "🔄 APPLICATION SWITCH REQUIRED"
    echo "=============================="
    echo "App Type: $app_type"
    echo "Instructions: $instructions"
    echo ""
    read -p "Switch to $app_type and press Enter when ready (or 's' to skip): " response
    
    if [[ "$response" == "s" || "$response" == "S" ]]; then
        echo "⏭️  Skipping $app_type tests"
        return 1
    fi
    
    echo "⏳ Waiting 3 seconds for window focus to settle..."
    sleep 3
    echo ""
    return 0
}

# Quick extension status check
echo "🔧 Quick Extension Status Check:"
enabled_extensions=$(gsettings get org.gnome.shell enabled-extensions)
if [[ $enabled_extensions == *"$UUID"* ]]; then
    echo "✅ Extension is enabled"
else
    echo "❌ Extension not enabled - please enable first!"
    echo "Current enabled extensions: $enabled_extensions"
    exit 1
fi

# Check D-Bus availability
if ! gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.freedesktop.DBus.Introspectable.Introspect > /dev/null 2>&1; then
    echo "❌ D-Bus object not available - extension may not be loaded properly"
    exit 1
fi

method_count=$(gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.freedesktop.DBus.Introspectable.Introspect 2>/dev/null | grep -o 'name="get[^"]*"' | wc -l)
echo "📊 Available methods: $method_count (expecting 19 for full Phase 1+2)"
echo ""

# Current window test (starting point)
echo "🏠 TESTING CURRENT WINDOW (Cursor IDE)"
echo "======================================"
echo "Testing with whatever window is currently focused..."
test_method "getWinFocusData" "Focused window title" "CURRENT"
test_method "getWinClass" "Window class" "CURRENT"
test_method "getAppContext" "Unified application context" "CURRENT"

# Test Phase 1 methods with current window
echo "📋 Quick Phase 1 Test with Current Window:"
test_method "getProcessCwd" "Working directory" "PHASE1"
test_method "getWinGeometry" "Window geometry" "PHASE1"

# Browser Testing
if prompt_switch "BROWSER" "Switch to one of your Brave browser windows. Make sure a website is loaded with a clear URL in the title."; then
    echo "🌐 TESTING BROWSER FUNCTIONALITY"
    echo "================================"
    
    # Test browser-specific methods
    test_method "getBrowserUrl" "Browser URL extraction" "BROWSER"
    test_method "getBrowserTabInfo" "Browser tab information" "BROWSER"
    test_method "getAppContext" "Unified browser context" "BROWSER"
    
    # Test core methods with browser
    echo "📋 Core methods with browser:"
    test_method "getWinClass" "Browser window class" "BROWSER"
    test_method "getProcessName" "Browser process name" "BROWSER"
    test_method "getProcessCwd" "Browser working directory" "BROWSER"
fi

# IDE Testing (back to Cursor)
if prompt_switch "IDE" "Switch back to Cursor IDE. Make sure you have a file open in the project."; then
    echo "💻 TESTING IDE FUNCTIONALITY"
    echo "============================"
    
    # Test IDE-specific methods
    test_method "getIdeProject" "IDE project detection" "IDE"
    test_method "getIdeActiveFile" "IDE active file detection" "IDE"
    test_method "getAppContext" "Unified IDE context" "IDE"
    
    # Test core methods with IDE
    echo "📋 Core methods with IDE:"
    test_method "getWinClass" "IDE window class" "IDE"
    test_method "getProcessCwd" "IDE working directory" "IDE"
    test_method "getProcessCmdline" "IDE command line" "IDE"
fi

# Terminal Testing
if prompt_switch "TERMINAL" "Open a terminal window (gnome-terminal, etc.) and navigate to a specific directory."; then
    echo "🖥️  TESTING TERMINAL FUNCTIONALITY"
    echo "=================================="
    
    # Test terminal-specific methods
    test_method "getTerminalCommand" "Terminal command context" "TERMINAL"
    test_method "getAppContext" "Unified terminal context" "TERMINAL"
    
    # Test core methods with terminal
    echo "📋 Core methods with terminal:"
    test_method "getWinClass" "Terminal window class" "TERMINAL"
    test_method "getProcessCwd" "Terminal working directory" "TERMINAL"
fi

# File Manager Testing
if prompt_switch "FILE_MANAGER" "Open file manager (Nautilus/Files) and navigate to a specific folder."; then
    echo "📁 TESTING FILE MANAGER FUNCTIONALITY"
    echo "====================================="
    
    # Test file manager-specific methods
    test_method "getFileManagerPath" "File manager current path" "FILE_MANAGER"
    test_method "getAppContext" "Unified file manager context" "FILE_MANAGER"
    
    # Test core methods with file manager
    echo "📋 Core methods with file manager:"
    test_method "getWinClass" "File manager window class" "FILE_MANAGER"
    test_method "getWinRole" "File manager window role" "FILE_MANAGER"
fi

# Document Testing
if prompt_switch "DOCUMENT" "Open a document viewer (PDF, LibreOffice, etc.) with a document loaded."; then
    echo "📄 TESTING DOCUMENT FUNCTIONALITY"
    echo "================================="
    
    # Test document-specific methods
    test_method "getDocumentPath" "Document path detection" "DOCUMENT"
    test_method "getAppContext" "Unified document context" "DOCUMENT"
    
    # Test core methods with document
    echo "📋 Core methods with document:"
    test_method "getWinClass" "Document window class" "DOCUMENT"
fi

# Final comprehensive test
echo ""
echo "🏁 TESTING COMPLETE!"
echo "===================="
echo ""
echo "📊 SUMMARY OF WHAT WE TESTED:"
echo ""
echo "✅ Application-Specific Context Detection:"
echo "   - Browser: URL extraction and browser type identification"
echo "   - IDE: Project path and active file detection"
echo "   - Terminal: Working directory and shell context"
echo "   - File Manager: Current directory path extraction"
echo "   - Document: Document path and type detection"
echo ""
echo "✅ Unified Context Method:"
echo "   - getAppContext: Automatic application type detection"
echo "   - Provides appropriate context based on detected app type"
echo ""
echo "📋 WHAT TO LOOK FOR IN RESULTS:"
echo "   ✅ SUCCESS responses with meaningful data"
echo "   🔍 JSON formatted responses for complex data"
echo "   ⚠️  Error messages for unsupported applications"
echo "   🎯 Accurate application type detection"
echo ""
echo "🔧 System Information:"
echo "GNOME Shell version: $(gnome-shell --version)"
echo "Extension directory: ~/.local/share/gnome-shell/extensions/$UUID"
echo "Test completed at: $(date)"

# Performance summary
echo ""
echo "⚡ QUICK PERFORMANCE CHECK:"
echo "=========================="
echo "Testing response time for getAppContext method..."

start_time=$(date +%s%N)
gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.gnome.Shell.Extensions.ActiveWindowDetails.getAppContext > /dev/null 2>&1
end_time=$(date +%s%N)
duration=$((($end_time - $start_time) / 1000000))
echo "getAppContext response time: ${duration}ms"

echo ""
echo "🎉 Interactive testing session complete!"
echo "You can run this script again anytime to test with different applications."
