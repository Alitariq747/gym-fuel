import SwiftUI

struct MainTabHeaderView: View {
    let selectedDate: Date
    let loggedDays: Set<Date>
    let canNavigateToNextDate: Bool
    let onPreviousDateTap: () -> Void
    let onNextDateTap: () -> Void
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

    private var calendar: Calendar {
        .current
    }

    private var hasLogsOnSelectedDate: Bool {
        loggedDays.contains(calendar.startOfDay(for: selectedDate))
    }

    private var dateChipBackground: Color {
        hasLogsOnSelectedDate ? Color.fuelGreen.opacity(0.12) : chipBackground
    }

    private var dateChipStroke: Color {
        hasLogsOnSelectedDate ? Color.fuelGreen.opacity(0.22) : chipStroke
    }

    var body: some View {
        HStack {
            Image("LiftEatsWelcomeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .frame(width: 76, alignment: .leading)

            Spacer()

            HStack(spacing: 8) {
                dateChevronButton(systemName: "chevron.left", isEnabled: true, action: onPreviousDateTap)

                Text(selectedDate.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(hasLogsOnSelectedDate ? Color.fuelGreen : .primary)
                    .frame(minWidth: 58)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(dateChipBackground, in: Capsule())
                    .overlay(Capsule().stroke(dateChipStroke, lineWidth: 1))
                    .shadow(color: chipShadow, radius: 10, y: 4)

                dateChevronButton(systemName: "chevron.right", isEnabled: canNavigateToNextDate, action: onNextDateTap)
            }

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

    private func dateChevronButton(systemName: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isEnabled ? Color.primary : Color.secondary.opacity(0.55))
                .frame(width: 34, height: 34)
//                .background(chipBackground.opacity(isEnabled ? 1 : 0.65), in: Circle())
//                .overlay(Circle().stroke(chipStroke, lineWidth: 1))
//                .shadow(color: chipShadow.opacity(isEnabled ? 1 : 0.45), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MainTabHeaderView(
        selectedDate: .now,
        loggedDays: [Calendar.current.startOfDay(for: .now)],
        canNavigateToNextDate: false,
        onPreviousDateTap: {},
        onNextDateTap: {},
        onStatsTap: {},
        onProfileTap: {}
    )
    .padding()
}
