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

/// Filter options for reflections list
enum ReflectionFilterType: String, CaseIterable {
    case all = "All"
    case quick = "Quick"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case project = "Project"
    case relationship = "Relationship"
    
    var icon: String {
        switch self {
        case .all: return "tray.full"
        case .quick: return "bolt.fill"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .quarterly: return "calendar.badge.plus"
        case .project: return "folder.fill"
        case .relationship: return "person.2.fill"
        }
    }
}

// MARK: - Weekly Rhythm Status
enum WeeklyRhythmStatus {
    case onTrack       // Already reflected this week
    case dueToday      // Today is a good day to reflect
    case overdue       // Missed this week's reflection
    case streak(Int)   // On a streak of consecutive weeks
    
    var label: String {
        switch self {
        case .onTrack: return "On Track"
        case .dueToday: return "Due Today"
        case .overdue: return "Time to Reflect"
        case .streak(let weeks): return "\(weeks) Week Streak"
        }
    }
    
    var color: Color {
        switch self {
        case .onTrack, .streak: return .green
        case .dueToday: return .orange
        case .overdue: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .onTrack: return "checkmark.circle.fill"
        case .dueToday: return "clock.fill"
        case .overdue: return "exclamationmark.triangle.fill"
        case .streak: return "flame.fill"
        }
    }
}

// MARK: - Date Group for Better Categorization
enum ReflectionDateGroup: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case lastWeek = "Last Week"
    case thisMonth = "Earlier This Month"
    case lastMonth = "Last Month"
    case older = "Older"
    
    static func group(for date: Date) -> ReflectionDateGroup {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return .today
        }
        
        if calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear) {
            return .thisWeek
        }
        
        let lastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: now)!
        if calendar.isDate(date, equalTo: lastWeek, toGranularity: .weekOfYear) {
            return .lastWeek
        }
        
        if calendar.isDate(date, equalTo: now, toGranularity: .month) {
            return .thisMonth
        }
        
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
        if calendar.isDate(date, equalTo: lastMonth, toGranularity: .month) {
            return .lastMonth
        }
        
        return .older
    }
}

