import SwiftUI

struct ProjectsListView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject private var viewModel = ProjectsListViewModel()
    @State private var showingCreateSheet = false

    var body: some View {
        NavigationStack {
            List {
                if let message = viewModel.errorMessage {
                    Section {
                        Text(message)
                            .foregroundStyle(.red)
                    }
                }

                ForEach(viewModel.projects) { project in
                    NavigationLink(destination: ProjectDetailView(projectId: project.id)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(project.name)
                                .font(LeaderDojoTypography.subheading)
                            HStack(spacing: LeaderDojoSpacing.s) {
                                Text(project.type.rawValue.capitalized)
                                    .font(LeaderDojoTypography.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(LeaderDojoColors.card)
                                    .clipShape(Capsule())
                                Text(project.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .font(LeaderDojoTypography.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("Priority \(project.priority)")
                                    .font(LeaderDojoTypography.caption)
                            }
                            if let lastActive = project.lastActiveAt {
                                Text("Last active \(lastActive.formattedShort())")
                                    .font(LeaderDojoTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable { await viewModel.load() }
            .sheet(isPresented: $showingCreateSheet) {
                CreateProjectView { input in
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
}
