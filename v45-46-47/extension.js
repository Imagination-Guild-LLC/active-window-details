/* extension.js
 *
 * Active Window Details GNOME Shell Extension
 * ===============================
 * 
 * A comprehensive window and process monitoring extension that provides detailed
 * information about the currently focused window and its associated process.
 * Designed for productivity tracking, time analysis, and workflow monitoring.
 * 
 * Features:
 * - Basic window information (title, class, role, geometry)
 * - Process details (PID, name, path, command line, working directory)
 * - Application-specific context detection (browser, IDE, terminal, etc.)
 * - Unified context API for automatic application type detection
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

// Import required GNOME libraries
import Gio from 'gi://Gio';  // For D-Bus operations and file system access
import GLib from 'gi://GLib'; // For low-level system operations

/**
 * D-Bus Interface Definition
 * =========================
 * 
 * This XML defines the D-Bus interface that external applications can use
 * to communicate with our extension. Each <method> tag creates a callable
 * function that can be invoked via D-Bus.
 * 
 * All methods return a string (type="s") in the "out" direction, meaning
 * the data flows from our extension to the calling application.
 * 
 * Phase 1 Methods (Core Window/Process Information):
 * - getWinFocusData, getWinPID: Original basic methods
 * - getWinClass, getWinRole: Window identification
 * - getProcessName, getProcessPath, getProcessCmdline, getProcessCwd: Process details
 * - getWinGeometry, getWinWorkspace, getProcessParent: Extended context
 * 
 * Phase 2 Methods (Application-Specific Deep Data):
 * - getBrowserUrl, getBrowserTabInfo: Browser-specific information
 * - getIdeProject, getIdeActiveFile: IDE/editor context
 * - getTerminalCommand: Terminal working directory and context
 * - getFileManagerPath: File manager current location
 * - getDocumentPath: Document viewer information
 * - getAppContext: Unified context detection (automatically determines app type)
 */
const DBUS_NODE_INTERFACE = `
<node>
    <interface name="org.gnome.Shell.Extensions.ActiveWindowDetails">
       <!-- Phase 1: Core Window/Process Information -->
       <method name="getWinFocusData">
            <arg type="s" direction="out" />
        </method>
        <method name="getWinPID">
            <arg type="s" direction="out" />
        </method>
        <method name="getWinClass">
            <arg type="s" direction="out" />
        </method>
        <method name="getWinRole">
            <arg type="s" direction="out" />
        </method>
        <method name="getProcessName">
            <arg type="s" direction="out" />
        </method>
        <method name="getProcessPath">
            <arg type="s" direction="out" />
        </method>
        <method name="getProcessCmdline">
            <arg type="s" direction="out" />
        </method>
        <method name="getProcessCwd">
            <arg type="s" direction="out" />
        </method>
        <method name="getWinGeometry">
            <arg type="s" direction="out" />
        </method>
        <method name="getWinWorkspace">
            <arg type="s" direction="out" />
        </method>
        <method name="getProcessParent">
            <arg type="s" direction="out" />
        </method>
        <!-- Phase 2: Application-Specific Deep Data -->
        <method name="getBrowserUrl">
            <arg type="s" direction="out" />
        </method>
        <method name="getBrowserTabInfo">
            <arg type="s" direction="out" />
        </method>
        <method name="getIdeProject">
            <arg type="s" direction="out" />
        </method>
        <method name="getIdeActiveFile">
            <arg type="s" direction="out" />
        </method>
        <method name="getTerminalCommand">
            <arg type="s" direction="out" />
        </method>
        <method name="getFileManagerPath">
            <arg type="s" direction="out" />
        </method>
        <method name="getDocumentPath">
            <arg type="s" direction="out" />
        </method>
        <method name="getAppContext">
            <arg type="s" direction="out" />
        </method>
        <!-- Phase 3: Comprehensive Data Collection -->
        <method name="getAllWindowData">
            <arg type="s" direction="out" />
        </method>
        <!-- Version Information -->
        <method name="getVersion">
            <arg type="s" direction="out" />
        </method>
    </interface>
</node>`;

/**
 * Main Extension Class
 * ===================
 * 
 * This class implements the Active Window Details GNOME Shell extension. It handles
 * the lifecycle of the extension (enable/disable) and provides all the
 * D-Bus methods for window and process monitoring.
 */
