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
            Reflection.self,
            Person.self
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
        
        // One-time cleanup of legacy entry data from older builds.
        // Specifically removes entries whose kind was the old \"commitment\" enum case.
        cleanupLegacyCommitmentEntries()
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

    /// Delete any legacy `Entry` records that were created when commitments
    /// were still modeled as an `EntryKind.commitment`. These are now invalid
    /// and should not appear in the timeline.
    private func cleanupLegacyCommitmentEntries() {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Entry>()
        
        do {
            let entries = try context.fetch(descriptor)
            var deletedCount = 0
            
            for entry in entries where entry.kind == ._legacyCommitment {
                context.delete(entry)
                deletedCount += 1
            }
            
            if deletedCount > 0 {
                try context.save()
                #if DEBUG
                print("LeaderDojo: Deleted \\(deletedCount) legacy commitment entries")
                #endif
            }
        } catch {
            #if DEBUG
            print("LeaderDojo: Failed to clean up legacy commitment entries: \\(error)")
            #endif
        }
    }
}

