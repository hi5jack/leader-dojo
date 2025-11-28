import SwiftUI
import SwiftData

struct NewEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let project: Project
    var preselectedKind: EntryKind?
    
    @State private var kind: EntryKind = .note
    @State private var title: String = ""
    @State private var rawContent: String = ""
    @State private var occurredAt: Date = Date()
    @State private var isDecision: Bool = false
    
    // AI Summary state
    @State private var isGeneratingSummary: Bool = false
    @State private var aiSummary: String = ""
    @State private var suggestedActions: [SuggestedAction] = []
    @State private var showAIResults: Bool = false
    @State private var aiError: String? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                // Entry Type Section
                Section {
                    Picker("Type", selection: $kind) {
                        ForEach(EntryKind.allCases, id: \.self) { entryKind in
                            Label(entryKind.displayName, systemImage: entryKind.icon)
                                .tag(entryKind)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    DatePicker("Date", selection: $occurredAt, displayedComponents: [.date, .hourAndMinute])
                }
                
                // Content Section
                Section {
                    TextField("Title", text: $title)
                    
                    TextEditor(text: $rawContent)
                        .frame(minHeight: 150)
                } header: {
                    Text("Content")
                } footer: {
                    if kind.supportsAISummary {
                        Text("Paste your meeting notes or raw content. AI can generate a summary and suggest commitments.")
                    }
                }
                
                // Decision marker
                if kind == .decision || kind == .meeting {
                    Section {
                        Toggle("Mark as Key Decision", isOn: $isDecision)
                    } footer: {
                        Text("Key decisions can be reviewed later for reflection.")
                    }
                }
                
                // AI Summary Section
                if kind.supportsAISummary && !rawContent.isEmpty {
                    Section {
                        Button {
                            generateAISummary()
                        } label: {
                            HStack {
                                if isGeneratingSummary {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(isGeneratingSummary ? "Generating..." : "Generate Summary & Actions")
                            }
                        }
                        .disabled(isGeneratingSummary || rawContent.isEmpty)
                        
                        if let error = aiError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    } header: {
                        Text("AI Assistant")
                    }
                }
                
                // AI Results Section
                if showAIResults {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Summary")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            TextEditor(text: $aiSummary)
                                .frame(minHeight: 100)
                        }
                    } header: {
                        Text("Generated Summary")
                    }
                    
                    if !suggestedActions.isEmpty {
                        Section {
                            ForEach($suggestedActions) { $action in
                                SuggestedActionRow(action: $action)
                            }
                        } header: {
                            Text("Suggested Commitments")
                        } footer: {
                            Text("Select the commitments you want to create.")
                        }
                    }
                }
            }
            .navigationTitle("New Entry")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(title.isEmpty)
                }
            }
            .onAppear {
                if let preselected = preselectedKind {
                    kind = preselected
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func generateAISummary() {
        isGeneratingSummary = true
        aiError = nil
        
        Task {
            do {
                let result = try await AIService.shared.summarizeEntry(
                    rawContent: rawContent,
                    projectName: project.name,
                    entryKind: kind
                )
                
                await MainActor.run {
                    aiSummary = result.summary
                    suggestedActions = result.suggestedActions
                    showAIResults = true
                    isGeneratingSummary = false
                }
            } catch {
                await MainActor.run {
                    aiError = error.localizedDescription
                    isGeneratingSummary = false
                }
            }
        }
    }
    
    private func saveEntry() {
        let entry = Entry(
            kind: kind,
            title: title,
            occurredAt: occurredAt,
            rawContent: rawContent.isEmpty ? nil : rawContent,
            aiSummary: aiSummary.isEmpty ? nil : aiSummary,
            isDecision: isDecision
        )
        
        entry.project = project
        
        // Store suggested actions
        if !suggestedActions.isEmpty {
            entry.aiSuggestedActions = suggestedActions
        }
        
        modelContext.insert(entry)
        
        // Create selected commitments
        let selectedActions = suggestedActions.filter { $0.isSelected }
        for action in selectedActions {
            let commitment = Commitment(
                title: action.title,
                direction: action.direction,
                counterparty: action.counterparty,
                aiGenerated: true
            )
            commitment.project = project
            commitment.sourceEntry = entry
            modelContext.insert(commitment)
        }
        
        // Update project's last active timestamp
        project.markActive()
        
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Suggested Action Row

struct SuggestedActionRow: View {
    @Binding var action: SuggestedAction
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                action.isSelected.toggle()
            } label: {
                Image(systemName: action.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(action.isSelected ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(action.title)
                    .font(.subheadline)
                
                HStack(spacing: 8) {
                    Label(action.direction.displayName, systemImage: action.direction.icon)
                        .font(.caption)
                        .foregroundStyle(action.direction == .iOwe ? .orange : .blue)
                    
                    if let counterparty = action.counterparty {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(counterparty)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NewEntryView(project: Project(name: "Test Project"))
        .modelContainer(for: [Project.self, Entry.self, Commitment.self], inMemory: true)
}


