import SwiftUI

struct ProjectsListView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject private var viewModel = ProjectsListViewModel()
    @State private var showingCreateSheet = false
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LeaderDojoColors.surfacePrimary
                    .ignoresSafeArea()
                
                content
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            Haptics.cardTap()
                            showingCreateSheet = true
                        }) {
                            Image(systemName: DojoIcons.add)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(LeaderDojoColors.dojoBlack)
                                .frame(width: 60, height: 60)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            LeaderDojoColors.dojoAmber,
                                            LeaderDojoColors.dojoAmber.opacity(0.9)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(
                                    color: LeaderDojoColors.dojoAmber.opacity(0.4),
                                    radius: 16,
                                    x: 0,
                                    y: 4
                                )
                        }
                        .padding(.trailing, LeaderDojoSpacing.ml)
                        .padding(.bottom, LeaderDojoSpacing.l)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: LeaderDojoSpacing.s) {
                        Image(systemName: DojoIcons.projects)
                            .dojoIconMedium(color: LeaderDojoColors.dojoAmber)
                        Text("Projects")
                            .dojoHeadingLarge()
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateProjectView { input in
                    Haptics.projectAction()
                    try await viewModel.createProject(input: input)
                }
            }
        }
        .onAppear {
            viewModel.configure(service: appEnvironment.projectsService)
        }
        .task {
            if viewModel.projects.isEmpty {
                await viewModel.load()
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if let message = viewModel.errorMessage {
            DojoErrorView(message: message) {
                Task { await viewModel.load() }
            }
        } else if viewModel.projects.isEmpty {
            emptyState
        } else {
            projectsList
        }
    }
    
    private var emptyState: some View {
        DojoEmptyState(
            icon: DojoIcons.emptyProjects,
            title: "Start Your First Project",
            message: "Projects help you organize your leadership work, track commitments, and reflect on outcomes.",
            actionTitle: "Create Project"
        ) {
            Haptics.cardTap()
            showingCreateSheet = true
        }
    }
    
    private var projectsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: LeaderDojoSpacing.m) {
                // Search bar
                searchBar
                
                // Projects
                ForEach(filteredProjects) { project in
                    NavigationLink(destination: ProjectDetailView(projectId: project.id)) {
                        ProjectCard(project: project)
                    }
                    .buttonStyle(.plain)
                    .onTapGesture {
                        Haptics.cardTap()
                    }
                }
            }
            .padding(.horizontal, LeaderDojoSpacing.ml)
            .padding(.vertical, LeaderDojoSpacing.l)
            .padding(.bottom, 80) // Space for FAB
        }
        .refreshable {
            Haptics.refreshTriggered()
            await viewModel.load()
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: LeaderDojoSpacing.m) {
            Image(systemName: DojoIcons.search)
                .dojoIconMedium(color: LeaderDojoColors.textTertiary)
            
            TextField("Search projects...", text: $searchText)
                .dojoBodyMedium()
                .autocorrectionDisabled()
        }
        .padding(LeaderDojoSpacing.m)
        .background(LeaderDojoColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusMedium, style: .continuous)
                .strokeBorder(LeaderDojoColors.dojoDarkGray, lineWidth: 1)
        )
    }
    
    private var filteredProjects: [Project] {
        if searchText.isEmpty {
            return viewModel.projects
        }
        return viewModel.projects.filter { project in
            project.name.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Project Card

private struct ProjectCard: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.m) {
            // Header with priority stripe
            HStack(spacing: LeaderDojoSpacing.m) {
                VStack(alignment: .leading, spacing: LeaderDojoSpacing.xs) {
                    Text(project.name)
                        .dojoHeadingMedium()
                        .lineLimit(2)
                    
                    if let description = project.description, !description.isEmpty {
                        Text(description)
                            .dojoCaptionRegular()
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Status indicator
                statusDot
            }
            
            // Metadata row
            HStack(spacing: LeaderDojoSpacing.s) {
                // Type badge
                DojoBadge.type(project.type.rawValue, size: .compact)
                
                // Status
                Text(project.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .dojoLabel()
                    .foregroundStyle(LeaderDojoColors.textTertiary)
                
                Spacer()
                
                // Priority
                DojoBadge.priority(project.priority, size: .compact)
            }
            
            // Footer with last active
            if let lastActive = project.lastActiveAt {
                HStack(spacing: LeaderDojoSpacing.s) {
                    Image(systemName: DojoIcons.clock)
                        .dojoIconSmall(color: LeaderDojoColors.textTertiary)
                    Text("Last active \(lastActive.formattedShort())")
                        .dojoCaptionRegular()
                }
            }
        }
        .dojoCardWithBorder(color: priorityColor(project.priority), width: 4)
    }
    
    private var statusDot: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .strokeBorder(statusColor.opacity(0.3), lineWidth: 4)
            )
    }
    
    private var statusColor: Color {
        switch project.status {
        case .active:
            return LeaderDojoColors.dojoGreen
        case .on_hold:
            return LeaderDojoColors.dojoAmber
        case .completed:
            return LeaderDojoColors.dojoBlue
        case .archived:
            return LeaderDojoColors.dojoMediumGray
        }
    }
}
