import SwiftUI

struct ProjectDetailView: View {
    let projectId: String

    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject private var viewModel = ProjectDetailViewModel()
    @State private var showingAddEntry = false
    @State private var selectedCommitmentTab: CommitmentTab = .iOwe

    var body: some View {
        ZStack {
            // Background
            LeaderDojoColors.surfacePrimary
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: LeaderDojoSpacing.xl) {
                    if let project = viewModel.project {
                        projectHeader(project)
                        actionButtons
                    }
                    
                    timelineSection
                    commitmentsSection
                }
                .padding(.horizontal, LeaderDojoSpacing.ml)
                .padding(.vertical, LeaderDojoSpacing.l)
            }
        }
        .navigationTitle(viewModel.project?.name ?? "Project")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddEntry) {
            if let project = viewModel.project {
                AddEntryView(project: project) {
                    Haptics.entryCreated()
                    await viewModel.fetchEntries()
                    await viewModel.fetchCommitments()
                }
                .environmentObject(appEnvironment)
            }
        }
        .onAppear {
            viewModel.configure(
                projectsService: appEnvironment.projectsService,
                entriesService: appEnvironment.entriesService,
                commitmentsService: appEnvironment.commitmentsService
            )
        }
        .task {
            await viewModel.load(projectId: projectId)
        }
        .refreshable {
            Haptics.refreshTriggered()
            await viewModel.load(projectId: projectId)
        }
    }

    private func projectHeader(_ project: Project) -> some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.m) {
            // Title section with gradient background
            VStack(alignment: .leading, spacing: LeaderDojoSpacing.s) {
                Text(project.name)
                    .dojoHeadingXL()
                
                if let description = project.description, !description.isEmpty {
                    Text(description)
                        .dojoBodyLarge()
                        .foregroundStyle(LeaderDojoColors.textSecondary)
                }
            }
            
            // Metadata badges
            HStack(spacing: LeaderDojoSpacing.s) {
                DojoBadge.type(project.type.rawValue, size: .regular)
                
                DojoBadge(
                    project.status.rawValue.replacingOccurrences(of: "_", with: " ").capitalized,
                    style: .status(project.status.rawValue),
                    size: .regular
                )
                
                DojoBadge.priority(project.priority, size: .regular)
            }
            
            // Owner notes (expandable)
            if let notes = project.ownerNotes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: LeaderDojoSpacing.s) {
                    HStack(spacing: LeaderDojoSpacing.xs) {
                        Image(systemName: DojoIcons.selfNote)
                            .dojoIconSmall(color: LeaderDojoColors.dojoAmber)
                        Text("YOUR NOTES")
                            .dojoLabel()
                            .foregroundStyle(LeaderDojoColors.dojoAmber)
                    }
                    
                    Text(notes)
                        .dojoBodyMedium()
                        .foregroundStyle(LeaderDojoColors.textSecondary)
                }
                .dojoFlatCard()
            }
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: LeaderDojoSpacing.m) {
            Button(action: {
                Haptics.cardTap()
                // TODO: Implement prep functionality
            }) {
                HStack(spacing: LeaderDojoSpacing.s) {
                    Image(systemName: DojoIcons.prep)
                        .dojoIconMedium(color: LeaderDojoColors.dojoBlue)
                    Text("Prep for Meeting")
                        .font(LeaderDojoTypography.bodyMedium)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.dojoSecondary)
            
            Button(action: {
                Haptics.cardTap()
                showingAddEntry = true
            }) {
                HStack(spacing: LeaderDojoSpacing.s) {
                    Image(systemName: DojoIcons.add)
                        .dojoIconMedium(color: LeaderDojoColors.dojoBlack)
                    Text("Add Entry")
                        .font(LeaderDojoTypography.bodyMedium)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.dojoPrimary)
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.m) {
            VStack(alignment: .leading, spacing: LeaderDojoSpacing.xs) {
                Text("Timeline")
                    .dojoHeadingMedium()
                Text("Recent activity and entries")
                    .dojoCaptionRegular()
            }
            
            if viewModel.entries.isEmpty {
                DojoEmptyState(
                    icon: DojoIcons.emptyBox,
                    title: "No Entries Yet",
                    message: "Start capturing meetings, updates, and reflections for this project.",
                    actionTitle: "Add First Entry"
                ) {
                    Haptics.cardTap()
                    showingAddEntry = true
                }
                .dojoFlatCard()
            } else {
                TimelineView(entries: viewModel.entries)
            }
        }
    }

    private var commitmentsSection: some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.m) {
            VStack(alignment: .leading, spacing: LeaderDojoSpacing.xs) {
                Text("Commitments")
                    .dojoHeadingMedium()
                Text("Open items linked to this project")
                    .dojoCaptionRegular()
            }
            
            // Tab selector
            HStack(spacing: 0) {
                CommitmentTabButton(
                    title: "I Owe",
                    count: iOweCommitments.count,
                    isSelected: selectedCommitmentTab == .iOwe
                ) {
                    Haptics.selection()
                    selectedCommitmentTab = .iOwe
                }
                
                CommitmentTabButton(
                    title: "Waiting For",
                    count: waitingForCommitments.count,
                    isSelected: selectedCommitmentTab == .waitingFor
                ) {
                    Haptics.selection()
                    selectedCommitmentTab = .waitingFor
                }
            }
            .dojoFlatCard()
            
            // Commitments list
            if currentCommitments.isEmpty {
                HStack(spacing: LeaderDojoSpacing.m) {
                    Image(systemName: DojoIcons.success)
                        .dojoIconLarge(color: LeaderDojoColors.dojoGreen)
                    Text("No open \(selectedCommitmentTab == .iOwe ? "I Owe" : "Waiting For") commitments")
                        .dojoBodyMedium()
                        .foregroundStyle(LeaderDojoColors.textSecondary)
                }
                .dojoFlatCard()
            } else {
                ForEach(currentCommitments) { commitment in
                    CommitmentRowCard(commitment: commitment)
                }
            }
        }
    }
    
    private var iOweCommitments: [Commitment] {
        viewModel.commitments.filter { $0.direction == .i_owe }
    }
    
    private var waitingForCommitments: [Commitment] {
        viewModel.commitments.filter { $0.direction == .waiting_for }
    }
    
    private var currentCommitments: [Commitment] {
        selectedCommitmentTab == .iOwe ? iOweCommitments : waitingForCommitments
    }
}

