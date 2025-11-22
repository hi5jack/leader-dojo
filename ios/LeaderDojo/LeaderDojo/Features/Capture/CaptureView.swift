import SwiftUI

struct CaptureView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject private var viewModel = CaptureViewModel()
    @State private var showSuccessAnimation = false
    @FocusState private var isNoteFieldFocused: Bool

    var body: some View {
        ZStack {
            // Background
            LeaderDojoColors.surfacePrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                header
                
                // Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: LeaderDojoSpacing.l) {
                        // Hero section
                        heroSection
                        
                        // Project selector
                        projectSection
                        
                        // Note editor
                        noteSection
                        
                        // Error message
                        if let message = viewModel.errorMessage {
                            HStack(spacing: LeaderDojoSpacing.m) {
                                Image(systemName: DojoIcons.error)
                                    .dojoIconMedium(color: LeaderDojoColors.dojoRed)
                                Text(message)
                                    .dojoBodyMedium()
                                    .foregroundStyle(LeaderDojoColors.dojoRed)
                            }
                            .dojoFlatCard()
                        }
                    }
                    .padding(.horizontal, LeaderDojoSpacing.ml)
                    .padding(.top, LeaderDojoSpacing.l)
                    .padding(.bottom, 120) // Space for save button
                }
                .scrollDismissesKeyboard(.interactively)
                
                Spacer()
                
                // Save button
                saveButton
            }
            
            // Success overlay
            if showSuccessAnimation {
                successOverlay
            }
        }
        .onAppear {
            viewModel.configure(service: appEnvironment.projectsService)
        }
        .task {
            await viewModel.loadProjects()
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button {
                    save()
                } label: {
                    Text(viewModel.isSaving ? "Saving..." : "Save")
                        .fontWeight(.semibold)
                }
                .disabled(viewModel.note.isEmpty || viewModel.isSaving)
                
                Spacer()
                
                Button("Done") {
                    isNoteFieldFocused = false
                }
                .fontWeight(.semibold)
            }
        }
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: LeaderDojoSpacing.xs) {
                Text("QUICK CAPTURE")
                    .dojoLabel()
                    .foregroundStyle(LeaderDojoColors.dojoAmber)
                
                Text("Capture Your Thoughts")
                    .dojoHeadingLarge()
            }
            
            Spacer()
        }
        .padding(.horizontal, LeaderDojoSpacing.ml)
        .padding(.top, LeaderDojoSpacing.l)
        .padding(.bottom, LeaderDojoSpacing.m)
    }
    
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.s) {
            Image(systemName: DojoIcons.capture)
                .dojoIconXXL(color: LeaderDojoColors.dojoAmber)
            
            Text("Capture insights, notes, and reflections on the go")
                .dojoBodyLarge()
                .foregroundStyle(LeaderDojoColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var projectSection: some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.m) {
            VStack(alignment: .leading, spacing: LeaderDojoSpacing.xs) {
                Text("Select Project")
                    .dojoHeadingMedium()
                Text("Link this note to a project")
                    .dojoCaptionRegular()
            }
            
            if viewModel.projects.isEmpty {
                HStack(spacing: LeaderDojoSpacing.m) {
                    ProgressView()
                        .tint(LeaderDojoColors.dojoAmber)
                    Text("Loading projects...")
                        .dojoBodyMedium()
                        .foregroundStyle(LeaderDojoColors.textSecondary)
                }
                .dojoFlatCard()
            } else {
                // Project picker
                Menu {
                    ForEach(viewModel.projects) { project in
                        Button(action: {
                            Haptics.selection()
                            viewModel.selectedProjectId = project.id
                            viewModel.newProjectName = ""
                        }) {
                            HStack {
                                Text(project.name)
                                if viewModel.selectedProjectId == project.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack {
                        if let selectedProject = viewModel.projects.first(where: { $0.id == viewModel.selectedProjectId }) {
                            VStack(alignment: .leading, spacing: LeaderDojoSpacing.xs) {
                                Text(selectedProject.name)
                                    .dojoBodyLarge()
                                    .foregroundStyle(LeaderDojoColors.textPrimary)
                                Text(selectedProject.type.rawValue.capitalized)
                                    .dojoCaptionRegular()
                            }
                        } else {
                            Text("Select a project")
                                .dojoBodyLarge()
                                .foregroundStyle(LeaderDojoColors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .dojoIconSmall(color: LeaderDojoColors.textTertiary)
                    }
                    .padding(LeaderDojoSpacing.m)
                    .background(LeaderDojoColors.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusMedium, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusMedium, style: .continuous)
                            .strokeBorder(LeaderDojoColors.dojoDarkGray, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                
                // Or create new project
                VStack(alignment: .leading, spacing: LeaderDojoSpacing.xs) {
                    Text("Or create new project")
                        .dojoCaptionLarge()
                    
                    TextField("New project name", text: $viewModel.newProjectName)
                        .dojoBodyLarge()
                        .padding(LeaderDojoSpacing.m)
                        .background(LeaderDojoColors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusMedium, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusMedium, style: .continuous)
                                .strokeBorder(
                                    viewModel.newProjectName.isEmpty ? LeaderDojoColors.dojoDarkGray : LeaderDojoColors.dojoAmber,
                                    lineWidth: viewModel.newProjectName.isEmpty ? 1 : 2
                                )
                        )
                        .textInputAutocapitalization(.words)
                        .onChange(of: viewModel.newProjectName) { _, newValue in
                            if !newValue.isEmpty {
                                viewModel.selectedProjectId = nil
                            }
                        }
                }
            }
        }
    }
    
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: LeaderDojoSpacing.m) {
            VStack(alignment: .leading, spacing: LeaderDojoSpacing.xs) {
                Text("Your Note")
                    .dojoHeadingMedium()
                Text("What's on your mind?")
                    .dojoCaptionRegular()
            }
            
            ZStack(alignment: .topLeading) {
                if viewModel.note.isEmpty {
                    Text("Capture your thoughts, insights, concerns, or any observations about this project...")
                        .dojoBodyMedium()
                        .foregroundStyle(LeaderDojoColors.textTertiary)
                        .padding(LeaderDojoSpacing.m)
                }
                
                TextEditor(text: $viewModel.note)
                    .dojoBodyLarge()
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 200)
                    .padding(LeaderDojoSpacing.s)
                    .focused($isNoteFieldFocused)
            }
            .background(LeaderDojoColors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LeaderDojoSpacing.cornerRadiusMedium, style: .continuous)
                    .strokeBorder(
                        isNoteFieldFocused ? LeaderDojoColors.dojoAmber : LeaderDojoColors.dojoDarkGray,
                        lineWidth: isNoteFieldFocused ? 2 : 1
                    )
            )
            
            // Character count
            HStack {
                Spacer()
                Text("\(viewModel.note.count) characters")
                    .dojoCaptionRegular()
            }
        }
    }
    
    private var saveButton: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            LeaderDojoColors.dojoDarkGray
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 1)
            
            Button(action: save) {
                if viewModel.isSaving {
                    HStack(spacing: LeaderDojoSpacing.m) {
                        ProgressView()
                            .tint(LeaderDojoColors.dojoBlack)
                        Text("Saving...")
                            .font(LeaderDojoTypography.bodyLarge)
                            .fontWeight(.semibold)
                    }
                } else {
                    HStack(spacing: LeaderDojoSpacing.m) {
                        Image(systemName: "arrow.down.doc.fill")
                            .dojoIconMedium(color: LeaderDojoColors.dojoBlack)
                        Text("Save Note")
                            .font(LeaderDojoTypography.bodyLarge)
                            .fontWeight(.semibold)
                    }
                }
            }
            .buttonStyle(.dojoPrimary)
            .disabled(viewModel.note.isEmpty || viewModel.isSaving)
            .padding(.horizontal, LeaderDojoSpacing.ml)
            .padding(.vertical, LeaderDojoSpacing.m)
            .background(LeaderDojoColors.surfacePrimary)
        }
    }
    
    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: LeaderDojoSpacing.l) {
                Image(systemName: DojoIcons.success)
                    .font(.system(size: 80))
                    .foregroundStyle(LeaderDojoColors.dojoGreen)
                    .scaleEffect(showSuccessAnimation ? 1.0 : 0.5)
                    .opacity(showSuccessAnimation ? 1.0 : 0.0)
                
                Text("Note Captured!")
                    .dojoHeadingLarge()
                    .opacity(showSuccessAnimation ? 1.0 : 0.0)
            }
        }
        .onAppear {
            withAnimation(LeaderDojoAnimation.completion) {
                showSuccessAnimation = true
            }
        }
    }

    private func save() {
        guard !viewModel.note.isEmpty, !viewModel.isSaving else {
            isNoteFieldFocused = false
            return
        }
        
        isNoteFieldFocused = false
        
        Task {
            do {
                Haptics.entryCreated()
                try await viewModel.saveNote()
                
                // Show success animation
                withAnimation {
                    showSuccessAnimation = true
                }
                
                // Wait and reset
                try await Task.sleep(nanoseconds: 1_500_000_000)
                
                withAnimation {
                    showSuccessAnimation = false
                    viewModel.note = ""
                    viewModel.newProjectName = ""
                    viewModel.errorMessage = nil
                }
                
                Haptics.success()
            } catch {
                Haptics.error()
                viewModel.errorMessage = error.localizedDescription
            }
        }
    }
}
