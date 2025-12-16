import SwiftUI
import SwiftData

struct PeopleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Person.name) private var allPeople: [Person]
    
    @State private var searchText: String = ""
    @State private var selectedRelationshipGroup: String? = nil
    @State private var selectedHealthFilter: RelationshipHealthStatus? = nil
    @State private var showingNewPerson: Bool = false
    @State private var selectedPerson: Person? = nil
    @State private var sortOrder: SortOrder = .name
    
    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case organization = "Organization"
        case recentActivity = "Recent Activity"
        case commitments = "Commitments"
        case health = "Health"
        
        var icon: String {
            switch self {
            case .name: return "textformat"
            case .organization: return "building.2"
            case .recentActivity: return "clock"
            case .commitments: return "checkmark.circle"
            case .health: return "heart.fill"
            }
        }
    }
    
    var body: some View {
        #if os(iOS)
        if UIDevice.current.userInterfaceIdiom == .pad {
            iPadLayout
        } else {
            iPhoneLayout
        }
        #else
        macLayout
        #endif
    }
    
    // MARK: - iPhone Layout
    
    #if os(iOS)
    private var iPhoneLayout: some View {
        Group {
            if filteredPeople.isEmpty {
                emptyState
            } else {
                peopleList
            }
        }
        .navigationTitle("People")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search people")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewPerson = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .secondaryAction) {
                filterMenu
            }
        }
        .sheet(isPresented: $showingNewPerson) {
            NewPersonView()
        }
    }
    
    private var peopleList: some View {
        List {
            ForEach(groupedPeople, id: \.0) { group, people in
                Section(group) {
                    ForEach(people) { person in
                        NavigationLink {
                            PersonDetailView(person: person)
                        } label: {
                            PersonRowView(person: person)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deletePerson(person)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    #endif
    
    // MARK: - iPad Layout
    
    #if os(iOS)
    private var iPadLayout: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                // Filter bar
                filterBar
                
                // List
                if filteredPeople.isEmpty {
                    emptyState
                } else {
                    List(selection: $selectedPerson) {
                        ForEach(groupedPeople, id: \.0) { group, people in
                            Section {
                                ForEach(people) { person in
                                    PersonRowView(person: person)
                                        .tag(person)
                                }
                            } header: {
                                HStack {
                                    Text(group)
                                    Spacer()
                                    Text("\(people.count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("People")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewPerson = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        } detail: {
            if let person = selectedPerson {
                PersonDetailView(person: person)
            } else {
                ContentUnavailableView {
                    Label("Select a Person", systemImage: "person.crop.circle")
                } description: {
                    Text("Choose someone from the list to view their details.")
                }
            }
        }
        .sheet(isPresented: $showingNewPerson) {
            NewPersonView()
        }
    }
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Relationship group filters
                Button {
                    withAnimation { selectedRelationshipGroup = nil }
                } label: {
                    FilterChipView(
                        title: "All",
                        isActive: selectedRelationshipGroup == nil
                    )
                }
                .buttonStyle(.plain)
                
                ForEach(RelationshipType.grouped, id: \.0) { groupName, _ in
                    Button {
                        withAnimation {
                            selectedRelationshipGroup = selectedRelationshipGroup == groupName ? nil : groupName
                        }
                    } label: {
                        FilterChipView(
                            title: groupName,
                            isActive: selectedRelationshipGroup == groupName
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Text("\(filteredPeople.count) people")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.trailing, 8)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(.bar)
    }
    #endif
    
    // MARK: - macOS Layout
    
    #if os(macOS)
    private var macLayout: some View {
        HSplitView {
            // Left: List
            VStack(spacing: 0) {
                macToolbar
                
                if filteredPeople.isEmpty {
                    emptyState
                } else {
                    macPeopleList
                }
            }
            .frame(minWidth: 350)
            
            // Right: Detail
            Group {
                if let person = selectedPerson {
                    ScrollView {
                        PersonDetailView(person: person)
                    }
                } else {
                    macEmptyDetailView
                }
            }
            .frame(minWidth: 400, idealWidth: 500)
        }
        .navigationTitle("People")
        .sheet(isPresented: $showingNewPerson) {
            NewPersonView()
        }
    }
    
    private var macToolbar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search people...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                .frame(maxWidth: 200)
                
                // Relationship group filter
                Menu {
                    Button("All Groups") { selectedRelationshipGroup = nil }
                    Divider()
                    ForEach(RelationshipType.grouped, id: \.0) { groupName, _ in
                        Button(groupName) { selectedRelationshipGroup = groupName }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "person.2")
                        Text(selectedRelationshipGroup ?? "All Groups")
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        selectedRelationshipGroup != nil
                            ? Color.accentColor.opacity(0.15)
                            : Color(nsColor: .controlBackgroundColor),
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)
                
                // Sort order
                Menu {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button {
                            sortOrder = order
                        } label: {
                            if sortOrder == order {
                                Label(order.rawValue, systemImage: "checkmark")
                            } else {
                                Text(order.rawValue)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                        Text(sortOrder.rawValue)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(nsColor: .controlBackgroundColor), in: Capsule())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Add button
                Button {
                    showingNewPerson = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut("n", modifiers: .command)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // Stats bar
            HStack(spacing: 16) {
                Text("\(filteredPeople.count) people")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // Quick stats
                HStack(spacing: 12) {
                    Label("\(totalCommitments) commitments", systemImage: "checkmark.circle")
                    Label("\(totalOverdue) overdue", systemImage: "exclamationmark.circle")
                        .foregroundStyle(totalOverdue > 0 ? .red : .secondary)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            Divider()
        }
        .background(.bar)
    }
    
    private var macPeopleList: some View {
        List(selection: $selectedPerson) {
            ForEach(groupedPeople, id: \.0) { group, people in
                Section {
                    ForEach(people) { person in
                        MacPersonRow(person: person)
                            .tag(person)
                            .contextMenu {
                                Button(role: .destructive) {
                                    deletePerson(person)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                } header: {
                    HStack {
                        Text(group)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(people.count)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.secondary.opacity(0.2), in: Capsule())
                    }
                }
            }
        }
        .listStyle(.inset)
    }
    
    private var macEmptyDetailView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("Select a Person")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Choose someone from the list to view their details and interactions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    #endif
    
    // MARK: - Shared Components
    
    private var filterMenu: some View {
        Menu {
            Section("Sort by") {
                ForEach(SortOrder.allCases, id: \.self) { order in
                    Button {
                        sortOrder = order
                    } label: {
                        if sortOrder == order {
                            Label(order.rawValue, systemImage: "checkmark")
                        } else {
                            Text(order.rawValue)
                        }
                    }
                }
            }
            
            Section("Relationship") {
                Button {
                    selectedRelationshipGroup = nil
                } label: {
                    if selectedRelationshipGroup == nil {
                        Label("All", systemImage: "checkmark")
                    } else {
                        Text("All")
                    }
                }
                
                ForEach(RelationshipType.grouped, id: \.0) { groupName, _ in
                    Button {
                        selectedRelationshipGroup = groupName
                    } label: {
                        if selectedRelationshipGroup == groupName {
                            Label(groupName, systemImage: "checkmark")
                        } else {
                            Text(groupName)
                        }
                    }
                }
            }
            
            Section("Health Status") {
                Button {
                    selectedHealthFilter = nil
                } label: {
                    if selectedHealthFilter == nil {
                        Label("All", systemImage: "checkmark")
                    } else {
                        Text("All")
                    }
                }
                
                ForEach(RelationshipHealthStatus.allCases, id: \.self) { status in
                    Button {
                        selectedHealthFilter = status
                    } label: {
                        if selectedHealthFilter == status {
                            Label(status.displayName, systemImage: "checkmark")
                        } else {
                            Label(status.displayName, systemImage: status.icon)
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No People", systemImage: "person.crop.circle.badge.plus")
        } description: {
            Text(searchText.isEmpty
                 ? "Add people to track your commitments and interactions."
                 : "No results for \"\(searchText)\"")
        } actions: {
            if searchText.isEmpty {
                Button("Add Person") {
                    showingNewPerson = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredPeople: [Person] {
        var result = allPeople
        
        // Search filter
        if !searchText.isEmpty {
            result = result.filter { person in
                person.name.localizedCaseInsensitiveContains(searchText) ||
                (person.organization?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (person.role?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Relationship group filter
        if let group = selectedRelationshipGroup {
            result = result.filter { person in
                person.relationshipType?.groupName == group
            }
        }
        
        // Health filter
        if let healthFilter = selectedHealthFilter {
            result = result.filter { $0.healthStatus == healthFilter }
        }
        
        // Apply sort
        switch sortOrder {
        case .name:
            result.sort { $0.name < $1.name }
        case .organization:
            result.sort { ($0.organization ?? "") < ($1.organization ?? "") }
        case .recentActivity:
            result.sort { ($0.lastInteractionDate ?? .distantPast) > ($1.lastInteractionDate ?? .distantPast) }
        case .commitments:
            result.sort { $0.activeCommitmentCount > $1.activeCommitmentCount }
        case .health:
            result.sort { $0.relationshipHealthScore < $1.relationshipHealthScore }
        }
        
        return result
    }
    
    private var groupedPeople: [(String, [Person])] {
        let grouped = Dictionary(grouping: filteredPeople) { person -> String in
            switch sortOrder {
            case .name:
                let firstChar = person.name.prefix(1).uppercased()
                return firstChar.isEmpty ? "#" : firstChar
            case .organization:
                return person.organization ?? "No Organization"
            case .recentActivity:
                guard let date = person.lastInteractionDate else { return "No Activity" }
                if Calendar.current.isDateInToday(date) { return "Today" }
                if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
                if let days = person.daysSinceLastInteraction, days <= 7 { return "This Week" }
                return "Earlier"
            case .commitments:
                let count = person.activeCommitmentCount
                if count == 0 { return "No Commitments" }
                if count <= 2 { return "1-2 Commitments" }
                if count <= 5 { return "3-5 Commitments" }
                return "5+ Commitments"
            case .health:
                return person.healthStatus.displayName
            }
        }
        
        let sortedKeys: [String]
        switch sortOrder {
        case .name:
            sortedKeys = grouped.keys.sorted()
        case .organization:
            sortedKeys = grouped.keys.sorted { a, b in
                if a == "No Organization" { return false }
                if b == "No Organization" { return true }
                return a < b
            }
        case .recentActivity:
            let order = ["Today", "Yesterday", "This Week", "Earlier", "No Activity"]
            sortedKeys = grouped.keys.sorted { order.firstIndex(of: $0) ?? 99 < order.firstIndex(of: $1) ?? 99 }
        case .commitments:
            let order = ["5+ Commitments", "3-5 Commitments", "1-2 Commitments", "No Commitments"]
            sortedKeys = grouped.keys.sorted { order.firstIndex(of: $0) ?? 99 < order.firstIndex(of: $1) ?? 99 }
        case .health:
            let order = [RelationshipHealthStatus.atRisk.displayName, RelationshipHealthStatus.needsAttention.displayName, RelationshipHealthStatus.healthy.displayName]
            sortedKeys = grouped.keys.sorted { order.firstIndex(of: $0) ?? 99 < order.firstIndex(of: $1) ?? 99 }
        }
        
        return sortedKeys.compactMap { key in
            guard let items = grouped[key] else { return nil }
            return (key, items)
        }
    }
    
    private var totalCommitments: Int {
        filteredPeople.reduce(0) { $0 + $1.activeCommitmentCount }
    }
    
    private var totalOverdue: Int {
        filteredPeople.filter { $0.hasOverdueCommitments }.count
    }
    
    // MARK: - Actions
    
    private func deletePerson(_ person: Person) {
        if selectedPerson?.id == person.id {
            selectedPerson = nil
        }
        modelContext.delete(person)
        try? modelContext.save()
    }
}

// MARK: - Person Row View (iPhone)

struct PersonRowView: View {
    let person: Person
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar with health indicator
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(avatarColor.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Text(initials)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(avatarColor)
                }
                
                // Health status indicator
                Circle()
                    .fill(healthColor)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(person.name)
                    .font(.body)
                    .fontWeight(.medium)
                
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
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // Last interaction
            if let lastText = person.lastInteractionDisplayText {
                Text(lastText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            // Commitment badge
            if person.activeCommitmentCount > 0 {
                HStack(spacing: 4) {
                    if person.hasOverdueCommitments {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                    
                    Text("\(person.activeCommitmentCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(person.hasOverdueCommitments ? Color.red.opacity(0.15) : Color.orange.opacity(0.15), in: Capsule())
                .foregroundStyle(person.hasOverdueCommitments ? .red : .orange)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var healthColor: Color {
        switch person.healthStatus {
        case .healthy: return .green
        case .needsAttention: return .yellow
        case .atRisk: return .red
        }
    }
    
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
}

// MARK: - Mac Person Row

#if os(macOS)
struct MacPersonRow: View {
    let person: Person
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar with health indicator
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(avatarColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Text(initials)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(avatarColor)
                }
                
                // Health status indicator
                Circle()
                    .fill(healthColor)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(Color(nsColor: .windowBackgroundColor), lineWidth: 1.5)
                    )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(person.name)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if let type = person.relationshipType {
                        Text(type.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(avatarColor.opacity(0.15), in: Capsule())
                            .foregroundStyle(avatarColor)
                    }
                }
                
                HStack(spacing: 4) {
                    if person.role != nil || person.organization != nil {
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
                    
                    if let lastText = person.lastInteractionDisplayText {
                        if person.role != nil || person.organization != nil {
                            Text("•")
                        }
                        Text(lastText)
                            .foregroundStyle(person.healthStatus == .atRisk ? .orange : .secondary)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Stats
            HStack(spacing: 8) {
                if person.iOweCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.right")
                            .font(.caption2)
                        Text("\(person.iOweCount)")
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                }
                
                if person.waitingForCount > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.down.left")
                            .font(.caption2)
                        Text("\(person.waitingForCount)")
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
                
                if person.hasOverdueCommitments {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
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
    
    private var healthColor: Color {
        switch person.healthStatus {
        case .healthy: return .green
        case .needsAttention: return .yellow
        case .atRisk: return .red
        }
    }
}
#endif

// MARK: - Filter Chip View

struct FilterChipView: View {
    let title: String
    let isActive: Bool
    
    var body: some View {
        Text(title)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isActive ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1), in: Capsule())
            .foregroundStyle(isActive ? .primary : .secondary)
    }
}

#Preview {
    NavigationStack {
        PeopleListView()
    }
    .modelContainer(for: [Person.self, Commitment.self, Entry.self], inMemory: true)
}



