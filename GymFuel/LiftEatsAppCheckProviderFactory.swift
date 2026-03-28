//
//  LiftEatsAppCheckProviderFactory.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 14/03/2026.
//

import Foundation
import FirebaseAppCheck
import FirebaseCore

final class LiftEatsAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if targetEnvironment(simulator)
        return AppCheckDebugProvider(app: app)
        #else
        if #available(iOS 14.0, *) {
            return AppAttestProvider(app: app)
        } else {
            return DeviceCheckProvider(app: app)
        }
        #endif
    }
}
