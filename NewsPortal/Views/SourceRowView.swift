import SwiftUI

struct SourceRowView: View {
    let source: Source
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            if let data = source.faviconData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            } else {
                Image(systemName: "globe")
                    .frame(width: 16, height: 16)
                    .foregroundStyle(.secondary)
            }

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

            Menu {
                Button(role: .destructive, action: onRemove) {
                    Label("Remove", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .contentShape(Rectangle())
    }
}
