//
//  MacroRow.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 17/12/2025.
//

import SwiftUI

struct MacroRow: View {
    let title: String
    let systemImage: String
    @Binding var value: String
    let color: Color

    var body: some View {
        HStack(alignment: .center) {
            
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(color)
                    .frame(width: 30, alignment: .leading)
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 80, alignment: .leading)
            }
            Spacer()
            TextField("0", text: $value)
                .keyboardType(.decimalPad)
                .font(.system(size: 20, weight: .semibold))
                .frame(width: 80)
                .multilineTextAlignment(.center)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)

        }
        
    }
}


//#Preview {
//    MacroRow()
//}
