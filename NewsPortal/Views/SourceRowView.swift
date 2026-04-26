import SwiftUI

struct SourceRowView: View {
    let source: Source

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(source.title)
                    .font(.body)
                    .lineLimit(1)
                Text(source.url.host ?? source.url.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if source.rssURL != nil && source.unreadCount > 0 {
                Text("\(source.unreadCount)")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor, in: Capsule())
            }
        }
        .contentShape(Rectangle())
    }
}
