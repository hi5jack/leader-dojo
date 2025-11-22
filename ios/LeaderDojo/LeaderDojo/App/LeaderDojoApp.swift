import SwiftUI

@main
struct LeaderDojoApp: App {
    @StateObject private var appEnvironment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appEnvironment)
        }
    }
}

private struct RootView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment

    var body: some View {
        Group {
            if appEnvironment.isAuthenticated {
                MainTabView()
                    .environmentObject(appEnvironment)
            } else {
                SignInView()
                    .environmentObject(appEnvironment)
            }
        }
        .task {
            await appEnvironment.bootstrap()
        }
    }
}
