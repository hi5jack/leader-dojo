import SwiftUI

struct CaptureView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject private var viewModel = CaptureViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    if viewModel.projects.isEmpty {
                        Text("Loading projects...")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Select", selection: $viewModel.selectedProjectId) {
                            ForEach(viewModel.projects) { project in
                                Text(project.name).tag(Optional(project.id))
                            }
                        }
                    }
                    TextField("New project name", text: $viewModel.newProjectName)
                        .textInputAutocapitalization(.words)
                }

                Section("Note") {
                    TextEditor(text: $viewModel.note)
                        .frame(minHeight: 200)
                }

                if let message = viewModel.errorMessage {
                    Section {
                        Text(message)
                            .foregroundStyle(.red)
                    }
                }

                Button(action: save) {
                    if viewModel.isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                    }
                }
                .disabled(viewModel.note.isEmpty || viewModel.isSaving)
            }
            .navigationTitle("Quick Capture")
        }
        .onAppear {
            viewModel.configure(service: appEnvironment.projectsService)
        }
        .task {
            await viewModel.loadProjects()
        }
    }

    private func save() {
        Task {
            do {
                try await viewModel.saveNote()
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
}
