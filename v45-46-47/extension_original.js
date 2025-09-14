/* extension.js
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

import Gio from 'gi://Gio';
import GLib from 'gi://GLib';

const DBUS_NODE_INTERFACE = `
<node>
    <interface name="org.gnome.Shell.Extensions.Evertrack">
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
    </interface>
</node>`;

export default class EvertrackExtension {
    enable() {
        if (!this._dbus) {
            this._dbus = Gio.DBusExportedObject.wrapJSObject(DBUS_NODE_INTERFACE, this);
            this._dbus.export(Gio.DBus.session, '/org/gnome/Shell/Extensions/Evertrack');
        }
    }

    disable() {
        if (this._dbus) {
            this._dbus.flush();
            this._dbus.unexport();
            this._dbus = null;
        }
    }

    getWinFocusData() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        return focusedWindow ? focusedWindow.get_title() : "";
    }

    getWinPID() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        return focusedWindow ? String(focusedWindow.get_pid()) : "";
    }

    getWinClass() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        return focusedWindow ? focusedWindow.get_wm_class() : "";
    }

    getWinRole() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        return focusedWindow ? (focusedWindow.get_role() || "") : "";
    }

    getProcessName() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const pid = focusedWindow.get_pid();
        try {
            const GLib = imports.gi.GLib;
            const [success, contents] = GLib.file_get_contents(`/proc/${pid}/comm`);
            if (success) {
                return new TextDecoder().decode(contents).trim();
            }
        } catch (e) {
            console.log(`Error reading process name for PID ${pid}: ${e}`);
        }
        return "";
    }

    getProcessPath() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const pid = focusedWindow.get_pid();
        try {
            const GLib = imports.gi.GLib;
            const [success, contents] = GLib.file_get_contents(`/proc/${pid}/exe`);
            if (success) {
                return new TextDecoder().decode(contents).trim();
            }
        } catch (e) {
            // Try alternative method with readlink
            try {
                const Gio = imports.gi.Gio;
                const file = Gio.File.new_for_path(`/proc/${pid}/exe`);
                const info = file.query_info('standard::symlink-target', Gio.FileQueryInfoFlags.NONE, null);
                return info.get_symlink_target() || "";
            } catch (e2) {
                console.log(`Error reading process path for PID ${pid}: ${e2}`);
            }
        }
        return "";
    }

    getProcessCmdline() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const pid = focusedWindow.get_pid();
        try {
            const GLib = imports.gi.GLib;
            const [success, contents] = GLib.file_get_contents(`/proc/${pid}/cmdline`);
            if (success) {
                // cmdline uses null separators, replace with spaces
                const cmdline = new TextDecoder().decode(contents).replace(/\0/g, ' ').trim();
                return cmdline;
            }
        } catch (e) {
            console.log(`Error reading process cmdline for PID ${pid}: ${e}`);
        }
        return "";
    }

    getProcessCwd() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const pid = focusedWindow.get_pid();
        try {
            const Gio = imports.gi.Gio;
            const file = Gio.File.new_for_path(`/proc/${pid}/cwd`);
            const info = file.query_info('standard::symlink-target', Gio.FileQueryInfoFlags.NONE, null);
            return info.get_symlink_target() || "";
        } catch (e) {
            console.log(`Error reading process cwd for PID ${pid}: ${e}`);
        }
        return "";
    }

    getWinGeometry() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const rect = focusedWindow.get_frame_rect();
        return JSON.stringify({
            x: rect.x,
            y: rect.y,
            width: rect.width,
            height: rect.height
        });
    }

    getWinWorkspace() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const workspace = focusedWindow.get_workspace();
        if (workspace) {
            return JSON.stringify({
                index: workspace.index(),
                name: workspace.meta_workspace ? workspace.meta_workspace.get_name() : `Workspace ${workspace.index() + 1}`
            });
        }
        return "";
    }

    getProcessParent() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const pid = focusedWindow.get_pid();
        try {
            const GLib = imports.gi.GLib;
            const [success, contents] = GLib.file_get_contents(`/proc/${pid}/stat`);
            if (success) {
                const stat = new TextDecoder().decode(contents);
                const parts = stat.split(' ');
                // PPID is the 4th field in /proc/pid/stat
                return parts[3] || "";
            }
        } catch (e) {
            console.log(`Error reading process parent for PID ${pid}: ${e}`);
        }
        return "";
    }

    // Phase 2: Application-Specific Deep Data Methods
    
    getBrowserUrl() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const windowClass = focusedWindow.get_wm_class() || "";
        const windowTitle = focusedWindow.get_title() || "";
        
        // Check if it's a browser
        const browserClasses = ["firefox", "chrome", "brave-browser", "chromium", "safari", "edge"];
        const isBrowser = browserClasses.some(browser => 
            windowClass.toLowerCase().includes(browser) || 
            windowClass.toLowerCase().includes(browser.replace("-", ""))
        );
        
        if (!isBrowser) {
            return JSON.stringify({
                error: "Not a browser window",
                windowClass: windowClass,
                isBrowser: false
            });
        }
        
        // For browsers, try to extract URL from window title
        let url = "";
        
        // Common patterns for extracting URLs from browser titles
        if (windowTitle.includes(" - ") && (windowTitle.includes("http") || windowTitle.includes("www"))) {
            const parts = windowTitle.split(" - ");
            url = parts.find(part => part.includes("http") || part.includes("www")) || "";
        } else if (windowTitle.includes("://")) {
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
    
    getIdeProject() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const windowClass = focusedWindow.get_wm_class() || "";
        const windowTitle = focusedWindow.get_title() || "";
        const pid = focusedWindow.get_pid();
        
        // Common IDE classes
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
        
        // Try to extract project info from working directory
        let projectPath = "";
        try {
            const GLib = imports.gi.GLib;
            const Gio = imports.gi.Gio;
            const cwdFile = Gio.File.new_for_path(`/proc/${pid}/cwd`);
            const info = cwdFile.query_info('standard::symlink-target', Gio.FileQueryInfoFlags.NONE, null);
            projectPath = info.get_symlink_target() || "";
        } catch (e) {
            console.log(`Error reading IDE working directory for PID ${pid}: ${e}`);
        }
        
        // Extract project name from path
        let projectName = "";
        if (projectPath) {
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
    
    getIdeActiveFile() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const windowClass = focusedWindow.get_wm_class() || "";
        const windowTitle = focusedWindow.get_title() || "";
        
        // Try to extract filename from window title
        let activeFile = "";
        
        // Common IDE title patterns: "filename.ext - Project - IDE"
        if (windowTitle.includes(" - ")) {
            const parts = windowTitle.split(" - ");
            const firstPart = parts[0];
            
            // Check if first part looks like a filename
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
    
    getTerminalCommand() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const windowClass = focusedWindow.get_wm_class() || "";
        const windowTitle = focusedWindow.get_title() || "";
        const pid = focusedWindow.get_pid();
        
        // Common terminal classes
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
        
        // Try to get working directory
        let workingDir = "";
        try {
            const GLib = imports.gi.GLib;
            const Gio = imports.gi.Gio;
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
    
    getFileManagerPath() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const windowClass = focusedWindow.get_wm_class() || "";
        const windowTitle = focusedWindow.get_title() || "";
        
        // Common file manager classes
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
        
        // Try to extract path from window title
        let currentPath = "";
        
        // Many file managers show the current path in title
        if (windowTitle.includes("/")) {
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
    
    getDocumentPath() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const windowClass = focusedWindow.get_wm_class() || "";
        const windowTitle = focusedWindow.get_title() || "";
        
        // Common document viewer classes
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
        
        // Try to extract document path from title
        let documentPath = "";
        
        if (windowTitle.includes("/")) {
            const pathMatch = windowTitle.match(/([\/][^\s]*\.[a-zA-Z0-9]+)/);
            documentPath = pathMatch ? pathMatch[1] : "";
        } else if (windowTitle.includes(" - ")) {
            const parts = windowTitle.split(" - ");
            const docPart = parts[0];
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
    
    getAppContext() {
        const focusedWindow = global.get_window_actors()
            .map(a => a.meta_window)
            .find(w => w.has_focus());

        if (!focusedWindow) return "";
        
        const windowClass = focusedWindow.get_wm_class() || "";
        const windowTitle = focusedWindow.get_title() || "";
        const pid = focusedWindow.get_pid();
        
        // Determine application type and get context
        let appType = "unknown";
        let context = {};
        
        // Browser detection
        const browserClasses = ["firefox", "chrome", "brave-browser", "chromium", "safari", "edge"];
        if (browserClasses.some(browser => 
            windowClass.toLowerCase().includes(browser) || 
            windowClass.toLowerCase().includes(browser.replace("-", ""))
        )) {
            appType = "browser";
            context = JSON.parse(this.getBrowserUrl());
        }
        // IDE detection
        else if (["code", "cursor", "atom", "sublime", "intellij", "pycharm", "vscode", "vim", "emacs", "gedit"].some(ide => 
            windowClass.toLowerCase().includes(ide)
        )) {
            appType = "ide";
            context = {
                project: JSON.parse(this.getIdeProject()),
                activeFile: JSON.parse(this.getIdeActiveFile())
            };
        }
        // Terminal detection
        else if (["gnome-terminal", "terminal", "konsole", "xterm", "alacritty", "terminator"].some(term => 
            windowClass.toLowerCase().includes(term)
        )) {
            appType = "terminal";
            context = JSON.parse(this.getTerminalCommand());
        }
        // File manager detection
        else if (["nautilus", "files", "dolphin", "thunar", "pcmanfm", "nemo"].some(fm => 
            windowClass.toLowerCase().includes(fm)
        )) {
            appType = "file_manager";
            context = JSON.parse(this.getFileManagerPath());
        }
        // Document detection
        else if (["evince", "okular", "libreoffice", "writer", "calc", "impress", "draw", "math", "acroread", "xpdf"].some(doc => 
            windowClass.toLowerCase().includes(doc)
        )) {
            appType = "document";
            context = JSON.parse(this.getDocumentPath());
        }
        
        return JSON.stringify({
            appType: appType,
            windowClass: windowClass,
            windowTitle: windowTitle,
            pid: pid,
            context: context,
            timestamp: Date.now()
        });
    }
}