import Foundation

/// AI Service for generating summaries, commitment suggestions, and reflection questions
actor AIService {
    static let shared = AIService()
    
    private var apiKey: String? {
        try? KeychainManager.shared.retrieve(for: .openAIAPIKey)
    }
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let transcriptionURL = "https://api.openai.com/v1/audio/transcriptions"
    private let model = "gpt-4o-mini"
    private let transcriptionModel = "gpt-4o-mini-transcribe"
    
    /// Timeout for AI requests (Guardrail: Reflection is never blocked by AI)
    /// Increased to 15s to reduce unintended fallbacks to generic default questions,
    /// especially on slower mobile networks.
    private let requestTimeout: TimeInterval = 15.0
    
    // MARK: - Public Methods
    
    /// Check if API key is configured
    var isConfigured: Bool {
        apiKey != nil && !(apiKey?.isEmpty ?? true)
    }
    
    // MARK: - Audio Transcription
    
    /// Transcribe audio using OpenAI's Whisper API with automatic formatting
    /// - Parameter audioData: Audio data in m4a format
    /// - Returns: Transcribed and formatted text
    func transcribeAudio(_ audioData: Data) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AIServiceError.apiKeyNotConfigured
        }
        
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: transcriptionURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build multipart form data
        var body = Data()
        
        // Add model field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(transcriptionModel)\r\n".data(using: .utf8)!)
        
        // Add prompt field for formatting guidance
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        body.append("Transcribe and format into readable paragraphs. Add line breaks between distinct topics or thoughts.\r\n".data(using: .utf8)!)
        
        // Add audio file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
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
        
        // Parse transcription response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let text = json["text"] as? String else {
            throw AIServiceError.invalidResponse
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
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
        
        // Use decision-specific prompt for decision entries
        let systemPrompt: String
        if entryKind == .decision {
            systemPrompt = """
            You are an executive coach helping a leader document and analyze an important decision.
            Analyze the decision content and provide:
            1. A structured summary of the decision (what was decided, context, rationale)
            2. Key assumptions that underlie this decision
            3. Suggested review timeframe based on the decision type
            4. A list of any commitments that arise from this decision
            
            Format your response as JSON with the following structure:
            {
                "summary": "Structured summary of the decision",
                "assumptions": "Key assumptions that must be true for this decision to succeed (as bullet points)",
                "suggestedReviewDays": 30,
                "commitments": [
                    {
                        "direction": "i_owe" or "waiting_for",
                        "title": "Brief commitment description",
                        "counterparty": "Person or team name if mentioned"
                    }
                ]
            }
            
            For suggestedReviewDays:
            - Strategic decisions: 90 days
            - Hiring/team decisions: 60 days
            - Process changes: 30 days
            - Tactical decisions: 14 days
            """
        } else {
            systemPrompt = """
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
        }
        
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
        
        return try parseEntrySummaryResponse(response, isDecision: entryKind == .decision)
    }
    
    /// Generate prep briefing for an upcoming meeting
    func generatePrepBriefing(
        project: Project,
        recentEntries: [Entry],
        openCommitments: [Commitment],
        relevantReflections: [Reflection] = []  // NEW: Include past reflection insights
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
        
        // NEW: Include relevant reflection insights
        let reflectionInsights = relevantReflections.prefix(3).compactMap { reflection -> String? in
            let answers = reflection.questionsAnswers.filter { !$0.answer.isEmpty }
            guard !answers.isEmpty else { return nil }
            let date = reflection.createdAt.formatted(date: .abbreviated, time: .omitted)
            let insight = answers.first?.answer.prefix(200) ?? ""
            return "- [\(date)] \(insight)..."
        }.joined(separator: "\n")
        
        let systemPrompt = """
        You are an executive coach helping a leader prepare for an important conversation.
        Generate a brief but insightful prep briefing that includes:
        1. Current project status (one sentence)
        2. Key events from the timeline
        3. Outstanding commitments to address
        4. Relevant insights from past reflections (if provided)
        5. Suggested talking points for the upcoming conversation
        
        Keep it concise and actionable.
        """
        
        var userPrompt = """
        Project: \(project.name)
        Priority: \(project.priority)/5
        Last Active: \(project.lastActiveAt?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")
        Owner Notes: \(project.ownerNotes ?? "None")
        
        Recent Timeline:
        \(entriesSummary.isEmpty ? "No recent entries" : entriesSummary)
        
        My Open Commitments (\(iOweCommitments.count)):
        \(iOweCommitments.map { "- \($0.title)" }.joined(separator: "\n"))
        
        Waiting For (\(waitingForCommitments.count)):
        \(waitingForCommitments.map { "- \($0.title) (from \($0.person?.name ?? "unknown"))" }.joined(separator: "\n"))
        """
        
        // Add reflection insights if available
        if !reflectionInsights.isEmpty {
            userPrompt += """
            
            Past Reflection Insights:
            \(reflectionInsights)
            """
        }
        
        let response = try await sendChatCompletion(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            apiKey: apiKey
        )
        
        return PrepBriefingResult(briefing: response)
    }
    
    // MARK: - Enhanced Reflection Question Generation
    
    /// Generate context-rich reflection questions based on specific events (NEW)
    func generateContextualReflectionQuestions(
        reflectionType: ReflectionType,
        periodType: ReflectionPeriodType? = nil,
        stats: ReflectionStats,
        selectedEntries: [Entry] = [],
        project: Project? = nil,
        person: Person? = nil,
        openCommitments: [Commitment] = []
    ) async throws -> ContextualReflectionResult {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AIServiceError.apiKeyNotConfigured
        }
        
        let (systemPrompt, userPrompt) = buildReflectionPrompt(
            reflectionType: reflectionType,
            periodType: periodType,
            stats: stats,
            selectedEntries: selectedEntries,
            project: project,
            person: person,
            openCommitments: openCommitments
        )
        
        let response = try await sendChatCompletionWithTimeout(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            apiKey: apiKey,
            timeout: requestTimeout
        )
        
        return try parseContextualReflectionResponse(response, selectedEntries: selectedEntries)
    }
    
    /// Generate reflection questions and suggestions based on period statistics (legacy support)
    func generateReflectionQuestions(
        periodType: ReflectionPeriodType,
        stats: ReflectionStats
    ) async throws -> ReflectionPromptsResult {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AIServiceError.apiKeyNotConfigured
        }
        
        let systemPrompt = """
        You are a leadership coach helping a leader reflect on their recent work.
        Based on their activity statistics:
        1. Generate 3-5 thoughtful reflection questions that help them recognize patterns, learn from experiences, and improve decision-making
        2. Provide 2-3 actionable suggestions for improvement based on the stats
        
        Return as JSON with structure:
        {
            "questions": ["question1", "question2", ...],
            "suggestions": ["suggestion1", "suggestion2", ...]
        }
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
        
        return try parseReflectionPromptsResponse(response)
    }
    
    /// Generate a quick reflection question for a specific entry (NEW)
    func generateQuickReflectionQuestion(
        entry: Entry
    ) async throws -> String {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AIServiceError.apiKeyNotConfigured
        }
        
        let systemPrompt = """
        You are a leadership coach. Generate ONE short, thought-provoking question to help the user reflect on this recent activity.
        The question should be specific to what happened, not generic.
        Keep it under 15 words. Return just the question, no formatting.
        """
        
        let userPrompt = """
        Entry Type: \(entry.kind.displayName)
        Title: \(entry.title)
        Content: \(entry.displayContent.prefix(500))
        \(entry.isDecision ? "This was marked as an important decision." : "")
        """
        
        let response = try await sendChatCompletionWithTimeout(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            apiKey: apiKey,
            timeout: 8.0  // Slightly longer timeout for quick reflections
        )
        
        return response.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Extract leadership themes/tags from reflection answers (NEW)
    func extractReflectionThemes(
        questionsAnswers: [ReflectionQA]
    ) async throws -> [String] {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            return []  // Don't throw, just return empty - tagging is optional
        }
        
        let answeredQAs = questionsAnswers.filter { !$0.answer.isEmpty }
        guard !answeredQAs.isEmpty else { return [] }
        
        let systemPrompt = """
        You are analyzing leadership reflection answers. Extract 1-3 key themes from the answers.
        Themes should be common leadership topics like: delegation, feedback, conflict, decision-making, 
        communication, time-management, prioritization, team-building, accountability, etc.
        
        Return as JSON array of lowercase theme strings: ["theme1", "theme2"]
        """
        
        let content = answeredQAs.map { "Q: \($0.question)\nA: \($0.answer)" }.joined(separator: "\n\n")
        
        let response = try await sendChatCompletionWithTimeout(
            systemPrompt: systemPrompt,
            userPrompt: content,
            apiKey: apiKey,
            timeout: 5.0
        )
        
        return parseThemesResponse(response)
    }
    
    /// Analyze decision-making patterns and generate insights (NEW)
    func analyzeDecisionPatterns(
        decisions: [Entry]
    ) async throws -> DecisionPatternAnalysis {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            throw AIServiceError.apiKeyNotConfigured
        }
        
        guard decisions.count >= 3 else {
            // Not enough decisions for meaningful pattern analysis
            return DecisionPatternAnalysis(
                calibrationInsight: nil,
                stakesPatternInsight: nil,
                timingInsight: nil,
                overallRecommendation: "Record more decisions to see pattern insights. You need at least 3 reviewed decisions."
            )
        }
        
        // Prepare decision data for analysis
        let decisionData = decisions.prefix(20).map { entry -> String in
            let outcome = entry.decisionOutcome?.rawValue ?? "pending"
            let confidence = entry.decisionConfidence ?? 3
            let stakes = entry.decisionStakes?.rawValue ?? "medium"
            let daysSinceDecision = Calendar.current.dateComponents([.day], from: entry.occurredAt, to: Date()).day ?? 0
            
            return """
            - Title: \(entry.title)
              Stakes: \(stakes)
              Confidence: \(confidence)/5
              Outcome: \(outcome)
              Days ago: \(daysSinceDecision)
              Rationale: \(entry.decisionRationale?.prefix(100) ?? "Not recorded")
              Learning: \(entry.decisionLearning?.prefix(100) ?? "Not recorded")
            """
        }.joined(separator: "\n\n")
        
        // Calculate basic stats for context
        let reviewedDecisions = decisions.filter { $0.hasBeenReviewed }
        let validatedCount = reviewedDecisions.filter { $0.decisionOutcome == .validated }.count
        let validationRate = reviewedDecisions.isEmpty ? 0 : Int(Double(validatedCount) / Double(reviewedDecisions.count) * 100)
        
        let highStakesDecisions = decisions.filter { $0.decisionStakes == .high }
        let highStakesValidated = highStakesDecisions.filter { $0.decisionOutcome == .validated }.count
        
        let systemPrompt = """
        You are a leadership coach analyzing a leader's decision-making patterns.
        
        Based on their decision history, provide:
        1. Calibration insight: How well does their confidence match outcomes?
        2. Stakes pattern insight: Any patterns in high vs low stakes decisions?
        3. Timing insight: Are decisions being reviewed at appropriate intervals?
        4. Overall recommendation: One actionable suggestion for better decision-making
        
        Be specific and reference actual patterns you see. Keep each insight to 1-2 sentences.
        
        Return as JSON:
        {
            "calibrationInsight": "Insight about confidence calibration...",
            "stakesPatternInsight": "Insight about stakes patterns...",
            "timingInsight": "Insight about review timing...",
            "overallRecommendation": "One key suggestion..."
        }
        """
        
        let userPrompt = """
        Decision History Analysis:
        
        Total decisions: \(decisions.count)
        Reviewed decisions: \(reviewedDecisions.count)
        Overall validation rate: \(validationRate)%
        High-stakes decisions: \(highStakesDecisions.count)
        High-stakes validated: \(highStakesValidated)
        
        Recent Decisions:
        \(decisionData)
        """
        
        let response = try await sendChatCompletionWithTimeout(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            apiKey: apiKey,
            timeout: 12.0
        )
        
        return try parseDecisionPatternResponse(response)
    }
    
    // MARK: - Private Methods
    
    private func buildReflectionPrompt(
        reflectionType: ReflectionType,
        periodType: ReflectionPeriodType?,
        stats: ReflectionStats,
        selectedEntries: [Entry],
        project: Project?,
        person: Person?,
        openCommitments: [Commitment]
    ) -> (system: String, user: String) {
        
        switch reflectionType {
        case .quick:
            return buildQuickReflectionPrompt(entries: selectedEntries)
            
        case .periodic:
            return buildPeriodicReflectionPrompt(
                periodType: periodType ?? .week,
                stats: stats,
                selectedEntries: selectedEntries,
                openCommitments: openCommitments
            )
            
        case .project:
            return buildProjectReflectionPrompt(
                project: project,
                stats: stats,
                selectedEntries: selectedEntries,
                openCommitments: openCommitments
            )
            
        case .relationship:
            return buildRelationshipReflectionPrompt(
                person: person,
                selectedEntries: selectedEntries,
                openCommitments: openCommitments
            )
        }
    }
    
    private func buildQuickReflectionPrompt(entries: [Entry]) -> (String, String) {
        let systemPrompt = """
        Generate ONE concise reflection question about this activity.
        Return as JSON: {"question": "Your question here?"}
        """
        
        let entry = entries.first
        let userPrompt = """
        Entry: \(entry?.kind.displayName ?? "Activity") - \(entry?.title ?? "")
        Content: \(entry?.displayContent.prefix(300) ?? "")
        """
        
        return (systemPrompt, userPrompt)
    }
    
    private func buildPeriodicReflectionPrompt(
        periodType: ReflectionPeriodType,
        stats: ReflectionStats,
        selectedEntries: [Entry],
        openCommitments: [Commitment]
    ) -> (String, String) {
        
        let systemPrompt = """
        You are a leadership coach helping a leader reflect on their \(periodType.displayName.lowercased()) work.
        
        Based on their specific activities and statistics:
        1. Generate 3-5 thoughtful, SPECIFIC reflection questions
        2. Reference events by their TITLE (e.g., "your meeting about X"), NEVER by ID or UUID
        3. Include at least one question about patterns or recurring themes
        4. Include at least one forward-looking question
        5. Provide 2-3 actionable suggestions
        
        IMPORTANT:
        - In question TEXT, refer to events by title/description, NEVER include UUIDs
        - Use "linkedEntryId" ONLY in JSON structure to link questions to events (metadata for the app)
        
        Return as JSON:
        {
            "questions": [
                {"text": "Human-readable question without IDs", "linkedEntryId": "uuid or null"}
            ],
            "suggestions": ["suggestion1", "suggestion2"]
        }
        """
        
        // Build context from selected entries
        let entriesContext = selectedEntries.prefix(5).enumerated().map { index, entry in
            """
            Event \(index + 1):
              ID (for linkedEntryId only): \(entry.id.uuidString)
              Type: \(entry.kind.displayName)
              Title: "\(entry.title)"
              Content: \(entry.displayContent.prefix(150))...
              \(entry.isDecision ? "Note: Key decision" : "")
            """
        }.joined(separator: "\n\n")
        
        let iOweCount = openCommitments.filter { $0.direction == .iOwe }.count
        let waitingCount = openCommitments.filter { $0.direction == .waitingFor }.count
        
        let userPrompt = """
        Reflection Period: \(periodType.displayName)
        
        Statistics:
        - Entries created: \(stats.entriesCreated)
        - Meetings held: \(stats.meetingsHeld)
        - Decisions recorded: \(stats.decisionsRecorded)
        - Commitments created: \(stats.commitmentsCreated)
        - Commitments completed: \(stats.commitmentsCompleted)
        - Open commitments I owe: \(iOweCount)
        - Open commitments waiting for: \(waitingCount)
        
        Key Events This Period:
        \(entriesContext.isEmpty ? "No specific events selected" : entriesContext)
        
        Remember: Reference events by TITLE in questions, use linkedEntryId only for metadata.
        """
        
        return (systemPrompt, userPrompt)
    }
    
    private func buildProjectReflectionPrompt(
        project: Project?,
        stats: ReflectionStats,
        selectedEntries: [Entry],
        openCommitments: [Commitment]
    ) -> (String, String) {
        
        let systemPrompt = """
        You are a leadership coach helping a leader reflect on their approach to a specific project.
        
        Generate 3-4 reflection questions that:
        1. Are specific to this project's situation
        2. Reference concrete events by their TITLE (e.g., "the meeting about X" or "your note on Y"), NOT by ID
        3. Address leadership behaviors, not just project status
        4. Surface potential blind spots
        5. Encourage honest self-assessment
        
        IMPORTANT: 
        - In the question TEXT, refer to events by their title or description, NEVER include UUIDs or IDs
        - Use "linkedEntryId" ONLY in the JSON structure to link the question to an event
        - The linkedEntryId is metadata for the app, not part of the question the user sees
        
        Return as JSON:
        {
            "questions": [{"text": "Human-readable question without IDs", "linkedEntryId": "uuid-or-null"}],
            "suggestions": ["suggestion1"]
        }
        
        Example good question: "In your meeting about the Q4 roadmap, how effectively did you communicate priorities?"
        Example BAD question: "Regarding entry ID A7711AF6-..., how did you handle it?" (NEVER do this)
        """
        
        let projectCommitments = openCommitments.filter { $0.project?.id == project?.id }
        let iOweCount = projectCommitments.filter { $0.direction == .iOwe }.count
        let waitingCount = projectCommitments.filter { $0.direction == .waitingFor }.count
        let overdueCount = projectCommitments.filter { $0.isOverdue }.count
        
        let entriesContext = selectedEntries.prefix(5).enumerated().map { index, entry in
            """
            Event \(index + 1):
              ID (for linkedEntryId only): \(entry.id.uuidString)
              Type: \(entry.kind.displayName)
              Title: "\(entry.title)"
              Content: \(entry.displayContent.prefix(160))...
              \(entry.isDecision ? "Note: This was marked as a key decision" : "")
            """
        }.joined(separator: "\n\n")
        
        let userPrompt = """
        Project: \(project?.name ?? "Unknown")
        Priority: \(project?.priority ?? 3)/5
        Status: \(project?.status.displayName ?? "Active")
        Days Since Last Activity: \(project?.daysSinceLastActive ?? 0)
        
        Commitment Status:
        - I owe \(iOweCount) commitments
        - Waiting for \(waitingCount) commitments
        - \(overdueCount) commitments are overdue
        
        Selected Events to Reflect On:
        \(entriesContext.isEmpty ? "No events selected" : entriesContext)
        
        Owner Notes: \(project?.ownerNotes ?? "None")
        
        Remember: Reference events by their TITLE in questions, use linkedEntryId only for metadata.
        """
        
        return (systemPrompt, userPrompt)
    }
    
    private func buildRelationshipReflectionPrompt(
        person: Person?,
        selectedEntries: [Entry],
        openCommitments: [Commitment]
    ) -> (String, String) {
        
        let systemPrompt = """
        You are a leadership coach helping a leader reflect on an important professional relationship.
        
        Generate 3-4 reflection questions that:
        1. Focus on how the leader is showing up for this person
        2. Address relationship dynamics, not just tasks
        3. Surface potential tensions or opportunities
        4. Are specific to the relationship context provided
        
        Return as JSON:
        {
            "questions": [{"text": "Question", "linkedEntryId": null}],
            "suggestions": ["suggestion1"]
        }
        """
        
        let personCommitments = openCommitments.filter { $0.person?.id == person?.id }
        let iOweCount = personCommitments.filter { $0.direction == .iOwe }.count
        let waitingCount = personCommitments.filter { $0.direction == .waitingFor }.count
        
        let entriesContext = selectedEntries.prefix(3).map { entry in
            "- \(entry.kind.displayName): \(entry.title)"
        }.joined(separator: "\n")
        
        let userPrompt = """
        Person: \(person?.name ?? "Unknown")
        Relationship Type: \(person?.relationshipType?.displayName ?? "Unknown")
        Organization: \(person?.organization ?? "Unknown")
        Role: \(person?.role ?? "Unknown")
        
        Commitment Status:
        - I owe them: \(iOweCount) commitments
        - They owe me: \(waitingCount) commitments
        
        Recent Interactions:
        \(entriesContext.isEmpty ? "No recent entries" : entriesContext)
        
        Days Since Last Interaction: \(person?.daysSinceLastInteraction ?? 0)
        """
        
        return (systemPrompt, userPrompt)
    }
    
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
    
    /// Send chat completion with timeout (Guardrail: Reflection is never blocked by AI)
    private func sendChatCompletionWithTimeout(
        systemPrompt: String,
        userPrompt: String,
        apiKey: String,
        timeout: TimeInterval
    ) async throws -> String {
        try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask {
                try await self.sendChatCompletion(
                    systemPrompt: systemPrompt,
                    userPrompt: userPrompt,
                    apiKey: apiKey
                )
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw AIServiceError.timeout
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    private func parseEntrySummaryResponse(_ response: String, isDecision: Bool = false) throws -> EntrySummaryResult {
        let jsonString = extractJSON(from: response)
        
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return EntrySummaryResult(summary: response, suggestedActions: [], assumptions: nil, suggestedReviewDays: nil)
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
        
        // Parse decision-specific fields
        var assumptions: String? = nil
        var suggestedReviewDays: Int? = nil
        
        if isDecision {
            assumptions = json["assumptions"] as? String
            suggestedReviewDays = json["suggestedReviewDays"] as? Int
        }
        
        return EntrySummaryResult(
            summary: summary,
            suggestedActions: actions,
            assumptions: assumptions,
            suggestedReviewDays: suggestedReviewDays
        )
    }
    
    private func parseReflectionPromptsResponse(_ response: String) throws -> ReflectionPromptsResult {
        let jsonString = extractJSON(from: response)
        
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let questions = response.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && $0.first != "{" && $0.first != "[" }
            return ReflectionPromptsResult(questions: questions, suggestions: [])
        }
        
        let questions = json["questions"] as? [String] ?? []
        let suggestions = json["suggestions"] as? [String] ?? []
        
        return ReflectionPromptsResult(questions: questions, suggestions: suggestions)
    }
    
    private func parseContextualReflectionResponse(_ response: String, selectedEntries: [Entry]) throws -> ContextualReflectionResult {
        let jsonString = extractJSON(from: response)
        
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // Fallback: try to extract questions from plain text
            let questions = response.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && $0.first != "{" && $0.first != "[" }
                .map { ContextualQuestion(text: $0, linkedEntryId: nil) }
            return ContextualReflectionResult(questions: questions, suggestions: [])
        }
        
        var questions: [ContextualQuestion] = []
        
        // Parse questions with optional entry links
        if let questionsArray = json["questions"] as? [[String: Any]] {
            for q in questionsArray {
                let text = q["text"] as? String ?? ""
                var linkedEntryId: UUID? = nil
                if let idString = q["linkedEntryId"] as? String {
                    linkedEntryId = UUID(uuidString: idString)
                }
                if !text.isEmpty {
                    questions.append(ContextualQuestion(text: text, linkedEntryId: linkedEntryId))
                }
            }
        } else if let simpleQuestions = json["questions"] as? [String] {
            questions = simpleQuestions.map { ContextualQuestion(text: $0, linkedEntryId: nil) }
        }
        
        let suggestions = json["suggestions"] as? [String] ?? []
        
        return ContextualReflectionResult(questions: questions, suggestions: suggestions)
    }
    
    private func parseThemesResponse(_ response: String) -> [String] {
        let jsonString = extractJSON(from: response)
        
        guard let data = jsonString.data(using: .utf8),
              let themes = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        
        return themes.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    private func parseDecisionPatternResponse(_ response: String) throws -> DecisionPatternAnalysis {
        let jsonString = extractJSON(from: response)
        
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // Fallback if JSON parsing fails
            return DecisionPatternAnalysis(
                calibrationInsight: nil,
                stakesPatternInsight: nil,
                timingInsight: nil,
                overallRecommendation: response.prefix(200).description
            )
        }
        
        return DecisionPatternAnalysis(
            calibrationInsight: json["calibrationInsight"] as? String,
            stakesPatternInsight: json["stakesPatternInsight"] as? String,
            timingInsight: json["timingInsight"] as? String,
            overallRecommendation: json["overallRecommendation"] as? String ?? "Continue tracking your decisions to build better insights."
        )
    }
    
    private func extractJSON(from text: String) -> String {
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
    
    // Decision-specific fields
    let assumptions: String?
    let suggestedReviewDays: Int?
}

