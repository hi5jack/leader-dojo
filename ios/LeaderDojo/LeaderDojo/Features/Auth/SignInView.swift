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
                        .dojoHeadingXL()
                    Text("Sign in to continue")
                        .dojoBodyMedium()
                        .foregroundStyle(LeaderDojoColors.textSecondary)
                }

                VStack(spacing: LeaderDojoSpacing.m) {
                    TextField("Email", text: $viewModel.email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .padding()
                        .background(LeaderDojoColors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                        .padding()
                        .background(LeaderDojoColors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if let message = viewModel.errorMessage {
                    Text(message)
                        .dojoCaptionLarge()
                        .foregroundStyle(LeaderDojoColors.dojoRed)
                }

                Button(action: submit) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                        }
                        Text("Sign In")
                            .font(LeaderDojoTypography.headingMedium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LeaderDojoColors.dojoAmber)
                    .foregroundStyle(LeaderDojoColors.dojoBlack)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(viewModel.isLoading)

                Spacer()
                Link("Need an account? Sign up on the web", destination: URL(string: "https://leaderdojo.com")!)
                    .dojoCaptionLarge()
                    .foregroundStyle(LeaderDojoColors.textSecondary)
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
