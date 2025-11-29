import SwiftUI
import SwiftData

/// Main navigation tabs
enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case activity = "Activity"
    case projects = "Projects"
    case commitments = "Commitments"
    case reflections = "Reflections"
    case capture = "Capture"
    case settings = "Settings"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dashboard: return "rectangle.3.group.fill"
        case .activity: return "clock.arrow.circlepath"
        case .projects: return "folder.fill"
        case .commitments: return "checklist"
        case .reflections: return "brain.head.profile"
        case .capture: return "plus.circle.fill"
        case .settings: return "gear"
        }
    }
    
    var label: String { rawValue }
    
    /// Tabs shown in the main navigation (excludes settings on iPhone)
    static var mainTabs: [AppTab] {
        [.dashboard, .activity, .projects, .commitments, .reflections, .capture]
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        Group {
            #if os(iOS)
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadLayout
            } else {
                iPhoneLayout
            }
            #else
            macOSLayout
            #endif
        }
    }
    
    // MARK: - iPhone Layout (Tab Bar)
    
    #if os(iOS)
    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            tabContent(for: .dashboard)
                .tabItem {
                    Label(AppTab.dashboard.label, systemImage: AppTab.dashboard.icon)
                }
                .tag(AppTab.dashboard)
            
            tabContent(for: .activity)
                .tabItem {
                    Label(AppTab.activity.label, systemImage: AppTab.activity.icon)
                }
                .tag(AppTab.activity)
            
            tabContent(for: .projects)
                .tabItem {
                    Label(AppTab.projects.label, systemImage: AppTab.projects.icon)
                }
                .tag(AppTab.projects)
            
            tabContent(for: .commitments)
                .tabItem {
                    Label(AppTab.commitments.label, systemImage: AppTab.commitments.icon)
                }
                .tag(AppTab.commitments)
            
            tabContent(for: .reflections)
                .tabItem {
                    Label(AppTab.reflections.label, systemImage: AppTab.reflections.icon)
                }
                .tag(AppTab.reflections)
            
            tabContent(for: .capture)
                .tabItem {
                    Label(AppTab.capture.label, systemImage: AppTab.capture.icon)
                }
                .tag(AppTab.capture)
            
            // Settings tab for iPhone (will appear in "More" section automatically if > 5 tabs)
            tabContent(for: .settings)
                .tabItem {
                    Label(AppTab.settings.label, systemImage: AppTab.settings.icon)
                }
                .tag(AppTab.settings)
        }
    }
    #endif
    
    // MARK: - iPad Layout (Sidebar + Content)
    
    #if os(iOS)
    private var iPadLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            NavigationStack {
                tabContent(for: selectedTab)
            }
            .id(selectedTab) // Reset navigation stack when tab changes
        }
    }
    #endif
    
    // MARK: - macOS Layout (Sidebar + Content)
    
    #if os(macOS)
    private var macOSLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        } detail: {
            NavigationStack {
                tabContent(for: selectedTab)
            }
            .id(selectedTab) // reset stack when switching tabs
        }
        .frame(minWidth: 900, minHeight: 600)
    }
    #endif
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        List {
            Section {
                sidebarRow(for: .dashboard)
                sidebarRow(for: .activity)
                sidebarRow(for: .projects)
                sidebarRow(for: .commitments)
                sidebarRow(for: .reflections)
                sidebarRow(for: .capture)
            } header: {
                Text("Leader Dojo")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            
            Section {
                sidebarRow(for: .settings)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Menu")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    private func sidebarRow(for tab: AppTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            HStack {
                Label(tab.label, systemImage: tab.icon)
                Spacer()
                if selectedTab == tab {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Tab Content
    
    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView()
        case .activity:
            ActivityView()
        case .projects:
            ProjectsListView()
        case .commitments:
            CommitmentsListView()
        case .reflections:
            ReflectionsListView()
        case .capture:
            CaptureView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self], inMemory: true)
}

