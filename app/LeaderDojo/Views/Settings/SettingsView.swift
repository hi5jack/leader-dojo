import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var showAPIKey: Bool = false
    @State private var isSaving: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isAPIKeyConfigured: Bool = false
    @State private var showImportSheet: Bool = false
    
    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }
    
    // MARK: - iOS Layout
    
    #if os(iOS)
    private var iOSLayout: some View {
        settingsForm
    }
    
    private var settingsForm: some View {
        Form {
            // AI Configuration Section
            Section {
                HStack {
                    if showAPIKey {
                        TextField("sk-...", text: $apiKey)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                    } else {
                        SecureField("sk-...", text: $apiKey)
                            .textFieldStyle(.plain)
                    }
                    
                    Button {
                        showAPIKey.toggle()
                    } label: {
                        Image(systemName: showAPIKey ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                HStack {
                    if isAPIKeyConfigured {
                        Label("API Key configured", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    } else {
                        Label("API Key not set", systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Button("Save") {
                        saveAPIKey()
                    }
                    .disabled(apiKey.isEmpty || isSaving)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            } header: {
                Label("OpenAI API Key", systemImage: "key.fill")
            } footer: {
                Text("Your API key is stored securely in the Keychain and synced via iCloud Keychain. Get your key from [platform.openai.com](https://platform.openai.com/api-keys)")
            }
            
            // Data Management Section
            Section {
                Button {
                    showImportSheet = true
                } label: {
                    Label("Import from Web App", systemImage: "square.and.arrow.down")
                }
                
                Button {
                    exportData()
                } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
            } header: {
                Label("Data Management", systemImage: "externaldrive.fill")
            } footer: {
                Text("Import data exported from the Leader Dojo web app, or export your local data as JSON.")
            }
            
            // About Section
            Section {
                LabeledContent("Version", value: appVersion)
                LabeledContent("Build", value: buildNumber)
                
                Link(destination: URL(string: "https://joinleaderdojo.com")!) {
                    Label("Visit Website", systemImage: "globe")
                }
                
                Link(destination: URL(string: "https://joinleaderdojo.com/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                }
            } header: {
                Label("About", systemImage: "info.circle.fill")
            }
            
            #if DEBUG
            // Debug Section (only in debug builds)
            Section {
                Button("Clear All Data", role: .destructive) {
                    // TODO: Implement data clearing
                }
                
                Button("Generate Sample Data") {
                    // TODO: Implement sample data generation
                }
            } header: {
                Label("Debug", systemImage: "ladybug.fill")
            }
            #endif
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadAPIKey()
        }
        .alert("Settings", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showImportSheet) {
            DataImportView()
        }
    }
    #endif
    
    // MARK: - macOS Layout
    
    #if os(macOS)
    private var macOSLayout: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Configure your Leader Dojo experience")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                
                // Two-column layout
                HStack(alignment: .top, spacing: 24) {
                    // Left Column
                    VStack(spacing: 20) {
                        apiKeyCard
                        dataManagementCard
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right Column
                    VStack(spacing: 20) {
                        aboutCard
                        #if DEBUG
                        debugCard
                        #endif
                    }
                    .frame(width: 300)
                }
            }
            .padding(32)
            .frame(maxWidth: 900)
        }
        .frame(maxWidth: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Settings")
        .onAppear {
            loadAPIKey()
        }
        .alert("Settings", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showImportSheet) {
            DataImportView()
        }
    }
    
    private var apiKeyCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("OpenAI API Key", systemImage: "key.fill")
                    .font(.headline)
                    .foregroundStyle(.purple)
                
                Spacer()
                
                if isAPIKeyConfigured {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Configured")
                    }
                    .font(.caption)
                    .foregroundStyle(.green)
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text("Not Set")
                    }
                    .font(.caption)
                    .foregroundStyle(.orange)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Group {
                        if showAPIKey {
                            TextField("sk-...", text: $apiKey)
                        } else {
                            SecureField("sk-...", text: $apiKey)
                        }
                    }
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                    
                    Button {
                        showAPIKey.toggle()
                    } label: {
                        Image(systemName: showAPIKey ? "eye.slash" : "eye")
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.borderless)
                    
                    Button("Save") {
                        saveAPIKey()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(apiKey.isEmpty || isSaving)
                }
                
                Text("Your API key is stored securely in the Keychain and synced via iCloud Keychain.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Link("Get your key from platform.openai.com →", destination: URL(string: "https://platform.openai.com/api-keys")!)
                    .font(.caption)
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var dataManagementCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Data Management", systemImage: "externaldrive.fill")
                .font(.headline)
                .foregroundStyle(.blue)
            
            VStack(spacing: 12) {
                Button {
                    showImportSheet = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Import from Web App")
                                .font(.subheadline)
                            Text("Import JSON data exported from the web version")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                
                Button {
                    exportData()
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Export Data")
                                .font(.subheadline)
                            Text("Export your local data as JSON")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("About", systemImage: "info.circle.fill")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Version")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(appVersion)
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                
                Divider()
                
                HStack {
                    Text("Build")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(buildNumber)
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                
                Divider()
                
                Link(destination: URL(string: "https://joinleaderdojo.com")!) {
                    HStack {
                        Image(systemName: "globe")
                            .frame(width: 20)
                        Text("Visit Website")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                }
                
                Divider()
                
                Link(destination: URL(string: "https://joinleaderdojo.com/privacy")!) {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .frame(width: 20)
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                }
            }
        }
        .padding(20)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }
    
    #if DEBUG
    private var debugCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Debug", systemImage: "ladybug.fill")
                .font(.headline)
                .foregroundStyle(.red)
            
            VStack(spacing: 12) {
                Button(role: .destructive) {
                    // TODO: Implement data clearing
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .frame(width: 20)
                        Text("Clear All Data")
                        Spacer()
                    }
                    .font(.subheadline)
                    .padding(10)
                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
                
                Button {
                    // TODO: Implement sample data generation
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .frame(width: 20)
                        Text("Generate Sample Data")
                        Spacer()
                    }
                    .font(.subheadline)
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(.red.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.red.opacity(0.2), lineWidth: 1)
        )
    }
    #endif
    #endif
    
    // MARK: - Computed Properties
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    // MARK: - Methods
    
    private func loadAPIKey() {
        do {
            if let key = try KeychainManager.shared.retrieve(for: .openAIAPIKey) {
                apiKey = key
                isAPIKeyConfigured = true
            }
        } catch {
            print("Error loading API key: \(error)")
        }
    }
    
    private func saveAPIKey() {
        isSaving = true
        
        do {
            if apiKey.isEmpty {
                try KeychainManager.shared.delete(for: .openAIAPIKey)
                isAPIKeyConfigured = false
                alertMessage = "API key removed"
            } else {
                try KeychainManager.shared.save(apiKey, for: .openAIAPIKey)
                isAPIKeyConfigured = true
                alertMessage = "API key saved successfully"
            }
            showAlert = true
        } catch {
            alertMessage = "Failed to save API key: \(error.localizedDescription)"
            showAlert = true
        }
        
        isSaving = false
    }
    
    private func exportData() {
        // TODO: Implement data export
        alertMessage = "Export feature coming soon"
        showAlert = true
    }
}

// MARK: - Data Import View

struct DataImportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var importText: String = ""
    @State private var isImporting: Bool = false
    @State private var importResult: String = ""
    
    var body: some View {
        NavigationStack {
            #if os(macOS)
            macOSImportLayout
            #else
            iOSImportLayout
            #endif
        }
    }
    
    // MARK: - iOS Layout
    
    #if os(iOS)
    private var iOSImportLayout: some View {
        VStack(spacing: 20) {
            Text("Paste the JSON data exported from the Leader Dojo web app below:")
                .foregroundStyle(.secondary)
            
            TextEditor(text: $importText)
                .font(.system(.body, design: .monospaced))
                .frame(maxHeight: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            
            if !importResult.isEmpty {
                Text(importResult)
                    .font(.caption)
                    .foregroundStyle(importResult.contains("Error") ? .red : .green)
            }
            
            Button {
                importData()
            } label: {
                if isImporting {
                    ProgressView()
                        .progressViewStyle(.circular)
                } else {
                    Text("Import Data")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(importText.isEmpty || isImporting)
        }
        .padding()
        .navigationTitle("Import Data")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
    #endif
    
    // MARK: - macOS Layout
    
    #if os(macOS)
    private var macOSImportLayout: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Import Data")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Import from Leader Dojo web app")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Button {
                        importData()
                    } label: {
                        if isImporting {
                            ProgressView()
                                .scaleEffect(0.7)
                                .frame(width: 16, height: 16)
                        } else {
                            Text("Import")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(importText.isEmpty || isImporting)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            
            // Content
            VStack(spacing: 20) {
                // Instructions Card
                VStack(alignment: .leading, spacing: 12) {
                    Label("Instructions", systemImage: "info.circle")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        instructionRow(number: 1, text: "Export your data from the Leader Dojo web app")
                        instructionRow(number: 2, text: "Copy the JSON content from the exported file")
                        instructionRow(number: 3, text: "Paste it in the text area below")
                        instructionRow(number: 4, text: "Click Import to bring your data into the app")
                    }
                }
                .padding(16)
                .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.blue.opacity(0.2), lineWidth: 1)
                )
                
                // JSON Input Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("JSON Data", systemImage: "doc.text")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        if !importText.isEmpty {
                            Text("\(importText.count) characters")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    MacTextEditor(text: $importText, placeholder: "Paste your JSON data here...")
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                }
                .padding(20)
                .background(.background, in: RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
                
                // Result
                if !importResult.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: importResult.contains("Error") ? "xmark.circle.fill" : "checkmark.circle.fill")
                            .font(.title2)
                        
                        Text(importResult)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        if !importResult.contains("Error") {
                            Button("Done") {
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding(16)
                    .background(
                        importResult.contains("Error") ? Color.red.opacity(0.1) : Color.green.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                    .foregroundStyle(importResult.contains("Error") ? .red : .green)
                }
                
                Spacer()
            }
            .padding(24)
        }
        .frame(minWidth: 500, minHeight: 500)
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Import Data")
    }
    
    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(.blue, in: Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    #endif
    
    private func importData() {
        isImporting = true
        importResult = ""
        
        Task {
            do {
                let result = try await DataImportService.shared.importFromJSON(importText, into: modelContext)
                await MainActor.run {
                    importResult = "Successfully imported \(result.projects) projects, \(result.entries) entries, \(result.commitments) commitments, \(result.reflections) reflections"
                    isImporting = false
                }
            } catch {
                await MainActor.run {
                    importResult = "Error: \(error.localizedDescription)"
                    isImporting = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}



