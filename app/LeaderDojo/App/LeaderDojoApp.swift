import SwiftUI
import SwiftData

@main
struct LeaderDojoApp: App {
    let modelContainer: ModelContainer
    
    init() {
        // Configure SwiftData with CloudKit sync
        let schema = Schema([
            Project.self,
            Entry.self,
            Commitment.self,
            Reflection.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.joinleaderdojo.app")
        )
        
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
        
        #if os(macOS)
        Settings {
            SettingsView()
                .modelContainer(modelContainer)
        }
        #endif
    }
}

