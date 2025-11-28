import Foundation

/// AI Service for generating summaries, commitment suggestions, and reflection questions
actor AIService {
    static let shared = AIService()
    
    private var apiKey: String? {
        try? KeychainManager.shared.retrieve(for: .openAIAPIKey)
    }
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let model = "gpt-4o-mini"
    
    // MARK: - Public Methods
    
    /// Check if API key is configured
    var isConfigured: Bool {
        apiKey != nil && !(apiKey?.isEmpty ?? true)
    }
    
    /// Generate summary and commitment suggestions from meeting/update content
    func summarizeEntry(
        rawContent: String,
        projectName: String,
        entryKind: EntryKind
    ) async throws -> EntrySummaryResult {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AIServiceError.apiKeyNotConfigured
        }
        
        let systemPrompt = """
        You are an executive assistant helping a leader process meeting notes and updates.
        Analyze the content and provide:
        1. A structured summary (background, key points, decisions, open questions)
        2. A list of commitments (things the user owes others, or things others owe the user)
        
        Format your response as JSON with the following structure:
        {
            "summary": "Structured summary text",
            "commitments": [
                {
                    "direction": "i_owe" or "waiting_for",
                    "title": "Brief commitment description",
                    "counterparty": "Person or team name if mentioned"
                }
            ]
        }
        """
        
        let userPrompt = """
        Project: \(projectName)
        Entry Type: \(entryKind.displayName)
        
        Content:
        \(rawContent)
        """
        
        let response = try await sendChatCompletion(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            apiKey: apiKey
        )
        
        return try parseEntrySummaryResponse(response)
    }
    
    /// Generate prep briefing for an upcoming meeting
    func generatePrepBriefing(
        project: Project,
        recentEntries: [Entry],
        openCommitments: [Commitment]
    ) async throws -> PrepBriefingResult {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AIServiceError.apiKeyNotConfigured
        }
        
        let entriesSummary = recentEntries.prefix(10).map { entry in
            """
            - [\(entry.kind.displayName)] \(entry.title) (\(entry.occurredAt.formatted(date: .abbreviated, time: .omitted)))
              \(entry.displayContent)
            """
        }.joined(separator: "\n")
        
        let iOweCommitments = openCommitments.filter { $0.direction == .iOwe }
        let waitingForCommitments = openCommitments.filter { $0.direction == .waitingFor }
        
        let systemPrompt = """
        You are an executive coach helping a leader prepare for an important conversation.
        Generate a brief but insightful prep briefing that includes:
        1. Current project status (one sentence)
        2. Key events from the timeline
        3. Outstanding commitments to address
        4. Suggested talking points for the upcoming conversation
        
        Keep it concise and actionable.
        """
        
        let userPrompt = """
        Project: \(project.name)
        Priority: \(project.priority)/5
        Last Active: \(project.lastActiveAt?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")
        Owner Notes: \(project.ownerNotes ?? "None")
        
        Recent Timeline:
        \(entriesSummary.isEmpty ? "No recent entries" : entriesSummary)
        
        My Open Commitments (\(iOweCommitments.count)):
        \(iOweCommitments.map { "- \($0.title)" }.joined(separator: "\n"))
        
        Waiting For (\(waitingForCommitments.count)):
        \(waitingForCommitments.map { "- \($0.title) (from \($0.counterparty ?? "unknown"))" }.joined(separator: "\n"))
        """
        
        let response = try await sendChatCompletion(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            apiKey: apiKey
        )
        
        return PrepBriefingResult(briefing: response)
    }
    
    /// Generate reflection questions based on period statistics
    func generateReflectionQuestions(
        periodType: ReflectionPeriodType,
        stats: ReflectionStats
    ) async throws -> [String] {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AIServiceError.apiKeyNotConfigured
        }
        
        let systemPrompt = """
        You are a leadership coach helping a leader reflect on their recent work.
        Based on their activity statistics, generate 3-5 thoughtful reflection questions.
        Questions should help them:
        - Recognize patterns in their behavior
        - Learn from successes and challenges
        - Improve their leadership and decision-making
        
        Return only the questions as a JSON array of strings.
        """
        
        let userPrompt = """
        Reflection Period: \(periodType.displayName)
        
        Statistics:
        - Entries created: \(stats.entriesCreated)
        - Meetings held: \(stats.meetingsHeld)
        - Decisions recorded: \(stats.decisionsRecorded)
        - Commitments created: \(stats.commitmentsCreated)
        - Commitments completed: \(stats.commitmentsCompleted)
        - Open "I Owe" commitments: \(stats.iOweOpen)
        - Open "Waiting For" commitments: \(stats.waitingForOpen)
        - Active projects: \(stats.projectsActive)
        """
        
        let response = try await sendChatCompletion(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            apiKey: apiKey
        )
        
        return try parseQuestionsResponse(response)
    }
    
    // MARK: - Private Methods
    
    private func sendChatCompletion(
        systemPrompt: String,
        userPrompt: String,
        apiKey: String
    ) async throws -> String {
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.7,
            "max_tokens": 2000
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIServiceError.apiError(message)
            }
            throw AIServiceError.httpError(httpResponse.statusCode)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIServiceError.invalidResponse
        }
        
        return content
    }
    
    private func parseEntrySummaryResponse(_ response: String) throws -> EntrySummaryResult {
        // Try to extract JSON from the response
        let jsonString = extractJSON(from: response)
        
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // If parsing fails, return the raw response as summary
            return EntrySummaryResult(summary: response, suggestedActions: [])
        }
        
        let summary = json["summary"] as? String ?? response
        var actions: [SuggestedAction] = []
        
        if let commitments = json["commitments"] as? [[String: Any]] {
            for commitment in commitments {
                let directionStr = commitment["direction"] as? String ?? "i_owe"
                let direction: CommitmentDirection = directionStr == "waiting_for" ? .waitingFor : .iOwe
                let title = commitment["title"] as? String ?? ""
                let counterparty = commitment["counterparty"] as? String
                
                if !title.isEmpty {
                    actions.append(SuggestedAction(
                        direction: direction,
                        title: title,
                        counterparty: counterparty
                    ))
                }
            }
        }
        
        return EntrySummaryResult(summary: summary, suggestedActions: actions)
    }
    
    private func parseQuestionsResponse(_ response: String) throws -> [String] {
        let jsonString = extractJSON(from: response)
        
        guard let data = jsonString.data(using: .utf8),
              let questions = try? JSONSerialization.jsonObject(with: data) as? [String] else {
            // If parsing fails, split by newlines
            return response.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && $0.first != "{" && $0.first != "[" }
        }
        
        return questions
    }
    
    private func extractJSON(from text: String) -> String {
        // Find JSON object or array in the response
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }
        if let start = text.firstIndex(of: "["),
           let end = text.lastIndex(of: "]") {
            return String(text[start...end])
        }
        return text
    }
}

// MARK: - Result Types

struct EntrySummaryResult {
    let summary: String
    let suggestedActions: [SuggestedAction]
}

struct PrepBriefingResult {
    let briefing: String
}

// MARK: - Errors

enum AIServiceError: LocalizedError {
    case apiKeyNotConfigured
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "OpenAI API key not configured. Please add your API key in Settings."
        case .invalidResponse:
            return "Invalid response from AI service"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}

