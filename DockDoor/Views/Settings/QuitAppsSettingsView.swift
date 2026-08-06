import AppKit
import Defaults
import SwiftUI

struct QuitAppsSettingsView: View {
    @Default(.enableCmdRightClickQuit) private var enableCmdRightClickQuit
    @Default(.quitAppOnWindowClose) private var quitAppOnWindowClose
    @Default(.quitAppOnWindowCloseMode) private var quitAppOnWindowCloseMode
    @Default(.quitAppOnWindowCloseExcludedApps) private var quitAppOnWindowCloseExcludedApps
    @Default(.quitAppOnWindowCloseAllowedApps) private var quitAppOnWindowCloseAllowedApps
    @Default(.quitAppOnWindowCloseDelay) private var quitAppOnWindowCloseDelay

    @State private var showingAppPicker = false

    var body: some View {
        BaseSettingsView {
            VStack(alignment: .leading, spacing: 16) {
                SettingsGroup {
                    SettingsToggleRow(
                        title: "Quit app when closing its last window",
                        description: "Closing an app's final window quits the app, matching the Windows close-button behavior.",
                        icon: "xmark.app.fill",
                        isOn: $quitAppOnWindowClose
                    )
                    .settingsSearchTarget("quitApps.lastWindow")
                }

                if quitAppOnWindowClose {
                    appRulesSection
                    quitDelaySection
                }

                SettingsGroup(header: "Dock Shortcut") {
                    SettingsToggleRow(
                        title: "CMD + Right Click on dock icon to quit app",
                        description: "Hold Command and right-click a Dock icon to quit that application immediately.",
                        icon: "cursorarrow.click.2",
                        isOn: $enableCmdRightClickQuit
                    )
                    .settingsSearchTarget("quitApps.cmdRightClick")
                }

                SettingsNote(
                    icon: "info.circle",
                    text: "Finder always stays running. Apps without normal windows are not affected by the last-window rule."
                )
            }
        }
        .sheet(isPresented: $showingAppPicker) {
            AppPickerSheet(
                selectedApps: selectedApps,
                title: appPickerTitle,
                description: appPickerDescription,
                selectionMode: .include
            )
        }
    }

    private var appRulesSection: some View {
        SettingsGroup(header: "App Rules") {
            VStack(alignment: .leading, spacing: 12) {
                SettingsPickerRow(
                    title: "Apply quit behavior to",
                    description: "Choose whether the selected apps form an ignore list or an allow list.",
                    icon: "checklist",
                    selection: $quitAppOnWindowCloseMode
                ) {
                    ForEach(QuitAppOnWindowCloseMode.allCases, id: \.self) { mode in
                        Text(mode.localizedName).tag(mode)
                    }
                }
                .settingsSearchTarget("quitApps.mode")

                Divider()

                HStack(spacing: 12) {
                    SettingsIcon(systemName: "app.badge.checkmark", color: .accentColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(appPickerTitle)
                            .font(.body)
                            .fontWeight(.medium)
                        Text(appRuleDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button("Choose Apps…") {
                        showingAppPicker = true
                    }
                    .buttonStyle(AccentButtonStyle(color: .accentColor))
                }
                .settingsSearchTarget("quitApps.apps")

                if selectedApps.wrappedValue.isEmpty {
                    Text("No apps selected")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 40)
                } else {
                    Divider().padding(.leading, 40)

                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(selectedApps.wrappedValue, id: \.self) { bundleIdentifier in
                            selectedAppRow(bundleIdentifier)
                        }
                    }
                    .padding(.leading, 40)
                }
            }
        }
    }

    private var quitDelaySection: some View {
        SettingsGroup(header: "Timing") {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    SettingsIcon(systemName: "timer", color: .accentColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Quit delay")
                            .font(.body)
                            .fontWeight(.medium)
                        Text("Wait before quitting so apps that briefly recreate a window are not closed by mistake.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(quitAppOnWindowCloseDelay, specifier: "%.1f") seconds")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Slider(value: $quitAppOnWindowCloseDelay, in: 0.1 ... 1.0, step: 0.1)
                    .controlSize(.small)
                    .padding(.leading, 40)
                    .accessibilityLabel("Quit delay")
            }
        }
        .settingsSearchTarget("quitApps.delay")
    }

    private func selectedAppRow(_ bundleIdentifier: String) -> some View {
        HStack(spacing: 8) {
            Image(nsImage: appIcon(for: bundleIdentifier))
                .resizable()
                .frame(width: 20, height: 20)

            VStack(alignment: .leading, spacing: 1) {
                Text(appName(for: bundleIdentifier))
                Text(bundleIdentifier)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button {
                removeSelectedApp(bundleIdentifier)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Remove app")
        }
        .padding(.vertical, 3)
    }

    private var selectedApps: Binding<[String]> {
        switch quitAppOnWindowCloseMode {
        case .allAppsExceptSelected:
            $quitAppOnWindowCloseExcludedApps
        case .selectedAppsOnly:
            $quitAppOnWindowCloseAllowedApps
        }
    }

    private var appPickerTitle: String {
        switch quitAppOnWindowCloseMode {
        case .allAppsExceptSelected:
            String(localized: "Apps to Keep Running")
        case .selectedAppsOnly:
            String(localized: "Apps to Quit")
        }
    }

    private var appPickerDescription: String {
        switch quitAppOnWindowCloseMode {
        case .allAppsExceptSelected:
            String(localized: "Selected apps will stay running when their last window closes.")
        case .selectedAppsOnly:
            String(localized: "Selected apps will quit when their last window closes.")
        }
    }

    private var appRuleDescription: String {
        switch quitAppOnWindowCloseMode {
        case .allAppsExceptSelected:
            String(localized: "Every app quits except the apps selected below.")
        case .selectedAppsOnly:
            String(localized: "Only the apps selected below will quit.")
        }
    }

    private func appName(for bundleIdentifier: String) -> String {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier),
              let bundle = Bundle(url: appURL)
        else {
            return bundleIdentifier
        }

        return bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ??
            bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ??
            appURL.deletingPathExtension().lastPathComponent
    }

    private func appIcon(for bundleIdentifier: String) -> NSImage {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return NSImage(systemSymbolName: "app", accessibilityDescription: nil) ?? NSImage()
        }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }

    private func removeSelectedApp(_ bundleIdentifier: String) {
        var apps = selectedApps.wrappedValue
        apps.removeAll { $0 == bundleIdentifier }
        selectedApps.wrappedValue = apps
    }
}
