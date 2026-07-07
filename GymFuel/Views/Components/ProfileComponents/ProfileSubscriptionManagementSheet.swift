import SwiftUI

struct ProfileSubscriptionManagementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!

    var body: some View {
        VStack(spacing: 18) {
            HStack {
                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.primary)
                        .frame(width: 34, height: 34)
                        .background(Color(.secondarySystemBackground), in: Circle())
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color.liftEatsCoral)
                    .frame(width: 64, height: 64)
                    .background(Color.liftEatsCoral.opacity(0.12), in: Circle())

                Text("LiftEats Pro is active")
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("You can manage or cancel your subscription through your Apple account.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                openURL(manageSubscriptionsURL)
            } label: {
                Text("Manage Subscription")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.primary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Button("Done") {
                dismiss()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .buttonStyle(.plain)
        }
        .padding(24)
    }
}
