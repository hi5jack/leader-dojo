import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment

    var body: some View {
        TabView(selection: $appEnvironment.activeTab) {
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: DojoIcons.dashboard)
                }
                .tag(AppEnvironment.MainTab.dashboard)
            
            ProjectsListView()
                .tabItem {
                    Label("Projects", systemImage: DojoIcons.projects)
                }
                .tag(AppEnvironment.MainTab.projects)
            
            CommitmentsView()
                .tabItem {
                    Label("Commits", systemImage: DojoIcons.commitments)
                }
                .tag(AppEnvironment.MainTab.commitments)
            
            ReflectionsListView()
                .tabItem {
                    Label("Reflect", systemImage: DojoIcons.reflections)
                }
                .tag(AppEnvironment.MainTab.reflections)
            
            CaptureView()
                .tabItem {
                    Label("Capture", systemImage: DojoIcons.capture)
                }
                .tag(AppEnvironment.MainTab.capture)
        }
        .tint(LeaderDojoColors.dojoAmber)
        .onAppear {
            configureTabBarAppearance()
        }
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(LeaderDojoColors.surfaceSecondary)
        
        // Configure normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(LeaderDojoColors.textTertiary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(LeaderDojoColors.textTertiary),
            .font: UIFont.systemFont(ofSize: 10, weight: .regular)
        ]
        
        // Configure selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(LeaderDojoColors.dojoAmber)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(LeaderDojoColors.dojoAmber),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        
        // Add subtle top border
        appearance.shadowColor = UIColor(LeaderDojoColors.dojoDarkGray)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Main Tab Extension

extension AppEnvironment.MainTab {
    var icon: String {
        switch self {
        case .dashboard:
            return DojoIcons.dashboard
        case .projects:
            return DojoIcons.projects
        case .commitments:
            return DojoIcons.commitments
        case .reflections:
            return DojoIcons.reflections
        case .capture:
            return DojoIcons.capture
        }
    }
    
    var label: String {
        switch self {
        case .dashboard:
            return "Home"
        case .projects:
            return "Projects"
        case .commitments:
            return "Commits"
        case .reflections:
            return "Reflect"
        case .capture:
            return "Capture"
        }
    }
    
    static var allCases: [AppEnvironment.MainTab] {
        [.dashboard, .projects, .commitments, .reflections, .capture]
    }
}
