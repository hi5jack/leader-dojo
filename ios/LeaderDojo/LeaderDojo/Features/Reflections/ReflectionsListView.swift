import SwiftUI

struct ReflectionsListView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject private var viewModel = ReflectionsViewModel()
    @State private var showingWizard = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LeaderDojoColors.surfacePrimary
                    .ignoresSafeArea()
                
                content
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            Haptics.cardTap()
                            showingWizard = true
                        }) {
                            Image(systemName: DojoIcons.add)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(LeaderDojoColors.dojoBlack)
                                .frame(width: 60, height: 60)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            LeaderDojoColors.dojoEmerald,
                                            LeaderDojoColors.dojoEmerald.opacity(0.9)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(Circle())
                                .shadow(
                                    color: LeaderDojoColors.dojoEmerald.opacity(0.4),
                                    radius: 16,
                                    x: 0,
                                    y: 4
                                )
                        }
                        .padding(.trailing, LeaderDojoSpacing.ml)
                        .padding(.bottom, LeaderDojoSpacing.l)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: LeaderDojoSpacing.s) {
                        Image(systemName: DojoIcons.reflections)
                            .dojoIconMedium(color: LeaderDojoColors.dojoEmerald)
                        Text("Reflections")
                            .dojoHeadingLarge()
                    }
                }
            }
            .sheet(isPresented: $showingWizard) {
                ReflectionWizardView {
                    Haptics.reflectionSaved()
                    await viewModel.load()
                }
                .environmentObject(appEnvironment)
            }
        }
        .onAppear {
            viewModel.configure(service: appEnvironment.reflectionsService)
        }
        .task {
            await viewModel.load()
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if let message = viewModel.errorMessage {
            DojoErrorView(message: message) {
                Task { await viewModel.load() }
            }
        } else if viewModel.reflections.isEmpty {
            emptyState
        } else {
            reflectionsList
        }
    }
    
    private var emptyState: some View {
        DojoEmptyState(
            icon: DojoIcons.insight,
            title: "Start Reflecting",
            message: "Weekly and monthly reflections help you identify patterns in your leadership and make intentional improvements.",
            actionTitle: "Create First Reflection"
        ) {
            Haptics.cardTap()
            showingWizard = true
        }
    }
    
    private var reflectionsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: LeaderDojoSpacing.m) {
                // Hero section
                VStack(alignment: .leading, spacing: LeaderDojoSpacing.s) {
                    Text("LEADERSHIP GROWTH")
                        .dojoLabel()
                        .foregroundStyle(LeaderDojoColors.dojoEmerald)
                    
                    Text("Your Practice Timeline")
                        .dojoDisplayMedium()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, LeaderDojoSpacing.ml)
                
                // Timeline
                ReflectionTimeline(reflections: viewModel.reflections)
            }
            .padding(.vertical, LeaderDojoSpacing.l)
            .padding(.bottom, 80) // Space for FAB
        }
        .refreshable {
            Haptics.refreshTriggered()
            await viewModel.load()
        }
    }
}

// MARK: - Reflection Timeline

private struct ReflectionTimeline: View {
    let reflections: [Reflection]
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(reflections.enumerated()), id: \.element.id) { index, reflection in
                NavigationLink(destination: ReflectionDetailView(reflection: reflection)) {
                    HStack(alignment: .top, spacing: LeaderDojoSpacing.m) {
                        // Timeline connector
                        VStack(spacing: 0) {
                            if index > 0 {
                                Rectangle()
                                    .fill(LeaderDojoColors.dojoDarkGray)
                                    .frame(width: 2, height: 20)
                            }
                            
                            // Timeline dot
                            Image(systemName: DojoIcons.insight)
                                .dojoIconMedium(color: LeaderDojoColors.dojoEmerald)
                                .frame(width: 32, height: 32)
                                .background(LeaderDojoColors.dojoEmerald.opacity(0.2))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .strokeBorder(LeaderDojoColors.dojoEmerald.opacity(0.3), lineWidth: 2)
                                )
                            
                            if index < reflections.count - 1 {
                                Rectangle()
                                    .fill(LeaderDojoColors.dojoDarkGray)
                                    .frame(width: 2)
                            }
                        }
                        
                        // Reflection card
                        VStack(alignment: .leading, spacing: LeaderDojoSpacing.m) {
                            // Header
                            HStack {
                                DojoBadge(
                                    reflection.periodType.rawValue.capitalized,
                                    style: .custom(
                                        background: LeaderDojoColors.dojoEmerald.opacity(0.2),
                                        foreground: LeaderDojoColors.dojoEmerald,
                                        border: nil
                                    ),
                                    size: .regular,
                                    icon: periodIcon(reflection.periodType)
                                )
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .dojoIconSmall(color: LeaderDojoColors.textTertiary)
                            }
                            
                            // Date range
                            Text("\(reflection.periodStart.formattedShort()) - \(reflection.periodEnd.formattedShort())")
                                .dojoHeadingMedium()
                            
                            // Preview text
                            if let preview = reflection.questionsAndAnswers.first?.answer, !preview.isEmpty {
                                Text(preview)
                                    .dojoBodyMedium()
                                    .foregroundStyle(LeaderDojoColors.textSecondary)
                                    .lineLimit(3)
                            }
                            
                            // Stats
                            HStack(spacing: LeaderDojoSpacing.m) {
                                HStack(spacing: LeaderDojoSpacing.xs) {
                                    Image(systemName: DojoIcons.insight)
                                        .dojoIconSmall(color: LeaderDojoColors.dojoEmerald)
                                    Text("Insights captured")
                                        .dojoCaptionRegular()
                                }
                                
                                Spacer()
                                
                                Text(reflection.createdAt.formattedShort())
                                    .dojoCaptionRegular()
                            }
                        }
                        .padding(.vertical, LeaderDojoSpacing.m)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, LeaderDojoSpacing.ml)
                    .padding(.bottom, index < reflections.count - 1 ? LeaderDojoSpacing.l : 0)
                }
                .buttonStyle(.plain)
                .onTapGesture {
                    Haptics.cardTap()
                }
            }
        }
    }
    
    private func periodIcon(_ periodType: Reflection.PeriodType) -> String {
        switch periodType {
        case .week:
            return "calendar.badge.clock"
        case .month:
            return "calendar"
        case .quarter:
            return "calendar.badge.exclamationmark"
        }
    }
}
