import SwiftUI

struct ReflectionsListView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject private var viewModel = ReflectionsViewModel()
    @State private var showingWizard = false

    var body: some View {
        NavigationStack {
            List {
                if let message = viewModel.errorMessage {
                    Section {
                        Text(message)
                            .foregroundStyle(.red)
                    }
                }

                ForEach(viewModel.reflections) { reflection in
                    NavigationLink(destination: ReflectionDetailView(reflection: reflection)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(reflection.periodType.rawValue.capitalized)
                                .font(LeaderDojoTypography.subheading)
                            Text("\(reflection.periodStart.formattedShort()) - \(reflection.periodEnd.formattedShort())")
                                .font(LeaderDojoTypography.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Reflections")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("New Reflection") { showingWizard = true }
                }
            }
            .refreshable { await viewModel.load() }
            .sheet(isPresented: $showingWizard) {
                ReflectionWizardView {
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
}