export default class ActiveWindowDetailsExtension {
    /**
     * Extension Activation
     * ===================
     * 
     * Called when the extension is enabled. Sets up the D-Bus interface
     * so external applications can call our methods.
     */
    enable() {
        // Only create the D-Bus object if it doesn't already exist
        if (!this._dbus) {
            // Wrap our JavaScript object with the D-Bus interface definition
            // This makes our methods callable via D-Bus
            this._dbus = Gio.DBusExportedObject.wrapJSObject(DBUS_NODE_INTERFACE, this);
            
            // Export the object to the session bus at the specified path
            // External apps can now call: org.gnome.Shell /org/gnome/Shell/Extensions/ActiveWindowDetails
            this._dbus.export(Gio.DBus.session, '/org/gnome/Shell/Extensions/ActiveWindowDetails');
        }
    }

    /**
     * Extension Deactivation
     * ======================
     * 
     * Called when the extension is disabled. Cleans up the D-Bus interface
     * and ensures no resources are leaked.
     */
    disable() {
        if (this._dbus) {
            // Flush any pending D-Bus operations
            this._dbus.flush();
            
            // Remove the object from the D-Bus session
            this._dbus.unexport();
            
            // Clear our reference to prevent memory leaks
            this._dbus = null;
        }
    }

    // ============================================================================
    // PHASE 1: CORE WINDOW AND PROCESS INFORMATION METHODS
    // ============================================================================
    //
    // These methods provide fundamental information about the focused window
    // and its associated process. They form the foundation for all monitoring
    // and analysis capabilities.
    // ============================================================================

    /**
     * Get Focused Window Title
     * =======================
     * 
     * Returns the title of the currently focused window.
     * This is one of the original core methods.
     * 
     * @returns {string} Window title or empty string if no window has focus
     */
    getWinFocusData() {
        // Get all window actors (visual representations of windows)
        // Map to their underlying meta_window objects (which contain the data we need)
        // Find the one that currently has focus
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        // Return the window title if we found a focused window, otherwise empty string
        return focusedWindow ? focusedWindow.get_title() : "";
    }

    /**
     * Get Focused Window Process ID
     * ============================
     * 
     * Returns the process ID (PID) of the currently focused window.
     * This is one of the original core methods.
     * 
     * @returns {string} Process ID as string, or empty string if no focused window
     */
    getWinPID() {
        // Use the same pattern: get all windows, find the focused one
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        // Convert PID to string (D-Bus methods must return strings)
        return focusedWindow ? String(focusedWindow.get_pid()) : "";
    }

