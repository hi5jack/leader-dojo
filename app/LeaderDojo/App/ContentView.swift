import SwiftUI
import SwiftData

/// Main navigation tabs
enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case activity = "Activity"
    case projects = "Projects"
    case people = "People"
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
        case .people: return "person.2.fill"
        case .commitments: return "checklist"
        case .reflections: return "brain.head.profile"
        case .capture: return "plus.circle.fill"
        case .settings: return "gear"
        }
    }
    
    var label: String { rawValue }
    
    /// Tabs shown in the main navigation (excludes settings on iPhone)
    static var mainTabs: [AppTab] {
        [.dashboard, .activity, .projects, .people, .commitments, .reflections, .capture]
    }
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    #if os(macOS)
    /// Shared navigation path for the detail column on macOS.
    @State private var navigationPath = NavigationPath()
    /// We inject the model context so we can resolve `AppRoute` identifiers
    /// back into SwiftData models.
    @Environment(\.modelContext) private var modelContext
    #endif
    
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
    // iOS TabView shows first 5 tabs directly, overflow goes to "More" tab.
    // The "More" tab provides its own UIKit navigation controller.
    // First 5 tabs need NavigationStack; overflow tabs should NOT have one to avoid double navigation.
    
    #if os(iOS)
    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            // First 5 tabs shown directly in tab bar - need NavigationStack
            NavigationStack {
                tabContent(for: .dashboard)
            }
            .tabItem {
                Label(AppTab.dashboard.label, systemImage: AppTab.dashboard.icon)
            }
            .tag(AppTab.dashboard)
            
            NavigationStack {
                tabContent(for: .activity)
            }
            .tabItem {
                Label(AppTab.activity.label, systemImage: AppTab.activity.icon)
            }
            .tag(AppTab.activity)
            
            NavigationStack {
                tabContent(for: .projects)
            }
            .tabItem {
                Label(AppTab.projects.label, systemImage: AppTab.projects.icon)
            }
            .tag(AppTab.projects)
            
            NavigationStack {
                tabContent(for: .people)
            }
            .tabItem {
                Label(AppTab.people.label, systemImage: AppTab.people.icon)
            }
            .tag(AppTab.people)
            
            NavigationStack {
                tabContent(for: .commitments)
            }
            .tabItem {
                Label(AppTab.commitments.label, systemImage: AppTab.commitments.icon)
            }
            .tag(AppTab.commitments)
            
            // Tabs 6-8 go into "More" tab - iOS provides navigation, so NO NavigationStack here
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
            NavigationStack(path: $navigationPath) {
                tabContent(for: selectedTab)
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .id(selectedTab) // reset root when switching tabs
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
                sidebarRow(for: .people)
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
            #if os(macOS)
            // On macOS, always clear the NavigationStack path when a sidebar item
            // is tapped so any pushed detail views (like reflection flows) are
            // dismissed and we return to the root of the selected tab.
            navigationPath = NavigationPath()
            #endif
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
    
    // MARK: - macOS Route Resolution
    
    #if os(macOS)
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .project(let id):
            if let project = modelContext.model(for: id) as? Project {
                ProjectDetailView(project: project)
            }
        case .projectEntries(let id):
            if let project = modelContext.model(for: id) as? Project {
                ProjectEntriesListView(project: project)
            }
        case .entry(let id):
            if let entry = modelContext.model(for: id) as? Entry {
                EntryDetailView(entry: entry)
            }
        case .commitment(let id):
            if let commitment = modelContext.model(for: id) as? Commitment {
                CommitmentDetailView(commitment: commitment)
            }
        case .reflection(let id):
            if let reflection = modelContext.model(for: id) as? Reflection {
                ReflectionDetailView(reflection: reflection)
            }
        case .person(let id):
            if let person = modelContext.model(for: id) as? Person {
                PersonDetailView(person: person)
            }
        case .newPeriodicReflection(let periodType):
            NewReflectionView(periodType: periodType)
        case .newProjectReflection(let id):
            if let project = modelContext.model(for: id) as? Project {
                NewReflectionView(project: project)
            }
        case .personEntries(let id):
            if let person = modelContext.model(for: id) as? Person {
                PersonEntriesView(person: person)
            }
        case .personPrep(let id):
            if let person = modelContext.model(for: id) as? Person {
                PersonPrepView(person: person)
            }
        case .reflectionInsights:
            ReflectionInsightsView()
        case .decisionInsights:
            DecisionInsightsView()
        case .relationshipInsights:
            RelationshipInsightsView()
        }
    }
    #endif
    
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
        case .people:
            PeopleListView()
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
        .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self, Person.self], inMemory: true)
}

