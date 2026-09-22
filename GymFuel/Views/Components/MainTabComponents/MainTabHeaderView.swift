import SwiftUI

struct MainTabHeaderView: View {
    let selectedDate: Date
    let canNavigateToNextDate: Bool
    let navigationDirection: DayNavigationDirection
    let onPreviousDateTap: () -> Void
    let onNextDateTap: () -> Void
    let onDateTap: () -> Void
    let onMenuTap: () -> Void

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

    private var dateChangeTransition: AnyTransition {
        switch navigationDirection {
        case .previous:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        case .next:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        }
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            headerLayout(compact: false)
                .frame(minWidth: 330)

            headerLayout(compact: true)
        }
    }

    private func headerLayout(compact: Bool) -> some View {
        HStack(spacing: compact ? 6 : 8) {
            Image("LiftEatsWelcomeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: compact ? 30 : 34, height: compact ? 30 : 34)
                .frame(width: compact ? 34 : 76, alignment: .leading)

            Spacer(minLength: compact ? 2 : 8)

            HStack(spacing: compact ? 4 : 8) {
                dateChevronButton(
                    systemName: "chevron.left",
                    isEnabled: true,
                    size: Circa.minHitTarget,
                    action: onPreviousDateTap
                )

                Button(action: onDateTap) {
                    ZStack {
                        Text(selectedDate.formatted(.dateTime.month(.abbreviated).day()))
                            .id(selectedDate)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                            .transition(dateChangeTransition)
                    }
                    .frame(minWidth: compact ? 50 : 58, minHeight: Circa.minHitTarget)
                    .padding(.horizontal, compact ? 8 : 12)
                    .background(chipBackground, in: Capsule())
                    .overlay(Capsule().stroke(chipStroke, lineWidth: 1))
                    .shadow(color: chipShadow, radius: 10, y: 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Choose date and Day or Week view")
                .animation(.easeInOut(duration: 0.24), value: selectedDate)

                dateChevronButton(
                    systemName: "chevron.right",
                    isEnabled: canNavigateToNextDate,
                    size: Circa.minHitTarget,
                    action: onNextDateTap
                )
            }

            Spacer(minLength: compact ? 2 : 8)

            Button(action: onMenuTap) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.circaInk)
                    .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                    .background(chipBackground, in: Circle())
                    .overlay(Circle().stroke(chipStroke, lineWidth: 1))
                    .shadow(color: chipShadow, radius: 10, y: 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open menu")
            .frame(width: compact ? 44 : 76, alignment: .trailing)
        }
    }

    private func dateChevronButton(
        systemName: String,
        isEnabled: Bool,
        size: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(isEnabled ? Color.primary : Color.secondary.opacity(0.55))
                .frame(width: size, height: size)
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
        canNavigateToNextDate: false,
        navigationDirection: .previous,
        onPreviousDateTap: {},
        onNextDateTap: {},
        onDateTap: {},
        onMenuTap: {}
    )
    .padding()
}
