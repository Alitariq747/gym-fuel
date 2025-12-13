//
//  FirebaseDayLogService.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 12/12/2025.
//

import Foundation
import FirebaseFirestore

final class FirebaseDayLogService: DayLogService {
    
    
    
    private let db: Firestore
    
    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }
    
    func fetchDayLog(for userId: String, date: Date) async throws -> DayLog? {
        
        let dayId = Self.dayId(for: date, userId: userId)
        let docRef = dayLogsCollection(for: userId).document(dayId) // doc ref from firestore
        
        // where doc actually exists
        let snapshot: DocumentSnapshot = try await withCheckedThrowingContinuation { continuation in
            docRef.getDocument { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                        continuation.resume(returning: snapshot)
                } else {
                    let error = NSError(
                                       domain: "FirebaseDayLogService",
                                       code: -1,
                                       userInfo: [NSLocalizedDescriptionKey: "Missing document snapshot."]
                                   )
                                   continuation.resume(throwing: error)
                }
                
            }
        }
        guard snapshot.exists, let data = snapshot.data() else {
            return nil
            // We will ask DayLogViewModel to create  a new DayLog
        }
        
        let storedDate = (data["date"] as? Timestamp)?.dateValue() ?? date
        let isTrainingDay = data["isTrainingDay"] as? Bool ?? true
        let sessionStart = (data["sessionStart"] as? Timestamp)?.dateValue()
        let intensityRaw = data["trainingIntensity"] as? String
        let trainingIntensity = intensityRaw.flatMap { TrainingIntensity(rawValue: $0) }
           
        let sessionTypeRaw = data["sessionType"] as? String
        let sessionType = sessionTypeRaw.flatMap { SessionType(rawValue: $0) }
        
        // Macro targets
        let macroDict = data["macroTargets"] as? [String: Any] ?? [:]
        let macroTargets = Macros(
            calories: Self.double(from: macroDict["calories"]),
            protein:  Self.double(from: macroDict["protein"]),
            carbs:    Self.double(from: macroDict["carbs"]),
            fat:      Self.double(from: macroDict["fat"])
        )
        
        // Fuel score (optional)
        var fuelScore: FuelScore? = nil
        if let fuelDict = data["fuelScore"] as? [String: Any] {
            let total = fuelDict["total"] as? Int
                ?? Int(Self.double(from: fuelDict["total"]))
            let macroAdherence = fuelDict["macroAdherence"] as? Int
                ?? Int(Self.double(from: fuelDict["macroAdherence"]))
            let timingAdherence = fuelDict["timingAdherence"] as? Int
                ?? Int(Self.double(from: fuelDict["timingAdherence"]))
            
            fuelScore = FuelScore(
                total: total,
                macroAdherence: macroAdherence,
                timingAdherence: timingAdherence
            )
        }
        
        // 5) Build and return the DayLog
        return DayLog(
            id: snapshot.documentID,
            userId: userId,
            date: storedDate,
            isTrainingDay: isTrainingDay,
            sessionStart: sessionStart,
            trainingIntensity: trainingIntensity,
            sessionType: sessionType,
            macroTargets: macroTargets,
            fuelScore: fuelScore
        )
    }
    
    func saveDayLog(_ dayLog: DayLog) async throws {
        let docRef = dayLogDocument(for: dayLog)
        
        // Prepare firestore data
        var data: [String: Any] = [
            "userId" : dayLog.userId,
            "date" : dayLog.date,
            "isTrainingDay": dayLog.isTrainingDay,
            "macroTargets": [
                "calories": dayLog.macroTargets.calories,
                "protein": dayLog.macroTargets.protein,
                "carbs": dayLog.macroTargets.carbs,
                "fat": dayLog.macroTargets.fat
            ],
            "updatedAt": FieldValue.serverTimestamp()
            
        ]
        
        if let sessionStart = dayLog.sessionStart {
            data["sessionStart"] = sessionStart
        }
        if let trainingIntensity = dayLog.trainingIntensity {
            data["trainingIntensity"] = trainingIntensity.rawValue
        }
        
        if let sessionType = dayLog.sessionType {
            data["sessionType"] = sessionType.rawValue
        }
        
        if let fuelScore = dayLog.fuelScore {
              data["fuelScore"] = [
                  "total":           fuelScore.total,
                  "macroAdherence":  fuelScore.macroAdherence,
                  "timingAdherence": fuelScore.timingAdherence
              ]
          }
        
        try await withCheckedThrowingContinuation{ (continuation: CheckedContinuation<Void,Error>) in
            docRef.setData(data, merge: true) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
        
    }
    
    private func dayLogsCollection(for userId: String) -> CollectionReference {
        db.collection("users").document(userId).collection("dayLogs")
    }
    
    private func dayLogDocument(for dayLog: DayLog) -> DocumentReference {
        dayLogsCollection(for: dayLog.userId).document(dayLog.id)
    }
    
    // helpers
    // Same dayId logic as in DayLogViewModel
    private static func dayId(for date: Date, userId: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dayString = formatter.string(from: date)
        return "\(userId)_\(dayString)"
    }

    /// Safely convert Firestore numeric fields (Int/Double/NSNumber) to Double.
    private static func double(from any: Any?, default defaultValue: Double = 0) -> Double {
        if let d = any as? Double { return d }
        if let i = any as? Int { return Double(i) }
        if let n = any as? NSNumber { return n.doubleValue }
        return defaultValue
    }

}
