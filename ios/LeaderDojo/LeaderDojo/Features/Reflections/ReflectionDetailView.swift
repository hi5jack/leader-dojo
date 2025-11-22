import SwiftUI

struct ReflectionDetailView: View {
    let reflection: Reflection

    var body: some View {
        List {
            Section("Stats") {
                ForEach(reflection.stats.keys.sorted(), id: \.self) { key in
                    if let value = reflection.stats[key] {
                        Text("\(key.capitalized): \(value)")
                    }
                }
            }

            Section("Questions & Answers") {
                ForEach(reflection.questionsAndAnswers) { qa in
                    VStack(alignment: .leading, spacing: LeaderDojoSpacing.s) {
                        Text(qa.question)
                            .font(LeaderDojoTypography.subheading)
                        Text(qa.answer)
                            .font(LeaderDojoTypography.body)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, LeaderDojoSpacing.s)
                }
            }
        }
        .navigationTitle("Reflection")
    }
}