struct ReflectionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Reflection.createdAt, order: .reverse) private var reflections: [Reflection]
    
    @State private var showingNewReflection: Bool = false
    @State private var selectedPeriodType: ReflectionPeriodType = .week
    @State private var selectedReflectionType: ReflectionType = .periodic
    @State private var selectedReflection: Reflection? = nil
    @State private var filterType: ReflectionFilterType = .all
    @State private var filterPeriodType: ReflectionPeriodType? = nil
    @State private var viewMode: ReflectionsViewMode = .grid
    @State private var searchText: String = ""
    @State private var showSuggestedSection: Bool = true
    
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
        reflectionsContent
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
                HStack(spacing: 12) {
                    NavigationLink {
                        ReflectionInsightsView()
                    } label: {
                        Image(systemName: "chart.bar.fill")
                    }
                    
                    addReflectionMenu
                }
            }
        }
        .sheet(isPresented: $showingNewReflection) {
            if selectedReflectionType == .quick {
                NewReflectionView(reflectionType: .quick, periodType: nil)
            } else {
                NewReflectionView(reflectionType: selectedReflectionType, periodType: selectedPeriodType)
            }
        }
    }
    
    private var reflectionsList: some View {
        List {
            // Stats Header Section
            Section {
                ReflectionStatsCard(
                    streak: weeklyStreak,
                    thisWeekCount: thisWeekReflections.count,
                    rhythmStatus: rhythmStatus,
                    topThemes: topThemes
                )
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
            
            // Suggested Reflections Section
            if showSuggestedSection && !suggestedReflections.isEmpty {
                Section {
                    ForEach(suggestedReflections, id: \.title) { suggestion in
                        SuggestedReflectionRow(suggestion: suggestion) {
                            selectedReflectionType = suggestion.type
                            if let periodType = suggestion.periodType {
                                selectedPeriodType = periodType
                            }
                            showingNewReflection = true
                        }
                    }
                } header: {
                    HStack {
                        Text("Suggested")
                        Spacer()
                        Button {
                            withAnimation {
                                showSuggestedSection = false
                            }
                        } label: {
                            Text("Hide")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            // Recent Reflections with Smart Grouping
            ForEach(smartGroupedReflections, id: \.0) { group, items in
                Section(group.rawValue) {
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
                // Stats Header
                iPadStatsHeader
                
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
                    HStack(spacing: 12) {
                        NavigationLink {
                            ReflectionInsightsView()
                        } label: {
                            Image(systemName: "chart.bar.fill")
                        }
                        
                        addReflectionMenu
                    }
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
            if selectedReflectionType == .quick {
                NewReflectionView(reflectionType: .quick, periodType: nil)
            } else {
                NewReflectionView(reflectionType: selectedReflectionType, periodType: selectedPeriodType)
            }
        }
    }
    
    private var iPadStatsHeader: some View {
        HStack(spacing: 16) {
            // Streak/Rhythm Status
            HStack(spacing: 8) {
                Image(systemName: rhythmStatus.icon)
                    .foregroundStyle(rhythmStatus.color)
                Text(rhythmStatus.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(rhythmStatus.color.opacity(0.15), in: Capsule())
            
            // This Week Count
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.caption)
                Text("\(thisWeekReflections.count) this week")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            
            Spacer()
            
            // Top Theme Preview
            if let topTheme = topThemes.first {
                HStack(spacing: 4) {
                    Image(systemName: "tag.fill")
                        .font(.caption2)
                    Text(topTheme.theme)
                        .font(.caption)
                }
                .foregroundStyle(.purple)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.purple.opacity(0.1), in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.bar)
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
        .background(Color.secondary.opacity(0.05))
    }
    
    private var iPadReflectionsList: some View {
        List(selection: $selectedReflection) {
            // Suggested Reflections
            if showSuggestedSection && !suggestedReflections.isEmpty {
                Section {
                    ForEach(suggestedReflections, id: \.title) { suggestion in
                        SuggestedReflectionRow(suggestion: suggestion) {
                            selectedReflectionType = suggestion.type
                            if let periodType = suggestion.periodType {
                                selectedPeriodType = periodType
                            }
                            showingNewReflection = true
                        }
                    }
                } header: {
                    HStack {
                        Label("Suggested", systemImage: "lightbulb.fill")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        Button {
                            withAnimation { showSuggestedSection = false }
                        } label: {
                            Text("Hide")
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Smart Grouped Reflections
            ForEach(smartGroupedReflections, id: \.0) { group, items in
                Section {
                    ForEach(items) { reflection in
                        iPadReflectionRow(reflection: reflection)
                            .tag(reflection)
                    }
                } header: {
                    HStack {
                        Text(group.rawValue)
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
                
                // Suggested Reflections Panel
                if showSuggestedSection && !suggestedReflections.isEmpty {
                    macSuggestedPanel
                }
                
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
            if selectedReflectionType == .quick {
                NewReflectionView(reflectionType: .quick, periodType: nil)
            } else {
                NewReflectionView(reflectionType: selectedReflectionType, periodType: selectedPeriodType)
            }
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
                
                // Insights link - use value-based navigation so it integrates with
                // NavigationStack(path:) and sidebar clicks can pop the view.
                NavigationLink(value: AppRoute.reflectionInsights) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                        Text("Insights")
                    }
                    .font(.subheadline)
                }
                .buttonStyle(.plain)
                
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
            
            // Enhanced Stats bar with rhythm status
            HStack(spacing: 16) {
                // Rhythm Status Badge
                HStack(spacing: 6) {
                    Image(systemName: rhythmStatus.icon)
                        .font(.caption)
                        .foregroundStyle(rhythmStatus.color)
                    
                    Text(rhythmStatus.label)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(rhythmStatus.color.opacity(0.15), in: Capsule())
                
                StatPill(
                    title: "This Week",
                    value: "\(thisWeekReflections.count)",
                    icon: "calendar",
                    color: .blue
                )
                
                StatPill(
                    title: "Complete",
                    value: "\(filteredReflections.filter { $0.isComplete }.count)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                // Top Themes
                if !topThemes.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "tag.fill")
                            .font(.caption2)
                            .foregroundStyle(.purple)
                        ForEach(topThemes.prefix(3), id: \.theme) { theme in
                            Text(theme.theme)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            Divider()
        }
        .background(.bar)
    }
    
    private var macSuggestedPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Suggested Reflections", systemImage: "lightbulb.fill")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
                
                Spacer()
                
                Button {
                    withAnimation { showSuggestedSection = false }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 12) {
                ForEach(suggestedReflections, id: \.title) { suggestion in
                    MacSuggestedCard(suggestion: suggestion) {
                        selectedReflectionType = suggestion.type
                        if let periodType = suggestion.periodType {
                            selectedPeriodType = periodType
                        }
                        showingNewReflection = true
                    }
                }
            }
        }
        .padding(16)
        .background(Color.orange.opacity(0.05))
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
            ForEach(smartGroupedReflections, id: \.0) { group, items in
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
                        Text(group.rawValue)
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
    
    /// Groups reflections by relative time periods (This Week, Last Week, etc.)
    private var smartGroupedReflections: [(ReflectionDateGroup, [Reflection])] {
        let grouped = Dictionary(grouping: filteredReflections) { reflection in
            ReflectionDateGroup.group(for: reflection.createdAt)
        }
        
        // Sort by the order defined in the enum
        let order: [ReflectionDateGroup] = [.today, .thisWeek, .lastWeek, .thisMonth, .lastMonth, .older]
        return order.compactMap { group in
            if let items = grouped[group], !items.isEmpty {
                return (group, items)
            }
            return nil
        }
    }
    
    /// Calculate weekly reflection streak
    private var weeklyStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var currentWeek = calendar.dateInterval(of: .weekOfYear, for: Date())!.start
        
        // Check each week going backwards
        while true {
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: currentWeek)!
            let hasReflection = reflections.contains { reflection in
                reflection.createdAt >= currentWeek && reflection.createdAt < weekEnd
            }
            
            if hasReflection {
                streak += 1
                currentWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeek)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    /// Reflections created this week
    private var thisWeekReflections: [Reflection] {
        let calendar = Calendar.current
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())!.start
        return reflections.filter { $0.createdAt >= weekStart }
    }
    
    /// Reflections created this month
    private var thisMonthReflections: [Reflection] {
        let calendar = Calendar.current
        let monthStart = calendar.dateInterval(of: .month, for: Date())!.start
        return reflections.filter { $0.createdAt >= monthStart }
    }
    
    /// Determine the current weekly rhythm status
    private var rhythmStatus: WeeklyRhythmStatus {
        let calendar = Calendar.current
        let today = Date()
        let dayOfWeek = calendar.component(.weekday, from: today)
        
        // Check if we have a reflection this week
        if !thisWeekReflections.isEmpty {
            if weeklyStreak > 1 {
                return .streak(weeklyStreak)
            }
            return .onTrack
        }
        
        // Friday (6) or later in the week, it's due
        if dayOfWeek >= 6 {
            return .dueToday
        }
        
        // Check if we missed last week
        let lastWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: calendar.dateInterval(of: .weekOfYear, for: today)!.start)!
        let lastWeekEnd = calendar.dateInterval(of: .weekOfYear, for: today)!.start
        let hasLastWeek = reflections.contains { $0.createdAt >= lastWeekStart && $0.createdAt < lastWeekEnd }
        
        if !hasLastWeek && dayOfWeek >= 3 { // Wednesday or later without last week's reflection
            return .overdue
        }
        
        return .dueToday
    }
    
    /// Top themes across all reflections
    private var topThemes: [(theme: String, count: Int)] {
        var themeCounts: [String: Int] = [:]
        
        for reflection in reflections {
            for tag in reflection.tags {
                themeCounts[tag, default: 0] += 1
            }
        }
        
        return themeCounts
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { ($0.key, $0.value) }
    }
    
    /// Suggested reflection prompts based on context
    private var suggestedReflections: [SuggestedReflection] {
        var suggestions: [SuggestedReflection] = []
        let calendar = Calendar.current
        let today = Date()
        
        // Weekly reflection if not done this week
        if thisWeekReflections.filter({ $0.periodType == .week }).isEmpty {
            suggestions.append(SuggestedReflection(
                type: .periodic,
                periodType: .week,
                title: "Weekly Reflection",
                reason: weeklyStreak > 0 ? "Keep your \(weeklyStreak)-week streak going!" : "End your week with clarity",
                priority: .high
            ))
        }
        
        // Monthly reflection at month end
        let dayOfMonth = calendar.component(.day, from: today)
        let daysInMonth = calendar.range(of: .day, in: .month, for: today)!.count
        if dayOfMonth >= daysInMonth - 3 {
            let hasMonthlyThisMonth = thisMonthReflections.contains { $0.periodType == .month }
            if !hasMonthlyThisMonth {
                suggestions.append(SuggestedReflection(
                    type: .periodic,
                    periodType: .month,
                    title: "Monthly Review",
                    reason: "Month ending soon - time to review",
                    priority: .medium
                ))
            }
        }
        
        // Quarterly reflection
        let currentMonth = calendar.component(.month, from: today)
        let isQuarterEnd = [3, 6, 9, 12].contains(currentMonth) && dayOfMonth >= daysInMonth - 7
        if isQuarterEnd {
            let hasQuarterlyRecent = reflections.prefix(10).contains { $0.periodType == .quarter }
            if !hasQuarterlyRecent {
                suggestions.append(SuggestedReflection(
                    type: .periodic,
                    periodType: .quarter,
                    title: "Quarterly Review",
                    reason: "Q\(currentMonth/3) ending - reflect on the quarter",
                    priority: .medium
                ))
            }
        }
        
        // Quick reflection if nothing recent
        if thisWeekReflections.isEmpty && suggestions.isEmpty {
            suggestions.append(SuggestedReflection(
                type: .quick,
                periodType: nil,
                title: "Quick Check-in",
                reason: "Capture a quick thought or learning",
                priority: .low
            ))
        }
        
        return suggestions.sorted { $0.priority.rawValue > $1.priority.rawValue }
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
            Image(systemName: reflectionIcon)
                .font(.title2)
                .foregroundStyle(reflectionColor)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(reflection.periodDisplay)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    // Reflection type badge
                    Text(reflectionTypeLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    // Mood indicator
                    if let mood = reflection.mood {
                        Text(mood.emoji)
                            .font(.caption)
                    }
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text("\(reflection.answeredCount)/\(reflection.questionsAnswers.count)")
                        .font(.caption)
                        .foregroundStyle(reflection.isComplete ? .green : .orange)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if reflection.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
                
                // Show linked entries count
                if reflection.hasLinkedEntries {
                    Text("\(reflection.linkedEntryIds.count) events")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var reflectionIcon: String {
        switch reflection.reflectionType {
        case .quick:
            return "bolt.fill"
        case .periodic:
            return reflection.periodType?.icon ?? "calendar.badge.clock"
        case .project:
            return "folder.fill"
        case .relationship:
            return "person.2.fill"
        }
    }
    
    private var reflectionColor: Color {
        switch reflection.reflectionType {
        case .quick:
            return .orange
        case .periodic:
            switch reflection.periodType {
            case .week: return .blue
            case .month: return .purple
            case .quarter: return .cyan
            case .none: return .gray
            }
        case .project:
            return .indigo
        case .relationship:
            return .pink
        }
    }
    
    private var reflectionTypeLabel: String {
        switch reflection.reflectionType {
        case .quick:
            return "Quick"
        case .periodic:
            return reflection.periodType?.displayName ?? "Periodic"
        case .project:
            return "Project"
        case .relationship:
            return "Relationship"
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

// MARK: - Suggested Reflection Model

struct SuggestedReflection {
    enum Priority: Int {
        case low = 0
        case medium = 1
        case high = 2
    }
    
    let type: ReflectionType
    let periodType: ReflectionPeriodType?
    let title: String
    let reason: String
    let priority: Priority
    
    var icon: String {
        switch type {
        case .quick: return "bolt.fill"
        case .periodic:
            return periodType?.icon ?? "calendar.badge.clock"
        case .project: return "folder.fill"
        case .relationship: return "person.2.fill"
        }
    }
    
    var color: Color {
        switch priority {
        case .high: return .orange
        case .medium: return .blue
        case .low: return .secondary
        }
    }
}

// MARK: - Reflection Stats Card (iPhone)

#if os(iOS)
struct ReflectionStatsCard: View {
    let streak: Int
    let thisWeekCount: Int
    let rhythmStatus: WeeklyRhythmStatus
    let topThemes: [(theme: String, count: Int)]
    
    var body: some View {
        VStack(spacing: 12) {
            // Top Row: Rhythm Status & Streak
            HStack(spacing: 12) {
                // Rhythm Status Badge
                HStack(spacing: 8) {
                    Image(systemName: rhythmStatus.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(rhythmStatus.color)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rhythmStatus.label)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(statusSubtitle)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(rhythmStatus.color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                
                // This Week Count
                VStack(spacing: 4) {
                    Text("\(thisWeekCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                    Text("This Week")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 70)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            
            // Top Themes
            if !topThemes.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "tag.fill")
                        .font(.caption2)
                        .foregroundStyle(.purple)
                    
                    Text("Top themes:")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    ForEach(topThemes.prefix(3), id: \.theme) { theme in
                        Text(theme.theme)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.1), in: Capsule())
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(4)
    }
    
    private var statusSubtitle: String {
        switch rhythmStatus {
        case .onTrack: return "Keep it up!"
        case .dueToday: return "Perfect time to reflect"
        case .overdue: return "Build your habit"
        case .streak(let weeks): return "\(weeks) consecutive weeks"
        }
    }
}
#endif

// MARK: - Suggested Reflection Row

struct SuggestedReflectionRow: View {
    let suggestion: SuggestedReflection
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(suggestion.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: suggestion.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(suggestion.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                    
                    Text(suggestion.reason)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Mac Suggested Card

#if os(macOS)
struct MacSuggestedCard: View {
    let suggestion: SuggestedReflection
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: suggestion.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(suggestion.color)
                    
                    Text(suggestion.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Text(suggestion.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(12)
            .frame(maxWidth: 200, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(suggestion.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
#endif

#Preview {
    NavigationStack {
        ReflectionsListView()
    }
    .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self], inMemory: true)
}
