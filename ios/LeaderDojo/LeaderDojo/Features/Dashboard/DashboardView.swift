import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LeaderDojoColors.surfacePrimary
                    .ignoresSafeArea()
                
                content
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: LeaderDojoSpacing.s) {
                        Image(systemName: DojoIcons.dashboard)
                            .dojoIconMedium(color: LeaderDojoColors.dojoAmber)
                        Text("Dashboard")
                            .dojoHeadingLarge()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Haptics.refreshTriggered()
                        reload()
                    }) {
                        Image(systemName: DojoIcons.refresh)
                            .dojoIconMedium(color: LeaderDojoColors.textPrimary)
                    }
                    .disabled(isLoading)
                }
            }
        }
        .onAppear {
            viewModel.configure(service: appEnvironment.dashboardService)
        }
        .task {
            await loadIfNeeded()
        }
    }

    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            return AnyView(DojoLoadingView("Loading your practice space..."))
        case let .failed(message):
            return AnyView(DojoErrorView(message: message, retryAction: reload))
        case let .loaded(data):
            return AnyView(loadedView(data: data))
        }
    }

    private func loadedView(data: DashboardData) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: LeaderDojoSpacing.xl) {
                // Hero Section
                heroSection()
                
                // Weekly Focus
                weeklyFocusSection(weeklyFocus: data.weeklyFocus)
                
                // Idle Projects
                idleProjectsSection(projects: data.idleProjects)
                
                // Stats Section
                pendingSection(pending: data.pending)
            }
            .padding(.horizontal, LeaderDojoSpacing.ml)
            .padding(.vertical, LeaderDojoSpacing.l)
        }
        .refreshable {
            Haptics.refreshTriggered()
            await reloadAsync()
        }
    }
    
    private func heroSection() -> some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.s) {
            Text("FOCUS TODAY")
                .dojoLabel()
                .foregroundStyle(LeaderDojoColors.dojoAmber)
            
            Text("Your Leadership Practice")
                .dojoDisplayMedium()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func weeklyFocusSection(weeklyFocus: [Commitment]) -> some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.m) {
            VStack(alignment: .leading, spacing: LeaderDojoSpacing.xs) {
                Text("Top Commitments")
                    .dojoHeadingMedium()
                Text("AI-prioritized focus for this week")
                    .dojoCaptionRegular()
            }
            
            if weeklyFocus.isEmpty {
                DojoEmptyState(
                    icon: DojoIcons.emptyCommitments,
                    title: "All Clear",
                    message: "No open commitments right now. Great work staying on top of things!"
                )
                .dojoFlatCard()
            } else {
                ForEach(Array(weeklyFocus.enumerated()), id: \.element.id) { index, commitment in
                    CommitmentCard(commitment: commitment, rank: index + 1)
                        .onTapGesture {
                            Haptics.cardTap()
                        }
                }
            }
        }
    }

    private func idleProjectsSection(projects: [Project]) -> some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.m) {
            VStack(alignment: .leading, spacing: LeaderDojoSpacing.xs) {
                HStack(spacing: LeaderDojoSpacing.s) {
                    Image(systemName: DojoIcons.warning)
                        .dojoIconSmall(color: LeaderDojoColors.dojoRed)
                    Text("Needs Attention")
                        .dojoHeadingMedium()
                }
                Text("High-priority projects with no recent activity")
                    .dojoCaptionRegular()
            }
            
            if projects.isEmpty {
                HStack(spacing: LeaderDojoSpacing.m) {
                    Image(systemName: DojoIcons.success)
                        .dojoIconLarge(color: LeaderDojoColors.dojoGreen)
                    Text("All priority projects have recent activity")
                        .dojoBodyMedium()
                        .foregroundStyle(LeaderDojoColors.textSecondary)
                }
                .dojoFlatCard()
            } else {
                ForEach(projects) { project in
                    IdleProjectCard(project: project)
                        .onTapGesture {
                            Haptics.cardTap()
                            appEnvironment.activeTab = .projects
                        }
                }
            }
        }
    }

    private func pendingSection(pending: DashboardData.Pending) -> some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.m) {
            VStack(alignment: .leading, spacing: LeaderDojoSpacing.xs) {
                Text("Pending Reviews")
                    .dojoHeadingMedium()
                Text("Close the loop on reflections and decisions")
                    .dojoCaptionRegular()
            }
            
            HStack(spacing: LeaderDojoSpacing.m) {
                PendingTile(
                    title: "Decisions",
                    subtitle: "Needing review",
                    value: pending.decisionsNeedingReview,
                    icon: DojoIcons.decision,
                    color: LeaderDojoColors.dojoAmber
                ) {
                    Haptics.cardTap()
                    appEnvironment.activeTab = .projects
                }
                
                PendingTile(
                    title: "Reflections",
                    subtitle: "To complete",
                    value: pending.pendingReflections,
                    icon: DojoIcons.insight,
                    color: LeaderDojoColors.dojoEmerald
                ) {
                    Haptics.cardTap()
                    appEnvironment.activeTab = .reflections
                }
            }
        }
    }

    private func reload() {
        Task { await reloadAsync() }
    }

    private func reloadAsync() async {
        await viewModel.load()
    }

    private func loadIfNeeded() async {
        if case .idle = viewModel.state {
            await viewModel.load()
        }
    }

    private var isLoading: Bool {
        if case .loading = viewModel.state { return true }
        return false
    }
}

