import XCTest
@testable import NewsPortal

final class QuizTests: XCTestCase {

    // MARK: - QuizQuestion

    func testRecordAttempt() {
        var question = QuizQuestion(question: "What is 2+2?", answer: "4")
        XCTAssertTrue(question.attempts.isEmpty)

        question.recordAttempt(correct: true)
        XCTAssertEqual(question.attempts.count, 1)
        XCTAssertTrue(question.attempts[0].correct)

        question.recordAttempt(correct: false)
        XCTAssertEqual(question.attempts.count, 2)
        XCTAssertFalse(question.attempts[1].correct)
    }

    func testAttemptRecordsDate() {
        var question = QuizQuestion(question: "Q?", answer: "A")
        let before = Date()
        question.recordAttempt(correct: true)
        let after = Date()

        let attemptDate = question.attempts[0].date
        XCTAssertTrue(attemptDate >= before && attemptDate <= after)
    }

    // MARK: - QuizPage

    func testRandomQuestionsReturnsRequestedCount() {
        let questions = (0..<10).map {
            QuizQuestion(question: "Q\($0)", answer: "A\($0)")
        }
        let page = QuizPage(pageURL: URL(string: "https://example.com")!, aiTitle: "Test", questions: questions)

        let picked = page.randomQuestions(count: 4)
        XCTAssertEqual(picked.count, 4)
    }

    func testRandomQuestionsDoesNotExceedAvailable() {
        let questions = [
            QuizQuestion(question: "Q1", answer: "A1"),
            QuizQuestion(question: "Q2", answer: "A2"),
        ]
        let page = QuizPage(pageURL: URL(string: "https://example.com")!, aiTitle: "Test", questions: questions)

        let picked = page.randomQuestions(count: 4)
        XCTAssertEqual(picked.count, 2)
    }

    func testRandomQuestionsAreSubset() {
        let questions = (0..<10).map {
            QuizQuestion(question: "Q\($0)", answer: "A\($0)")
        }
        let page = QuizPage(pageURL: URL(string: "https://example.com")!, aiTitle: "Test", questions: questions)

        let picked = page.randomQuestions(count: 4)
        let allIDs = Set(questions.map(\.id))
        for q in picked {
            XCTAssertTrue(allIDs.contains(q.id))
        }
    }

    // MARK: - Codable round-trip

    func testQuizPageCodableRoundTrip() throws {
        var q1 = QuizQuestion(question: "What?", answer: "That")
        q1.recordAttempt(correct: true)
        q1.recordAttempt(correct: false)
        let q2 = QuizQuestion(question: "Who?", answer: "Him")

        let page = QuizPage(
            pageURL: URL(string: "https://example.com/article")!,
            aiTitle: "Test Article",
            questions: [q1, q2]
        )

        let data = try JSONEncoder().encode(page)
        let decoded = try JSONDecoder().decode(QuizPage.self, from: data)

        XCTAssertEqual(decoded.aiTitle, "Test Article")
        XCTAssertEqual(decoded.pageURL.absoluteString, "https://example.com/article")
        XCTAssertEqual(decoded.questions.count, 2)
        XCTAssertEqual(decoded.questions[0].attempts.count, 2)
        XCTAssertTrue(decoded.questions[0].attempts[0].correct)
        XCTAssertFalse(decoded.questions[0].attempts[1].correct)
    }

    func testSourceWithQuizPagesCodable() throws {
        var source = Source(url: URL(string: "https://example.com")!, title: "Example")
        let page = QuizPage(
            pageURL: URL(string: "https://example.com/page")!,
            aiTitle: "Page Quiz",
            questions: [QuizQuestion(question: "Q?", answer: "A")]
        )
        source.quizPages.append(page)

        let data = try JSONEncoder().encode(source)
        let decoded = try JSONDecoder().decode(Source.self, from: data)

        XCTAssertEqual(decoded.quizPages.count, 1)
        XCTAssertEqual(decoded.quizPages[0].aiTitle, "Page Quiz")
        XCTAssertEqual(decoded.quizPages[0].questions.count, 1)
    }
}

@MainActor
final class SourceStoreQuizTests: XCTestCase {

    private func makeTempFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
    }

    func testAddQuizPage() {
        let store = SourceStore(fileURL: makeTempFileURL())
        let source = Source(url: URL(string: "https://example.com")!, title: "Example")
        store.add(source)

        let page = QuizPage(
            pageURL: URL(string: "https://example.com/article")!,
            aiTitle: "Article Quiz",
            questions: [QuizQuestion(question: "Q?", answer: "A")]
        )
        store.addQuizPage(sourceID: source.id, quizPage: page)

        XCTAssertEqual(store.sources[0].quizPages.count, 1)
        XCTAssertEqual(store.sources[0].quizPages[0].aiTitle, "Article Quiz")
    }

    func testRecordQuizAttempt() {
        let store = SourceStore(fileURL: makeTempFileURL())
        let source = Source(url: URL(string: "https://example.com")!, title: "Example")
        store.add(source)

        let question = QuizQuestion(question: "Q?", answer: "A")
        let page = QuizPage(
            pageURL: URL(string: "https://example.com/article")!,
            aiTitle: "Quiz",
            questions: [question]
        )
        store.addQuizPage(sourceID: source.id, quizPage: page)

        store.recordQuizAttempt(sourceID: source.id, quizPageID: page.id, questionID: question.id, correct: true)

        let attempts = store.sources[0].quizPages[0].questions[0].attempts
        XCTAssertEqual(attempts.count, 1)
        XCTAssertTrue(attempts[0].correct)
    }

    func testQuizPagesPersistence() {
        let fileURL = makeTempFileURL()

        let store1 = SourceStore(fileURL: fileURL)
        let source = Source(url: URL(string: "https://example.com")!, title: "Example")
        store1.add(source)
        let page = QuizPage(
            pageURL: URL(string: "https://example.com/p")!,
            aiTitle: "Persisted Quiz",
            questions: [QuizQuestion(question: "Q?", answer: "A")]
        )
        store1.addQuizPage(sourceID: source.id, quizPage: page)

        let store2 = SourceStore(fileURL: fileURL)
        XCTAssertEqual(store2.sources[0].quizPages.count, 1)
        XCTAssertEqual(store2.sources[0].quizPages[0].aiTitle, "Persisted Quiz")
    }
}
