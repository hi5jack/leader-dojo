import SwiftUI
import SwiftData

struct PrepBriefingView: View {
    @Environment(\.dismiss) private var dismiss
    let project: Project
    
    @State private var isLoading: Bool = true
    @State private var briefing: String = ""
    @State private var error: String? = nil
    @State private var dayRange: Int = 90
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Project Header
                    projectHeader
                    
                    // Settings
                    settingsSection
                    
                    // Briefing Content
                    if isLoading {
                        loadingView
                    } else if let error = error {
                        errorView(error)
                    } else {
                        briefingContent
                    }
                    
                    // Commitments Summary
                    commitmentsSummary
                    
                    // Recent Timeline
                    recentTimeline
                }
                .padding()
            }
            .navigationTitle("Prep Briefing")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await generateBriefing()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .task {
                await generateBriefing()
            }
        }
    }
    
    // MARK: - Project Header
    
    private var projectHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(project.name)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 8) {
                Badge(text: project.status.displayName, icon: project.status.icon, color: statusColor)
                Badge(text: "P\(project.priority)", icon: "flag.fill", color: priorityColor)
            }
            
            if let lastActive = project.lastActiveAt {
                Text("Last active \(lastActive, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        HStack {
            Text("Time range:")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Picker("", selection: $dayRange) {
                Text("30 days").tag(30)
                Text("60 days").tag(60)
                Text("90 days").tag(90)
                Text("180 days").tag(180)
            }
            .pickerStyle(.segmented)
            .onChange(of: dayRange) { _, _ in
                Task {
                    await generateBriefing()
                }
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
            
            Text("Generating briefing...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            
            Text("Failed to generate briefing")
                .font(.headline)
            
            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                Task {
                    await generateBriefing()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    // MARK: - Briefing Content
    
    private var briefingContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AI Briefing", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.purple)
            
            MarkdownText(briefing)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Commitments Summary
    
    private var commitmentsSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Open Commitments", systemImage: "checklist")
                .font(.headline)
            
            let iOwe = project.commitments?.filter { $0.direction == .iOwe && $0.status.isActive } ?? []
            let waitingFor = project.commitments?.filter { $0.direction == .waitingFor && $0.status.isActive } ?? []
            
            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "arrow.up.right.circle.fill")
                            .foregroundStyle(.orange)
                        Text("I Owe")
                            .font(.subheadline)
                    }
                    Text("\(iOwe.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "arrow.down.left.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Waiting For")
                            .font(.subheadline)
                    }
                    Text("\(waitingFor.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            
            // List overdue items
            let overdueItems = iOwe.filter { $0.isOverdue }
            if !overdueItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Overdue", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    
                    ForEach(overdueItems) { commitment in
                        Text("• \(commitment.title)")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    // MARK: - Recent Timeline
    
    private var recentTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Recent Activity", systemImage: "clock.fill")
                .font(.headline)
            
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -dayRange, to: Date()) ?? Date()
            let entries = (project.entries ?? [])
                .filter { $0.deletedAt == nil && $0.occurredAt > cutoffDate }
                .sorted { $0.occurredAt > $1.occurredAt }
                .prefix(5)
            
            if entries.isEmpty {
                Text("No entries in the selected time range.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            } else {
                ForEach(Array(entries)) { entry in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: entry.kind.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.title)
                                .font(.subheadline)
                            Text(entry.occurredAt, style: .date)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func generateBriefing() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        do {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -dayRange, to: Date()) ?? Date()
            let recentEntries = (project.entries ?? [])
                .filter { $0.deletedAt == nil && $0.occurredAt > cutoffDate }
                .sorted { $0.occurredAt > $1.occurredAt }
            
            let openCommitments = (project.commitments ?? [])
                .filter { $0.status.isActive }
            
            let result = try await AIService.shared.generatePrepBriefing(
                project: project,
                recentEntries: recentEntries,
                openCommitments: openCommitments
            )
            
            await MainActor.run {
                briefing = result.briefing
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        switch project.status {
        case .active: return .green
        case .onHold: return .orange
        case .completed: return .blue
        case .archived: return .gray
        }
    }
    
    private var priorityColor: Color {
        switch project.priority {
        case 5: return .red
        case 4: return .orange
        case 3: return .yellow
        case 2: return .blue
        default: return .gray
        }
    }
}

#Preview {
    PrepBriefingView(project: Project(name: "Sample Project"))
        .modelContainer(for: [Project.self, Entry.self, Commitment.self], inMemory: true)
}

