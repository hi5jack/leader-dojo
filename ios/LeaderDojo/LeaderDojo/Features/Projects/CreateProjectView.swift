import SwiftUI

struct CreateProjectView: View {
    enum Field { case name }

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    @State private var name: String = ""
    @State private var description: String = ""
    @State private var type: Project.ProjectType = .project
    @State private var status: Project.Status = .active
    @State private var priority: Double = 3
    @State private var notes: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    let onCreate: (CreateProjectInput) async throws -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Basics") {
                    TextField("Name", text: $name)
                        .focused($focusedField, equals: .name)
                    Picker("Type", selection: $type) {
                        Text("Project").tag(Project.ProjectType.project)
                        Text("Relationship").tag(Project.ProjectType.relationship)
                        Text("Area").tag(Project.ProjectType.area)
                    }
                    Picker("Status", selection: $status) {
                        Text("Active").tag(Project.Status.active)
                        Text("On Hold").tag(Project.Status.on_hold)
                        Text("Completed").tag(Project.Status.completed)
                        Text("Archived").tag(Project.Status.archived)
                    }
                    Slider(value: $priority, in: 1...5, step: 1) {
                        Text("Priority")
                    }
                    Text("Priority \(Int(priority))")
                        .dojoCaptionLarge()
                        .foregroundStyle(LeaderDojoColors.textSecondary)
                }

                Section("Details") {
                    TextField("Description", text: $description, axis: .vertical)
                    TextField("Owner notes", text: $notes, axis: .vertical)
                }

                if let message = errorMessage {
                    Section {
                        Text(message)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Project")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Create")
                        }
                    }
                    .disabled(isSaving || name.isEmpty)
                }
            }
        }
    }

    private func save() {
        guard !name.isEmpty else {
            errorMessage = "Name is required"
            focusedField = .name
            return
        }
        errorMessage = nil
        isSaving = true
        let input = CreateProjectInput(
            name: name,
            description: description.isEmpty ? nil : description,
            type: type,
            status: status,
            priority: Int(priority),
            ownerNotes: notes.isEmpty ? nil : notes
        )

        Task {
            do {
                try await onCreate(input)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
