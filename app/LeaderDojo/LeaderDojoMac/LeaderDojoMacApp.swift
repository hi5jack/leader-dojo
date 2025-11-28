//
//  LeaderDojoMacApp.swift
//  LeaderDojoMac
//
//  Created by Jack Chen on 11/28/25.
//

import SwiftUI
import SwiftData

@main
struct LeaderDojoMacApp: App {
    let modelContainer: ModelContainer
    
    init() {
        let schema = Schema([
            Project.self,
            Entry.self,
            Commitment.self,
            Reflection.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.joinleaderdojo.app")
        )
        
        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer for macOS: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