struct PrepBriefingResult {
    let briefing: String
}

struct ReflectionPromptsResult {
    let questions: [String]
    let suggestions: [String]
}

/// NEW: Contextual question with optional link to specific entry
struct ContextualQuestion: Sendable {
    let text: String
    let linkedEntryId: UUID?
}

/// NEW: Result type for contextual reflection generation
struct ContextualReflectionResult: Sendable {
    let questions: [ContextualQuestion]
    let suggestions: [String]
    
    /// Convert to ReflectionQA array
    func toQAArray() -> [ReflectionQA] {
        questions.map { ReflectionQA(question: $0.text, linkedEntryId: $0.linkedEntryId) }
    }
}

/// NEW: Result type for decision pattern analysis
struct DecisionPatternAnalysis: Sendable {
    let calibrationInsight: String?
    let stakesPatternInsight: String?
    let timingInsight: String?
    let overallRecommendation: String
    
    /// Check if there are meaningful insights to show
    var hasInsights: Bool {
        calibrationInsight != nil || stakesPatternInsight != nil || timingInsight != nil
    }
}

// MARK: - Errors

enum AIServiceError: LocalizedError {
    case apiKeyNotConfigured
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case timeout
    
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
        case .timeout:
            return "AI request timed out"
        }
    }
}
