//
//  StringExtension.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 18/12/2025.
//

import Foundation

extension String {
    func truncated(to length: Int, addEllipsis: Bool = true) -> String {
        guard count > length, length > 0 else { return self }

        let endIndex = index(startIndex, offsetBy: length)
        let sliced = self[startIndex..<endIndex]

        if addEllipsis {
            return sliced + "…"
        } else {
            return String(sliced)
        }
    }
}

