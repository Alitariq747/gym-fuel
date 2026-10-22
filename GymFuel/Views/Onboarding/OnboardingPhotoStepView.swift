//
//  OnboardingPhotoStepView.swift
//  GymFuel
//
//  Photos work too, and words say what a photo can't. Information only: the
//  live meal before it stays text-only (build-order.md, 15a and 15g).
//

import SwiftUI

struct OnboardingPhotoStepView: View {
    let onNext: () -> Void

    private static let photos = ["onboarding_pizza", "onboarding_rice_curry", "onboarding_kung_pao"]
    /// The plate whose two readings sit under the strip.
    private static let readPhoto = "onboarding_rice_curry"
    private static let photoHeight: CGFloat = 138

    var body: some View {
        VStack(spacing: 0) {
            AdaptiveScrollContainer {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 10) {
                        CircaSectionLabel("Photos work too")
                        Text("Snap the plate. Add what it can't show.")
                            .font(.circaTitle)
                            .foregroundStyle(Color.circaInk)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    strip
                    fromPhoto
                    yourWords
                }
                .padding(.horizontal, Circa.Space.screenMargin)
                .padding(.top, 18)
                .padding(.bottom, 20)
            }

            footer
        }
        .circaPaper()
    }

    private var strip: some View {
        HStack(spacing: 10) {
            ForEach(Self.photos, id: \.self) { name in
                let shape = RoundedRectangle(cornerRadius: Circa.Radius.cardSmall, style: .continuous)
                let isRead = name == Self.readPhoto
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: Self.photoHeight)
                    .overlay { Image(name).resizable().scaledToFill() }
                    .clipShape(shape)
                    .overlay {
                        shape.strokeBorder(isRead ? Color.circaAccent : Color.circaCardBorder,
                                           lineWidth: isRead ? 2 : Circa.Rule.hairline)
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Three meal photos: a pizza, rice with chicken curry and a boiled egg, and kung pao chicken.")
    }

    /// Circa's reading of the ringed photo, as the photo sheet shows it.
    private var fromPhoto: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "camera")
                    .font(.caption2)
                    .foregroundStyle(Color.circaInk3)
                CircaSectionLabel("From your photo")
            }
            Text("a plate of white rice, chicken curry with green peppers and a boiled egg")
                .font(.circaRow)
                .foregroundStyle(Color.circaInk2)
                .fixedSize(horizontal: false, vertical: true)
            marked("Circa guesses *the cut*, *the oil* and *how much*.", strong: .circaInk)
                .font(.circaCaption)
                .foregroundStyle(Color.circaInk3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 2)
        .accessibilityElement(children: .combine)
    }

    private var yourWords: some View {
        CircaCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "pencil")
                        .font(.caption2)
                        .foregroundStyle(Color.circaAccent)
                    CircaSectionLabel("Your words", tint: .circaAccent)
                }
                marked("**1½ cups of** rice, **chicken breast** curry with green peppers **made with 1 tbsp oil**, and a boiled egg",
                       strong: .circaAccent)
                    .font(.circaEntryTitle)
                    .foregroundStyle(Color.circaInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Less for Circa to guess.")
                    .font(.circaCaption)
                    .foregroundStyle(Color.circaInk3)
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: Circa.Radius.card, style: .continuous)
                .strokeBorder(Color.circaInk, lineWidth: 1.5)
        }
        .circaLift()
        .accessibilityElement(children: .combine)
    }

    private var footer: some View {
        VStack(spacing: 12) {
            marked("Photos are quick. **Typing tells Circa the most.**", strong: .circaInk)
                .font(.circaBody)
                .foregroundStyle(Color.circaInk2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                onNext()
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.circa(.primary, height: 52))
        }
        .padding(.horizontal, Circa.Space.screenMargin)
        .padding(.bottom, 16)
    }

    /// `*guess*` takes the dotted rule (design.md rule 1); `**words**` take `strong`.
    private func marked(_ markdown: String, strong: Color) -> Text {
        var text = (try? AttributedString(markdown: markdown)) ?? AttributedString(markdown)
        for run in text.runs {
            if run.inlinePresentationIntent == .emphasized {
                text[run.range].inlinePresentationIntent = nil
                text[run.range].underlineStyle = Text.LineStyle(pattern: .dot, color: .circaDotted)
            } else if run.inlinePresentationIntent == .stronglyEmphasized {
                text[run.range].foregroundColor = strong
            }
        }
        return Text(text)
    }
}

#Preview("Photos · light") {
    OnboardingPhotoStepView(onNext: {})
}

#Preview("Photos · dark") {
    OnboardingPhotoStepView(onNext: {})
        .preferredColorScheme(.dark)
}
