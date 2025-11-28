import SwiftUI
import SwiftData

/// Main navigation tabs
enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case projects = "Projects"
    case commitments = "Commitments"
    case reflections = "Reflections"
    case capture = "Capture"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dashboard: return "rectangle.3.group.fill"
        case .projects: return "folder.fill"
        case .commitments: return "checklist"
        case .reflections: return "brain.head.profile"
        case .capture: return "plus.circle.fill"
        }
    }
    
    var label: String { rawValue }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showingSettings: Bool = false
    
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
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
        }
    }
    
    // MARK: - iPhone Layout (Tab Bar)
    
    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            tabContent(for: .dashboard)
                .tabItem {
                    Label(AppTab.dashboard.label, systemImage: AppTab.dashboard.icon)
                }
                .tag(AppTab.dashboard)
            
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
        }
    }
    
    // MARK: - iPad Layout (Sidebar + Content)
    
    private var iPadLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } detail: {
            tabContent(for: selectedTab)
        }
    }
    
    // MARK: - macOS Layout (Sidebar + Content)
    
    private var macOSLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
                #if os(macOS)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
                #endif
        } detail: {
            tabContent(for: selectedTab)
        }
        #if os(macOS)
        .frame(minWidth: 900, minHeight: 600)
        #endif
    }
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        List {
            Section {
                sidebarRow(for: .dashboard)
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
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                }
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
        case .projects:
            ProjectsListView()
        case .commitments:
            CommitmentsListView()
        case .reflections:
            ReflectionsListView()
        case .capture:
            CaptureView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self], inMemory: true)
}

