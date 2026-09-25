import SwiftUI

/// Settings: graphics, audio, controller, performance, saves and developer
/// mode. Every change persists immediately to UserDefaults.
struct SettingsView: View {
    @EnvironmentObject private var state: EmulatorAppState
    @State private var newProfileName = ""
    @State private var notice: String?

    var body: some View {
        NavigationStack {
            Form {
                self.graphicsSection
                self.audioSection
                self.controllerSection
                self.performanceSection
                self.savesSection
                self.developerSection
            }
            .navigationTitle("Settings")
            .alert("Notice", isPresented: self.noticeBinding()) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(self.notice ?? "")
            }
        }
    }

    private var graphicsSection: some View {
        Section("Graphics") {
            Picker("Internal resolution", selection: self.resolutionBinding()) {
                Text("720p").tag(720)
                Text("1080p").tag(1080)
            }
            Toggle("Upscaling", isOn: self.upscalingBinding())
            Toggle("VSync", isOn: self.vsyncBinding())
        }
    }

    private var audioSection: some View {
        Section("Audio") {
            Slider(value: self.volumeBinding(), in: 0 ... 1) {
                Text("Volume")
            }
            Stepper("Buffer blocks: \(self.state.settings.audioBufferBlocks)", value: self.bufferBinding(), in: 2 ... 32)
        }
    }

    private var controllerSection: some View {
        Section("Controller") {
            let names = self.state.controllers.connectedControllerNames()
            if names.isEmpty {
                Text("No external controller connected.").foregroundStyle(.secondary)
            } else {
                ForEach(names, id: \.self) { name in
                    Text(name)
                }
            }
            Text("Rumble: \(self.state.controllers.supportsRumble ? "supported" : "not wired")")
                .foregroundStyle(.secondary)
        }
    }

    private var performanceSection: some View {
        Section("Performance") {
            Picker("Profile", selection: self.profileBinding()) {
                Text("Battery").tag("Battery")
                Text("Balanced").tag("Balanced")
                Text("Performance").tag("Performance")
            }
            Toggle("Developer mode", isOn: self.developerBinding())
            Toggle("Show FPS", isOn: self.showFpsBinding())
        }
    }

    private var savesSection: some View {
        Section("Save profiles") {
            ForEach(self.state.saves.profiles()) { profile in
                Text(profile.name)
            }
            HStack {
                TextField("New profile", text: self.$newProfileName)
                Button("Add") {
                    self.addProfile()
                }
                .disabled(self.newProfileName.isEmpty)
            }
        }
    }

    private var developerSection: some View {
        Section("Developer") {
            if self.state.settings.developerMode {
                let stats = self.state.shaderCache.statistics()
                Text("Shader cache: \(stats.hits) hits, \(stats.misses) misses, \(stats.entryCount) entries")
                Button("Clear shader cache", role: .destructive) {
                    self.state.shaderCache.clear()
                }
                Button("Export logs") {
                    self.exportLogs()
                }
            } else {
                Text("Enable developer mode for diagnostics.").foregroundStyle(.secondary)
            }
        }
    }

    private func addProfile() {
        do {
            _ = try self.state.saves.addProfile(named: self.newProfileName)
            self.newProfileName = ""
        } catch {
            self.notice = "Could not create profile: \(error)."
        }
    }

    private func exportLogs() {
        do {
            let url = try Logger.shared.export()
            self.notice = "Logs exported to \(url.lastPathComponent) (temporary directory)."
        } catch {
            self.notice = "Log export failed: \(error)."
        }
    }

    private func noticeBinding() -> Binding<Bool> {
        Binding(
            get: { self.notice != nil },
            set: { newValue in if !newValue { self.notice = nil } }
        )
    }

    private func resolutionBinding() -> Binding<Int> {
        Binding(
            get: { self.state.settings.internalResolution },
            set: { self.state.settings.internalResolution = $0; self.state.settings.persist() }
        )
    }

    private func upscalingBinding() -> Binding<Bool> {
        Binding(
            get: { self.state.settings.upscalingEnabled },
            set: { self.state.settings.upscalingEnabled = $0; self.state.settings.persist() }
        )
    }

    private func vsyncBinding() -> Binding<Bool> {
        Binding(
            get: { self.state.settings.vsyncEnabled },
            set: { self.state.settings.vsyncEnabled = $0; self.state.settings.persist() }
        )
    }

    private func volumeBinding() -> Binding<Double> {
        Binding(
            get: { self.state.settings.audioVolume },
            set: { self.state.settings.audioVolume = $0; self.state.settings.persist() }
        )
    }

    private func bufferBinding() -> Binding<Int> {
        Binding(
            get: { self.state.settings.audioBufferBlocks },
            set: { self.state.settings.audioBufferBlocks = $0; self.state.settings.persist() }
        )
    }

    private func profileBinding() -> Binding<String> {
        Binding(
            get: { self.state.settings.performanceProfile },
            set: { self.state.settings.performanceProfile = $0; self.state.settings.persist() }
        )
    }

    private func developerBinding() -> Binding<Bool> {
        Binding(
            get: { self.state.settings.developerMode },
            set: { self.state.settings.developerMode = $0; self.state.settings.persist() }
        )
    }

    private func showFpsBinding() -> Binding<Bool> {
        Binding(
            get: { self.state.settings.showFps },
            set: { self.state.settings.showFps = $0; self.state.settings.persist() }
        )
    }
}
