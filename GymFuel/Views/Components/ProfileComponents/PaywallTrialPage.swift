import SwiftUI

struct PaywallTrialPage: View {
    let timeline: TrialTimeline
    /// The selected package's price and period, as "Rs 24,900.00 per year".
    let billing: String
    let planName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PaywallPageHeader(label: "Your free trial", title: "How your free trial works")

            VStack(alignment: .leading, spacing: 0) {
                row(
                    symbol: "lock.open",
                    title: "Today",
                    detail: "Full access to everything in Circa Pro.",
                    emphasised: true
                )
                row(
                    symbol: "clock",
                    title: "During your \(timeline.lengthText) trial",
                    detail: "Cancel at least 24 hours before it ends and you won't be charged."
                )
                row(
                    symbol: "creditcard",
                    title: billingTitle,
                    detail: "Billing starts at \(billing), unless you've cancelled.",
                    isLast: true
                )
            }

            CircaHairline()

            Text("Shown for the \(planName) plan. You choose on the next page.")
                .font(.circaMono)
                .foregroundStyle(Color.circaInk3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var billingTitle: String {
        guard let date = timeline.billingDate(from: .now) else { return "When your trial ends" }
        return "On \(date.formatted(.dateTime.day().month(.wide)))"
    }

    private func row(
        symbol: String,
        title: String,
        detail: String,
        emphasised: Bool = false,
        isLast: Bool = false
    ) -> some View {
        HStack(alignment: .top, spacing: 15) {
            VStack(spacing: 6) {
                CircaSymbolWell(symbol: symbol, emphasised: emphasised)
                if !isLast {
                    Rectangle()
                        .fill(Color.circaRule)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.circaRow.weight(.semibold))
                    .foregroundStyle(Color.circaInk)
                Text(detail)
                    .font(.circaBody)
                    .foregroundStyle(Color.circaInk2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 8)
            .padding(.bottom, isLast ? 0 : 22)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
