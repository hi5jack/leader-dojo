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
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
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
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
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

