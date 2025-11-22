import SwiftUI

struct SignInView: View {
    @EnvironmentObject private var appEnvironment: AppEnvironment
    @StateObject private var viewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: LeaderDojoSpacing.l) {
                Spacer()
                VStack(spacing: LeaderDojoSpacing.s) {
                    Text("Leader Dojo")
                        .font(LeaderDojoTypography.heading)
                    Text("Sign in to continue")
                        .font(LeaderDojoTypography.body)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: LeaderDojoSpacing.m) {
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .padding()
                        .background(LeaderDojoColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                        .padding()
                        .background(LeaderDojoColors.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if let message = viewModel.errorMessage {
                    Text(message)
                        .font(LeaderDojoTypography.caption)
                        .foregroundStyle(.red)
                }

                Button(action: submit) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                        }
                        Text("Sign In")
                            .font(LeaderDojoTypography.subheading)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LeaderDojoColors.primaryAction)
                    .foregroundStyle(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(viewModel.isLoading)

                Spacer()
                Link("Need an account? Sign up on the web", destination: URL(string: "https://leaderdojo.com")!)
                    .font(LeaderDojoTypography.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(LeaderDojoSpacing.xl)
            .onAppear {
                viewModel.bind(environment: appEnvironment)
            }
        }
    }

    private func submit() {
        Task {
            await viewModel.signIn()
        }
    }
}
