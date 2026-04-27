import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = QuizService.apiKey

    var body: some View {
        Form {
            Section("Claude API") {
                SecureField("API Key", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: apiKey) { _, newValue in
                        QuizService.apiKey = newValue
                    }
                Text("Required for the \"Quiz me\" feature. Get a key at console.anthropic.com")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 150)
    }
}
