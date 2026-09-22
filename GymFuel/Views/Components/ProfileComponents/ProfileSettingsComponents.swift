import SwiftUI

struct ProfileSectionHeader: View {
    let title: String

    var body: some View {
        CircaSectionLabel(title)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProfileSettingsRow: View {
    let title: String
    let systemImage: String
    let value: String
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    titleLabel
                    HStack {
                        valueLabel
                        Spacer()
                        chevron
                    }
                }
            } else {
                HStack(spacing: 12) {
                    titleLabel
                    Spacer(minLength: 8)
                    valueLabel
                    chevron
                }
            }
        }
        .contentShape(Rectangle())
        .padding(16)
        .frame(minHeight: Circa.minHitTarget)
    }

    private var titleLabel: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.circaRow)
                .foregroundStyle(Color.circaInk2)
                .frame(width: 40, height: 40)
                .background(Color.circaWell, in: RoundedRectangle(cornerRadius: Circa.Radius.thumb))
                .accessibilityHidden(true)
            Text(title)
                .font(.circaRow)
                .foregroundStyle(Color.circaInk)
        }
    }

    private var valueLabel: some View {
        Text(value)
            .font(.circaMono)
            .foregroundStyle(Color.circaInk2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.circaCaption)
            .foregroundStyle(Color.circaInk3)
            .accessibilityHidden(true)
    }
}

struct ProfileCardBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: Circa.Radius.card, style: .continuous)
            .fill(Color.circaCard)
            .overlay {
                RoundedRectangle(cornerRadius: Circa.Radius.card, style: .continuous)
                    .strokeBorder(Color.circaCardBorder, lineWidth: Circa.Rule.hairline)
            }
    }
}