// MARK: - Timeline View

private struct TimelineView: View {
    let entries: [Entry]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                HStack(alignment: .top, spacing: LeaderDojoSpacing.m) {
                    // Timeline connector
                    VStack(spacing: 0) {
                        if index > 0 {
                            Rectangle()
                                .fill(LeaderDojoColors.dojoDarkGray)
                                .frame(width: 2, height: 20)
                        }
                        
                        // Timeline dot
                        Image(systemName: entryKindIcon(entry.kind.rawValue))
                            .dojoIconMedium(color: entryKindColor(entry.kind.rawValue))
                            .frame(width: 32, height: 32)
                            .background(entryKindColor(entry.kind.rawValue).opacity(0.2))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .strokeBorder(entryKindColor(entry.kind.rawValue).opacity(0.3), lineWidth: 2)
                            )
                        
                        if index < entries.count - 1 {
                            Rectangle()
                                .fill(LeaderDojoColors.dojoDarkGray)
                                .frame(width: 2)
                        }
                    }
                    
                    // Entry card
                    VStack(alignment: .leading, spacing: LeaderDojoSpacing.s) {
                        HStack {
                            DojoBadge(
                                entry.kind.rawValue.capitalized,
                                style: .custom(
                                    background: entryKindColor(entry.kind.rawValue).opacity(0.2),
                                    foreground: entryKindColor(entry.kind.rawValue),
                                    border: nil
                                ),
                                size: .compact
                            )
                            
                            Spacer()
                            
                            Text(entry.occurredAt.formattedShort())
                                .dojoCaptionRegular()
                        }
                        
                        Text(entry.title)
                            .dojoHeadingMedium()
                            .lineLimit(2)
                        
                        if let summary = entry.aiSummary, !summary.isEmpty {
                            Text(summary)
                                .dojoBodyMedium()
                                .foregroundStyle(LeaderDojoColors.textSecondary)
                                .lineLimit(3)
                        } else if let raw = entry.rawContent {
                            Text(raw)
                                .dojoBodyMedium()
                                .foregroundStyle(LeaderDojoColors.textSecondary)
                                .lineLimit(3)
                        }
                    }
                    .padding(.vertical, LeaderDojoSpacing.s)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.bottom, index < entries.count - 1 ? LeaderDojoSpacing.m : 0)
            }
        }
    }
    
    private func entryKindColor(_ kind: String) -> Color {
        switch kind.lowercased() {
        case "meeting":
            return LeaderDojoColors.dojoBlue
        case "update":
            return LeaderDojoColors.dojoGreen
        case "self_note", "selfnote":
            return LeaderDojoColors.dojoAmber
        case "decision":
            return LeaderDojoColors.dojoRed
        default:
            return LeaderDojoColors.textSecondary
        }
    }
}

