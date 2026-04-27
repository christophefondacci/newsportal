import SwiftUI

struct QuizView: View {
    let questions: [QuizQuestion]
    let sourceID: UUID
    let quizPageID: UUID
    @ObservedObject var store: SourceStore
    @Environment(\.dismiss) private var dismiss

    @State private var currentIndex = 0
    @State private var answerRevealed = false
    @State private var answered = false

    private var currentQuestion: QuizQuestion? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    private var isLastQuestion: Bool {
        currentIndex >= questions.count - 1
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            HStack(spacing: 4) {
                ForEach(0..<questions.count, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(i <= currentIndex ? Color.accentColor : Color.secondary.opacity(0.2))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 16)

            // Question number
            Text("Question \(currentIndex + 1) of \(questions.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)

            if let q = currentQuestion {
                // Question
                Text(q.question)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity)

                // Answer area
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.controlBackgroundColor))
                        .frame(minHeight: 80)

                    if answerRevealed {
                        Text(q.answer)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(16)
                            .transition(.opacity)
                    } else {
                        Text(q.answer)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .padding(16)
                            .blur(radius: 12)
                            .accessibilityHidden(true)
                    }
                }
                .padding(.horizontal, 32)
                .animation(.easeInOut(duration: 0.3), value: answerRevealed)

                Spacer().frame(height: 28)

                // Buttons
                if !answerRevealed {
                    Button(action: { answerRevealed = true }) {
                        Text("Reveal Answer")
                            .font(.headline)
                            .frame(maxWidth: 260)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.return, modifiers: [])
                } else if !answered {
                    HStack(spacing: 16) {
                        Button(action: { recordAndAdvance(correct: false) }) {
                            Label("I got it wrong", systemImage: "xmark.circle")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .controlSize(.large)

                        Button(action: { recordAndAdvance(correct: true) }) {
                            Label("I got it right!", systemImage: "checkmark.circle")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        .controlSize(.large)
                    }
                    .padding(.horizontal, 32)
                }
            }

            Spacer()

            // Close button
            Button("Close") { dismiss() }
                .keyboardShortcut(.cancelAction)
                .padding(.bottom, 20)
        }
        .frame(width: 520, height: 420)
    }

    private func recordAndAdvance(correct: Bool) {
        guard let q = currentQuestion else { return }
        store.recordQuizAttempt(sourceID: sourceID, quizPageID: quizPageID, questionID: q.id, correct: correct)
        answered = true

        if isLastQuestion {
            // Small delay then dismiss
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { dismiss() }
        } else {
            // Move to next question after brief pause
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                currentIndex += 1
                answerRevealed = false
                answered = false
            }
        }
    }
}
