import SwiftUI

struct CommitmentsView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject private var viewModel = CommitmentsViewModel()
    @State private var selectedDirection: Commitment.Direction = .i_owe

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LeaderDojoColors.surfacePrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom segmented control
                    customSegmentedControl
                        .padding(.horizontal, LeaderDojoSpacing.ml)
                        .padding(.vertical, LeaderDojoSpacing.m)
                    
                    // Content
                    content
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: LeaderDojoSpacing.s) {
                        Image(systemName: DojoIcons.commitments)
                            .dojoIconMedium(color: LeaderDojoColors.dojoAmber)
                        Text("Commitments")
                            .dojoHeadingLarge()
                    }
                }
            }
        }
        .onAppear {
            viewModel.configure(service: appEnvironment.commitmentsService)
        }
        .task {
            await viewModel.load()
        }
    }
    
    private var customSegmentedControl: some View {
        HStack(spacing: 0) {
            segmentButton(
                title: "I Owe",
                count: viewModel.iOwe.count,
                isSelected: selectedDirection == .i_owe,
                direction: .i_owe
            )
            
            segmentButton(
                title: "Waiting For",
                count: viewModel.waitingFor.count,
                isSelected: selectedDirection == .waiting_for,
                direction: .waiting_for
            )
        }
        .dojoFlatCard()
    }
    
    private func segmentButton(
        title: String,
        count: Int,
        isSelected: Bool,
        direction: Commitment.Direction
    ) -> some View {
        Button(action: {
            Haptics.selection()
            selectedDirection = direction
        }) {
            VStack(spacing: LeaderDojoSpacing.xs) {
                HStack(spacing: LeaderDojoSpacing.s) {
                    Image(systemName: direction == .i_owe ? DojoIcons.iOwe : DojoIcons.waitingFor)
                        .dojoIconSmall(color: isSelected ? LeaderDojoColors.textPrimary : LeaderDojoColors.textTertiary)
                    
                    Text(title)
                        .font(LeaderDojoTypography.bodyMedium)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? LeaderDojoColors.textPrimary : LeaderDojoColors.textSecondary)
                    
                    if count > 0 {
                        Text("\(count)")
                            .font(LeaderDojoTypography.captionRegular)
                            .foregroundStyle(isSelected ? LeaderDojoColors.dojoBlack : LeaderDojoColors.textSecondary)
                            .padding(.horizontal, LeaderDojoSpacing.s)
                            .padding(.vertical, 2)
                            .background(isSelected ? (direction == .i_owe ? LeaderDojoColors.dojoAmber : LeaderDojoColors.dojoBlue) : LeaderDojoColors.dojoDarkGray)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, LeaderDojoSpacing.s)
                
                if isSelected {
                    Rectangle()
                        .fill(direction == .i_owe ? LeaderDojoColors.dojoAmber : LeaderDojoColors.dojoBlue)
                        .frame(height: 3)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var content: some View {
        if let message = viewModel.errorMessage {
            DojoErrorView(message: message) {
                Task { await viewModel.load() }
            }
        } else if commitmentsForSelectedDirection().isEmpty {
            emptyState
        } else {
            commitmentsList
        }
    }
    
    private var emptyState: some View {
        DojoEmptyState(
            icon: selectedDirection == .i_owe ? "checkmark.circle.badge.xmark" : "arrow.down.circle.badge.clock",
            title: selectedDirection == .i_owe ? "All Caught Up!" : "Nothing to Wait For",
            message: selectedDirection == .i_owe ?
                "You have no open commitments to others. Great work staying on top of things!" :
                "No one owes you anything right now. Check back later."
        )
        .padding(LeaderDojoSpacing.xl)
    }
    
    private var commitmentsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: LeaderDojoSpacing.m) {
                ForEach(commitmentsForSelectedDirection()) { commitment in
                    NavigationLink(destination: CommitmentDetailView(commitment: commitment)) {
                        CommitmentListCard(
                            commitment: commitment,
                            onComplete: {
                                Task {
                                    Haptics.commitmentCompleted()
                                    let input = UpdateCommitmentInput(
                                        status: .done,
                                        counterparty: nil,
                                        dueDate: nil,
                                        importance: nil,
                                        urgency: nil,
                                        notes: nil
                                    )
                                    await viewModel.update(commitment: commitment, input: input)
                                    await viewModel.load()
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .onTapGesture {
                        Haptics.cardTap()
                    }
                }
            }
            .padding(.horizontal, LeaderDojoSpacing.ml)
            .padding(.vertical, LeaderDojoSpacing.m)
        }
        .refreshable {
            Haptics.refreshTriggered()
            await viewModel.load()
        }
    }

    private func commitmentsForSelectedDirection() -> [Commitment] {
        selectedDirection == .i_owe ? viewModel.iOwe : viewModel.waitingFor
    }
}

// MARK: - Commitment List Card

private struct CommitmentListCard: View {
    let commitment: Commitment
    let onComplete: () -> Void
    @State private var offset: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Swipe action background
            HStack {
                Spacer()
                Button(action: onComplete) {
                    VStack(spacing: LeaderDojoSpacing.xs) {
                        Image(systemName: DojoIcons.success)
                            .dojoIconLarge(color: Color.white)
                        Text("Done")
                            .font(LeaderDojoTypography.captionLarge)
                            .foregroundStyle(Color.white)
                    }
                    .padding(.horizontal, LeaderDojoSpacing.l)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LeaderDojoColors.dojoGreen)
            .clipShape(RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusLarge, style: .continuous))
            
            // Card content
            HStack(spacing: LeaderDojoSpacing.m) {
                // Complete button
                Button(action: onComplete) {
                    Image(systemName: commitment.status == .done ? DojoIcons.statusDone : DojoIcons.statusOpen)
                        .dojoIconMedium(color: commitment.status == .done ? LeaderDojoColors.dojoGreen : LeaderDojoColors.textTertiary)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: LeaderDojoSpacing.s) {
                    // Title
                    Text(commitment.title)
                        .dojoHeadingMedium()
                        .lineLimit(2)
                    
                    // Metadata row
                    HStack(spacing: LeaderDojoSpacing.m) {
                        // Counterparty
                        if let counterparty = commitment.counterparty {
                            HStack(spacing: LeaderDojoSpacing.xs) {
                                Image(systemName: "person.circle.fill")
                                    .dojoIconSmall(color: LeaderDojoColors.textTertiary)
                                Text(counterparty)
                                    .dojoCaptionRegular()
                            }
                        }
                        
                        // Due date with urgency
                        if let due = commitment.dueDate {
                            HStack(spacing: LeaderDojoSpacing.xs) {
                                Image(systemName: dueDateIcon(due))
                                    .dojoIconSmall(color: dueDateColor(due))
                                Text(due.formattedShort())
                                    .font(LeaderDojoTypography.captionLarge)
                                    .foregroundStyle(dueDateColor(due))
                            }
                        }
                    }
                    
                    // Priority stars
                    if let importance = commitment.importance {
                        importanceStars(importance)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .dojoIconSmall(color: LeaderDojoColors.textTertiary)
            }
            .dojoCardWithBorder(
                color: commitment.direction == .i_owe ? LeaderDojoColors.dojoAmber : LeaderDojoColors.dojoBlue
            )
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        if gesture.translation.width < 0 {
                            offset = gesture.translation.width
                        }
                    }
                    .onEnded { gesture in
                        if gesture.translation.width < -80 {
                            Haptics.swipeReveal()
                            onComplete()
                        }
                        withAnimation(LeaderDojoAnimation.swipeReveal) {
                            offset = 0
                        }
                    }
            )
        }
    }
    
    private func dueDateIcon(_ date: Date) -> String {
        let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if daysUntilDue < 0 {
            return DojoIcons.overdue
        } else if daysUntilDue <= 3 {
            return DojoIcons.warning
        } else {
            return DojoIcons.clock
        }
    }
    
    private func dueDateColor(_ date: Date) -> Color {
        let daysUntilDue = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if daysUntilDue < 0 {
            return LeaderDojoColors.dojoRed
        } else if daysUntilDue <= 3 {
            return LeaderDojoColors.dojoAmber
        } else {
            return LeaderDojoColors.textSecondary
        }
    }
    
    private func importanceStars(_ importance: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<importanceLevel(importance), id: \.self) { _ in
                Image(systemName: DojoIcons.star)
                    .font(.system(size: 10))
                    .foregroundStyle(LeaderDojoColors.dojoAmber)
            }
        }
    }
    
    private func importanceLevel(_ importance: Int) -> Int {
        switch importance {
        case let value where value >= 5:
            return 3
        case 4:
            return 2
        default:
            return 1
        }
    }
}
