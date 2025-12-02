import SwiftUI
import SwiftData

struct PersonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var person: Person
    
    @State private var showingEditPerson: Bool = false
    @State private var showingNewCommitment: Bool = false
    @State private var showingRelationshipReflection: Bool = false
    @State private var selectedCommitmentDirection: CommitmentDirection = .iOwe
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                // Header
                personHeader
                
                // Quick Stats
                statsSection
                
                // Commitments Section
                commitmentsSection
                
                // Entries Section
                entriesSection
                
                // Notes Section
                if let notes = person.notes, !notes.isEmpty {
                    notesSection(notes)
                }
                
                // Metadata
                metadataSection
            }
            .padding()
        }
        .navigationTitle(person.name)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        showingEditPerson = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Menu("Add Commitment") {
                        Button {
                            selectedCommitmentDirection = .iOwe
                            showingNewCommitment = true
                        } label: {
                            Label("I Owe", systemImage: "arrow.up.right.circle")
                        }
                        
                        Button {
                            selectedCommitmentDirection = .waitingFor
                            showingNewCommitment = true
                        } label: {
                            Label("Waiting For", systemImage: "arrow.down.left.circle")
                        }
                    }
                    
                    Button {
                        showingRelationshipReflection = true
                    } label: {
                        Label("Reflect on Relationship", systemImage: "brain.head.profile")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditPerson) {
            EditPersonView(person: person)
        }
        .sheet(isPresented: $showingNewCommitment) {
            NewCommitmentView(
                project: nil,
                person: person,
                sourceEntry: nil,
                preselectedDirection: selectedCommitmentDirection
            )
        }
        .sheet(isPresented: $showingRelationshipReflection) {
            NewReflectionView(person: person)
        }
    }
    
    // MARK: - Header
    
    private var personHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Avatar and name
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(avatarColor.opacity(0.2))
                        .frame(width: 64, height: 64)
                    
                    Text(initials)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(avatarColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(person.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if person.role != nil || person.organization != nil {
                        HStack(spacing: 4) {
                            if let role = person.role, !role.isEmpty {
                                Text(role)
                            }
                            if let org = person.organization, !org.isEmpty {
                                if person.role != nil {
                                    Text("•")
                                }
                                Text(org)
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Badges
            HStack(spacing: 8) {
                if let type = person.relationshipType {
                    Badge(text: type.displayName, icon: type.icon, color: avatarColor)
                }
                
                if person.hasOverdueCommitments {
                    Badge(text: "Overdue", icon: "exclamationmark.triangle.fill", color: .red)
                }
                
                if let days = person.daysSinceLastInteraction {
                    if days == 0 {
                        Badge(text: "Active today", icon: "clock.fill", color: .green)
                    } else if days <= 7 {
                        Badge(text: "\(days)d ago", icon: "clock", color: .blue)
                    } else if days > 30 {
                        Badge(text: "\(days)d silent", icon: "clock.badge.exclamationmark", color: .orange)
                    }
                }
            }
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            StatBox(title: "I Owe", value: person.iOweCount, icon: "arrow.up.right", color: .orange)
            StatBox(title: "Waiting", value: person.waitingForCount, icon: "arrow.down.left", color: .blue)
            StatBox(title: "Entries", value: person.entryCount, icon: "doc.text", color: .purple)
        }
    }
    
    // MARK: - Commitments Section
    
    private var commitmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Commitments", systemImage: "checkmark.circle")
                    .font(.headline)
                
                Spacer()
                
                Menu {
                    Button {
                        selectedCommitmentDirection = .iOwe
                        showingNewCommitment = true
                    } label: {
                        Label("I Owe", systemImage: "arrow.up.right.circle")
                    }
                    
                    Button {
                        selectedCommitmentDirection = .waitingFor
                        showingNewCommitment = true
                    } label: {
                        Label("Waiting For", systemImage: "arrow.down.left.circle")
                    }
                } label: {
                    Image(systemName: "plus.circle")
                        .foregroundStyle(.blue)
                }
            }
            
            if let commitments = person.commitments, !commitments.isEmpty {
                // I Owe section
                let iOweCommitments = commitments.filter { $0.direction == .iOwe && $0.status.isActive }
                if !iOweCommitments.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("I Owe")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.orange)
                        
                        ForEach(iOweCommitments) { commitment in
                            PersonCommitmentRow(commitment: commitment) {
                                toggleCommitment(commitment)
                            }
                        }
                    }
                }
                
                // Waiting For section
                let waitingCommitments = commitments.filter { $0.direction == .waitingFor && $0.status.isActive }
                if !waitingCommitments.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Waiting For")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                        
                        ForEach(waitingCommitments) { commitment in
                            PersonCommitmentRow(commitment: commitment) {
                                toggleCommitment(commitment)
                            }
                        }
                    }
                }
                
                // Completed section (collapsed by default)
                let completedCommitments = commitments.filter { !$0.status.isActive }
                if !completedCommitments.isEmpty {
                    DisclosureGroup {
                        ForEach(completedCommitments.prefix(5)) { commitment in
                            PersonCommitmentRow(commitment: commitment, showStatus: true) {
                                toggleCommitment(commitment)
                            }
                        }
                        
                        if completedCommitments.count > 5 {
                            Text("+\(completedCommitments.count - 5) more")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } label: {
                        Text("Completed (\(completedCommitments.count))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                EmptyStateCard(
                    icon: "checkmark.circle",
                    title: "No Commitments",
                    message: "Add a commitment to track what you owe or are waiting for."
                )
            }
        }
    }
    
    // MARK: - Entries Section
    
    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Entries", systemImage: "doc.text")
                .font(.headline)
            
            if let entries = person.entries, !entries.isEmpty {
                let sortedEntries = entries.sorted { $0.occurredAt > $1.occurredAt }
                
                ForEach(sortedEntries.prefix(5)) { entry in
                    #if os(macOS)
                    NavigationLink(value: AppRoute.entry(entry.persistentModelID)) {
                        PersonEntryRow(entry: entry)
                    }
                    .buttonStyle(.plain)
                    #else
                    NavigationLink {
                        EntryDetailView(entry: entry)
                    } label: {
                        PersonEntryRow(entry: entry)
                    }
                    .buttonStyle(.plain)
                    #endif
                }
                
                if entries.count > 5 {
                    Text("+ \(entries.count - 5) more entries")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
            } else {
                EmptyStateCard(
                    icon: "doc.text",
                    title: "No Entries",
                    message: "Entries involving this person will appear here."
                )
            }
        }
    }
    
    // MARK: - Notes Section
    
    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text")
                .font(.headline)
            
            Text(notes)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Metadata Section
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            LabeledContent("Added", value: person.createdAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
            
            LabeledContent("Updated", value: person.updatedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.caption)
            
            if let lastDate = person.lastInteractionDate {
                LabeledContent("Last interaction", value: lastDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Computed Properties
    
    private var initials: String {
        let components = person.name.components(separatedBy: " ")
        let initials = components.prefix(2).compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }
    
    private var avatarColor: Color {
        switch person.relationshipType?.groupName {
        case "Internal": return .blue
        case "Investment & Advisory": return .purple
        case "External": return .green
        default: return .gray
        }
    }
    
    // MARK: - Actions
    
    private func toggleCommitment(_ commitment: Commitment) {
        if commitment.status == .done {
            commitment.reopen()
        } else {
            commitment.markDone()
        }
        try? modelContext.save()
    }
}

// MARK: - Supporting Views

struct StatBox: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct PersonCommitmentRow: View {
    let commitment: Commitment
    var showStatus: Bool = false
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: commitment.status == .done ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(commitment.status == .done ? .green : .secondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(commitment.title)
                    .font(.subheadline)
                    .strikethrough(commitment.status == .done)
                    .foregroundStyle(commitment.status == .done ? .secondary : .primary)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    if let project = commitment.project {
                        Text(project.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let dueDate = commitment.dueDate {
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(commitment.isOverdue ? .red : .secondary)
                    }
                    
                    if showStatus && commitment.status != .open {
                        Text(commitment.status.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if commitment.isOverdue {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct PersonEntryRow: View {
    let entry: Entry
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.kind.icon)
                .font(.title3)
                .foregroundStyle(kindColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(entry.kind.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(entry.occurredAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var kindColor: Color {
        switch entry.kind {
        case .meeting: return .blue
        case .update: return .green
        case .decision: return .purple
        case .note: return .orange
        case .prep: return .cyan
        case .reflection: return .pink
        }
    }
}

#Preview {
    let person = Person(
        name: "Sarah Chen",
        organization: "Acme Corp",
        role: "CEO",
        relationshipType: .directReport,
        notes: "Key relationship for the Series A round. Very responsive and proactive."
    )
    
    return NavigationStack {
        PersonDetailView(person: person)
    }
    .modelContainer(for: [Person.self, Commitment.self, Entry.self, Project.self], inMemory: true)
}


