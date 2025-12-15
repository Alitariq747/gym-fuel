//
//  CardSkeleton.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 14/12/2025.
//

import SwiftUI

struct CardSkeleton: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
                  .fill(Color(.secondarySystemBackground))
                  .frame(height: 92)
                  .redacted(reason: .placeholder)
    }
}

#Preview {
    CardSkeleton()
}
