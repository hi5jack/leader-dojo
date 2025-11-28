import SwiftUI
import SwiftData

struct ReflectionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Reflection.createdAt, order: .reverse) private var reflections: [Reflection]
    
    @State private var showingNewReflection: Bool = false
    @State private var selectedPeriodType: ReflectionPeriodType = .week
    
    var body: some View {
        NavigationStack {
            Group {
                if reflections.isEmpty {
                    emptyState
                } else {
                    reflectionsList
                }
            }
            .navigationTitle("Reflections")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
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
            }
            .sheet(isPresented: $showingNewReflection) {
                NewReflectionView(periodType: selectedPeriodType)
            }
        }
    }
    
    // MARK: - Empty State
    
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
    
    // MARK: - Reflections List
    
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
    
    // MARK: - Computed Properties
    
    private var groupedReflections: [(String, [Reflection])] {
        let grouped = Dictionary(grouping: reflections) { reflection -> String in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: reflection.createdAt)
        }
        
        return grouped.sorted { $0.key > $1.key }
    }
    
    // MARK: - Actions
    
    private func deleteReflections(at offsets: IndexSet, from items: [Reflection]) {
        for index in offsets {
            modelContext.delete(items[index])
        }
        try? modelContext.save()
    }
}

// MARK: - Reflection Row View

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

#Preview {
    ReflectionsListView()
        .modelContainer(for: [Project.self, Entry.self, Commitment.self, Reflection.self], inMemory: true)
}

