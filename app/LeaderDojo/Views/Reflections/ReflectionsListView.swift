import SwiftUI
import SwiftData

// MARK: - View Mode
enum ReflectionsViewMode: String, CaseIterable {
    case grid = "Grid"
    case list = "List"
    
    var icon: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        }
    }
}

struct ReflectionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Reflection.createdAt, order: .reverse) private var reflections: [Reflection]
    
    @State private var showingNewReflection: Bool = false
    @State private var selectedPeriodType: ReflectionPeriodType = .week
    @State private var selectedReflection: Reflection? = nil
    @State private var filterPeriodType: ReflectionPeriodType? = nil
    @State private var viewMode: ReflectionsViewMode = .grid
    @State private var searchText: String = ""
    
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
        NavigationStack {
            reflectionsContent
        }
    }
    
    private var reflectionsContent: some View {
        Group {
            if reflections.isEmpty {
                emptyState
            } else {
                reflectionsList
            }
        }
        .navigationTitle("Reflections")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                addReflectionMenu
            }
        }
        .sheet(isPresented: $showingNewReflection) {
            NewReflectionView(periodType: selectedPeriodType)
        }
    }
    
    private var reflectionsList: some View {
        List {
            ForEach(groupedReflections, id: \.0) { month, items in
                Section(month) {
                    ForEach(items) { reflection in
                        NavigationLink {
                            ReflectionDetailView(reflection: reflection)
                        } label: {
                            ReflectionRowView(reflection: reflection)
                        }
                    }
                    .onDelete { indexSet in
                        deleteReflections(at: indexSet, from: items)
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
                iPadFilterBar
                
                // Content
                if filteredReflections.isEmpty {
                    emptyState
                } else {
                    iPadReflectionsList
                }
            }
            .navigationTitle("Reflections")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    addReflectionMenu
                }
            }
        } detail: {
            if let reflection = selectedReflection {
                ReflectionDetailView(reflection: reflection)
            } else {
                ContentUnavailableView {
                    Label("Select a Reflection", systemImage: "brain.head.profile")
                } description: {
                    Text("Choose a reflection from the list to view its details.")
                }
            }
        }
        .sheet(isPresented: $showingNewReflection) {
            NewReflectionView(periodType: selectedPeriodType)
        }
    }
    
    private var iPadFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Period type filter
                ForEach([nil] + ReflectionPeriodType.allCases.map { Optional($0) }, id: \.self) { type in
                    Button {
                        withAnimation {
                            filterPeriodType = type
                        }
                    } label: {
                        HStack(spacing: 4) {
                            if let t = type {
                                Image(systemName: t.icon)
                                    .font(.caption)
                                Text(t.displayName)
                            } else {
                                Image(systemName: "tray.full")
                                    .font(.caption)
                                Text("All")
                            }
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            filterPeriodType == type ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1),
                            in: Capsule()
                        )
                        .foregroundStyle(filterPeriodType == type ? .primary : .secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                Text("\(filteredReflections.count) reflections")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(.bar)
    }
    
    private var iPadReflectionsList: some View {
        List(selection: $selectedReflection) {
            ForEach(groupedFilteredReflections, id: \.0) { month, items in
                Section {
                    ForEach(items) { reflection in
                        iPadReflectionRow(reflection: reflection)
                            .tag(reflection)
                    }
                } header: {
                    HStack {
                        Text(month)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(items.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func iPadReflectionRow(reflection: Reflection) -> some View {
        HStack(spacing: 12) {
            // Period type icon
            ZStack {
                Circle()
                    .fill(periodColor(for: reflection.periodType).opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: reflection.periodType?.icon ?? "brain.head.profile")
                    .font(.system(size: 16))
                    .foregroundStyle(periodColor(for: reflection.periodType))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reflection.periodDisplay)
                    .font(.headline)
                
                HStack {
                    if let type = reflection.periodType {
                        Text(type.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Progress indicator
                    ProgressView(value: Double(reflection.answeredCount), total: Double(max(1, reflection.questionsAnswers.count)))
                        .progressViewStyle(.linear)
                        .frame(width: 60)
                        .tint(reflection.isComplete ? .green : .orange)
                }
            }
            
            Spacer()
            
            if reflection.isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Text("\(reflection.answeredCount)/\(reflection.questionsAnswers.count)")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
    }
    #endif
    
    // MARK: - macOS Layout
    
    #if os(macOS)
    private var macLayout: some View {
        HSplitView {
            // Left: Grid/List view
            VStack(spacing: 0) {
                macToolbar
                
                if filteredReflections.isEmpty {
                    emptyState
                } else {
                    if viewMode == .grid {
                        macGridView
                    } else {
                        macListView
                    }
                }
            }
            .frame(minWidth: 450)
            
            // Right: Detail view
            Group {
                if let reflection = selectedReflection {
                    ScrollView {
                        ReflectionDetailView(reflection: reflection)
                    }
                } else {
                    macEmptyDetailView
                }
            }
            .frame(minWidth: 400, idealWidth: 500)
        }
        .navigationTitle("Reflections")
        .sheet(isPresented: $showingNewReflection) {
            NewReflectionView(periodType: selectedPeriodType)
        }
    }
    
    private var macToolbar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search reflections...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                .frame(maxWidth: 200)
                
                // Period type filter
                Menu {
                    Button("All Types") { filterPeriodType = nil }
                    Divider()
                    ForEach(ReflectionPeriodType.allCases, id: \.self) { type in
                        Button {
                            filterPeriodType = type
                        } label: {
                            Label(type.displayName, systemImage: type.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: filterPeriodType?.icon ?? "tray.full")
                        Text(filterPeriodType?.displayName ?? "All Types")
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .font(.subheadline)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(filterPeriodType != nil ? Color.accentColor.opacity(0.15) : Color(nsColor: .controlBackgroundColor), in: Capsule())
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // View mode toggle
                Picker("View", selection: $viewMode) {
                    ForEach(ReflectionsViewMode.allCases, id: \.self) { mode in
                        Image(systemName: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 80)
                
                // Add button
                addReflectionMenu
                    .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            Divider()
            
            // Stats bar
            HStack(spacing: 16) {
                StatPill(
                    title: "Total",
                    value: "\(filteredReflections.count)",
                    icon: "doc.text",
                    color: .blue
                )
                
                StatPill(
                    title: "Complete",
                    value: "\(filteredReflections.filter { $0.isComplete }.count)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                StatPill(
                    title: "In Progress",
                    value: "\(filteredReflections.filter { !$0.isComplete }.count)",
                    icon: "circle.dashed",
                    color: .orange
                )
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            Divider()
        }
        .background(.bar)
    }
    
    private var macGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 240, maximum: 320), spacing: 16)
            ], spacing: 16) {
                ForEach(filteredReflections) { reflection in
                    ReflectionCard(
                        reflection: reflection,
                        isSelected: selectedReflection?.id == reflection.id
                    ) {
                        selectedReflection = reflection
                    }
                    .contextMenu {
                        reflectionContextMenu(for: reflection)
                    }
                }
            }
            .padding(16)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var macListView: some View {
        List(selection: $selectedReflection) {
            ForEach(groupedFilteredReflections, id: \.0) { month, items in
                Section {
                    ForEach(items) { reflection in
                        MacReflectionRow(reflection: reflection)
                            .tag(reflection)
                            .contextMenu {
                                reflectionContextMenu(for: reflection)
                            }
                    }
                } header: {
                    HStack {
                        Text(month)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Text("\(items.count)")
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
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            
            Text("Select a Reflection")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Choose a reflection to view and edit your answers.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 250)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    @ViewBuilder
    private func reflectionContextMenu(for reflection: Reflection) -> some View {
        Button(role: .destructive) {
            if selectedReflection?.id == reflection.id {
                selectedReflection = nil
            }
            modelContext.delete(reflection)
            try? modelContext.save()
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    #endif
    
    // MARK: - Shared Components
    
    private var addReflectionMenu: some View {
        Menu {
            Button {
                selectedPeriodType = .week
                showingNewReflection = true
            } label: {
                Label("Weekly Reflection", systemImage: "calendar.badge.clock")
            }
            
            Button {
                selectedPeriodType = .month
                showingNewReflection = true
            } label: {
                Label("Monthly Reflection", systemImage: "calendar")
            }
            
            Button {
                selectedPeriodType = .quarter
                showingNewReflection = true
            } label: {
                Label("Quarterly Reflection", systemImage: "calendar.badge.plus")
            }
        } label: {
            Image(systemName: "plus")
        }
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Reflections", systemImage: "brain.head.profile")
        } description: {
            Text("Start reflecting on your leadership journey.")
        } actions: {
            Button("Create Reflection") {
                selectedPeriodType = .week
                showingNewReflection = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredReflections: [Reflection] {
        var result = reflections
        
        // Filter by period type
        if let type = filterPeriodType {
            result = result.filter { $0.periodType == type }
        }
        
        // Search filter
        if !searchText.isEmpty {
            result = result.filter { reflection in
                let displayMatch = reflection.periodDisplay.localizedCaseInsensitiveContains(searchText)
                let qaMatch = reflection.questionsAnswers.contains { qa in
                    qa.question.localizedCaseInsensitiveContains(searchText) ||
                    qa.answer.localizedCaseInsensitiveContains(searchText)
                }
                return displayMatch || qaMatch
            }
        }
        
        return result
    }
    
    private var groupedReflections: [(String, [Reflection])] {
        let grouped = Dictionary(grouping: reflections) { reflection -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: reflection.createdAt)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
    
    private var groupedFilteredReflections: [(String, [Reflection])] {
        let grouped = Dictionary(grouping: filteredReflections) { reflection -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: reflection.createdAt)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
    
    private func periodColor(for type: ReflectionPeriodType?) -> Color {
        switch type {
        case .week: return .blue
        case .month: return .purple
        case .quarter: return .orange
        case .none: return .gray
        }
    }
    
    // MARK: - Actions
    
    private func deleteReflections(at offsets: IndexSet, from items: [Reflection]) {
        for index in offsets {
            modelContext.delete(items[index])
        }
        try? modelContext.save()
    }
}

// MARK: - Reflection Row View (iPhone)

struct ReflectionRowView: View {
    let reflection: Reflection
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: reflection.periodType?.icon ?? "brain.head.profile")
                .font(.title2)
                .foregroundStyle(periodColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reflection.periodDisplay)
                    .font(.headline)
                
                HStack {
                    if let type = reflection.periodType {
                        Text(type.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text("\(reflection.answeredCount)/\(reflection.questionsAnswers.count) answered")
                        .font(.caption)
                        .foregroundStyle(reflection.isComplete ? .green : .orange)
                }
            }
            
            Spacer()
            
            if reflection.isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var periodColor: Color {
        switch reflection.periodType {
        case .week: return .blue
        case .month: return .purple
        case .quarter: return .orange
        case .none: return .gray
        }
    }
}

// MARK: - Stat Pill (macOS)

#if os(macOS)
struct StatPill: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.1), in: Capsule())
    }
}
#endif

// MARK: - Reflection Card (macOS Grid)

#if os(macOS)
struct ReflectionCard: View {
    let reflection: Reflection
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Period type badge
                HStack(spacing: 4) {
                    Image(systemName: reflection.periodType?.icon ?? "brain.head.profile")
                        .font(.caption)
                    Text(reflection.periodType?.displayName ?? "General")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(periodColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(periodColor.opacity(0.15), in: Capsule())
                
                Spacer()
                
                // Status indicator
                if reflection.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    Text("\(reflection.answeredCount)/\(reflection.questionsAnswers.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                }
            }
            
            // Title
            Text(reflection.periodDisplay)
                .font(.headline)
                .lineLimit(1)
            
            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                ProgressView(value: Double(reflection.answeredCount), total: Double(max(1, reflection.questionsAnswers.count)))
                    .progressViewStyle(.linear)
                    .tint(reflection.isComplete ? .green : .orange)
                
                Text("\(reflection.answeredCount) of \(reflection.questionsAnswers.count) questions answered")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            // Preview of first unanswered question
            if let unanswered = reflection.questionsAnswers.first(where: { $0.answer.isEmpty }) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Question")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text(unanswered.question)
                        .font(.caption)
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                }
            } else if let lastAnswer = reflection.questionsAnswers.last {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Latest Answer")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text(lastAnswer.answer)
                        .font(.caption)
                        .lineLimit(2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 0)
            
            // Date
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(reflection.createdAt, style: .date)
                    .font(.caption2)
            }
            .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 200)
        .background(
            isSelected ? Color.accentColor.opacity(0.1) : Color(nsColor: .controlBackgroundColor),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .onTapGesture(perform: onTap)
    }
    
    private var periodColor: Color {
        switch reflection.periodType {
        case .week: return .blue
        case .month: return .purple
        case .quarter: return .orange
        case .none: return .gray
        }
    }
}
#endif

// MARK: - Mac Reflection Row

#if os(macOS)
struct MacReflectionRow: View {
    let reflection: Reflection
    
    var body: some View {
        HStack(spacing: 12) {
            // Period type icon
            ZStack {
                Circle()
                    .fill(periodColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: reflection.periodType?.icon ?? "brain.head.profile")
                    .font(.system(size: 16))
                    .foregroundStyle(periodColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(reflection.periodDisplay)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if reflection.isComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                
                HStack(spacing: 8) {
                    // Type badge
                    if let type = reflection.periodType {
                        Text(type.displayName)
                            .font(.caption)
                            .foregroundStyle(periodColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(periodColor.opacity(0.1), in: Capsule())
                    }
                    
                    // Progress
                    HStack(spacing: 4) {
                        ProgressView(value: Double(reflection.answeredCount), total: Double(max(1, reflection.questionsAnswers.count)))
                            .progressViewStyle(.linear)
                            .frame(width: 50)
                            .tint(reflection.isComplete ? .green : .orange)
                        
                        Text("\(reflection.answeredCount)/\(reflection.questionsAnswers.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Date
            Text(reflection.createdAt, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
    
    private var periodColor: Color {
        switch reflection.periodType {
        case .week: return .blue
        case .month: return .purple
        case .quarter: return .orange
        case .none: return .gray
        }
    }
}
#endif

#Preview {
    ReflectionsListView()
        .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self], inMemory: true)
}
