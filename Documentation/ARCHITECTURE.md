# VANTA Architecture

Original, modular SwiftUI architecture. No code from Scarlet / KSign / SideStore.

```
Vanta/
├── App/            VantaApp, ContentView, DeveloperConfig, AppState, Info.plist
├── Core/           Models (ManagedApp, Certificate, Repository…), VantaError, Validators
├── UI/             VantaDS (colors, cards, buttons), AppCard, CertCard, StatusViews
├── Applications/   ManagedAppStore (actor), IPAAnalyzer, IPAImporter
├── Certificates/   CertificateStore (Keychain refs), ProvisioningProfile parser
├── Signing/        SignerProvider protocol + providers + SigningPipeline
├── Installation/   InstallationService (honest availability gating)
├── Repositories/   RepositoryClient (URLSession + cache), RepositoryValidator
├── Devices/        DeviceInfo (UIDevice, no private APIs)
├── Networking/     GitHubAPI (avatar w/ cache), DownloadManager
├── FileManager/    VantaFileStore (scoped dirs: IPAs, Certs, Profiles, Downloads…)
├── Backup/         BackupService (Codable + AES-GCM for secrets)
├── Logs/           Logger (actor, categorized, exportable)
├── Settings/       SettingsStore (@AppStorage backed, sections)
```

## Principles

- **Honesty over magic.** Every privileged step (`sign`, `install`, `refresh`)
  checks real preconditions and returns typed `VantaError` with remedy actions.
- **Actors for shared state.** `ManagedAppStore`, `CertificateStore`, `Logger`
  are actors; UI observes via `@MainActor` view models.
- **async/await everywhere.** No blocking the main thread; downloads + parsing
  are background tasks with progress callbacks.
- **Cache + lazy load.** Repository feeds, GitHub avatar, IPA icons are cached
  (`URLCache` + disk); lists use `LazyVStack` / pagination-friendly models.
- **Testable parsers.** `IPAAnalyzer`, `CertificateParser`,
  `RepositoryValidator` are pure functions over `Data` → unit-tested.

## Navigation

- iPhone: `TabView` (Home, Apps, Discover, Files, Settings)
- iPad: `NavigationSplitView` sidebar + detail; same view models, adaptive layout
  via `horizontalSizeClass` — not a scaled-up phone UI.
