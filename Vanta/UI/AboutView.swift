import SwiftUI

/// Professional About page: VANTA branding, version, GitHub profile (live avatar
/// with cached fallback), repository card, real links only.
struct AboutView: View {
    @State private var user: GitHubAPI.User?
    @State private var avatar: Image?
    @State private var loadingAvatar = true

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                logoHeader
                developerCard
                repositoryCard
                linksCard
            }.padding()
        }
        .background(VantaDS.background.ignoresSafeArea())
        .navigationTitle("About")
        .task { await load() }
    }

    private var logoHeader: some View {
        VantaCard {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.black)
                        .frame(width: 96, height: 96)
                        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(VantaDS.accent.opacity(0.5), lineWidth: 1))
                        .shadow(color: VantaDS.accentGlow, radius: 24)
                    Text("V").font(.system(size: 52, weight: .black, design: .rounded))
                        .foregroundStyle(VantaDS.accent)
                }
                .accessibilityLabel("VANTA logo")
                Text("VANTA").font(.largeTitle).bold()
                Text(DeveloperConfig.tagline).foregroundStyle(VantaDS.secondaryText)
                HStack(spacing: 12) {
                    Text("Version \(DeveloperConfig.appVersion)").font(.caption)
                    Text("Build \(DeveloperConfig.buildNumber)").font(.caption)
                }.foregroundStyle(VantaDS.secondaryText)
            }.frame(maxWidth: .infinity)
        }
    }

    private var developerCard: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Developer").font(.headline)
                HStack(spacing: 12) {
                    Group {
                        if let avatar { avatar.resizable() }
                        else if loadingAvatar { ProgressView().tint(VantaDS.accent) }
                        else {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(VantaDS.secondary)
                                .overlay(Text(String(DeveloperConfig.githubUsername.prefix(1))).bold().foregroundStyle(VantaDS.accent))
                        }
                    }
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .accessibilityLabel("Developer avatar")
                    VStack(alignment: .leading) {
                        Text("@\(DeveloperConfig.githubUsername)").font(.subheadline).bold()
                        if let url = DeveloperConfig.githubProfileURL {
                            Link(url.absoluteString, destination: url)
                                .font(.caption).foregroundStyle(VantaDS.accent)
                        }
                    }
                    Spacer()
                    if let url = DeveloperConfig.githubProfileURL {
                        Link(destination: url) {
                            Image(systemName: "arrow.up.right.circle.fill")
                                .foregroundStyle(VantaDS.accent).font(.title2)
                        }.accessibilityLabel("Open GitHub profile")
                    }
                }
                if let url = DeveloperConfig.githubProfileURL {
                    Link(destination: url) {
                        HStack {
                            Text("Open GitHub Profile")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .padding().frame(maxWidth: .infinity)
                        .background(VantaDS.secondary)
                        .foregroundStyle(VantaDS.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }.accessibilityLabel("Open GitHub profile of \(DeveloperConfig.githubUsername)")
                }
                if !loadingAvatar, user?.login == nil {
                    Text("Offline — showing cached identity.").font(.caption2).foregroundStyle(VantaDS.secondaryText)
                }
            }
        }
    }

    private var repositoryCard: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("GitHub Repository").font(.headline)
                Text("VANTA — open source, MIT licensed.").font(.subheadline).foregroundStyle(VantaDS.secondaryText)
                if let url = DeveloperConfig.githubRepositoryURL {
                    Link(destination: url) {
                        HStack {
                            Text("Open GitHub Repository")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                        .padding().frame(maxWidth: .infinity)
                        .background(VantaDS.accent).foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }.accessibilityLabel("Open VANTA repository on GitHub")
                }
            }
        }
    }

    private var linksCard: some View {
        VantaCard {
            VStack(alignment: .leading, spacing: 4) {
                Text("Links").font(.headline)
                linkRow("GitHub", DeveloperConfig.githubProfileURL)
                linkRow("Documentation", DeveloperConfig.documentationURL)
                linkRow("Releases", DeveloperConfig.releasesURL)
                linkRow("Issues", DeveloperConfig.issuesURL)
                if let licenseURL = DeveloperConfig.githubRepositoryURL?.appendingPathComponent("blob/main/LICENSE")
                    ?? URL(string: "https://opensource.org/licenses/MIT") {
                    Link("License: MIT", destination: licenseURL)
                        .font(.subheadline).foregroundStyle(VantaDS.accent)
                }
            }
        }
    }

    private func linkRow(_ title: String, _ url: URL?) -> some View {
        Group {
            if let url { Link(title, destination: url).font(.subheadline).foregroundStyle(VantaDS.accent) }
        }
    }

    private func load() async {
        loadingAvatar = true
        let u = await GitHubAPI.shared.loadUser(username: DeveloperConfig.githubUsername)
        self.user = u
        if let data = await GitHubAPI.shared.loadAvatarData(from: u?.avatar_url),
           let ui = UIImage(data: data) {
            await MainActor.run { self.avatar = Image(uiImage: ui) }
        }
        await MainActor.run { self.loadingAvatar = false }
    }
}
