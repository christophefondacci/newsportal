import SwiftUI

struct SourceListView: View {
    @ObservedObject var store: SourceStore
    @Binding var selectedSourceID: UUID?

    @State private var showingAddSheet = false

    var body: some View {
        List(selection: $selectedSourceID) {
            ForEach(store.sortedSources) { source in
                SourceRowView(source: source) {
                    if selectedSourceID == source.id {
                        selectedSourceID = nil
                    }
                    store.remove(id: source.id)
                }
                .tag(source.id)
            }
            .onDelete { offsets in
                let sorted = store.sortedSources
                for offset in offsets {
                    if selectedSourceID == sorted[offset].id {
                        selectedSourceID = nil
                    }
                }
                store.remove(at: offsets)
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
    }
}