// MARK: - Commitment Card

private struct CommitmentCard: View {
    let commitment: Commitment
    let rank: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.m) {
            // Header with rank
            HStack(alignment: .top) {
                // Rank indicator
                Text("#\(rank)")
                    .font(LeaderDojoTypography.label)
                    .foregroundStyle(LeaderDojoColors.dojoAmber)
                    .padding(.horizontal, LeaderDojoSpacing.s)
                    .padding(.vertical, LeaderDojoSpacing.xs)
                    .background(LeaderDojoColors.dojoAmber.opacity(0.2))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: LeaderDojoSpacing.xs) {
                    Text(commitment.title)
                        .dojoHeadingMedium()
                        .lineLimit(2)
                    
                    if let counterparty = commitment.counterparty {
                        HStack(spacing: LeaderDojoSpacing.xs) {
                            Image(systemName: "person.circle.fill")
                                .dojoIconSmall(color: LeaderDojoColors.textTertiary)
                            Text(counterparty)
                                .dojoCaptionRegular()
                        }
                    }
                }
                
                Spacer()
                
                // Direction badge
                DojoBadge.direction(
                    commitment.direction == .i_owe ? "i_owe" : "waiting_for",
                    size: .compact
                )
            }
            
            // Due date with urgency indicator
            if let dueDate = commitment.dueDate {
                HStack(spacing: LeaderDojoSpacing.s) {
                    Image(systemName: DojoIcons.clock)
                        .dojoIconSmall(color: dueDateColor(dueDate))
                    Text("Due \(dueDate.formattedShort())")
                        .font(LeaderDojoTypography.captionLarge)
                        .foregroundStyle(dueDateColor(dueDate))
                }
            }
        }
        .dojoCardWithBorder(
            color: commitment.direction == .i_owe ? LeaderDojoColors.dojoAmber : LeaderDojoColors.dojoBlue
        )
    }
    
    private func dueDateColor(_ date: Date) -> Color {
        let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if daysUntilDue < 0 {
            return LeaderDojoColors.dojoRed
        } else if daysUntilDue <= 3 {
            return LeaderDojoColors.dojoAmber
        } else {
            return LeaderDojoColors.textSecondary
        }
    }
}

// MARK: - Idle Project Card

private struct IdleProjectCard: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: LeaderDojoSpacing.m) {
            // Warning indicator
            Image(systemName: DojoIcons.warning)
                .dojoIconLarge(color: LeaderDojoColors.dojoRed)
                .frame(width: 44, height: 44)
                .background(LeaderDojoColors.dojoRed.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: LeaderDojoSpacing.xs) {
                Text(project.name)
                    .dojoHeadingMedium()
                    .lineLimit(1)
                
                if let lastActive = project.lastActiveAt {
                    let daysSince = Calendar.current.dateComponents([.day], from: lastActive, to: Date()).day ?? 0
                    Text("\(daysSince) days since last activity")
                        .dojoCaptionLarge()
                        .foregroundStyle(LeaderDojoColors.dojoRed)
                } else {
                    Text("No recent activity")
                        .dojoCaptionRegular()
                }
            }
            
            Spacer()
            
            DojoBadge.priority(project.priority, size: .compact)
        }
        .dojoCardWithBorder(color: LeaderDojoColors.dojoRed)
    }
}

// MARK: - Pending Tile

private struct PendingTile: View {
    let title: String
    let subtitle: String
    let value: Int
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: LeaderDojoSpacing.m) {
                Image(systemName: icon)
                    .dojoIconXL(color: color)
                
                VStack(alignment: .leading, spacing: LeaderDojoSpacing.xs) {
                    Text("\(value)")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(LeaderDojoColors.textPrimary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(LeaderDojoTypography.captionLarge)
                            .foregroundStyle(LeaderDojoColors.textPrimary)
                        Text(subtitle)
                            .font(LeaderDojoTypography.captionRegular)
                            .foregroundStyle(LeaderDojoColors.textTertiary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .dojoCard()
        }
        .buttonStyle(.plain)
    }
}



