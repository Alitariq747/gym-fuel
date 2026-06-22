import SwiftUI

struct ProfileSavedMealsSection: View {
    let savedMealCount: Int
    let onOpen: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ProfileSectionHeader(title: "Saved Meals", systemImage: "bookmark")

            Button(action: onOpen) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.fuelBlue.opacity(0.12))
                            .frame(width: 52, height: 52)

                        Image(systemName: "fork.knife")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.fuelBlue)
                    }

                    Text("Manage Saved Meals")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text("\(savedMealCount)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.primary)

                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 4)
                }
                .contentShape(Rectangle())
                .padding(16)
            }
            .buttonStyle(.plain)
            .background(ProfileCardBackground())
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.fuelBlue.opacity(0.12), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }
}
