/* prefs.js
 *
 * Active Window Details GNOME Shell Extension - Preferences
 * ========================================================
 * 
 * This file provides the preferences UI for the Active Window Details extension.
 * It creates a configuration dialog accessible from the Extension Manager's
 * gear icon, containing an About section with extension information and links.
 */

import Adw from 'gi://Adw';
import Gtk from 'gi://Gtk';
import Gio from 'gi://Gio';

/**
 * Extension Preferences Class for GNOME Shell Compatibility
 * ========================================================
 */
export default class ActiveWindowDetailsPreferences {
    constructor() {
        // Simple constructor for compatibility
    }

    /**
     * Fill Preferences Window - Main Implementation
     * ============================================
     */
    fillPreferencesWindow(window) {
        return fillPreferencesWindow(window);
    }
}

/**
 * Initialize Preferences
 * =====================
 * 
 * Entry point called by GNOME Shell when the preferences window is opened.
 */
export function init() {
    // No special initialization needed for this preferences UI
}

/**
 * Fill Preferences Window
 * ======================
 * 
 * Called by GNOME Shell to populate the preferences window.
 * Creates the settings object and builds the UI.
 */
export function fillPreferencesWindow(window) {
    // Get the extension's settings schema
    const settings = new Gio.Settings({
        schema_id: 'org.gnome.shell.extensions.active-window-details',
    });

    // Create the main preferences page
    const page = new Adw.PreferencesPage({
        title: 'About',
        icon_name: 'help-about-symbolic',
    });

    // About Section
    const aboutGroup = new Adw.PreferencesGroup({
        title: 'About Active Window Details',
        description: 'Comprehensive window and process monitoring extension for GNOME Shell',
    });

    // Extension Information Row
    const extensionRow = new Adw.ActionRow({
        title: 'Active Window Details',
        subtitle: 'Version 1.0.0',
    });

    // Add extension icon if available
    const extensionIcon = new Gtk.Image({
        icon_name: 'applications-system-symbolic',
        icon_size: Gtk.IconSize.LARGE,
    });
    extensionRow.add_prefix(extensionIcon);

    aboutGroup.add(extensionRow);

    // Description Row
    const descriptionRow = new Adw.ActionRow({
        title: 'Description',
        subtitle: 'Provides detailed window and process monitoring capabilities through D-Bus with 20 specialized methods for productivity tracking and workflow analysis.',
    });
    aboutGroup.add(descriptionRow);

    // Features Section
    const featuresGroup = new Adw.PreferencesGroup({
        title: 'Key Features',
    });

    // Core Features
    const coreRow = new Adw.ActionRow({
        title: 'Core Window/Process Information',
        subtitle: '11 methods for basic window properties, process details, and extended context',
    });
    const coreIcon = new Gtk.Image({
        icon_name: 'applications-debugging-symbolic',
        icon_size: Gtk.IconSize.NORMAL,
    });
    coreRow.add_prefix(coreIcon);
    featuresGroup.add(coreRow);

    // Application-Specific Context
    const contextRow = new Adw.ActionRow({
        title: 'Application-Specific Context Detection',
        subtitle: '8 methods for browser URLs, IDE projects, terminal context, and document paths',
    });
    const contextIcon = new Gtk.Image({
        icon_name: 'applications-development-symbolic',
        icon_size: Gtk.IconSize.NORMAL,
    });
    contextRow.add_prefix(contextIcon);
    featuresGroup.add(contextRow);

    // Comprehensive Data Collection
    const dataRow = new Adw.ActionRow({
        title: 'Comprehensive Data Collection',
        subtitle: 'Single API call combining all monitoring data with performance metrics',
    });
    const dataIcon = new Gtk.Image({
        icon_name: 'applications-science-symbolic',
        icon_size: Gtk.IconSize.NORMAL,
    });
    dataRow.add_prefix(dataIcon);
    featuresGroup.add(dataRow);

    // Company Information Section
    const companyGroup = new Adw.PreferencesGroup({
        title: 'Developer Information',
    });

    // Company Row with Homepage Link
    const companyRow = new Adw.ActionRow({
        title: 'Imagination Guild LLC',
        subtitle: 'Professional software development and system integration services',
    });

    const companyIcon = new Gtk.Image({
        icon_name: 'applications-internet-symbolic',
        icon_size: Gtk.IconSize.NORMAL,
    });
    companyRow.add_prefix(companyIcon);

    // Homepage Button
    const homepageButton = new Gtk.Button({
        label: 'Visit Homepage',
        valign: Gtk.Align.CENTER,
        css_classes: ['suggested-action'],
    });
    homepageButton.connect('clicked', () => {
        try {
            Gtk.show_uri(window, 'https://github.com/Imagination-Guild-LLC', Gdk.CURRENT_TIME);
        } catch (e) {
            console.log('Error opening homepage:', e);
        }
    });
    companyRow.add_suffix(homepageButton);
    companyGroup.add(companyRow);

    // Attribution Section
    const attributionGroup = new Adw.PreferencesGroup({
        title: 'Attribution & Links',
    });

    // Original Project Attribution
    const originalRow = new Adw.ActionRow({
        title: 'Based on Evertrack',
        subtitle: 'Original concept by @rodrigopfarias - significantly enhanced and rewritten',
    });
    const originalIcon = new Gtk.Image({
        icon_name: 'emblem-shared-symbolic',
        icon_size: Gtk.IconSize.NORMAL,
    });
    originalRow.add_prefix(originalIcon);

    const originalButton = new Gtk.Button({
        label: 'Original Project',
        valign: Gtk.Align.CENTER,
    });
    originalButton.connect('clicked', () => {
        try {
            Gtk.show_uri(window, 'https://github.com/rodrigopfarias/evt-pid-win-ext', Gdk.CURRENT_TIME);
        } catch (e) {
            console.log('Error opening original project:', e);
        }
    });
    originalRow.add_suffix(originalButton);
    attributionGroup.add(originalRow);

    // Current Project Repository
    const repoRow = new Adw.ActionRow({
        title: 'Source Code Repository',
        subtitle: 'View source code, documentation, and contribute to the project',
    });
    const repoIcon = new Gtk.Image({
        icon_name: 'text-x-generic-symbolic',
        icon_size: Gtk.IconSize.NORMAL,
    });
    repoRow.add_prefix(repoIcon);

    const repoButton = new Gtk.Button({
        label: 'View on GitHub',
        valign: Gtk.Align.CENTER,
    });
    repoButton.connect('clicked', () => {
        try {
            Gtk.show_uri(window, 'https://github.com/Imagination-Guild-LLC/active-window-details', Gdk.CURRENT_TIME);
        } catch (e) {
            console.log('Error opening repository:', e);
        }
    });
    repoRow.add_suffix(repoButton);
    attributionGroup.add(repoRow);

    // Usage Information Section
    const usageGroup = new Adw.PreferencesGroup({
        title: 'Usage Information',
    });

    // D-Bus Information
    const dbusRow = new Adw.ActionRow({
        title: 'D-Bus Interface',
        subtitle: 'org.gnome.Shell.Extensions.ActiveWindowDetails - 20 methods available',
    });
    const dbusIcon = new Gtk.Image({
        icon_name: 'network-wired-symbolic',
        icon_size: Gtk.IconSize.NORMAL,
    });
    dbusRow.add_prefix(dbusIcon);
    usageGroup.add(dbusRow);

    // Performance Information
    const perfRow = new Adw.ActionRow({
        title: 'Performance',
        subtitle: 'Fast D-Bus response times (~20ms) with efficient /proc filesystem access',
    });
    const perfIcon = new Gtk.Image({
        icon_name: 'utilities-system-monitor-symbolic',
        icon_size: Gtk.IconSize.NORMAL,
    });
    perfRow.add_prefix(perfIcon);
    usageGroup.add(perfRow);

    // License Information Section
    const licenseGroup = new Adw.PreferencesGroup({
        title: 'License Information',
    });

    const licenseRow = new Adw.ActionRow({
        title: 'GNU General Public License v2.0',
        subtitle: 'This extension is free and open source software',
    });
    const licenseIcon = new Gtk.Image({
        icon_name: 'emblem-documents-symbolic',
        icon_size: Gtk.IconSize.NORMAL,
    });
    licenseRow.add_prefix(licenseIcon);
    licenseGroup.add(licenseRow);

    // Add all groups to the page
    page.add(aboutGroup);
    page.add(featuresGroup);
    page.add(companyGroup);
    page.add(attributionGroup);
    page.add(usageGroup);
    page.add(licenseGroup);

    // Add the page to the window
    window.add(page);
}