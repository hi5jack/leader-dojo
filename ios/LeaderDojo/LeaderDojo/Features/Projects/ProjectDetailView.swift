import SwiftUI

struct ProjectDetailView: View {
    let projectId: String

    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject private var viewModel = ProjectDetailViewModel()
    @State private var showingAddEntry = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LeaderDojoSpacing.l) {
                if let project = viewModel.project {
                    projectHeader(project)
                }
                timelineSection
                commitmentsSection
            }
            .padding()
        }
        .navigationTitle(viewModel.project?.name ?? "Project")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add Entry") { showingAddEntry = true }
            }
        }
        .sheet(isPresented: $showingAddEntry) {
            if let project = viewModel.project {
                AddEntryView(project: project) {
                    await viewModel.fetchEntries()
                    await viewModel.fetchCommitments()
                }
                .environmentObject(appEnvironment)
            }
        }
        .onAppear {
            viewModel.configure(
                projectsService: appEnvironment.projectsService,
                entriesService: appEnvironment.entriesService,
                commitmentsService: appEnvironment.commitmentsService
            )
        }
        .task {
            await viewModel.load(projectId: projectId)
        }
        .refreshable {
            await viewModel.load(projectId: projectId)
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.m) {
            header(title: "Timeline", subtitle: "Recent entries")
            if viewModel.entries.isEmpty {
                Text("No entries yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.entries) { entry in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.kind.rawValue.capitalized)
                                .font(LeaderDojoTypography.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(LeaderDojoColors.card)
                                .clipShape(Capsule())
                            Spacer()
                            Text(entry.occurredAt.formattedShort())
                                .font(LeaderDojoTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text(entry.title)
                            .font(LeaderDojoTypography.subheading)
                        if let summary = entry.aiSummary, !summary.isEmpty {
                            Text(summary)
                                .font(LeaderDojoTypography.caption)
                                .foregroundStyle(.secondary)
                        } else if let raw = entry.rawContent {
                            Text(raw)
                                .font(LeaderDojoTypography.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(3)
                        }
                    }
                    .cardStyle()
                }
            }
        }
    }

    private var commitmentsSection: some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.m) {
            header(title: "Open commitments", subtitle: "Linked to this project")
            if viewModel.commitments.isEmpty {
                Text("Nothing outstanding.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.commitments) { commitment in
                    VStack(alignment: .leading, spacing: LeaderDojoSpacing.s) {
                        HStack {
                            Text(commitment.title)
                                .font(LeaderDojoTypography.subheading)
                            Spacer()
                            Text(commitment.direction == .i_owe ? "I Owe" : "Waiting For")
                                .font(LeaderDojoTypography.caption)
                        }
                        if let due = commitment.dueDate {
                            Text("Due \(due.formattedShort())")
                                .font(LeaderDojoTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .cardStyle()
                }
            }
        }
    }

    private func projectHeader(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.s) {
            Text(project.name)
                .font(LeaderDojoTypography.heading)
            Text(project.description ?? "No description")
                .foregroundStyle(.secondary)
            HStack(spacing: LeaderDojoSpacing.s) {
                Text(project.type.rawValue.capitalized)
                    .font(LeaderDojoTypography.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(LeaderDojoColors.card)
                    .clipShape(Capsule())
                Text(project.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(LeaderDojoTypography.caption)
                    .foregroundStyle(.secondary)
                Text("Priority \(project.priority)")
                    .font(LeaderDojoTypography.caption)
            }
            if let notes = project.ownerNotes, !notes.isEmpty {
                Text(notes)
                    .font(LeaderDojoTypography.body)
            }
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
}
