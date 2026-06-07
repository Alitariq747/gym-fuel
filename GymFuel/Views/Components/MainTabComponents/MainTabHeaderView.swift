import SwiftUI

struct MainTabHeaderView: View {
    let selectedDate: Date
    let onDateTap: () -> Void
    let onStatsTap: () -> Void
    let onProfileTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var chipBackground: Color {
        colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)
    }

    private var chipStroke: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.clear
    }

    private var chipShadow: Color {
        colorScheme == .dark ? Color.clear : Color.black.opacity(0.08)
    }

    var body: some View {
        HStack {
            Image("LiftEatsWelcomeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .frame(width: 76, alignment: .leading)

            Spacer()

            Button(action: onDateTap) {
                Text(selectedDate.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(chipBackground, in: Capsule())
                    .overlay(Capsule().stroke(chipStroke, lineWidth: 1))
                    .shadow(color: chipShadow, radius: 10, y: 4)
            }
            .buttonStyle(.plain)

            Spacer()

            HStack(spacing: 14) {
                Button(action: onStatsTap) {
                    Image(systemName: "flame.fill")
                        .frame(width: 18, height: 18)
                        .foregroundStyle(Color.fuelOrange)
                }

                Button(action: onProfileTap) {
                    Image(systemName: "gearshape")
                        .frame(width: 18, height: 18)
                }
            }
            .buttonStyle(.plain)
            .font(.system(size: 16, weight: .semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(chipBackground, in: Capsule())
            .overlay(Capsule().stroke(chipStroke, lineWidth: 1))
            .shadow(color: chipShadow, radius: 10, y: 4)
            .frame(width: 76, alignment: .trailing)
        }
    }
}

#Preview {
    MainTabHeaderView(
        selectedDate: .now,
        onDateTap: {},
        onStatsTap: {},
        onProfileTap: {}
    )
    .padding()
}
