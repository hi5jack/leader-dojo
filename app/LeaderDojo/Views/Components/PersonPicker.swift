import SwiftUI
import SwiftData

// MARK: - Person Picker Mode

enum PersonPickerMode {
    case single
    case multiple
}

// MARK: - Person Picker (Single Selection)

/// A picker component for selecting a single person, with quick-create support
struct PersonPicker: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.name) private var allPeople: [Person]
    
    @Binding var selection: Person?
    var label: String = "Person"
    var allowCreate: Bool = true
    var placeholder: String = "Select a person"
    
    @State private var showingPicker: Bool = false
    @State private var searchText: String = ""
    @State private var showingNewPerson: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !label.isEmpty {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Button {
                showingPicker = true
            } label: {
                HStack {
                    if let person = selection {
                        PersonChip(person: person, showRemove: true) {
                            selection = nil
                        }
                    } else {
                        Text(placeholder)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showingPicker) {
            PersonPickerSheet(
                selection: $selection,
                mode: .single,
                allowCreate: allowCreate
            )
        }
    }
}

// MARK: - Multi Person Picker

/// A picker component for selecting multiple people
struct MultiPersonPicker: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.name) private var allPeople: [Person]
    
    @Binding var selection: [Person]
    var label: String = "Participants"
    var allowCreate: Bool = true
    var placeholder: String = "Add participants"
    
    @State private var showingPicker: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !label.isEmpty {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Button {
                showingPicker = true
            } label: {
                HStack {
                    if selection.isEmpty {
                        Text(placeholder)
                            .foregroundStyle(.secondary)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selection) { person in
                                    PersonChip(person: person, showRemove: true) {
                                        selection.removeAll { $0.id == person.id }
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer(minLength: 8)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showingPicker) {
            PersonPickerSheet(
                multiSelection: $selection,
                mode: .multiple,
                allowCreate: allowCreate
            )
        }
    }
}

// MARK: - Person Chip

/// A small chip showing a person's name with optional remove button
struct PersonChip: View {
    let person: Person
    var showRemove: Bool = false
    var onRemove: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "person.fill")
                .font(.caption2)
            
            Text(person.name)
                .font(.subheadline)
                .lineLimit(1)
            
            if showRemove, let onRemove = onRemove {
                Button {
                    onRemove()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.15), in: Capsule())
        .foregroundStyle(.blue)
    }
}

// MARK: - Person Picker Sheet

