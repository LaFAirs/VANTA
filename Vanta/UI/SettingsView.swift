import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    Picker("Appearance", selection: $settings.appearance) {
                        ForEach(Appearance.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                    }
                    Toggle("Notifications", isOn: $settings.notifications)
                    Toggle("Larger text", isOn: $settings.largerText)
                    Toggle("Reduce motion", isOn: $settings.reduceMotion)
                }
                Section("Signing") {
                    NavigationLink("Certificates") { CertificatesView() }
                    Toggle("Automatic verification", isOn: $settings.autoVerify)
                }
                Section("Repositories") {
                    NavigationLink("Manage repositories") { RepositoriesView() }
                    Stepper("Update interval: \(settings.repoUpdateIntervalH)h",
                            value: $settings.repoUpdateIntervalH, in: 1...168)
                    Toggle("Allow HTTP (insecure, warns)", isOn: $settings.allowInsecureRepos)
                }
                Section("Installation") {
                    Toggle("Confirm before install", isOn: $settings.confirmBeforeInstall)
                    Toggle("Installation notifications", isOn: $settings.installNotifications)
                }
                Section("Advanced") {
                    Toggle("Debug logs", isOn: $settings.debugLogs)
                    NavigationLink("Logs") { LogsView() }
                    Button("Reset settings", role: .destructive) { settings.reset() }
                }
                Section("VANTA") {
                    NavigationLink("About VANTA") { AboutView() }
                }
            }
            .scrollContentBackground(.hidden)
            .background(VantaDS.background)
            .navigationTitle("Settings")
        }
    }
}
