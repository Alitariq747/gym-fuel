//
//  RestDayCard.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 14/12/2025.
//

import SwiftUI

struct RestDayCard: View {
    
    let onEdit: () -> Void
    
    var body: some View {
        
        HStack(alignment: .center, spacing: 20) {
            
            Image(systemName: "moon.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.liftEatsCoral)
                .padding(8)
                .background(Color.white, in: Circle())
                .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 1))
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Rest Day")
                    .font(.headline).bold()
                    .foregroundStyle(.primary)
                
                Text("Take it easy and prioritize recovery. Focus on hydration, quality sleep and light activity like walking.")
                    .font(.caption2)
                    .foregroundStyle(.primary)
            }
            
            Spacer()
            
        
                Button {
                    onEdit()
                } label: {
                    Image(systemName: "pencil")
                        .font(.subheadline)
                        .foregroundStyle(Color.liftEatsCoral)
                }
                .padding(.bottom, 50)

        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white, lineWidth: 1))
    }
}

#Preview {
    RestDayCard(onEdit: { print("")})
}