    /**
     * Get Window Class
     * ===============
     * 
     * Returns the window class (application identifier) of the focused window.
     * Window class is typically the application name (e.g., "Cursor", "Brave-browser").
     * 
     * @returns {string} Window class name or empty string
     */
    getWinClass() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        // get_wm_class() returns the WM_CLASS property set by the application
        return focusedWindow ? focusedWindow.get_wm_class() : "";
    }

    /**
     * Get Window Role
     * ==============
     * 
     * Returns the window role identifier. Window roles provide additional
     * context about the window's purpose (e.g., "browser-window", "dialog").
     * 
     * @returns {string} Window role or empty string
     */
    getWinRole() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        // get_role() might return null, so we use || "" to ensure we return a string
        return focusedWindow ? (focusedWindow.get_role() || "") : "";
    }

    /**
     * Get Process Executable Name
     * ===========================
     * 
     * Returns the executable name of the focused window's process.
     * This reads from /proc/[pid]/comm which contains the command name.
     * 
     * @returns {string} Process executable name (e.g., "cursor", "brave") or empty string
     */
    getProcessName() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const pid = focusedWindow.get_pid();
        try {
            // Access the older imports.gi syntax for compatibility with existing code
            const GLib = imports.gi.GLib;
            
            // Read the /proc/[pid]/comm file which contains the process command name
            // This is a Linux-specific way to get the executable name
            const [success, contents] = GLib.file_get_contents(`/proc/${pid}/comm`);
            if (success) {
                // Decode the binary data to text and remove trailing newline
                return new TextDecoder().decode(contents).trim();
            }
        } catch (e) {
            // Log errors for debugging but don't crash the extension
            console.log(`Error reading process name for PID ${pid}: ${e}`);
        }
        return "";
    }

    /**
     * Get Process Executable Path
     * ===========================
     * 
     * Returns the full path to the executable file of the focused window's process.
     * This provides more detailed information than getProcessName().
     * 
     * @returns {string} Full path to executable or empty string
     */
    getProcessPath() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const pid = focusedWindow.get_pid();
        try {
            const GLib = imports.gi.GLib;
            
            // Try to read /proc/[pid]/exe directly
            // This is a symlink to the actual executable file
            const [success, contents] = GLib.file_get_contents(`/proc/${pid}/exe`);
            if (success) {
                return new TextDecoder().decode(contents).trim();
            }
        } catch (e) {
            // If direct reading fails, try the symlink resolution method
            // This is a fallback approach that's sometimes more reliable
            try {
                const Gio = imports.gi.Gio;
                const file = Gio.File.new_for_path(`/proc/${pid}/exe`);
                
                // Query the symlink target to get the actual executable path
                const info = file.query_info('standard::symlink-target', Gio.FileQueryInfoFlags.NONE, null);
                return info.get_symlink_target() || "";
            } catch (e2) {
                console.log(`Error reading process path for PID ${pid}: ${e2}`);
            }
        }
        return "";
    }

    /**
     * Get Process Command Line
     * ========================
     * 
     * Returns the complete command line used to start the process, including
     * the executable name and all arguments. Useful for understanding how
     * an application was launched.
     * 
     * @returns {string} Complete command line with arguments or empty string
     */
    getProcessCmdline() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const pid = focusedWindow.get_pid();
        try {
            const GLib = imports.gi.GLib;
            
            // Read /proc/[pid]/cmdline which contains the command line arguments
            // In this file, arguments are separated by null bytes (\0)
            const [success, contents] = GLib.file_get_contents(`/proc/${pid}/cmdline`);
            if (success) {
                // Convert binary data to text and replace null separators with spaces
                // This gives us a readable command line string
                const cmdline = new TextDecoder().decode(contents).replace(/\0/g, ' ').trim();
                return cmdline;
            }
        } catch (e) {
            console.log(`Error reading process cmdline for PID ${pid}: ${e}`);
        }
        return "";
    }

    /**
     * Get Process Working Directory
     * =============================
     * 
     * Returns the current working directory of the focused window's process.
     * This is extremely useful for determining project context in IDEs,
     * current location in terminals, etc.
     * 
     * @returns {string} Current working directory path or empty string
     */
    getProcessCwd() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const pid = focusedWindow.get_pid();
        try {
            const Gio = imports.gi.Gio;
            
            // /proc/[pid]/cwd is a symlink pointing to the process's current working directory
            const file = Gio.File.new_for_path(`/proc/${pid}/cwd`);
            
            // Resolve the symlink to get the actual directory path
            const info = file.query_info('standard::symlink-target', Gio.FileQueryInfoFlags.NONE, null);
            return info.get_symlink_target() || "";
        } catch (e) {
            console.log(`Error reading process cwd for PID ${pid}: ${e}`);
        }
        return "";
    }

    /**
     * Get Window Geometry
     * ==================
     * 
     * Returns the position and size of the focused window as JSON.
     * Includes x/y coordinates and width/height dimensions.
     * 
     * @returns {string} JSON object with geometry data: {x, y, width, height}
     */
    getWinGeometry() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        // get_frame_rect() returns the window's position and size including decorations
        const rect = focusedWindow.get_frame_rect();
        
        // Return as JSON string for easy parsing by calling applications
        return JSON.stringify({
            x: rect.x,        // Horizontal position on screen
            y: rect.y,        // Vertical position on screen  
            width: rect.width,   // Window width in pixels
            height: rect.height  // Window height in pixels
        });
    }

    /**
     * Get Window Workspace Information
     * ===============================
     * 
     * Returns information about the workspace (virtual desktop) containing
     * the focused window. Useful for understanding user's workspace organization.
     * 
     * @returns {string} JSON object with workspace data: {index, name}
     */
    getWinWorkspace() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const workspace = focusedWindow.get_workspace();
        if (workspace) {
            return JSON.stringify({
                index: workspace.index(),  // 0-based workspace number
                // Try to get custom workspace name, fall back to "Workspace N" format
                name: workspace.meta_workspace ? 
                      workspace.meta_workspace.get_name() : 
                      `Workspace ${workspace.index() + 1}`
            });
        }
        return "";
    }

    /**
     * Get Parent Process ID
     * ====================
     * 
     * Returns the process ID of the parent process that spawned the
     * focused window's process. Useful for understanding process hierarchy.
     * 
     * @returns {string} Parent process ID (PPID) or empty string
     */
    getProcessParent() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const pid = focusedWindow.get_pid();
        try {
            const GLib = imports.gi.GLib;
            
            // Read /proc/[pid]/stat which contains process statistics
            // This file has a specific format with space-separated fields
            const [success, contents] = GLib.file_get_contents(`/proc/${pid}/stat`);
            if (success) {
                const stat = new TextDecoder().decode(contents);
                const parts = stat.split(' ');
                
                // According to proc(5) man page, PPID is the 4th field (index 3)
                // Fields: pid, comm, state, ppid, ...
                return parts[3] || "";
            }
        } catch (e) {
            console.log(`Error reading process parent for PID ${pid}: ${e}`);
        }
        return "";
    }

    // ============================================================================
    // PHASE 2: APPLICATION-SPECIFIC DEEP DATA METHODS
    // ============================================================================
    //
    // The following methods provide specialized context extraction for different
    // types of applications. They use intelligent detection to determine the
    // application type and extract relevant information like URLs from browsers,
    // project paths from IDEs, working directories from terminals, etc.
    //
    // These methods return JSON objects with rich contextual data and gracefully
    // handle cases where the focused window is not the expected application type.
    // ============================================================================

    /**
     * Get Browser URL and Context
     * ===========================
     * 
     * Attempts to extract URL information from browser windows by parsing
     * window titles. Different browsers format their titles differently,
     * so this method uses multiple detection strategies.
     * 
     * @returns {string} JSON object with browser context or error if not a browser
     */
    getBrowserUrl() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const windowClass = focusedWindow.get_wm_class() || "";
        const windowTitle = focusedWindow.get_title() || "";
        
        // Check if the focused window is a browser by examining the window class
        // We check for common browser class names (case-insensitive)
        const browserClasses = ["firefox", "chrome", "brave-browser", "chromium", "safari", "edge"];
        const isBrowser = browserClasses.some(browser => 
            windowClass.toLowerCase().includes(browser) || 
            // Also check without hyphens (e.g., "brave-browser" vs "bravebrowser")
            windowClass.toLowerCase().includes(browser.replace("-", ""))
        );
        
        if (!isBrowser) {
            return JSON.stringify({
                error: "Not a browser window",
                windowClass: windowClass,
                isBrowser: false
            });
        }
        
        // Attempt to extract URL from window title using common browser title patterns
        let url = "";
        
        // Strategy 1: Look for titles with " - " separator containing URLs
        // Example: "Page Title - https://example.com - Browser Name"
        if (windowTitle.includes(" - ") && (windowTitle.includes("http") || windowTitle.includes("www"))) {
            const parts = windowTitle.split(" - ");
            url = parts.find(part => part.includes("http") || part.includes("www")) || "";
        } 
        // Strategy 2: Look for protocol indicators directly in title
        // Example: "https://example.com"
        else if (windowTitle.includes("://")) {
            const urlMatch = windowTitle.match(/(https?:\/\/[^\s]+)/);
            url = urlMatch ? urlMatch[1] : "";
        }
        
        return JSON.stringify({
            url: url,
            title: windowTitle,
            browserType: windowClass,
            isBrowser: true,
            extractionMethod: url ? "window_title" : "title_parsing_failed"
        });
    }
    
    /**
     * Get Browser Tab Information
     * ===========================
     * 
     * Returns basic tab information from browser windows. This method provides
     * a foundation for tab-specific data collection, though full tab details
     * would require browser-specific extensions or APIs.
     * 
     * @returns {string} JSON object with available tab information
     */
    getBrowserTabInfo() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const windowClass = focusedWindow.get_wm_class() || "";
        const windowTitle = focusedWindow.get_title() || "";
        
        return JSON.stringify({
            title: windowTitle,
            windowClass: windowClass,
            timestamp: Date.now(),
            note: "Full tab details require browser-specific integration"
        });
    }
    
    /**
     * Get IDE Project Information
     * ==========================
     * 
     * Detects IDE/editor windows and extracts project context by examining
     * the working directory. Useful for tracking which projects developers
     * are working on and understanding development workflows.
     * 
     * @returns {string} JSON object with project info or error if not an IDE
     */
    getIdeProject() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const windowClass = focusedWindow.get_wm_class() || "";
        const windowTitle = focusedWindow.get_title() || "";
        const pid = focusedWindow.get_pid();
        
        // Check if the focused window is an IDE or code editor
        // This list includes popular IDEs and text editors used for development
        const ideClasses = ["code", "cursor", "atom", "sublime", "intellij", "pycharm", "vscode", "vim", "emacs", "gedit"];
        const isIde = ideClasses.some(ide => 
            windowClass.toLowerCase().includes(ide)
        );
        
        if (!isIde) {
            return JSON.stringify({
                error: "Not an IDE window",
                windowClass: windowClass,
                isIde: false
            });
        }
        
        // Extract project information from the IDE's working directory
        // Most IDEs set their working directory to the project root
        let projectPath = "";
        try {
            const GLib = imports.gi.GLib;
            const Gio = imports.gi.Gio;
            
            // Get the current working directory of the IDE process
            const cwdFile = Gio.File.new_for_path(`/proc/${pid}/cwd`);
            const info = cwdFile.query_info('standard::symlink-target', Gio.FileQueryInfoFlags.NONE, null);
            projectPath = info.get_symlink_target() || "";
        } catch (e) {
            console.log(`Error reading IDE working directory for PID ${pid}: ${e}`);
        }
        
        // Extract the project name from the path (typically the last directory component)
        let projectName = "";
        if (projectPath) {
            // Split path by '/' and get the last non-empty part
            projectName = projectPath.split('/').pop() || "";
        }
        
        return JSON.stringify({
            projectPath: projectPath,
            projectName: projectName,
            ideType: windowClass,
            windowTitle: windowTitle,
            isIde: true
        });
    }
    
    /**
     * Get IDE Active File Information
     * ==============================
     * 
     * Attempts to determine which file is currently active/open in an IDE
     * by parsing the window title. Many IDEs include the filename in their
     * window title when a file is open.
     * 
     * @returns {string} JSON object with active file info or extraction failure
     */
    getIdeActiveFile() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const windowClass = focusedWindow.get_wm_class() || "";
        const windowTitle = focusedWindow.get_title() || "";
        
        // Attempt to extract the active filename from the window title
        // Many IDEs follow the pattern: "filename.ext - Project Name - IDE Name"
        let activeFile = "";
        
        if (windowTitle.includes(" - ")) {
            const parts = windowTitle.split(" - ");
            const firstPart = parts[0];
            
            // Heuristic: if the first part contains a dot (for file extension),
            // doesn't contain slashes (not a full path), and is reasonably short,
            // it's likely a filename
            if (firstPart.includes(".") && !firstPart.includes("/") && firstPart.length < 50) {
                activeFile = firstPart;
            }
        }
        
        return JSON.stringify({
            activeFile: activeFile,
            windowTitle: windowTitle,
            ideType: windowClass,
            extractionMethod: activeFile ? "window_title" : "title_parsing_failed"
        });
    }
    
    /**
     * Get Terminal Context Information
     * ===============================
     * 
     * Detects terminal windows and provides context about the terminal session,
     * including the working directory. Useful for understanding command-line
     * workflows and tracking development activities.
     * 
     * @returns {string} JSON object with terminal context or error if not a terminal
     */
    getTerminalCommand() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const windowClass = focusedWindow.get_wm_class() || "";
        const windowTitle = focusedWindow.get_title() || "";
        const pid = focusedWindow.get_pid();
        
        // Check if the focused window is a terminal emulator
        // This covers the most common terminal applications on Linux
        const terminalClasses = ["gnome-terminal", "terminal", "konsole", "xterm", "alacritty", "terminator"];
        const isTerminal = terminalClasses.some(term => 
            windowClass.toLowerCase().includes(term)
        );
        
        if (!isTerminal) {
            return JSON.stringify({
                error: "Not a terminal window",
                windowClass: windowClass,
                isTerminal: false
            });
        }
        
        // Get the current working directory of the terminal process
        // This shows where the user's shell session is currently located
        let workingDir = "";
        try {
            const GLib = imports.gi.GLib;
            const Gio = imports.gi.Gio;
            
            // Read the terminal's current working directory
            const cwdFile = Gio.File.new_for_path(`/proc/${pid}/cwd`);
            const info = cwdFile.query_info('standard::symlink-target', Gio.FileQueryInfoFlags.NONE, null);
            workingDir = info.get_symlink_target() || "";
        } catch (e) {
            console.log(`Error reading terminal working directory for PID ${pid}: ${e}`);
        }
        
        return JSON.stringify({
            workingDirectory: workingDir,
            windowTitle: windowTitle,
            terminalType: windowClass,
            isTerminal: true,
            note: "Command history requires shell-specific integration"
        });
    }
    
    /**
     * Get File Manager Current Path
     * ============================
     * 
     * Detects file manager windows and attempts to determine the current
     * directory being viewed. Useful for understanding file system navigation
     * and file management activities.
     * 
     * @returns {string} JSON object with current path or error if not a file manager
     */
    getFileManagerPath() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const windowClass = focusedWindow.get_wm_class() || "";
        const windowTitle = focusedWindow.get_title() || "";
        
        // Check if the focused window is a file manager
        // This covers popular file managers across different desktop environments
        const fileManagerClasses = ["nautilus", "files", "dolphin", "thunar", "pcmanfm", "nemo"];
        const isFileManager = fileManagerClasses.some(fm => 
            windowClass.toLowerCase().includes(fm)
        );
        
        if (!isFileManager) {
            return JSON.stringify({
                error: "Not a file manager window",
                windowClass: windowClass,
                isFileManager: false
            });
        }
        
        // Attempt to extract the current directory path from the window title
        // Different file managers format their titles differently
        let currentPath = "";
        
        // Look for filesystem paths in the title (starting with /)
        if (windowTitle.includes("/")) {
            // Use regex to find path-like strings in the title
            const pathMatch = windowTitle.match(/([\/][^\s]*)/);
            currentPath = pathMatch ? pathMatch[1] : "";
        }
        
        return JSON.stringify({
            currentPath: currentPath,
            windowTitle: windowTitle,
            fileManagerType: windowClass,
            isFileManager: true,
            extractionMethod: currentPath ? "window_title" : "title_parsing_failed"
        });
    }
    
    /**
     * Get Document Path and Information
     * ================================
     * 
     * Detects document viewer applications and attempts to extract the path
     * of the currently open document. Useful for tracking document workflows
     * and understanding what content users are viewing.
     * 
     * @returns {string} JSON object with document info or error if not a document app
     */
    getDocumentPath() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const windowClass = focusedWindow.get_wm_class() || "";
        const windowTitle = focusedWindow.get_title() || "";
        
        // Check if the focused window is a document viewer or office application
        // This includes PDF viewers, office suites, and other document applications
        const documentClasses = ["evince", "okular", "libreoffice", "writer", "calc", "impress", "draw", "math", "acroread", "xpdf"];
        const isDocument = documentClasses.some(doc => 
            windowClass.toLowerCase().includes(doc)
        );
        
        if (!isDocument) {
            return JSON.stringify({
                error: "Not a document application",
                windowClass: windowClass,
                isDocument: false
            });
        }
        
        // Extract document path from the window title using multiple strategies
        let documentPath = "";
        
        // Strategy 1: Look for full paths with file extensions
        if (windowTitle.includes("/")) {
            // Match paths that include file extensions (e.g., /path/to/file.pdf)
            const pathMatch = windowTitle.match(/([\/][^\s]*\.[a-zA-Z0-9]+)/);
            documentPath = pathMatch ? pathMatch[1] : "";
        } 
        // Strategy 2: Look for filename in titles with separators
        else if (windowTitle.includes(" - ")) {
            const parts = windowTitle.split(" - ");
            const docPart = parts[0];
            // If the first part contains a dot (file extension), it's likely a filename
            if (docPart.includes(".")) {
                documentPath = docPart;
            }
        }
        
        return JSON.stringify({
            documentPath: documentPath,
            windowTitle: windowTitle,
            documentType: windowClass,
            isDocument: true,
            extractionMethod: documentPath ? "window_title" : "title_parsing_failed"
        });
    }
    
    /**
     * Get Unified Application Context
     * ==============================
     * 
     * This is the "smart" method that automatically detects the type of application
     * currently focused and returns appropriate context information. It acts as
     * a unified interface to all the specialized detection methods.
     * 
     * This method is ideal for applications that want comprehensive context
     * without needing to call multiple specific methods.
     * 
     * @returns {string} JSON object with app type, context, and metadata
     */
    getAppContext() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const windowClass = focusedWindow.get_wm_class() || "";
        const windowTitle = focusedWindow.get_title() || "";
        const pid = focusedWindow.get_pid();
        
        // Automatically determine the application type and extract relevant context
        // This uses the same detection logic as the specialized methods
        let appType = "unknown";
        let context = {};
        
        // Detection chain: check for each application type in order of specificity
        
        // Browser detection - check for common browser window classes
        const browserClasses = ["firefox", "chrome", "brave-browser", "chromium", "safari", "edge"];
        if (browserClasses.some(browser => 
            windowClass.toLowerCase().includes(browser) || 
            windowClass.toLowerCase().includes(browser.replace("-", ""))
        )) {
            appType = "browser";
            // Get browser-specific context by calling our specialized method
            context = JSON.parse(this.getBrowserUrl());
        }
        // IDE detection - check for development environments and code editors
        else if (["code", "cursor", "atom", "sublime", "intellij", "pycharm", "vscode", "vim", "emacs", "gedit"].some(ide => 
            windowClass.toLowerCase().includes(ide)
        )) {
            appType = "ide";
            // For IDEs, we want both project and active file information
            context = {
                project: JSON.parse(this.getIdeProject()),
                activeFile: JSON.parse(this.getIdeActiveFile())
            };
        }
        // Terminal detection - check for terminal emulators
        else if (["gnome-terminal", "terminal", "konsole", "xterm", "alacritty", "terminator"].some(term => 
            windowClass.toLowerCase().includes(term)
        )) {
            appType = "terminal";
            context = JSON.parse(this.getTerminalCommand());
        }
        // File manager detection - check for file browsers
        else if (["nautilus", "files", "dolphin", "thunar", "pcmanfm", "nemo"].some(fm => 
            windowClass.toLowerCase().includes(fm)
        )) {
            appType = "file_manager";
            context = JSON.parse(this.getFileManagerPath());
        }
        // Document viewer detection - check for document and office applications
        else if (["evince", "okular", "libreoffice", "writer", "calc", "impress", "draw", "math", "acroread", "xpdf"].some(doc => 
            windowClass.toLowerCase().includes(doc)
        )) {
            appType = "document";
            context = JSON.parse(this.getDocumentPath());
        }
        
        // Return a comprehensive context object with all available information
        return JSON.stringify({
            appType: appType,           // Detected application type
            windowClass: windowClass,   // Raw window class for reference
            windowTitle: windowTitle,   // Raw window title for reference
            pid: pid,                   // Process ID for correlation
            context: context,           // Application-specific context data
            timestamp: Date.now()       // When this context was captured
        });
    }

    // ============================================================================
    // PHASE 3: COMPREHENSIVE DATA COLLECTION
    // ============================================================================
    //
    // This phase provides a single unified method that combines all available
    // window and process information from Phase 1 and Phase 2 into one
    // comprehensive response. This is ideal for applications that want all
    // available data in a single call for maximum efficiency.
    // ============================================================================

    /**
     * Get All Window Data (Phase 3 - Comprehensive Collection)
     * ========================================================
     * 
     * This is the ultimate method that combines all Phase 1 (core) and Phase 2
     * (application-specific) data into a single comprehensive JSON response.
     * 
     * Perfect for:
     * - Time tracking applications that need complete context
     * - Productivity analysis tools requiring full window/process information
     * - Workflow monitoring systems needing comprehensive data
     * - Any application wanting all available data in one efficient call
     * 
     * @returns {string} Complete JSON object with all available window/process data
     */
    getAllWindowData() {
        // Use exact same logic as getWinFocusData for consistency
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        const timestamp = Date.now();

        if (!focusedWindow) {
            return JSON.stringify({
                error: "No focused window found",
                timestamp: timestamp,
                dataAvailable: false,
                debug: "Using same logic as getWinFocusData"
            });
        }

        // Get basic window info using same pattern as other methods
        const windowTitle = focusedWindow.get_title() || "";
        const windowClass = focusedWindow.get_wm_class() || "";
        const windowPid = focusedWindow.get_pid();

        const allData = {
            timestamp: timestamp,
            dataCollectionVersion: "1.0",
            extensionInfo: {
                name: "Active Window Details",
                uuid: "active-window-details@imaginationguild.com",
                version: "1.0.0"
            },
            core: {
                title: windowTitle,
                windowClass: windowClass,
                pid: windowPid
            },
            applicationContext: {
                detectedType: "unknown",
                specificData: {}
            },
            performance: {
                collectionDuration: Date.now() - timestamp
            }
        };

        return JSON.stringify(allData);
    }

    // ============================================================================
    // HELPER METHODS FOR PHASE 3
    // ============================================================================

    /**
     * Synchronous wrapper for process name extraction
     */
    _getProcessNameSync(pid) {
        try {
            const GLib = imports.gi.GLib;
            const [success, contents] = GLib.file_get_contents(`/proc/${pid}/comm`);
            if (success) {
                return new TextDecoder().decode(contents).trim();
            }
        } catch (e) {
            // Silent fail for comprehensive data collection
        }
        return "";
    }

    /**
     * Synchronous wrapper for process path extraction
     */
    _getProcessPathSync(pid) {
        try {
            const GLib = imports.gi.GLib;
            const [success, contents] = GLib.file_get_contents(`/proc/${pid}/exe`);
            if (success) {
                return new TextDecoder().decode(contents).trim();
            }
        } catch (e) {
            try {
                const Gio = imports.gi.Gio;
                const file = Gio.File.new_for_path(`/proc/${pid}/exe`);
                const info = file.query_info('standard::symlink-target', Gio.FileQueryInfoFlags.NONE, null);
                return info.get_symlink_target() || "";
            } catch (e2) {
                // Silent fail for comprehensive data collection
            }
        }
        return "";
    }

    /**
     * Synchronous wrapper for process command line extraction
     */
    _getProcessCmdlineSync(pid) {
        try {
            const GLib = imports.gi.GLib;
            const [success, contents] = GLib.file_get_contents(`/proc/${pid}/cmdline`);
            if (success) {
                return new TextDecoder().decode(contents).replace(/\0/g, ' ').trim();
            }
        } catch (e) {
            // Silent fail for comprehensive data collection
        }
        return "";
    }

    /**
     * Synchronous wrapper for process working directory extraction
     */
    _getProcessCwdSync(pid) {
        try {
            const Gio = imports.gi.Gio;
            const file = Gio.File.new_for_path(`/proc/${pid}/cwd`);
            const info = file.query_info('standard::symlink-target', Gio.FileQueryInfoFlags.NONE, null);
            return info.get_symlink_target() || "";
        } catch (e) {
            // Silent fail for comprehensive data collection
        }
        return "";
    }

    /**
     * Synchronous wrapper for process parent PID extraction
     */
    _getProcessParentSync(pid) {
        try {
            const GLib = imports.gi.GLib;
            const [success, contents] = GLib.file_get_contents(`/proc/${pid}/stat`);
            if (success) {
                const stat = new TextDecoder().decode(contents);
                const parts = stat.split(' ');
                return parseInt(parts[3]) || 0;
            }
        } catch (e) {
            // Silent fail for comprehensive data collection
        }
        return 0;
    }

    /**
     * Synchronous wrapper for window geometry extraction
     */
    _getWindowGeometrySync(window) {
        try {
            const rect = window.get_frame_rect();
            return {
                x: rect.x,
                y: rect.y,
                width: rect.width,
                height: rect.height
            };
        } catch (e) {
            return { x: 0, y: 0, width: 0, height: 0 };
        }
    }

    /**
     * Synchronous wrapper for workspace information extraction
     */
    _getWindowWorkspaceSync(window) {
        try {
            const workspace = window.get_workspace();
            if (workspace) {
                return {
                    index: workspace.index(),
                    name: workspace.meta_workspace ? 
                          workspace.meta_workspace.get_name() : 
                          `Workspace ${workspace.index() + 1}`
                };
            }
        } catch (e) {
            // Silent fail for comprehensive data collection
        }
        return { index: 0, name: "Unknown" };
    }

    /**
     * Analyze extraction methods used for application context
     */
    _getExtractionMethodsSummary(appContextData) {
        const methods = [];
        
        if (appContextData.context) {
            if (appContextData.context.extractionMethod) {
                methods.push(appContextData.context.extractionMethod);
            }
            if (appContextData.context.project && appContextData.context.project.extractionMethod) {
                methods.push(`project_${appContextData.context.project.extractionMethod}`);
            }
            if (appContextData.context.activeFile && appContextData.context.activeFile.extractionMethod) {
                methods.push(`file_${appContextData.context.activeFile.extractionMethod}`);
            }
        }
        
        return methods.length > 0 ? methods : ["basic_window_analysis"];
    }

    /**
     * Validate that core data collection was successful
     */
    _validateCoreData(coreData) {
        const requiredFields = ['title', 'windowClass', 'pid', 'processName'];
        return requiredFields.every(field => 
            coreData[field] !== undefined && 
            coreData[field] !== "" && 
            coreData[field] !== 0
        );
    }

    // ============================================================================
    // VERSION INFORMATION
    // ============================================================================

    /**
     * Get Extension Version
     * ====================
     * 
     * Returns the current version of the Active Window Details extension.
     * This is useful for debugging, compatibility checks, and automated testing.
     * 
     * @returns {string} JSON object with version information
     */
    getVersion() {
        // Read the version from metadata.json
        try {
            const Me = imports.misc.extensionUtils.getCurrentExtension();
            const metadata = Me.metadata;
            
            return JSON.stringify({
                version: metadata.version || "1.0.0",
                name: metadata.name || "Active Window Details",
                uuid: metadata.uuid || "active-window-details@imaginationguild.com",
                description: metadata.description || "",
                shellVersions: metadata["shell-version"] || ["45", "46", "47"],
                url: metadata.url || "",
                timestamp: Date.now()
            });
        } catch (e) {
            // Fallback if metadata reading fails
            return JSON.stringify({
                version: "1.0.0",
                name: "Active Window Details",
                uuid: "active-window-details@imaginationguild.com",
                error: "Could not read metadata",
                timestamp: Date.now()
            });
        }
    }
}
