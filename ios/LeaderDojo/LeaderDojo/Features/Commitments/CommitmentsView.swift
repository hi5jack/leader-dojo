import SwiftUI

struct CommitmentsView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject private var viewModel = CommitmentsViewModel()
    @State private var selectedDirection: Commitment.Direction = .i_owe

    var body: some View {
        NavigationStack {
            List {
                if let message = viewModel.errorMessage {
                    Section {
                        Text(message)
                            .foregroundStyle(.red)
                    }
                }

                ForEach(commitmentsForSelectedDirection()) { commitment in
                    NavigationLink(destination: CommitmentDetailView(commitment: commitment)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(commitment.title)
                                .font(LeaderDojoTypography.subheading)
                            if let counterparty = commitment.counterparty {
                                Text(counterparty)
                                    .font(LeaderDojoTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                            if let due = commitment.dueDate {
                                Text("Due \(due.formattedShort())")
                                    .font(LeaderDojoTypography.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions {
                            Button("Done") {
                                Task {
                                    let input = UpdateCommitmentInput(status: .done, counterparty: nil, dueDate: nil, importance: nil, urgency: nil, notes: nil)
                                    await viewModel.update(commitment: commitment, input: input)
                                    await viewModel.load()
                                }
                            }
                            .tint(.green)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Commitments")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Direction", selection: $selectedDirection) {
                        Text("I Owe").tag(Commitment.Direction.i_owe)
                        Text("Waiting For").tag(Commitment.Direction.waiting_for)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 240)
                }
            }
            .refreshable { await viewModel.load() }
        }
        .onAppear {
            viewModel.configure(service: appEnvironment.commitmentsService)
        }
        .task {
            await viewModel.load()
        }
    }

    private func commitmentsForSelectedDirection() -> [Commitment] {
        selectedDirection == .i_owe ? viewModel.iOwe : viewModel.waitingFor
    }
}
