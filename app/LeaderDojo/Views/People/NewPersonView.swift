import SwiftUI
import SwiftData

struct NewPersonView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var organization: String = ""
    @State private var role: String = ""
    @State private var relationshipType: RelationshipType? = nil
    @State private var notes: String = ""
    
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
                TextField("Name", text: $name)
                    .textContentType(.name)
                
                TextField("Organization (optional)", text: $organization)
                    .textContentType(.organizationName)
                
                TextField("Role (optional)", text: $role)
                    .textContentType(.jobTitle)
            }
            
            Section("Relationship Type") {
                relationshipTypePicker
            }
            
            Section("Notes") {
                TextEditor(text: $notes)
                    .frame(minHeight: 80)
            }
        }
        .navigationTitle("New Person")
        .navigationBarTitleDisplayMode(.inline)
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
    #endif
    
    // MARK: - macOS Layout
    
    #if os(macOS)
    private var macOSLayout: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("New Person")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Add someone to your network")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Button("Add Person") {
                        createPerson()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
                                    TextField("Full name", text: $name)
                                        .textFieldStyle(.plain)
                                        .font(.body)
                                        .padding(10)
                                        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    MacFormField(label: "Organization")
                                    TextField("Company or organization", text: $organization)
                                        .textFieldStyle(.plain)
                                        .font(.body)
                                        .padding(10)
                                        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    MacFormField(label: "Role")
                                    TextField("Job title or role", text: $role)
                                        .textFieldStyle(.plain)
                                        .font(.body)
                                        .padding(10)
                                        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                        
                        MacFormCard(title: "Notes", icon: "note.text", iconColor: .secondary) {
                            MacTextEditor(text: $notes, placeholder: "Add any notes about this person...")
                                .frame(minHeight: 100)
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
                            if relationshipType == type {
                                relationshipType = nil
                            } else {
                                relationshipType = type
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: type.icon)
                                    .font(.caption)
                                    .foregroundStyle(relationshipType == type ? .white : .secondary)
                                    .frame(width: 20)
                                
                                Text(type.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(relationshipType == type ? .white : .primary)
                                
                                Spacer()
                                
                                if relationshipType == type {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                relationshipType == type
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
                        if relationshipType == type {
                            relationshipType = nil
                        } else {
                            relationshipType = type
                        }
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
    
    // MARK: - Actions
    
    private func createPerson() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let person = Person(
            name: trimmedName,
            organization: organization.isEmpty ? nil : organization,
            role: role.isEmpty ? nil : role,
            relationshipType: relationshipType,
            notes: notes.isEmpty ? nil : notes
        )
        
        modelContext.insert(person)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    NewPersonView()
        .modelContainer(for: [Person.self, Commitment.self, Entry.self], inMemory: true)
}











