import SwiftUI
import SwiftData

struct EditPersonView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var person: Person
    
    @State private var showingDeleteAlert: Bool = false
    
    var body: some View {
        #if os(iOS)
        NavigationStack {
            iOSLayout
        }
        #else
        macOSLayout
        #endif
    }
    
    // MARK: - iOS Layout
    
    #if os(iOS)
    private var iOSLayout: some View {
        Form {
            Section {
                TextField("Name", text: $person.name)
                    .textContentType(.name)
                
                TextField("Organization", text: Binding(
                    get: { person.organization ?? "" },
                    set: { person.organization = $0.isEmpty ? nil : $0 }
                ))
                .textContentType(.organizationName)
                
                TextField("Role", text: Binding(
                    get: { person.role ?? "" },
                    set: { person.role = $0.isEmpty ? nil : $0 }
                ))
                .textContentType(.jobTitle)
            }
            
            Section("Relationship Type") {
                relationshipTypePicker
            }
            
            Section("Notes") {
                TextEditor(text: Binding(
                    get: { person.notes ?? "" },
                    set: { person.notes = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 80)
            }
            
            Section {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Person")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Edit Person")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    savePerson()
                }
                .disabled(person.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .alert("Delete Person", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePerson()
            }
        } message: {
            Text("Are you sure you want to delete \(person.name)? This will remove them from all commitments and entries.")
        }
    }
    #endif
    
    // MARK: - macOS Layout
    
    #if os(macOS)
    private var macOSLayout: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Edit Person")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(person.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Button("Save Changes") {
                        savePerson()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(person.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            
            Divider()
            
            ScrollView {
                HStack(alignment: .top, spacing: 24) {
                    // Left Column - Basic Info
                    VStack(spacing: 20) {
                        MacFormCard(title: "Basic Information", icon: "person.fill", iconColor: .blue) {
                            VStack(alignment: .leading, spacing: 14) {
                                VStack(alignment: .leading, spacing: 6) {
                                    MacFormField(label: "Name *")
                                    TextField("Full name", text: $person.name)
                                        .textFieldStyle(.plain)
                                        .font(.body)
                                        .padding(10)
                                        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    MacFormField(label: "Organization")
                                    TextField("Company or organization", text: Binding(
                                        get: { person.organization ?? "" },
                                        set: { person.organization = $0.isEmpty ? nil : $0 }
                                    ))
                                    .textFieldStyle(.plain)
                                    .font(.body)
                                    .padding(10)
                                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    MacFormField(label: "Role")
                                    TextField("Job title or role", text: Binding(
                                        get: { person.role ?? "" },
                                        set: { person.role = $0.isEmpty ? nil : $0 }
                                    ))
                                    .textFieldStyle(.plain)
                                    .font(.body)
                                    .padding(10)
                                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        
                        MacFormCard(title: "Notes", icon: "note.text", iconColor: .secondary) {
                            MacTextEditor(
                                text: Binding(
                                    get: { person.notes ?? "" },
                                    set: { person.notes = $0.isEmpty ? nil : $0 }
                                ),
                                placeholder: "Add any notes about this person..."
                            )
                            .frame(minHeight: 100)
                        }
                        
                        // Stats card
                        if person.activeCommitmentCount > 0 || person.entryCount > 0 {
                            MacFormCard(title: "Activity", icon: "chart.bar.fill", iconColor: .orange) {
                                HStack(spacing: 24) {
                                    VStack {
                                        Text("\(person.iOweCount)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.orange)
                                        Text("I Owe")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    VStack {
                                        Text("\(person.waitingForCount)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.blue)
                                        Text("Waiting")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    VStack {
                                        Text("\(person.entryCount)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundStyle(.purple)
                                        Text("Entries")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .frame(minWidth: 350, maxWidth: .infinity)
                    
                    // Right Column - Relationship Type
                    VStack(spacing: 20) {
                        MacFormCard(title: "Relationship", icon: "person.2.fill", iconColor: .purple) {
                            macOSRelationshipTypePicker
                        }
                    }
                    .frame(width: 280)
                }
                .padding(24)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("Delete Person", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePerson()
            }
        } message: {
            Text("Are you sure you want to delete \(person.name)? This will remove them from all commitments and entries.")
        }
    }
    
    private var macOSRelationshipTypePicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(RelationshipType.grouped, id: \.0) { groupName, types in
                VStack(alignment: .leading, spacing: 6) {
                    Text(groupName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    ForEach(types, id: \.self) { type in
                        Button {
                            if person.relationshipType == type {
                                person.relationshipType = nil
                            } else {
                                person.relationshipType = type
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: type.icon)
                                    .font(.caption)
                                    .foregroundStyle(person.relationshipType == type ? .white : .secondary)
                                    .frame(width: 20)
                                
                                Text(type.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(person.relationshipType == type ? .white : .primary)
                                
                                Spacer()
                                
                                if person.relationshipType == type {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                person.relationshipType == type
                                    ? Color.accentColor
                                    : Color(nsColor: .controlBackgroundColor),
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }
    #endif
    
    // MARK: - Shared Components
    
    private var relationshipTypePicker: some View {
        ForEach(RelationshipType.grouped, id: \.0) { groupName, types in
            Section(groupName) {
                ForEach(types, id: \.self) { type in
                    Button {
                        if person.relationshipType == type {
                            person.relationshipType = nil
                        } else {
                            person.relationshipType = type
                        }
                    } label: {
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                            
                            Text(type.displayName)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if person.relationshipType == type {
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
    
    // MARK: - Actions
    
    private func savePerson() {
        person.updatedAt = Date()
        try? modelContext.save()
        dismiss()
    }
    
    private func deletePerson() {
        modelContext.delete(person)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    EditPersonView(person: Person(
        name: "Sarah Chen",
        organization: "Acme Corp",
        role: "CEO",
        relationshipType: .directReport
    ))
    .modelContainer(for: [Person.self, Commitment.self, Entry.self], inMemory: true)
}