// MARK: - Commitment Tab

private enum CommitmentTab {
    case iOwe
    case waitingFor
}

private struct CommitmentTabButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: LeaderDojoSpacing.xs) {
                HStack(spacing: LeaderDojoSpacing.xs) {
                    Text(title)
                        .font(LeaderDojoTypography.bodyMedium)
                        .fontWeight(isSelected ? .semibold : .regular)
                    
                    if count > 0 {
                        Text("\(count)")
                            .font(LeaderDojoTypography.captionRegular)
                            .foregroundStyle(isSelected ? LeaderDojoColors.dojoBlack : LeaderDojoColors.textSecondary)
                            .padding(.horizontal, LeaderDojoSpacing.s)
                            .padding(.vertical, 2)
                            .background(isSelected ? LeaderDojoColors.dojoAmber : LeaderDojoColors.dojoDarkGray)
                            .clipShape(Capsule())
                    }
                }
                .foregroundStyle(isSelected ? LeaderDojoColors.textPrimary : LeaderDojoColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, LeaderDojoSpacing.s)
                
                if isSelected {
                    Rectangle()
                        .fill(LeaderDojoColors.dojoAmber)
                        .frame(height: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Commitment Row Card

private struct CommitmentRowCard: View {
    let commitment: Commitment
    
    var body: some View {
        HStack(spacing: LeaderDojoSpacing.m) {
            VStack(alignment: .leading, spacing: LeaderDojoSpacing.xs) {
                Text(commitment.title)
                    .dojoHeadingMedium()
                    .lineLimit(2)
                
                if let counterparty = commitment.counterparty {
                    HStack(spacing: LeaderDojoSpacing.xs) {
                        Image(systemName: "person.circle.fill")
                            .dojoIconSmall(color: LeaderDojoColors.textTertiary)
                        Text(counterparty)
                            .dojoCaptionRegular()
                    }
                }
                
                if let due = commitment.dueDate {
                    HStack(spacing: LeaderDojoSpacing.xs) {
                        Image(systemName: DojoIcons.clock)
                            .dojoIconSmall(color: LeaderDojoColors.textTertiary)
                        Text("Due \(due.formattedShort())")
                            .dojoCaptionRegular()
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .dojoIconSmall(color: LeaderDojoColors.textTertiary)
        }
        .dojoCardWithBorder(
            color: commitment.direction == .i_owe ? LeaderDojoColors.dojoAmber : LeaderDojoColors.dojoBlue
        )
    }
}
