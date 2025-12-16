import SwiftUI
import SwiftData

/// A dedicated view showing all entries involving a specific person across all projects
struct PersonEntriesView: View {
    let person: Person
    
    @State private var selectedKindFilter: EntryKind? = nil
    @State private var selectedProjectFilter: Project? = nil
    
    private var allEntries: [Entry] {
        person.entries ?? []
    }
    
    private var filteredEntries: [Entry] {
        var entries = allEntries.filter { $0.deletedAt == nil }
        
        if let kindFilter = selectedKindFilter {
            entries = entries.filter { $0.kind == kindFilter }
        }
        
        if let projectFilter = selectedProjectFilter {
            entries = entries.filter { $0.project?.id == projectFilter.id }
        }
        
        return entries.sorted { $0.occurredAt > $1.occurredAt }
    }
    
    /// All unique projects from entries
    private var entryProjects: [Project] {
        let projects = Set(allEntries.compactMap { $0.project })
        return Array(projects).sorted { $0.name < $1.name }
    }
    
    /// Group entries by project
    private var entriesByProject: [(Project?, [Entry])] {
        let grouped = Dictionary(grouping: filteredEntries) { $0.project }
        return grouped.sorted { ($0.key?.name ?? "") < ($1.key?.name ?? "") }
    }
    
    var body: some View {
        Group {
            if filteredEntries.isEmpty {
                emptyState
            } else {
                entriesList
            }
        }
        .navigationTitle("Entries with \(person.name)")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                filterMenu
            }
        }
    }
    
    // MARK: - Entries List
    
    private var entriesList: some View {
        List {
            ForEach(entriesByProject, id: \.0?.id) { project, entries in
                Section {
                    ForEach(entries) { entry in
                        #if os(macOS)
                        NavigationLink(value: AppRoute.entry(entry.persistentModelID)) {
                            PersonEntriesRowView(entry: entry, showProject: selectedProjectFilter == nil)
                        }
                        #else
                        NavigationLink {
                            EntryDetailView(entry: entry)
                        } label: {
                            PersonEntriesRowView(entry: entry, showProject: selectedProjectFilter == nil)
                        }
                        #endif
                    }
                } header: {
                    if selectedProjectFilter == nil, let project = project {
                        HStack {
                            Image(systemName: project.type.icon)
                                .foregroundStyle(.secondary)
                            Text(project.name)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Entries", systemImage: "doc.text")
        } description: {
            if selectedKindFilter != nil || selectedProjectFilter != nil {
                Text("No entries match the current filters.")
            } else {
                Text("No entries involving \(person.name) yet.")
            }
        } actions: {
            if selectedKindFilter != nil || selectedProjectFilter != nil {
                Button("Clear Filters") {
                    selectedKindFilter = nil
                    selectedProjectFilter = nil
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    // MARK: - Filter Menu
    
    private var filterMenu: some View {
        Menu {
            // Entry Kind Filter
            Menu("Entry Type") {
                Button {
                    selectedKindFilter = nil
                } label: {
                    HStack {
                        Text("All Types")
                        if selectedKindFilter == nil {
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Divider()
                
                ForEach(EntryKind.activeCases, id: \.self) { kind in
                    Button {
                        selectedKindFilter = kind
                    } label: {
                        HStack {
                            Label(kind.displayName, systemImage: kind.icon)
                            if selectedKindFilter == kind {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            
            // Project Filter
            if entryProjects.count > 1 {
                Menu("Project") {
                    Button {
                        selectedProjectFilter = nil
                    } label: {
                        HStack {
                            Text("All Projects")
                            if selectedProjectFilter == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Divider()
                    
                    ForEach(entryProjects) { project in
                        Button {
                            selectedProjectFilter = project
                        } label: {
                            HStack {
                                Label(project.name, systemImage: project.type.icon)
                                if selectedProjectFilter?.id == project.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            }
            
            // Clear all filters
            if selectedKindFilter != nil || selectedProjectFilter != nil {
                Divider()
                
                Button(role: .destructive) {
                    selectedKindFilter = nil
                    selectedProjectFilter = nil
                } label: {
                    Label("Clear Filters", systemImage: "xmark.circle")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                if selectedKindFilter != nil || selectedProjectFilter != nil {
                    Text("Filtered")
                        .font(.caption)
                }
            }
        }
    }
}

// MARK: - Entry Row View

struct PersonEntriesRowView: View {
    let entry: Entry
    var showProject: Bool = true
    
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
    
    var body: some View {
        HStack(spacing: 12) {
            // Kind icon
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: entry.kind.icon)
                    .font(.title3)
                    .foregroundStyle(kindColor)
                    .frame(width: 32)
                
                if entry.isDecisionEntry && entry.kind != .decision {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.purple)
                        .offset(x: 4, y: 4)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Text(entry.kind.displayName)
                        .font(.caption)
                        .foregroundStyle(kindColor)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(entry.occurredAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if showProject, let project = entry.project {
                        Text("•")
                            .foregroundStyle(.secondary)
                        
                        Text(project.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let person = Person(name: "Sarah Chen", organization: "Acme Corp", role: "CEO")
    
    return NavigationStack {
        PersonEntriesView(person: person)
    }
    .modelContainer(for: [Person.self, Entry.self, Project.self], inMemory: true)
}

