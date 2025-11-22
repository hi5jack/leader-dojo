import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject private var viewModel = DashboardViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Dashboard")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: reload) {
                            Image(systemName: "arrow.clockwise")
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
            return AnyView(loadingView)
        case let .failed(message):
            return AnyView(errorView(message: message))
        case let .loaded(data):
            return AnyView(loadedView(data: data))
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView("Loading dashboard")
            Spacer()
        }
        .padding()
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: LeaderDojoSpacing.m) {
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button("Retry", action: reload)
                .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
    }

    private func loadedView(data: DashboardData) -> some View {
        ScrollView {
            VStack(spacing: LeaderDojoSpacing.l) {
                weeklyFocusSection(weeklyFocus: data.weeklyFocus)
                idleProjectsSection(projects: data.idleProjects)
                pendingSection(pending: data.pending)
            }
            .padding()
        }
        .refreshable { await reloadAsync() }
    }

    private func weeklyFocusSection(weeklyFocus: [Commitment]) -> some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.m) {
            header(title: "Top commitments", subtitle: "AI-prioritized focus for this week")
            if weeklyFocus.isEmpty {
                Text("No open commitments right now.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(weeklyFocus) { commitment in
                    VStack(alignment: .leading, spacing: LeaderDojoSpacing.s) {
                        HStack {
                            Text(commitment.title)
                                .font(LeaderDojoTypography.subheading)
                            Spacer()
                            Text(commitment.direction == .i_owe ? "I Owe" : "Waiting For")
                                .font(LeaderDojoTypography.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(commitment.direction == .i_owe ? LeaderDojoColors.amber.opacity(0.2) : LeaderDojoColors.blue.opacity(0.2))
                                .clipShape(Capsule())
                        }
                        if let counterparty = commitment.counterparty {
                            Text("Counterparty: \(counterparty)")
                                .font(LeaderDojoTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                        if let dueDate = commitment.dueDate {
                            Text("Due \(dueDate.formattedShort())")
                                .font(LeaderDojoTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .cardStyle()
                }
            }
        }
    }

    private func idleProjectsSection(projects: [Project]) -> some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.m) {
            header(title: "Idle projects", subtitle: "High-priority work with no recent activity")
            if projects.isEmpty {
                Text("All priority projects have recent activity.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(projects) { project in
                    VStack(alignment: .leading, spacing: LeaderDojoSpacing.s) {
                        HStack {
                            Text(project.name)
                                .font(LeaderDojoTypography.subheading)
                            Spacer()
                            Text("Priority \(project.priority)")
                                .font(LeaderDojoTypography.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(LeaderDojoColors.warning.opacity(0.2))
                                .clipShape(Capsule())
                        }
                        Text("Last update: \(project.lastActiveAt?.formattedShort() ?? "Unknown")")
                            .font(LeaderDojoTypography.caption)
                            .foregroundStyle(.secondary)
                    }
                    .cardStyle()
                }
            }
        }
    }

    private func pendingSection(pending: DashboardData.Pending) -> some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.m) {
            header(title: "Pending reviews", subtitle: "Close the loop on reflections and decisions")
            HStack(spacing: LeaderDojoSpacing.l) {
                pendingTile(title: "Decisions needing review", value: pending.decisionsNeedingReview) {
                    appEnvironment.activeTab = .projects
                }
                pendingTile(title: "Pending reflections", value: pending.pendingReflections) {
                    appEnvironment.activeTab = .reflections
                }
            }
        }
    }

    private func pendingTile(title: String, value: Int, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.s) {
            Text("\(value)")
                .font(.system(size: 34, weight: .bold))
            Text(title)
                .font(LeaderDojoTypography.caption)
                .foregroundStyle(.secondary)
            Button("Go") {
                action()
            }
            .buttonStyle(.borderedProminent)
        }
        .cardStyle()
    }

    private func header(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(LeaderDojoTypography.subheading)
            Text(subtitle)
                .font(LeaderDojoTypography.caption)
                .foregroundStyle(.secondary)
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
