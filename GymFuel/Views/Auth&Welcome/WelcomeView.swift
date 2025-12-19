//
//  WelcomeView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 13/12/2025.
//

import SwiftUI

struct WelcomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    let onSignIn: () -> Void
    let onSignUp: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 24)

            Image("LiftEatsWelcomeIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 220, height: 220)
                .padding(.top, 16)
                

            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome to LiftEats")
                    .font(.title.bold())

                Text("Fuel your training with personalised macros, meal timing, and AI-powered logging.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 8)

            Spacer()

            VStack(spacing: 12) {

                Button {
                    onSignUp()
                } label: {
                    Text("Sign up")
                        .font(.title3).bold()
                        .foregroundStyle(.white)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(colorScheme == .light ? Color.black : Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(colorScheme == .dark ? Color(.secondarySystemBackground) : .black, lineWidth: 1))
                }
                .buttonStyle(.plain)


                Button {
                    onSignIn()
                } label: {
                    Text("Already have an account? Sign in")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
    }
}


#Preview {
    WelcomeView(onSignIn: {print("")}, onSignUp: { print("")})
}
