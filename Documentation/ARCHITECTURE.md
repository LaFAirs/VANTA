# VANTA Architecture

Original, modular SwiftUI architecture. No code from Scarlet / KSign / SideStore.

```
// MARK: - Module map
Vanta/
├── App/            VantaApp, ContentView, DeveloperConfig, AppState, Info.plist
├── Core/           Models (DateProvider, validated inits), VantaError (codes, i18n), Validators
├── UI/             VantaDS (colors, cards, buttons), AppCard, CertificateCard, views
├── Applications/   ManagedAppStore (actor), IPAAnalyzer, IPAImporter
├── Certificates/   CertificateStore (Keychain refs), CertificateParser
├── Signing/        SignerProvider protocol + providers + SigningPipeline (AsyncStream, DI)
├── Installation/   InstallationService (honest availability gating)
├── Repositories/   RepositoryClient (URLSession + cache), RepositoryValidator
├── Devices/        DeviceInfo (UIDevice, no private APIs)
├── Networking/     GitHubAPI (avatar w/ cache), DownloadManager
├── FileManager/    VantaFileStore (scoped dirs: IPAs, Certs, Profiles, Downloads…)
├── Backup/         BackupService (Codable + AES-GCM, rotation, wipe)
├── Logs/           Logger (actor + OSLog, categorized, exportable)
├── Settings/       SettingsStore (@AppStorage backed, sections)
└── Resources/      AppIcon.xcassets, PrivacyInfo.xcprivacy, Vanta.entitlements, Localizable.xcstrings
```

```mermaid
flowchart LR
    IPA[IPA import] --> Analyze[IPA Analyzer]
    Analyze --> Cert[Certificate Center]
    Cert --> Signer[SignerProvider]
    Signer --> Pipe[Signing Pipeline]
    Pipe --> Verify[Verify]
    Verify --> Install[Install]
    Repo[Repositories] --> Discover[Discover]
    Discover --> IPA
```

## Principles

- **Honesty over magic.** Every privileged step (`sign`, `install`, `refresh`)
  checks real preconditions and returns typed `VantaError` with remedy actions.
- **Actors for shared state.** `ManagedAppStore`, `CertificateStore`, `Logger`
  are actors; collaborators are injected as protocols (`InstallationVerifying`,
  `PipelineLogging`), never singletons in logic.
- **Testable time.** `DateProvider` (`SystemClock`/`FixedClock`) makes expiry
  logic deterministic in tests.
- **async/await everywhere.** No blocking the main thread; downloads + parsing
  are background tasks with progress callbacks.
- **Cache + lazy load.** Repository feeds, GitHub avatar, IPA icons are cached
  (`URLCache` + disk); lists use `LazyVStack` / pagination-friendly models.
- **Testable parsers.** `IPAAnalyzer`, `CertificateParser`,
  `RepositoryValidator` are pure functions over `Data` → unit-tested.

## Navigation

- iPhone: `TabView` (Home, Apps, Discover, Certificates, Files, Settings)
- iPad: `NavigationSplitView` sidebar + detail via `ViewThatFits`, not a
  scaled-up phone UI.
