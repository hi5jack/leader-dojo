import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            TabView(selection: $appEnvironment.activeTab) {
                DashboardView()
                    .tag(AppEnvironment.MainTab.dashboard)

                ProjectsListView()
                    .tag(AppEnvironment.MainTab.projects)

                CommitmentsView()
                    .tag(AppEnvironment.MainTab.commitments)

                ReflectionsListView()
                    .tag(AppEnvironment.MainTab.reflections)

                CaptureView()
                    .tag(AppEnvironment.MainTab.capture)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            // Custom Tab Bar
            CustomTabBar(selectedTab: $appEnvironment.activeTab)
                .ignoresSafeArea(.keyboard)
        }
    }
}

// MARK: - Custom Tab Bar

private struct CustomTabBar: View {
    @Binding var selectedTab: AppEnvironment.MainTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppEnvironment.MainTab.allCases, id: \.self) { tab in
                TabButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: {
                        Haptics.tabSwitch()
                        withAnimation(LeaderDojoAnimation.tabSwitch) {
                            selectedTab = tab
                        }
                    }
                )
            }
        }
        .padding(.horizontal, LeaderDojoSpacing.s)
        .padding(.top, LeaderDojoSpacing.sm)
        .padding(.bottom, LeaderDojoSpacing.m)
        .background(
            Rectangle()
                .fill(LeaderDojoColors.surfaceSecondary)
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: 20,
                    x: 0,
                    y: -4
                )
        )
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            LeaderDojoColors.dojoDarkGray,
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 1),
            alignment: .top
        )
    }
}

// MARK: - Tab Button

private struct TabButton: View {
    let tab: AppEnvironment.MainTab
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: LeaderDojoSpacing.xs) {
                ZStack {
                    // Background circle for selected state
                    if isSelected {
                        Circle()
                            .fill(LeaderDojoColors.dojoAmber.opacity(0.2))
                            .frame(width: 44, height: 44)
                    }
                    
                    // Icon
                    Image(systemName: tab.icon)
                        .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(isSelected ? LeaderDojoColors.dojoAmber : LeaderDojoColors.textTertiary)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                
                // Label
                Text(tab.label)
                    .font(LeaderDojoTypography.label)
                    .foregroundStyle(isSelected ? LeaderDojoColors.dojoAmber : LeaderDojoColors.textTertiary)
                
                // Active indicator
                if isSelected {
                    Capsule()
                        .fill(LeaderDojoColors.dojoAmber)
                        .frame(width: 32, height: 3)
                } else {
                    Capsule()
                        .fill(Color.clear)
                        .frame(width: 32, height: 3)
                }
            }
            .frame(maxWidth: .infinity)
            .animation(LeaderDojoAnimation.tabSwitch, value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Main Tab Extension

extension AppEnvironment.MainTab {
    var icon: String {
        switch self {
        case .dashboard:
            return DojoIcons.dashboard
        case .projects:
            return DojoIcons.projects
        case .commitments:
            return DojoIcons.commitments
        case .reflections:
            return DojoIcons.reflections
        case .capture:
            return DojoIcons.capture
        }
    }
    
    var label: String {
        switch self {
        case .dashboard:
            return "Home"
        case .projects:
            return "Projects"
        case .commitments:
            return "Commits"
        case .reflections:
            return "Reflect"
        case .capture:
            return "Capture"
        }
    }
    
    static var allCases: [AppEnvironment.MainTab] {
        [.dashboard, .projects, .commitments, .reflections, .capture]
    }
}
