//
//  TrainingCard.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 14/12/2025.
//

import SwiftUI

struct TrainingCard: View {
    
        let sessionStart: Date?
       let intensity: TrainingIntensity?
       let sessionType: SessionType?
    
    let onEdit: () -> Void
    
    @State private var caption = "Let’s lift."
    
    let cardTexts = ["Work mode.", "Let’s lift.", "No excuses. Just reps.", "Make it count.", "Show up. Do work.", "It's lift time."]
    
    var body: some View {
        HStack(alignment: .center, spacing: 20) {
                Text("🏋️")
                .font(.system(size: 22, weight: .semibold))
                .padding(8)
                .background(Color.white, in: Circle())
                .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(sessionType?.displayName ?? "Set type 👉🏻")
                    .font(.subheadline)
                Text(caption)
                    .font(.title3).bold()
                
                HStack(alignment: .center) {
                    // Two Hstacks needed
                    HStack {
                        
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 14, weight: .light))
                        Text("Intensity:")
                            .font(.system(size: 14, weight: .light))
                        Text(intensity?.displayName ?? "Intensity not set")
                            .font(.system(size: 14, weight: .light))
                    }
                    HStack {
                        Image(systemName: "alarm")
                            .font(.system(size: 14, weight: .light))
                        
                        Text(sessionStart?.formatted(date: .omitted, time: .shortened) ?? "set 👆🏻")
                            .font(.system(size: 14, weight: .light))
                    }
                }
                
            }
            Spacer()
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .font(.subheadline)
                    .foregroundStyle(Color.gray.opacity(0.5))
            }
            .padding(.bottom, 50)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white, lineWidth: 1))
        .onAppear {
                    caption = cardTexts.randomElement() ?? caption
                }
    }
}

#Preview {
    TrainingCard(sessionStart: nil, intensity: .hard, sessionType: .hypertrophy, onEdit: { print("") })
}
