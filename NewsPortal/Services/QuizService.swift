import Foundation

struct QuizGenerationResult: Codable {
    let title: String
    let questions: [GeneratedQA]

    struct GeneratedQA: Codable {
        let question: String
        let answer: String
    }
}

protocol QuizGenerating {
    func generateQuiz(pageContent: String, pageTitle: String, pageURL: URL) async throws -> QuizPage
}

class QuizService: QuizGenerating {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    static var apiKey: String {
        get { UserDefaults.standard.string(forKey: "claudeAPIKey") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "claudeAPIKey") }
    }

    func generateQuiz(pageContent: String, pageTitle: String, pageURL: URL) async throws -> QuizPage {
        let apiKey = Self.apiKey
        guard !apiKey.isEmpty else {
            throw QuizError.noAPIKey
        }

        let prompt = """
        You are helping a reader remember the gist of an article they just read. Analyze the following web page content and generate exactly 10 quiz questions with answers.

        Guidelines:
        - Questions should be specific and direct, targeting one clear fact or concept each
        - Focus on the important points: main findings, key concepts, why it matters — skip trivial details
        - Answers MUST be short: a few words to one sentence max. Think flashcard-style.
        - Example good Q&A: "What causes X?" → "Y inhibits Z, leading to cell death."
        - Example bad Q&A: "What causes X?" → "According to the researchers, the primary mechanism involves Y, which acts by inhibiting Z. This process ultimately leads to..." (too long)

        Also generate a short, accurate title describing the page's content (you may use the original page title "\(pageTitle)" if it's a good representation, or create a better one).

        Respond ONLY with valid JSON in this exact format, no markdown, no code fences:
        {"title": "...", "questions": [{"question": "...", "answer": "..."}, ...]}

        Page URL: \(pageURL.absoluteString)
        Page content:
        \(String(pageContent.prefix(25000)))
        """

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 4096,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]

        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let responseBody = String(data: data, encoding: .utf8) ?? ""
            throw QuizError.apiError(statusCode: statusCode, message: responseBody)
        }

        // Parse the Claude response to extract the text content
        let apiResponse: [String: Any]
        do {
            apiResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        } catch {
            let preview = String(String(data: data, encoding: .utf8)?.prefix(300) ?? "")
            throw QuizError.parseError("API response is not valid JSON: \(preview)")
        }

        guard let content = apiResponse["content"] as? [[String: Any]],
              let textBlock = content.first(where: { $0["type"] as? String == "text" }),
              let text = textBlock["text"] as? String
        else {
            let preview = String(String(data: data, encoding: .utf8)?.prefix(500) ?? "")
            throw QuizError.parseError("Could not extract text from API response: \(preview)")
        }

        // Strip markdown code fences if present
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw QuizError.parseError("Could not convert response to data")
        }

        let result: QuizGenerationResult
        do {
            result = try JSONDecoder().decode(QuizGenerationResult.self, from: jsonData)
        } catch {
            let preview = String(cleaned.prefix(300))
            throw QuizError.parseError("JSON decode failed: \(error.localizedDescription)\nResponse preview: \(preview)")
        }

        let questions = result.questions.map { qa in
            QuizQuestion(question: qa.question, answer: qa.answer)
        }

        return QuizPage(pageURL: pageURL, aiTitle: result.title, questions: questions)
    }
}

enum QuizError: LocalizedError {
    case noAPIKey
    case apiError(statusCode: Int, message: String)
    case parseError(String)
    case noContent

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No Claude API key configured. Go to Settings to add your API key."
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .parseError(let msg):
            return "Failed to parse quiz: \(msg)"
        case .noContent:
            return "Could not extract content from the page."
        }
    }
}
