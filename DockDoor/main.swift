import AppKit

#if DOCKDOOR_CUSTOM
    private let officialPreferencesDomain = "com.ethanbills.DockDoor"
    private let preferencesMigrationMarker = "didMigrateOfficialDockDoorPreferences"

    private func migrateOfficialPreferencesIfNeeded() {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }

        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: preferencesMigrationMarker),
              let customPreferencesDomain = Bundle.main.bundleIdentifier
        else {
            return
        }

        let existingPreferences = defaults.persistentDomain(forName: customPreferencesDomain) ?? [:]
        let officialPreferences = defaults.persistentDomain(forName: officialPreferencesDomain) ?? [:]

        for (key, value) in officialPreferences where existingPreferences[key] == nil {
            defaults.set(value, forKey: key)
        }

        defaults.set(false, forKey: "reopenSettingsAfterRestart")
        defaults.set(true, forKey: preferencesMigrationMarker)
    }

    migrateOfficialPreferencesIfNeeded()
#endif

let appDelegate = AppDelegate()
NSApplication.shared.delegate = appDelegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
