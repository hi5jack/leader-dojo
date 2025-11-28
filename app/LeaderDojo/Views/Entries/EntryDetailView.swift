import SwiftUI
import SwiftData

struct EntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var entry: Entry
    
    @State private var showingEditEntry: Bool = false
    @State private var showingDeleteAlert: Bool = false
    @State private var showingNewCommitment: Bool = false
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                // Header
                entryHeader
                
                // Content sections
                if let summary = entry.aiSummary, !summary.isEmpty {
                    summarySection(summary)
                }
                
                if let rawContent = entry.rawContent, !rawContent.isEmpty {
                    rawContentSection(rawContent)
                }
                
                if let decisions = entry.decisions, !decisions.isEmpty {
                    decisionsSection(decisions)
                }
                
                // Related Commitments
                commitmentsSection
                
                // Metadata
                metadataSection
            }
            .padding()
        }
        .navigationTitle(entry.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditEntry = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button {
                        showingNewCommitment = true
                    } label: {
                        Label("Add Commitment", systemImage: "plus.circle")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditEntry) {
            EditEntryView(entry: entry)
        }
        .sheet(isPresented: $showingNewCommitment) {
            NewCommitmentView(project: entry.project, sourceEntry: entry)
        }
        .alert("Delete Entry", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                entry.softDelete()
                try? modelContext.save()
            }
        } message: {
            Text("Are you sure you want to delete this entry? This action cannot be undone.")
        }
    }
    
    // MARK: - Entry Header
    
    private var entryHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Badge(text: entry.kind.displayName, icon: entry.kind.icon, color: kindColor)
                
                if entry.isDecision {
                    Badge(text: "Decision", icon: "checkmark.seal.fill", color: .purple)
                }
            }
            
            if let project = entry.project {
                NavigationLink {
                    ProjectDetailView(project: project)
                } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                        Text(project.name)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.secondary)
                Text(entry.occurredAt, style: .date)
                Text("at")
                    .foregroundStyle(.secondary)
                Text(entry.occurredAt, style: .time)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Summary Section
    
    private func summarySection(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("AI Summary", systemImage: "sparkles")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.purple)
            
            MarkdownText(summary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Raw Content Section
    
    private func rawContentSection(_ content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Original Notes", systemImage: "doc.text")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            MarkdownText(content)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Decisions Section
    
    private func decisionsSection(_ decisions: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Decisions Made", systemImage: "checkmark.seal.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.green)
            
            MarkdownText(decisions)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Commitments Section
    
    private var commitmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Related Commitments", systemImage: "checklist")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    showingNewCommitment = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            let commitments = entry.commitments ?? []
            
            if commitments.isEmpty {
                Text("No commitments linked to this entry.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(commitments) { commitment in
                    NavigationLink {
                        CommitmentDetailView(commitment: commitment)
                    } label: {
                        MiniCommitmentRow(commitment: commitment)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    // MARK: - Metadata Section
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            LabeledContent("Created", value: entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
            
            LabeledContent("Updated", value: entry.updatedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
            
            LabeledContent("ID", value: entry.id.uuidString.prefix(8).description)
                .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Computed Properties
    
    private var kindColor: Color {
        switch entry.kind {
        case .meeting: return .blue
        case .update: return .green
        case .decision: return .purple
        case .note: return .orange
        case .prep: return .cyan
        case .reflection: return .pink
        case .commitment: return .indigo
        }
    }
}

// MARK: - Edit Entry View

struct EditEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var entry: Entry
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $entry.kind) {
                        ForEach(EntryKind.allCases, id: \.self) { kind in
                            Label(kind.displayName, systemImage: kind.icon)
                                .tag(kind)
                        }
                    }
                    
                    DatePicker("Date", selection: $entry.occurredAt, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section("Content") {
                    TextField("Title", text: $entry.title)
                    
                    TextEditor(text: Binding(
                        get: { entry.rawContent ?? "" },
                        set: { entry.rawContent = $0.isEmpty ? nil : $0 }
                    ))
                    .frame(minHeight: 150)
                }
                
                Section {
                    Toggle("Key Decision", isOn: $entry.isDecision)
                }
                
                if entry.aiSummary != nil {
                    Section("AI Summary") {
                        TextEditor(text: Binding(
                            get: { entry.aiSummary ?? "" },
                            set: { entry.aiSummary = $0.isEmpty ? nil : $0 }
                        ))
                        .frame(minHeight: 100)
                    }
                }
            }
            .navigationTitle("Edit Entry")
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
                        entry.updatedAt = Date()
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let entry = Entry(kind: .meeting, title: "Weekly Sync")
    entry.rawContent = "Discussed project progress and next steps."
    entry.aiSummary = "Team aligned on Q4 priorities. Key blockers identified."
    
    return NavigationStack {
        EntryDetailView(entry: entry)
    }
    .modelContainer(for: [Project.self, Entry.self, Commitment.self], inMemory: true)
}

