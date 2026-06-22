import SwiftUI

struct MainTabTimelineContentView: View {
    @ObservedObject var viewModel: TimelineViewModel
    let localPreviewData: (String) -> Data?
    let onSelectEntry: (LogEntry) -> Void
    let onRetryEntry: (LogEntry) -> Void
    let onDeleteFailedEntry: (LogEntry) -> Void
    let onSuccessRevealCompleted: (String) -> Void
    let bottomContentInset: CGFloat

    @State private var lastAutoScrolledPendingEntryID: String?

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let errorMessage = viewModel.errorMessage {
                errorView(errorMessage)
            } else if !viewModel.timeline.entries.isEmpty {
                timelineList
            } else {
                Color.clear
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var timelineList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
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
        let shouldAnimateSuccessReveal = viewModel.shouldAnimateSuccessReveal(for: entry)

        return Button {
            onSelectEntry(entry)
        } label: {
            TimelineEntryRow(
                entry: entry,
                localPreviewData: localPreviewData(entry.id),
                onRetry: entry.status == .failed ? { onRetryEntry(entry) } : nil,
                onDelete: entry.status == .failed ? { onDeleteFailedEntry(entry) } : nil,
                shouldAnimateSuccessReveal: shouldAnimateSuccessReveal,
                onSuccessRevealCompleted: shouldAnimateSuccessReveal ? {
                    onSuccessRevealCompleted(entry.id)
                } : nil
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
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}
