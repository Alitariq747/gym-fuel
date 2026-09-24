import SwiftUI

struct MainTabTimelineContentView: View {
    @ObservedObject var viewModel: TimelineViewModel
    let localPreviewData: (String) -> Data?
    let onSelectEntry: (LogEntry) -> Void
    let onRetryEntry: (LogEntry) -> Void
    let onDeleteFailedEntry: (LogEntry) -> Void
    let bottomContentInset: CGFloat
    let canModifyEntries: Bool

    @State private var lastAutoScrolledPendingEntryID: String?
    @ScaledMetric(relativeTo: .largeTitle) private var emptyGlyphSize: CGFloat = 34

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                errorView(errorMessage)
            } else if !viewModel.timeline.entries.isEmpty {
                timelineList
            } else {
                emptyDay
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    /// The `Empty day` artboard. An empty log is not an error and not a card —
    /// the summary card above still carries the whole day as the headline.
    private var emptyDay: some View {
        VStack(spacing: 14) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: emptyGlyphSize, weight: .light))
                .foregroundStyle(Color.circaInk3)
            Text("Nothing written yet")
                .font(.circaEntryTitle)
                .foregroundStyle(Color.circaInk2)
            Text("A sentence is enough. \u{201C}Two roti and daal\u{201D} gets you a number and a list of what Circa assumed.")
                .font(.circaBody)
                .foregroundStyle(Color.circaInk3)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 44)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var timelineList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                // Rows sit directly on paper and bring their own padding, so
                // there is no gap between them — the `Day` artboard.
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.timeline.entries) { entry in
                        timelineButton(for: entry)
                            .id(entry.id)
                    }
                }
                .padding(.bottom, bottomContentInset)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.timeline.entries) { oldEntries, newEntries in
                guard let pendingEntryID = newPendingEntryID(oldEntries: oldEntries, newEntries: newEntries),
                      pendingEntryID != lastAutoScrolledPendingEntryID else { return }

                lastAutoScrolledPendingEntryID = pendingEntryID
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.easeOut(duration: 0.35)) {
                        proxy.scrollTo(pendingEntryID, anchor: .bottom)
                    }
                }
            }
        }
    }

    private func newPendingEntryID(oldEntries: [LogEntry], newEntries: [LogEntry]) -> String? {
        guard !oldEntries.isEmpty else { return nil }

        let oldIDs = Set(oldEntries.map(\.id))
        return newEntries.last { entry in
            !oldIDs.contains(entry.id) && entry.status == .analyzing
        }?.id
    }

    private func timelineButton(for entry: LogEntry) -> some View {
        Button {
            onSelectEntry(entry)
        } label: {
            TimelineEntryRow(
                entry: entry,
                localPreviewData: localPreviewData(entry.id),
                onRetry: canModifyEntries && entry.status == .failed ? { onRetryEntry(entry) } : nil,
                onDelete: canModifyEntries && entry.status == .failed ? { onDeleteFailedEntry(entry) } : nil
            )
        }
        .buttonStyle(.plain)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 8) {
            Text("Failed to load timeline")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.circaInk2)
                .multilineTextAlignment(.center)
        }
    }
}
