import SwiftUI

struct CommitmentDetailView: View {
    let commitment: Commitment

    @EnvironmentObject private var appEnvironment: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    @State private var status: Commitment.Status
    @State private var counterparty: String
    @State private var dueDate: Date?
    @State private var importance: Double
    @State private var urgency: Double
    @State private var notes: String
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(commitment: Commitment) {
        self.commitment = commitment
        _status = State(initialValue: commitment.status)
        _counterparty = State(initialValue: commitment.counterparty ?? "")
        _dueDate = State(initialValue: commitment.dueDate)
        _importance = State(initialValue: Double(commitment.importance ?? 3))
        _urgency = State(initialValue: Double(commitment.urgency ?? 3))
        _notes = State(initialValue: commitment.notes ?? "")
    }

    var body: some View {
        Form {
            Section("Details") {
                Picker("Status", selection: $status) {
                    Text("Open").tag(Commitment.Status.open)
                    Text("Done").tag(Commitment.Status.done)
                    Text("Blocked").tag(Commitment.Status.blocked)
                    Text("Dropped").tag(Commitment.Status.dropped)
                }
                TextField("Counterparty", text: $counterparty)
                Toggle("Has due date", isOn: Binding(
                    get: { dueDate != nil },
                    set: { value in dueDate = value ? (dueDate ?? Date()) : nil }
                ))
                if let existingDueDate = dueDate {
                    DatePicker("Due Date", selection: Binding(
                        get: { existingDueDate },
                        set: { dueDate = $0 }
                    ), displayedComponents: .date)
                }
                Slider(value: $importance, in: 1...5, step: 1) {
                    Text("Importance")
                }
                Text("Importance: \(Int(importance))")
                    .dojoCaptionLarge()
                Slider(value: $urgency, in: 1...5, step: 1) {
                    Text("Urgency")
                }
                Text("Urgency: \(Int(urgency))")
                    .dojoCaptionLarge()
            }

            Section("Notes") {
                TextField("Notes", text: $notes, axis: .vertical)
            }

            if let message = errorMessage {
                Section {
                    Text(message)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Commitment")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: save) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                    }
                }
            }
        }
    }

    private func save() {
        isSaving = true
        errorMessage = nil
        let input = UpdateCommitmentInput(
            status: status,
            counterparty: counterparty.isEmpty ? nil : counterparty,
            dueDate: dueDate,
            importance: Int(importance),
            urgency: Int(urgency),
            notes: notes.isEmpty ? nil : notes
        )

        Task {
            do {
                _ = try await appEnvironment.commitmentsService.updateCommitment(id: commitment.id, input: input)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
