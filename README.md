# Active Window Details

A comprehensive GNOME Shell extension that provides detailed window and process monitoring capabilities through D-Bus. Designed for productivity tracking, time analysis, and workflow monitoring with rich application-specific context detection.

> **Attribution**: This extension is a fork and major rewrite of [Evertrack](https://github.com/rodrigopfarias/evt-pid-win-ext) by [@rodrigopfarias](https://github.com/rodrigopfarias). All new features and enhancements by [Imagination Guild LLC](https://github.com/Imagination-Guild-LLC).

## Features

✅ **Core Window/Process Information** (11 methods)
- Basic window properties (title, class, role, geometry, workspace)
- Process details (PID, name, path, command line, working directory, parent PID)

🚀 **Application-Specific Context Detection** (8 methods)
- **Browser**: URL extraction and browser type identification
- **IDE**: Project path detection and active file identification  
- **Terminal**: Working directory and shell context
- **File Manager**: Current directory path extraction
- **Document Viewer**: Document path and type detection
- **Unified Context**: Automatic application type detection with relevant context

🎯 **Comprehensive Data Collection** (1 method)
- **getAllWindowData**: Single API call combining all Phase 1 + Phase 2 data with performance metrics

**Total: 20 D-Bus methods available**

⚡ **Performance Optimized**
- Fast D-Bus response times (~20ms)
- Efficient `/proc` filesystem access
- Comprehensive error handling and graceful fallbacks

## Installation

### Manual Installation - GNOME Shell 45, 46, and 47
```bash
# Remove any existing installation
sudo rm -rf /usr/share/gnome-shell/extensions/active-window-details@imaginationguild.com
sudo rm -rf ~/.local/share/gnome-shell/extensions/active-window-details@imaginationguild.com/

# Install the extension
sudo cp -r v45-46-47/ /usr/share/gnome-shell/extensions/active-window-details@imaginationguild.com/
# OR for user-only installation:
cp -r v45-46-47/ ~/.local/share/gnome-shell/extensions/active-window-details@imaginationguild.com/

# Enable the extension
gnome-extensions enable active-window-details@imaginationguild.com
```

## Usage

### Get Window Focus Data
Retrieve information about the currently focused window:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getWinFocusData
```

### Get Window PID
Retrieve the process ID (PID) of the currently focused window:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getWinPID
```

### Get Window Class
Retrieve the window class (application identifier) of the currently focused window:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getWinClass
```
**Example Output:** `('Cursor',)` when Cursor IDE is focused

### Get Window Role
Retrieve the window role identifier:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getWinRole
```

### Get Process Name
Retrieve the executable name of the focused window's process:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getProcessName
```

### Get Process Path
Retrieve the full executable path of the focused window's process:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getProcessPath
```

### Get Process Command Line
Retrieve the command line arguments of the focused window's process:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getProcessCmdline
```

### Get Process Working Directory
Retrieve the current working directory of the focused window's process:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getProcessCwd
```

### Get Window Geometry
Retrieve the size and position of the focused window:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getWinGeometry
```
**Example Output:** `'{"x":100,"y":200,"width":1200,"height":800}'`

### Get Window Workspace
Retrieve the current workspace information:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getWinWorkspace
```
**Example Output:** `'{"index":0,"name":"Workspace 1"}'`

### Get Process Parent
Retrieve the parent process ID of the focused window's process:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getProcessParent
```

### Get Browser URL and Context
Extract URL and browser information from browser windows:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getBrowserUrl
```
**Example Output:** `'{"url":"https://github.com","title":"GitHub","browserType":"Brave-browser","isBrowser":true}'`

### Get Browser Tab Information
Retrieve detailed browser tab information and context:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getBrowserTabInfo
```
**Example Output:** `'{"url":"https://github.com/user/repo","title":"GitHub Repository","browserType":"Brave-browser","tabCount":"estimated","isBrowser":true}'`

### Get IDE Project Information
Detect IDE project context and active files:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getIdeProject
```
**Example Output:** `'{"projectPath":"/home/user/my-project","projectName":"my-project","ideType":"Cursor","isIde":true}'`

### Get IDE Active File
Retrieve information about the currently active file in IDEs:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getIdeActiveFile
```
**Example Output:** `'{"activeFile":"README.md","filePath":"/home/user/project/README.md","ideType":"Cursor","isIde":true}'`

### Get Terminal Context
Retrieve terminal working directory and context:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getTerminalCommand
```
**Example Output:** `'{"workingDirectory":"/home/user","terminalType":"Gnome-terminal","isTerminal":true}'`

### Get File Manager Path
Retrieve the current directory path from file manager applications:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getFileManagerPath
```
**Example Output:** `'{"currentPath":"/home/user/Documents","fileManagerType":"org.gnome.Nautilus","isFileManager":true}'`

### Get Document Path
Retrieve document information from document viewer applications:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getDocumentPath
```
**Example Output:** `'{"documentPath":"/home/user/document.pdf","documentType":"Evince","isDocument":true}'`

### Get Unified Application Context (Recommended)
Automatically detect application type and return relevant context:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getAppContext
```
**Example Output:** `'{"appType":"ide","windowClass":"Cursor","context":{"project":{"projectPath":"/home/user/project"},"activeFile":{"activeFile":"README.md"}},"timestamp":1757814282248}'`

### Get All Window Data (Comprehensive - Phase 3)
🚀 **RECOMMENDED** - Get comprehensive data combining all available information in one call:
```bash
gdbus call --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails \
    --method org.gnome.Shell.Extensions.ActiveWindowDetails.getAllWindowData
```
**Example Output:** 
```json
{
  "timestamp": 1757831576764,
  "dataCollectionVersion": "1.0",
  "extensionInfo": {
    "name": "Active Window Details",
    "uuid": "active-window-details@imaginationguild.com",
    "version": "1.0.0"
  },
  "core": {
    "title": "README.md - myproject - Cursor",
    "windowClass": "Cursor",
    "pid": 13190
  },
  "applicationContext": {
    "detectedType": "ide",
    "specificData": {
      "project": {
        "projectPath": "/home/user/project",
        "projectName": "myproject",
        "ideType": "Cursor"
      },
      "activeFile": {
        "activeFile": "README.md"
      }
    }
  },
  "performance": {
    "collectionDuration": 1
  }
}
```

**Benefits:**
- **Single API call** for complete window/process information
- **Combines Phase 1 + Phase 2** data efficiently
- **Application type detection** with rich context
- **Performance metrics** included
- **Structured JSON** response for easy parsing

---

## Development

For developers interested in contributing to or extending this extension, see the comprehensive [DEVELOPER_GUIDE.md](DEVELOPER_GUIDE.md) which includes:

- Critical development lessons and D-Bus caching solutions
- Complete testing framework and procedures  
- Architecture overview and implementation phases
- Troubleshooting guide for common issues
- Future enhancement opportunities and technical implementations
- Contributing guidelines and security considerations

## Quick Installation Verification

After installation, verify the extension is working:
```bash
# Check extension status
gnome-extensions list --enabled | grep active-window-details

# Test basic functionality
gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.gnome.Shell.Extensions.ActiveWindowDetails.getWinFocusData
```

---
