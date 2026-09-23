import SwiftUI

/// Grouped settings (general, signing, repositories, installation, advanced).
struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    Picker("Appearance", selection: self.$settings.appearance) {
                        ForEach(Appearance.allCases, id: \.self) {
                            Text($0.rawValue.capitalized).tag($0)
                        }
                    }
                    Toggle("Notifications", isOn: self.$settings.notifications)
                    Toggle("Larger text", isOn: self.$settings.largerText)
                    Toggle("Reduce motion", isOn: self.$settings.reduceMotion)
                }
                Section("Signing") {
                    NavigationLink("Certificates") { CertificatesView() }
                    Toggle("Automatic verification", isOn: self.$settings.autoVerify)
                }
                Section("Repositories") {
                    NavigationLink("Manage repositories") { RepositoriesView() }
                    Stepper(
                        "Update interval: \(self.settings.repoUpdateIntervalH)h",
                        value: self.$settings.repoUpdateIntervalH,
                        in: 1...168
                    )
                    Toggle("Allow HTTP (insecure, warns)", isOn: self.$settings.allowInsecureRepos)
                }
                Section("Installation") {
                    Toggle("Confirm before install", isOn: self.$settings.confirmBeforeInstall)
                    Toggle("Installation notifications", isOn: self.$settings.installNotifications)
                }
                Section("Advanced") {
                    Toggle("Debug logs", isOn: self.$settings.debugLogs)
                    NavigationLink("Logs") { LogsView() }
                    Button("Reset settings", role: .destructive) { self.settings.reset() }
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
