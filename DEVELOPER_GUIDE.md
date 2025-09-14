# Active Window Details - Developer Guide

A comprehensive guide for developers working on the Active Window Details GNOME Shell extension. This document contains critical development lessons, testing procedures, and future enhancement opportunities.

## Table of Contents
1. [Critical Development Lessons](#critical-development-lessons)
2. [Development Workflow](#development-workflow)
3. [Testing Framework](#testing-framework)
4. [Architecture Overview](#architecture-overview)
5. [Troubleshooting Guide](#troubleshooting-guide)
6. [Future Enhancement Opportunities](#future-enhancement-opportunities)
7. [Contributing Guidelines](#contributing-guidelines)

---

## Critical Development Lessons

### ⚠️ D-Bus Extension Development Rules

These lessons were learned through extensive debugging and should be strictly followed:

#### 1. D-Bus Interface Caching
**CRITICAL**: GNOME Shell heavily caches D-Bus interfaces. Simple file updates do not refresh them.

- **Adding new methods**: Requires restarting the user session or full logout/login
- **Interface changes**: Major interface modifications may require system reboot
- **Safe reload command**: `dbus-send --session --dest=org.gnome.Shell --type=method_call /org/gnome/Shell/Actions org.gnome.Shell.Actions.Reload`
- **Result**: Clears ALL D-Bus cache completely, requires extension re-enable but is SAFE

#### 2. Extension Management
**Never run destructive commands** like `killall gnome-shell` on production systems.

**Safe Extension Reload Workflow**:
```bash
# 1. Copy updated files
cp -r v45-46-47/* ~/.local/share/gnome-shell/extensions/active-window-details@imaginationguild.com/

# 2. Restart extension
gnome-extensions disable active-window-details@imaginationguild.com
gnome-extensions enable active-window-details@imaginationguild.com

# 3. Verify interface (optional)
busctl --user introspect org.gnome.Shell /org/gnome/Shell/Extensions/ActiveWindowDetails

# 4. Test method
gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.gnome.Shell.Extensions.ActiveWindowDetails.getWinFocusData
```

#### 2.1. Configuration UI Caching Issues
**CRITICAL**: GNOME Shell and Extension Manager heavily cache configuration interfaces and metadata.

- **Adding preferences UI**: Often requires system reboot to appear in Extension Manager
- **Metadata changes**: Extension Manager may not detect `settings-schema` additions without reboot
- **GSettings schema changes**: New schema files may not be recognized until session restart
- **Preferences window updates**: Changes to `prefs.js` may require logout/login or reboot

**Configuration UI Troubleshooting**:
```bash
# 1. Verify files are copied correctly
ls -la ~/.local/share/gnome-shell/extensions/active-window-details@imaginationguild.com/
cat ~/.local/share/gnome-shell/extensions/active-window-details@imaginationguild.com/metadata.json

# 2. Check schema compilation
ls -la ~/.local/share/gnome-shell/extensions/active-window-details@imaginationguild.com/schemas/

# 3. Test preferences directly (may work even when Extension Manager doesn't show gear icon)
gnome-extensions prefs active-window-details@imaginationguild.com

# 4. If gear icon doesn't appear in Extension Manager: REBOOT REQUIRED
# Extension Manager caching is more aggressive than D-Bus caching
```

**Why Reboot is Often Required**:
- Extension Manager loads metadata once and caches it heavily
- GSettings schema registration happens at session start
- Preferences UI discovery is part of extension enumeration during shell startup
- Unlike D-Bus methods, UI changes require deeper shell integration refresh

#### 3. GNOME Shell Restart (Safe Method)
```bash
# Safe GNOME Shell restart (equivalent to Alt+F2 → "r")
gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval 'Meta.restart("Restarting GNOME Shell for extension development");'
```
**WARNING**: May not be sufficient for D-Bus interface changes.

#### 4. Extension Management Commands
```bash
# Check installed extensions
ls -la ~/.local/share/gnome-shell/extensions/

# List all extensions
gnome-extensions list

# List enabled extensions
gnome-extensions list --enabled

# Extension information
gnome-extensions info active-window-details@imaginationguild.com

# System-wide extensions
ls -la /usr/share/gnome-shell/extensions/
```

---

## Development Workflow

### Proven Development Strategy

1. **Add ALL D-Bus method definitions at once** (avoid interface caching issues)
2. **Implement methods with stubs initially**: `return "NOT_IMPLEMENTED_YET";`
3. **Use D-Bus reload when interface changes are needed**
4. **Implement actual functionality incrementally**
5. **Update documentation as each method is completed**

### Safe Testing Approach

1. **Development Environment Setup**:
   ```bash
   # Create development copy
   cp -r v45-46-47/ ~/.local/share/gnome-shell/extensions/active-window-details@imaginationguild.com/
   
   # Enable extension
   gnome-extensions enable active-window-details@imaginationguild.com
   ```

2. **Iterative Development**:
   - Make code changes
   - Copy files to extension directory
   - Disable/enable extension
   - Test functionality
   - Document results

3. **Always verify after changes**:
   ```bash
   # Check extension status
   gnome-extensions show active-window-details@imaginationguild.com
   
   # Test basic functionality
   gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.gnome.Shell.Extensions.ActiveWindowDetails.getWinFocusData
   ```

---

## Testing Framework

### Comprehensive Test Scripts

The extension includes three test scripts for different testing scenarios:

#### 1. `test_all_phases.sh` - Complete Functionality Test
Tests all 20 D-Bus methods across 3 implementation phases.

**Usage**:
```bash
./test_all_phases.sh
```

**What it tests**:
- Phase 1: Core Window/Process Information (11 methods)
- Phase 2: Application-Specific Context Detection (8 methods)
- Phase 3: Comprehensive Data Collection (1 method)
- Performance validation
- Method count verification

#### 2. `test_interactive.sh` - Application-Specific Testing
Guided testing across different application types with user interaction.

**Usage**:
```bash
./test_interactive.sh
```

**Testing flow**:
- Browser applications (URL extraction)
- IDE/Editor applications (project context)
- Terminal applications (working directory)
- File manager applications (current path)
- Document viewer applications (document context)

#### 3. `test_getAllWindowData.sh` - Comprehensive Method Testing
Focused testing of the Phase 3 comprehensive data collection method.

**Usage**:
```bash
./test_getAllWindowData.sh
```

**Validation points**:
- JSON structure completeness
- Application type detection accuracy
- Performance metrics (target: <50ms response time)
- Data quality indicators
- Error handling

### Manual Testing Commands

#### Quick Functionality Test
```bash
# Basic window data
gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.gnome.Shell.Extensions.ActiveWindowDetails.getWinFocusData

# Application context detection
gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.gnome.Shell.Extensions.ActiveWindowDetails.getAppContext

# Comprehensive data (recommended)
gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.gnome.Shell.Extensions.ActiveWindowDetails.getAllWindowData
```

#### Installation Validation
```bash
# Check extension status
gnome-extensions list --enabled | grep active-window-details

# Verify D-Bus interface
gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.freedesktop.DBus.Introspectable.Introspect
```

### Performance Benchmarking

**Expected Response Times**:
- Core methods (Phase 1): 5-20ms
- Application-specific methods (Phase 2): 10-30ms
- Comprehensive method (Phase 3): 20-50ms

**Performance Test**:
```bash
# Time individual method calls
time gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.gnome.Shell.Extensions.ActiveWindowDetails.getAllWindowData
```

---

## Architecture Overview

### Project Structure
```
v45-46-47/
├── extension.js       # Main extension implementation
├── metadata.json      # Extension metadata and configuration
└── LICENSE           # License information
```

### Implementation Phases

#### Phase 1: Core Window/Process Information (11 methods)
- `getWinFocusData`, `getWinPID` - Original basic methods
- `getWinClass`, `getWinRole` - Window identification
- `getProcessName`, `getProcessPath`, `getProcessCmdline`, `getProcessCwd` - Process details
- `getWinGeometry`, `getWinWorkspace`, `getProcessParent` - Extended context

#### Phase 2: Application-Specific Context Detection (8 methods)
- `getBrowserUrl`, `getBrowserTabInfo` - Browser-specific information
- `getIdeProject`, `getIdeActiveFile` - IDE/editor context
- `getTerminalCommand` - Terminal working directory and context
- `getFileManagerPath` - File manager current location
- `getDocumentPath` - Document viewer information
- `getAppContext` - Unified context detection (automatically determines app type)

#### Phase 3: Comprehensive Data Collection (1 method)
- `getAllWindowData` - Single method combining all Phase 1 + Phase 2 data with metadata

### D-Bus Interface Definition

The extension exposes methods through the D-Bus interface:
- **Service**: `org.gnome.Shell`
- **Object Path**: `/org/gnome/Shell/Extensions/ActiveWindowDetails`
- **Interface**: `org.gnome.Shell.Extensions.ActiveWindowDetails`

### Application Context Detection

The extension intelligently detects application types and extracts relevant context:

- **Browser Detection**: Window class patterns, title parsing for URLs
- **IDE Detection**: Project path extraction, active file identification
- **Terminal Detection**: Working directory extraction from process information
- **File Manager Detection**: Current directory parsing from window titles
- **Document Detection**: Document path extraction from viewer applications

---

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. Extension Not Loading
**Symptoms**: Extension not listed in `gnome-extensions list`

**Solutions**:
```bash
# Check file permissions
ls -la ~/.local/share/gnome-shell/extensions/active-window-details@imaginationguild.com/

# Verify metadata.json syntax
cat ~/.local/share/gnome-shell/extensions/active-window-details@imaginationguild.com/metadata.json

# Check GNOME Shell logs
journalctl -f -o cat /usr/bin/gnome-shell
```

#### 2. D-Bus Methods Not Available
**Symptoms**: `Error: GDBus.Error:org.freedesktop.DBus.Error.UnknownMethod`

**Solutions**:
```bash
# 1. Restart extension
gnome-extensions disable active-window-details@imaginationguild.com
gnome-extensions enable active-window-details@imaginationguild.com

# 2. Clear D-Bus cache
dbus-send --session --dest=org.gnome.Shell --type=method_call /org/gnome/Shell/Actions org.gnome.Shell.Actions.Reload

# 3. Full GNOME Shell restart
gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell --method org.gnome.Shell.Eval 'Meta.restart("Extension reload");'

# 4. If still failing, logout/login or reboot
```

#### 3. Methods Returning Empty Data
**Symptoms**: Methods return empty strings or null data

**Debugging**:
```bash
# Check if window has focus
gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.gnome.Shell.Extensions.ActiveWindowDetails.getWinFocusData

# Verify process information
gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.gnome.Shell.Extensions.ActiveWindowDetails.getWinPID

# Check extension logs
journalctl -f -o cat | grep -i "active-window"
```

#### 4. Performance Issues
**Symptoms**: Slow response times (>100ms)

**Investigation**:
```bash
# Profile method calls
time gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.gnome.Shell.Extensions.ActiveWindowDetails.getAllWindowData

# Check system load
top -p $(gdbus call --session --dest org.gnome.Shell --object-path /org/gnome/Shell/Extensions/ActiveWindowDetails --method org.gnome.Shell.Extensions.ActiveWindowDetails.getWinPID | tr -d "(,)'")
```

#### 5. UUID Conflicts
**Symptoms**: Multiple versions of extension conflict

**Resolution**:
```bash
# Remove all versions
rm -rf ~/.local/share/gnome-shell/extensions/*active-window*
rm -rf ~/.local/share/gnome-shell/extensions/*evt-pid*
rm -rf ~/.local/share/gnome-shell/extensions/*evertrack*

# Install clean version
cp -r v45-46-47/ ~/.local/share/gnome-shell/extensions/active-window-details@imaginationguild.com/
gnome-extensions enable active-window-details@imaginationguild.com
```

---

## Future Enhancement Opportunities

### System Context Features

#### Network Connection Monitoring
**Implementation Approach**: Monitor `/proc/[pid]/net/` files and use `netstat`/`ss` command integration

**Potential Methods**:
- `getNetworkConnections`: Return active network connections for focused process
- `getRemoteHosts`: List remote servers/services the application is communicating with
- `getBandwidthUsage`: Monitor network I/O for the process
- `getSocketInfo`: Detailed socket information (TCP/UDP states, ports)

**Technical Implementation**:
- Parse `/proc/[pid]/net/tcp` and `/proc/[pid]/net/udp` files
- Use `lsof -p [pid]` for detailed socket information
- Integrate with NetworkManager D-Bus for connection context

#### File System Monitoring
**Implementation Approach**: Use `inotify` and `/proc/[pid]/fd/` monitoring

**Potential Methods**:
- `getOpenFiles`: List all files currently open by the process
- `getRecentFileAccess`: Track recently accessed files
- `getFileSystemActivity`: Monitor read/write operations
- `getWorkingSet`: Identify the "working set" of files for a project

**Technical Implementation**:
- Monitor `/proc/[pid]/fd/` directory for file descriptors
- Use `lsof -p [pid]` for comprehensive file handle information
- Implement inotify watchers for file access patterns
- Parse `/proc/[pid]/io` for I/O statistics

#### Process Resource Monitoring
**Implementation Approach**: Integrate with `/proc` filesystem and system monitoring APIs

**Potential Methods**:
- `getMemoryUsage`: Detailed memory consumption (RSS, VSZ, shared)
- `getCPUUsage`: Real-time and historical CPU utilization
- `getProcessTree`: Complete parent/child process hierarchy
- `getThreadInfo`: Thread count and individual thread details

**Technical Implementation**:
- Parse `/proc/[pid]/stat`, `/proc/[pid]/status`, `/proc/[pid]/smaps`
- Use `ps` command integration for extended process information
- Monitor `/proc/[pid]/task/` for thread-level details

#### Environment and Configuration
**Implementation Approach**: Access process environment and system configuration

**Potential Methods**:
- `getEnvironmentVars`: Process environment variables (filtered for privacy)
- `getSystemdServices`: Related systemd services for the process
- `getContainerInfo`: Docker/Podman container context if applicable
- `getUserContext`: User session and group information

**Technical Implementation**:
- Read `/proc/[pid]/environ` with privacy filtering
- Use `systemctl` and D-Bus integration for systemd information
- Parse container runtime information from `/proc/[pid]/cgroup`

### Advanced Monitoring Capabilities

#### Screen and Display Integration
**Implementation Approach**: Integrate with Mutter and display server APIs

**Potential Methods**:
- `getScreenRegions`: Identify which monitor/region has focus
- `getDisplayConfiguration`: Multi-monitor setup details
- `getZoomLevel`: Current display zoom/scaling
- `getColorProfile`: Active color profile for color-sensitive work

**Technical Implementation**:
- Use Mutter D-Bus interfaces for display information
- Integrate with GNOME Settings for display configuration
- Access Wayland/X11 display server information

#### Input Device Integration
**Implementation Approach**: Monitor input devices with privacy considerations

**Potential Methods**:
- `getKeyboardActivity`: Keystroke frequency patterns (no content capture)
- `getMouseActivity`: Mouse movement and click patterns
- `getInputDevices`: Connected input devices (external keyboards, mice)
- `getInputLatency`: Measure input lag for performance analysis

**Technical Implementation**:
- Use evdev for input device monitoring (requires careful permission handling)
- Integrate with GNOME Settings for input device configuration
- Monitor `/dev/input/` devices with appropriate permissions

#### Audio and Media Monitoring
**Implementation Approach**: PulseAudio/PipeWire integration

**Potential Methods**:
- `getAudioState`: Microphone usage, audio playback status
- `getMediaSessions`: Active media playback information
- `getScreenSharing`: Screen sharing or recording status
- `getCallStatus`: Video call detection and status

**Technical Implementation**:
- Use PulseAudio/PipeWire D-Bus APIs
- Monitor media keys and MPRIS D-Bus interface
- Integrate with portal APIs for screen sharing detection

#### Notification and Alert Integration
**Implementation Approach**: GNOME notification system integration

**Potential Methods**:
- `getNotificationHistory`: Recent notifications correlated with activity
- `getAlertContext`: System alerts and their relationship to current work
- `getFocusInterruptions`: Track notification-caused focus changes

**Technical Implementation**:
- Use GNOME Shell notification D-Bus interfaces
- Monitor notification daemon logs
- Track focus change events triggered by notifications

### Integration Opportunities

#### External Tool Integration
- **Git Integration**: Detect repository context and branch information
- **Docker Integration**: Container and compose stack context
- **IDE Plugin APIs**: Deep integration with VS Code, IntelliJ, etc.
- **Browser Extension APIs**: Coordinate with browser extensions for page context

#### Data Export and Analysis
- **Time Tracking APIs**: Integration with tools like Toggl, RescueTime
- **Analytics Frameworks**: Export data for analysis in R, Python, etc.
- **Visualization Tools**: Integration with Grafana, custom dashboards
- **Productivity Metrics**: Calculate and export productivity indicators

---

## Contributing Guidelines

### Security and Privacy Considerations

1. **Data Minimization**: Only collect data that serves the time tracking purpose
2. **User Consent**: All monitoring features should be opt-in
3. **Local Storage**: Keep all data local, no cloud transmission
4. **Encryption**: Sensitive data should be encrypted at rest
5. **Access Control**: Restrict access to monitoring data

### Performance Considerations

1. **Async Operations**: Use asynchronous D-Bus calls to prevent UI blocking
2. **Caching**: Cache frequently accessed data to reduce system calls
3. **Rate Limiting**: Implement rate limiting for expensive operations
4. **Resource Cleanup**: Properly clean up monitors and file handles

### Code Organization

1. **Modular Design**: Each feature category should be a separate module
2. **Common Interfaces**: Standardize return formats and error handling
3. **Configuration**: Make features configurable through GNOME settings
4. **Documentation**: Document all D-Bus interfaces and system dependencies

### Testing Requirements

1. **Multi-Environment**: Test on different GNOME Shell versions
2. **Permission Handling**: Test behavior with restricted permissions
3. **Error Scenarios**: Test with processes that don't expose expected information
4. **Performance Impact**: Measure and document performance overhead

### Submission Process

1. **Fork and Branch**: Create feature branches for new functionality
2. **Test Coverage**: Include comprehensive tests for new methods
3. **Documentation**: Update this guide and user documentation
4. **Performance Validation**: Ensure new features meet performance targets
5. **Privacy Review**: Verify compliance with privacy guidelines

---

## Development Environment

### Recommended Setup

**Primary Test Environment**:
- **Application**: Cursor IDE
- **Test Project**: Any development project with multiple files
- **GNOME Shell Versions**: 45-47 (current focus)

**Testing Applications**:
- **Browser**: Brave, Firefox, Chrome (for browser context testing)
- **IDE**: Cursor, VS Code, IntelliJ (for IDE context testing)
- **Terminal**: GNOME Terminal, Terminator (for terminal context testing)
- **File Manager**: Nautilus (for file manager context testing)
- **Document Viewer**: Evince, LibreOffice (for document context testing)

### Development Tools

**Essential Commands**:
```bash
# Extension development workflow
gnome-extensions disable active-window-details@imaginationguild.com && gnome-extensions enable active-window-details@imaginationguild.com

# D-Bus debugging
busctl --user introspect org.gnome.Shell /org/gnome/Shell/Extensions/ActiveWindowDetails

# GNOME Shell logs
journalctl -f -o cat /usr/bin/gnome-shell

# Process monitoring
htop -p $(pgrep gnome-shell)
```

This guide serves as the comprehensive resource for anyone developing or extending the Active Window Details GNOME Shell extension. Keep it updated as new lessons are learned and features are implemented.