/// The sheet view for selecting people
struct PersonPickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Person.name) private var allPeople: [Person]
    
    // Single selection binding
    @Binding var selection: Person?
    
    // Multi selection binding
    @Binding var multiSelection: [Person]
    
    let mode: PersonPickerMode
    let allowCreate: Bool
    
    @State private var searchText: String = ""
    @State private var showingNewPerson: Bool = false
    
    // Convenience initializer for single selection
    init(selection: Binding<Person?>, mode: PersonPickerMode = .single, allowCreate: Bool = true) {
        self._selection = selection
        self._multiSelection = .constant([])
        self.mode = mode
        self.allowCreate = allowCreate
    }
    
    // Convenience initializer for multi selection
    init(multiSelection: Binding<[Person]>, mode: PersonPickerMode = .multiple, allowCreate: Bool = true) {
        self._selection = .constant(nil)
        self._multiSelection = multiSelection
        self.mode = mode
        self.allowCreate = allowCreate
    }
    
    private var filteredPeople: [Person] {
        if searchText.isEmpty {
            return allPeople
        }
        return allPeople.filter { person in
            person.name.localizedCaseInsensitiveContains(searchText) ||
            (person.organization?.localizedCaseInsensitiveContains(searchText) ?? false) ||
            (person.role?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }
    
    private var canQuickCreate: Bool {
        allowCreate && !searchText.isEmpty && !filteredPeople.contains { $0.name.lowercased() == searchText.lowercased() }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    
                    TextField("Search or create...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(.bar)
                
                Divider()
                
                // Quick create option
                if canQuickCreate {
                    Button {
                        quickCreatePerson()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.green)
                            
                            Text("Create \"\(searchText)\"")
                                .font(.subheadline)
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                }
                
                // People list
                if filteredPeople.isEmpty && !canQuickCreate {
                    ContentUnavailableView {
                        Label("No People", systemImage: "person.crop.circle.badge.questionmark")
                    } description: {
                        Text(allPeople.isEmpty ? "Add your first person to get started." : "No results for \"\(searchText)\"")
                    } actions: {
                        if allowCreate {
                            Button("Add Person") {
                                showingNewPerson = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    List {
                        ForEach(filteredPeople) { person in
                            PersonPickerRow(
                                person: person,
                                isSelected: isSelected(person),
                                onSelect: { selectPerson(person) }
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(mode == .single ? "Select Person" : "Select Participants")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if mode == .multiple {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                
                if allowCreate {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingNewPerson = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingNewPerson) {
                QuickNewPersonView { newPerson in
                    selectPerson(newPerson)
                }
            }
        }
    }
    
    private func isSelected(_ person: Person) -> Bool {
        switch mode {
        case .single:
            return selection?.id == person.id
        case .multiple:
            return multiSelection.contains { $0.id == person.id }
        }
    }
    
    private func selectPerson(_ person: Person) {
        switch mode {
        case .single:
            selection = person
            dismiss()
        case .multiple:
            if let index = multiSelection.firstIndex(where: { $0.id == person.id }) {
                multiSelection.remove(at: index)
            } else {
                multiSelection.append(person)
            }
        }
    }
    
    private func quickCreatePerson() {
        let trimmedName = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let newPerson = Person(name: trimmedName)
        modelContext.insert(newPerson)
        try? modelContext.save()
        
        selectPerson(newPerson)
        searchText = ""
    }
}

// MARK: - Person Picker Row

struct PersonPickerRow: View {
    let person: Person
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .font(.title3)
                
                // Person info
                VStack(alignment: .leading, spacing: 2) {
                    Text(person.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    if person.role != nil || person.organization != nil || person.relationshipType != nil {
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
                            
                            if let type = person.relationshipType {
                                if person.role != nil || person.organization != nil {
                                    Text("•")
                                }
                                Text(type.displayName)
                                    .foregroundStyle(relationshipColor(type))
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                // Commitment count badge
                if person.activeCommitmentCount > 0 {
                    Text("\(person.activeCommitmentCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2), in: Capsule())
                        .foregroundStyle(.orange)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    private func relationshipColor(_ type: RelationshipType) -> Color {
        switch type.groupName {
        case "Internal": return .blue
        case "Investment & Advisory": return .purple
        case "External": return .green
        default: return .gray
        }
    }
}

// MARK: - Quick New Person View

/// A minimal form for quickly creating a new person
struct QuickNewPersonView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var onCreate: ((Person) -> Void)? = nil
    
    @State private var name: String = ""
    @State private var organization: String = ""
    @State private var role: String = ""
    @State private var relationshipType: RelationshipType? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Organization (optional)", text: $organization)
                    TextField("Role (optional)", text: $role)
                }
                
                Section("Relationship Type") {
                    ForEach(RelationshipType.grouped, id: \.0) { groupName, types in
                        DisclosureGroup(groupName) {
                            ForEach(types, id: \.self) { type in
                                Button {
                                    relationshipType = type
                                } label: {
                                    HStack {
                                        Image(systemName: type.icon)
                                            .foregroundStyle(.secondary)
                                            .frame(width: 24)
                                        
                                        Text(type.displayName)
                                            .foregroundStyle(.primary)
                                        
                                        Spacer()
                                        
                                        if relationshipType == type {
                                            Image(systemName: "checkmark")
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Person")
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
                    Button("Add") {
                        createPerson()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func createPerson() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let person = Person(
            name: trimmedName,
            organization: organization.isEmpty ? nil : organization,
            role: role.isEmpty ? nil : role,
            relationshipType: relationshipType
        )
        
        modelContext.insert(person)
        try? modelContext.save()
        
        onCreate?(person)
        dismiss()
    }
}

// MARK: - Previews

#Preview("Person Picker") {
    struct PreviewWrapper: View {
        @State private var selectedPerson: Person? = nil
        
        var body: some View {
            VStack {
                PersonPicker(
                    selection: $selectedPerson,
                    label: "Who is this for?",
                    placeholder: "Select a person"
                )
                .padding()
            }
        }
    }
    
    return PreviewWrapper()
        .modelContainer(for: [Person.self, Commitment.self, Entry.self], inMemory: true)
}

#Preview("Multi Person Picker") {
    struct PreviewWrapper: View {
        @State private var selectedPeople: [Person] = []
        
        var body: some View {
            VStack {
                MultiPersonPicker(
                    selection: $selectedPeople,
                    label: "Participants",
                    placeholder: "Add participants"
                )
                .padding()
            }
        }
    }
    
    return PreviewWrapper()
        .modelContainer(for: [Person.self, Commitment.self, Entry.self], inMemory: true)
}


