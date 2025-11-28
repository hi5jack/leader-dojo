import SwiftUI
import SwiftData

struct CaptureView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(sort: \Project.lastActiveAt, order: .reverse)
    private var allProjects: [Project]
    
    private var activeProjects: [Project] {
        allProjects.filter { $0.status == .active }
    }
    
    @State private var selectedProject: Project?
    @State private var noteContent: String = ""
    @State private var isSaving: Bool = false
    @State private var showToast: Bool = false
    @State private var toastMessage: String = ""
    
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Content area
                ScrollView {
                    VStack(spacing: 24) {
                        // Project selector
                        projectSelector
                        
                        // Text input
                        textInput
                        
                        // Quick tips
                        quickTips
                    }
                    .padding()
                }
                
                // Save button (fixed at bottom)
                saveButton
            }
            .navigationTitle("Quick Capture")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .onAppear {
                // Auto-select most recent project
                if selectedProject == nil {
                    selectedProject = activeProjects.first
                }
            }
            .overlay(alignment: .top) {
                if showToast {
                    toastView
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }
    
    // MARK: - Project Selector
    
    private var projectSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Project")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Menu {
                ForEach(activeProjects) { project in
                    Button {
                        selectedProject = project
                    } label: {
                        HStack {
                            Text(project.name)
                            if selectedProject?.id == project.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                Divider()
                
                NavigationLink {
                    NewProjectView()
                } label: {
                    Label("New Project", systemImage: "plus")
                }
            } label: {
                HStack {
                    if let project = selectedProject {
                        Image(systemName: project.type.icon)
                            .foregroundStyle(.secondary)
                        Text(project.name)
                            .foregroundStyle(.primary)
                    } else {
                        Text("Select a project")
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Text Input
    
    private var textInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Note")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(noteContent.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            TextEditor(text: $noteContent)
                .focused($isTextEditorFocused)
                .frame(minHeight: 200)
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(alignment: .topLeading) {
                    if noteContent.isEmpty {
                        Text("What's on your mind? Quick thoughts, observations, follow-ups...")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 28)
                            .allowsHitTesting(false)
                    }
                }
        }
    }
    
    // MARK: - Quick Tips
    
    private var quickTips: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Tips")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                tipRow(icon: "lightbulb.fill", text: "Capture thoughts immediately after conversations")
                tipRow(icon: "arrow.up.right", text: "Use \"I need to...\" to track your commitments")
                tipRow(icon: "arrow.down.left", text: "Use \"Waiting on...\" to track what others owe you")
                tipRow(icon: "checkmark.seal", text: "Note any decisions made for future reference")
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Save Button
    
    private var saveButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button {
                saveNote()
            } label: {
                HStack {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(isSaving ? "Saving..." : "Save Note")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canSave ? Color.accentColor : Color.gray, in: RoundedRectangle(cornerRadius: 12))
                .foregroundStyle(.white)
            }
            .disabled(!canSave || isSaving)
            .padding()
        }
        .background(.ultraThinMaterial)
    }
    
    // MARK: - Toast View
    
    private var toastView: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(toastMessage)
                .font(.subheadline)
        }
        .padding()
        .background(.ultraThickMaterial, in: Capsule())
        .shadow(radius: 10)
        .padding(.top, 8)
    }
    
    // MARK: - Computed Properties
    
    private var canSave: Bool {
        selectedProject != nil && !noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Actions
    
    private func saveNote() {
        guard let project = selectedProject else { return }
        
        isSaving = true
        isTextEditorFocused = false
        
        // Create the entry
        let entry = Entry(
            kind: .note,
            title: generateTitle(),
            occurredAt: Date(),
            rawContent: noteContent
        )
        entry.project = project
        
        modelContext.insert(entry)
        
        // Update project's last active timestamp
        project.markActive()
        
        do {
            try modelContext.save()
            
            // Show success toast
            toastMessage = "Note saved to \(project.name)"
            withAnimation {
                showToast = true
            }
            
            // Clear the form
            noteContent = ""
            
            // Hide toast after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showToast = false
                }
            }
        } catch {
            toastMessage = "Failed to save"
            withAnimation {
                showToast = true
            }
        }
        
        isSaving = false
    }
    
    private func generateTitle() -> String {
        // Generate a title from the first line or first few words
        let firstLine = noteContent
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
            .first ?? ""
        
        let words = firstLine.components(separatedBy: .whitespaces).prefix(8)
        var title = words.joined(separator: " ")
        
        if title.count > 50 {
            title = String(title.prefix(47)) + "..."
        } else if title.isEmpty {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            title = "Note - \(formatter.string(from: Date()))"
        }
        
        return title
    }
}

#Preview {
    CaptureView()
        .modelContainer(for: [Project.self, Entry.self, Commitment.self], inMemory: true)
}

