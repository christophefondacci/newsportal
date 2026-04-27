import Foundation

struct QuizAttempt: Codable, Equatable {
    let date: Date
    let correct: Bool
}

struct QuizQuestion: Identifiable, Codable, Equatable {
    let id: UUID
    var question: String
    var answer: String
    var attempts: [QuizAttempt]

    init(id: UUID = UUID(), question: String, answer: String) {
        self.id = id
        self.question = question
        self.answer = answer
        self.attempts = []
    }

    mutating func recordAttempt(correct: Bool) {
        attempts.append(QuizAttempt(date: Date(), correct: correct))
    }
}

struct QuizPage: Identifiable, Codable, Equatable {
    let id: UUID
    var pageURL: URL
    var aiTitle: String
    var questions: [QuizQuestion]
    let dateCreated: Date

    init(id: UUID = UUID(), pageURL: URL, aiTitle: String, questions: [QuizQuestion]) {
        self.id = id
        self.pageURL = pageURL
        self.aiTitle = aiTitle
        self.questions = questions
        self.dateCreated = Date()
    }

    func randomQuestions(count: Int = 4) -> [QuizQuestion] {
        Array(questions.shuffled().prefix(count))
    }
}
