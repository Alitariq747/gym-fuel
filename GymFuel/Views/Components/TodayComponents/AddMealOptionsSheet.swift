//
//  AddMealOptionsSheet.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 01/03/2026.
//

import SwiftUI

struct AddMealOptionsSheet: View {
    let onSelect: (TodayView.AddMealMode) -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 16) {
                Capsule()
                    .fill(Color.secondary.opacity(0.35))
                    .frame(width: 42, height: 5)
                    .padding(.top, 8)

                HStack {
                    Text("Add a meal")
                        .font(.title3).bold()
                    Spacer()
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline).bold()
                            .foregroundStyle(Color(.systemGray))
                            .padding(8)
                            .background(Color(.systemBackground), in: Circle())
                            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(.plain)
                }

                VStack(spacing: 12) {
                    OptionRow(
                        icon: "square.and.pencil",
                        title: "Add manually",
                        subtitle: "Type your meal details"
                    ) {
                        onSelect(.manual)
                    }

                    OptionRow(
                        icon: "sparkles",
                        title: "Use AI (text)",
                        subtitle: "Describe your meal in words"
                    ) {
                        onSelect(.ai)
                    }

                    OptionRow(
                        icon: "camera",
                        title: "Use camera",
                        subtitle: "Snap a photo for estimation"
                    ) {
                        onSelect(.camera)
                    }

                    OptionRow(
                        icon: "photo.on.rectangle",
                        title: "Pick from gallery",
                        subtitle: "Choose an existing meal photo"
                    ) {
                        onSelect(.gallery)
                    }
                }

                Spacer(minLength: 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .presentationDetents([.medium])
    }
}

struct OptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(Color.liftEatsCoral)
                    .frame(width: 36, height: 36)
                    .background(Color.liftEatsCoral.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.9))
            )
        }
        .buttonStyle(.plain)
    }
}
