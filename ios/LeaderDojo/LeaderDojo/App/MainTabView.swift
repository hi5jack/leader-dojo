import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment

    var body: some View {
        TabView(selection: $appEnvironment.activeTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }
                .tag(AppEnvironment.MainTab.dashboard)

            ProjectsListView()
                .tabItem { Label("Projects", systemImage: "folder.fill") }
                .tag(AppEnvironment.MainTab.projects)

            CommitmentsView()
                .tabItem { Label("Commitments", systemImage: "checkmark.circle.fill") }
                .tag(AppEnvironment.MainTab.commitments)

            ReflectionsListView()
                .tabItem { Label("Reflections", systemImage: "book.pages.fill") }
                .tag(AppEnvironment.MainTab.reflections)

            CaptureView()
                .tabItem { Label("Capture", systemImage: "plus.circle.fill") }
                .tag(AppEnvironment.MainTab.capture)
        }
    }
}
