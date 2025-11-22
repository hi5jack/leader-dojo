import SwiftUI

struct ReflectionWizardView: View {
    let onComplete: (() async -> Void)?

    @EnvironmentObject private var appEnvironment: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    enum Step {
        case configure
        case answer
    }

    @State private var step: Step = .configure
    @State private var periodType: Reflection.PeriodType = .week
    @State private var periodStart: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var periodEnd: Date = Date()
    @State private var promptResponse: ReflectionPromptResponse?
    @State private var answers: [String: String] = [:]
    @State private var isGenerating = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("New Reflection")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        if step == .answer {
                            Button(action: save) {
                                if isSaving {
                                    ProgressView()
                                } else {
                                    Text("Save")
                                }
                            }
                            .disabled(isSaving)
                        }
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .configure:
            Form {
                Picker("Period", selection: $periodType) {
                    Text("Week").tag(Reflection.PeriodType.week)
                    Text("Month").tag(Reflection.PeriodType.month)
                    Text("Quarter").tag(Reflection.PeriodType.quarter)
                }
                DatePicker("Start", selection: $periodStart, displayedComponents: .date)
                DatePicker("End", selection: $periodEnd, displayedComponents: .date)

                if let message = errorMessage {
                    Section {
                        Text(message)
                            .foregroundStyle(.red)
                    }
                }

                Button(action: generate) {
                    if isGenerating {
                        ProgressView()
                    } else {
                        Text("Generate prompts")
                    }
                }
                .disabled(isGenerating)
            }
        case .answer:
            Form {
                if let promptResponse {
                    ForEach(promptResponse.questions, id: \.self) { question in
                        VStack(alignment: .leading, spacing: LeaderDojoSpacing.s) {
                            Text(question)
                                .dojoHeadingMedium()
                            TextField("Your answer", text: Binding(
                                get: { answers[question] ?? "" },
                                set: { answers[question] = $0 }
                            ), axis: .vertical)
                        }
                    }
                }

                if let message = errorMessage {
                    Section {
                        Text(message)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    private func generate() {
        errorMessage = nil
        isGenerating = true
        Task {
            do {
                let prompt = try await appEnvironment.reflectionsService.generateReflection(
                    periodType: periodType,
                    periodStart: periodStart,
                    periodEnd: periodEnd
                )
                promptResponse = prompt
                answers = Dictionary(uniqueKeysWithValues: prompt.questions.map { ($0, "") })
                step = .answer
            } catch {
                errorMessage = error.localizedDescription
            }
            isGenerating = false
        }
    }

    private func save() {
        guard promptResponse != nil else { return }
        let answerPayload = answers.map { ReflectionAnswerInput(question: $0.key, answer: $0.value) }
        let payload = ReflectionRequestInput(
            periodType: periodType,
            periodStart: periodStart,
            periodEnd: periodEnd,
            answers: answerPayload
        )

        isSaving = true
        errorMessage = nil
        Task {
            do {
                _ = try await appEnvironment.reflectionsService.saveReflection(payload: payload)
                if let onComplete {
                    await onComplete()
                }
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
