import SwiftUI

enum SidebarSelection: Hashable {
    case source(UUID)
    case quizPage(sourceID: UUID, quizPageID: UUID)
}

struct SourceListView: View {
    @ObservedObject var store: SourceStore
    @Binding var selectedSourceID: UUID?
    var onQuizPageSelected: ((_ sourceID: UUID, _ quizPage: QuizPage) -> Void)?

    @State private var showingAddSheet = false
    @State private var sidebarSelection: SidebarSelection?

    var body: some View {
        List(selection: $sidebarSelection) {
            ForEach(store.sortedSources) { source in
                if source.quizPages.isEmpty {
                    SourceRowView(source: source) {
                        if selectedSourceID == source.id {
                            selectedSourceID = nil
                            sidebarSelection = nil
                        }
                        store.remove(id: source.id)
                    }
                    .tag(SidebarSelection.source(source.id))
                } else {
                    DisclosureGroup {
                        ForEach(source.quizPages) { quiz in
                            HStack(spacing: 6) {
                                Image(systemName: "questionmark.bubble")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                Text(quiz.aiTitle)
                                    .font(.callout)
                                    .lineLimit(1)
                            }
                            .tag(SidebarSelection.quizPage(sourceID: source.id, quizPageID: quiz.id))
                        }
                    } label: {
                        SourceRowView(source: source) {
                            if selectedSourceID == source.id {
                                selectedSourceID = nil
                                sidebarSelection = nil
                            }
                            store.remove(id: source.id)
                        }
                        .tag(SidebarSelection.source(source.id))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingAddSheet = true }) {
                    Label("Add Source", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddSourceView(store: store)
        }
        .onChange(of: sidebarSelection) { _, newValue in
            switch newValue {
            case .source(let id):
                selectedSourceID = id
            case .quizPage(let sourceID, let quizPageID):
                if let source = store.sources.first(where: { $0.id == sourceID }),
                   let quizPage = source.quizPages.first(where: { $0.id == quizPageID }) {
                    onQuizPageSelected?(sourceID, quizPage)
                }
            case nil:
                selectedSourceID = nil
            }
        }
    }
}
