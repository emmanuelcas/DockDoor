import AppKit

#if PEEKDECK
    private let previousPreferencesDomains = [
        "com.emmanuelcas.DockLens",
        "com.emmanuelcas.DockDoorCustom",
        "com.ethanbills.DockDoor",
    ]
    private let preferencesMigrationMarker = "didMigratePeekDeckPreferences"

    private func migratePreviousPreferencesIfNeeded() {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }

        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: preferencesMigrationMarker),
              let peekDeckPreferencesDomain = Bundle.main.bundleIdentifier
        else {
            return
        }

        var migratedPreferences = defaults.persistentDomain(forName: peekDeckPreferencesDomain) ?? [:]

        for sourceDomain in previousPreferencesDomains {
            let sourcePreferences = defaults.persistentDomain(forName: sourceDomain) ?? [:]
            for (key, value) in sourcePreferences where migratedPreferences[key] == nil {
                defaults.set(value, forKey: key)
                migratedPreferences[key] = value
            }
        }

        defaults.set(false, forKey: "reopenSettingsAfterRestart")
        defaults.set(true, forKey: preferencesMigrationMarker)
    }

    migratePreviousPreferencesIfNeeded()
#endif

let appDelegate = AppDelegate()
NSApplication.shared.delegate = appDelegate
_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
