//
//  WelcomeView.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 13/12/2025.
//

import SwiftUI

struct WelcomeView: View {
    let onGetStarted: () -> Void
    let onSignIn: () -> Void

    var body: some View {
        AdaptiveScrollContainer {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Circa")
                        .font(.system(.title2).weight(.semibold))
                        .foregroundStyle(Color.circaInk)

                    CircaSectionLabel("Food & calorie journal")
                }

                Spacer(minLength: 48)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Your food, in your words.")
                        .font(.system(.largeTitle).weight(.semibold))
                        .foregroundStyle(Color.circaInk)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Describe a meal or add a photo. See the portions and ingredients we assumed, then correct what differs.")
                        .font(.circaBody)
                        .foregroundStyle(Color.circaInk2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 48)

                VStack(spacing: 12) {
                    Button(action: onGetStarted) {
                        Text("Get Started")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.circa(.primary, height: 56))

                    Button(action: onSignIn) {
                        Text("Already have an account? Sign in")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.circa(.link))
                }
            }
            .padding(.horizontal, Circa.Space.screenMargin)
            .padding(.top, 32)
            .padding(.bottom, 24)
        }
        .circaPaper()
    }
}


#Preview {
    WelcomeView(onGetStarted: { }, onSignIn: { })
}
