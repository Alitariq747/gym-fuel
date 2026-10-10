import SwiftUI

// iOS 26 wraps every toolbar item in its own glass, which clips a drawn circle,
// so from 26 these defer to the system's buttons. Below 26 they draw the circle.

struct CircaCloseButton: View {
    let action: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            Button(role: .close, action: action)
        } else {
            Button(action: action) {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.circaInk2)
                    .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                    .background(Color.circaWell, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }
}

struct CircaConfirmButton: View {
    let isEnabled: Bool
    var isWorking = false
    let action: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            Button(role: .confirm, action: action) { label }
                .buttonStyle(.glassProminent)
                .tint(Color.circaInk)
                .disabled(!isEnabled || isWorking)
                .accessibilityLabel("Save")
        } else {
            Button(action: action) {
                label
                    .font(.subheadline.weight(.bold))
                    .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                    .background(isEnabled ? Color.circaInk : Color.circaSunken, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!isEnabled || isWorking)
            .accessibilityLabel("Save")
        }
    }

    // Ink fill with a paper glyph flips correctly in dark mode; the glass
    // default, a white glyph, vanishes on dark mode's light ink.
    @ViewBuilder
    private var label: some View {
        if isWorking {
            ProgressView()
                .tint(Color.circaPaperTop)
        } else {
            Image(systemName: "checkmark")
                .foregroundStyle(isEnabled ? Color.circaPaperTop : Color.circaInk3)
        }
    }
}

struct CircaBackButton: View {
    let action: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            Button(action: action) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Color.circaInk)
            }
            .accessibilityLabel("Back")
        } else {
            Button(action: action) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Color.circaInk)
                    .frame(width: Circa.minHitTarget, height: Circa.minHitTarget)
                    .background(Color.circaCard, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
        }
    }
}
