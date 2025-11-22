import SwiftUI

struct AddEntryView: View {
    let project: Project
    let onCompletion: () async -> Void

    @EnvironmentObject private var appEnvironment: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    @State private var kind: Entry.Kind = .meeting
    @State private var title: String = ""
    @State private var occurredAt: Date = .init()
    @State private var rawContent: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var summaryResult: SummarizeEntryResponse?
    @State private var createdEntry: Entry?
    @State private var selectedActions: Set<UUID> = []
    @State private var isCreatingCommitments = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    Picker("Kind", selection: $kind) {
                        Text("Meeting").tag(Entry.Kind.meeting)
                        Text("Update").tag(Entry.Kind.update)
                        Text("Self Note").tag(Entry.Kind.self_note)
                        Text("Decision").tag(Entry.Kind.decision)
                    }
                    TextField("Title", text: $title)
                    DatePicker("Occurred", selection: $occurredAt, displayedComponents: [.date, .hourAndMinute])
                    TextField("Raw notes", text: $rawContent, axis: .vertical)
                        .lineLimit(5...10)
                }

                if let message = errorMessage {
                    Section {
                        Text(message)
                            .foregroundStyle(.red)
                    }
                }

                if let summaryResult {
                    summarySection(summaryResult)
                }
            }
            .navigationTitle("New Entry")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(isSaving || title.isEmpty)
                }
            }
        }
    }

    private func save() {
        guard !title.isEmpty else {
            errorMessage = "Title required"
            return
        }
        errorMessage = nil
        isSaving = true

        let input = CreateEntryInput(
            kind: kind,
            title: title,
            occurredAt: occurredAt,
            rawContent: rawContent.isEmpty ? nil : rawContent
        )

        Task {
            do {
                let entry = try await appEnvironment.projectsService.createEntry(projectId: project.id, input: input)
                createdEntry = entry
                summaryResult = try await appEnvironment.entriesService.summarizeEntry(entryId: entry.id)
                selectedActions = Set(summaryResult?.suggestedActions.map { $0.id } ?? [])
                await onCompletion()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }

    private func summarySection(_ summary: SummarizeEntryResponse) -> some View {
        Section("AI Summary") {
            Text(summary.summary)
                .dojoBodyLarge()
            if summary.suggestedActions.isEmpty {
                Text("No suggested commitments.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: LeaderDojoSpacing.m) {
                    ForEach(summary.suggestedActions) { action in
                        Toggle(isOn: Binding(
                            get: { selectedActions.contains(action.id) },
                            set: { value in
                                if value {
                                    selectedActions.insert(action.id)
                                } else {
                                    selectedActions.remove(action.id)
                                }
                            }
                        )) {
                            VStack(alignment: .leading, spacing: LeaderDojoSpacing.s) {
                                Text(action.title)
                                Text(action.direction == .i_owe ? "I Owe" : "Waiting For")
                                    .dojoCaptionLarge()
                                    .foregroundStyle(LeaderDojoColors.textSecondary)
                            }
                        }
                    }
                    Button(action: createCommitments) {
                        if isCreatingCommitments {
                            ProgressView()
                        } else {
                            Text("Create commitments")
                        }
                    }
                    .disabled(isCreatingCommitments || selectedActions.isEmpty)
                }
            }
        }
    }

    private func createCommitments() {
        guard let entry = createdEntry, let summary = summaryResult else { return }
        isCreatingCommitments = true
        let selected = summary.suggestedActions.filter { selectedActions.contains($0.id) }
        let actions = selected.map { action in
            EntrySuggestionInput.Action(
                title: action.title,
                direction: action.direction,
                counterparty: action.counterparty,
                dueDate: action.dueDate,
                importance: action.importance,
                urgency: action.urgency,
                notes: action.notes
            )
        }
        let payload = EntrySuggestionInput(projectId: project.id, actions: actions)

        Task {
            do {
                _ = try await appEnvironment.entriesService.createCommitmentsFromSuggestions(entryId: entry.id, payload: payload)
                await onCompletion()
                Haptics.success()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                Haptics.error()
            }
            isCreatingCommitments = false
        }
    }
}
