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
        guard snapshot.exists else {
            return nil
           
        }
        
     return try decodeDayLog(from: snapshot, userId: userId, defaultDate: date)
        
        
    }
    
    func fetchDayLogs(for userId: String, from startDate: Date, to endDate: Date) async throws -> [DayLog] {
        let collection = dayLogsCollection(for: userId)
        
        let query = collection.whereField("date", isGreaterThanOrEqualTo: startDate)
            .whereField("date", isLessThan: endDate)
            .order(by: "date", descending: false)
        
        let snapshot: QuerySnapshot = try await withCheckedThrowingContinuation { continuation in
            query.getDocuments { snapshot, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let snapshot = snapshot {
                    continuation.resume(returning: snapshot)
                } else {
                    let error = NSError(
                                            domain: "FirebaseDayLogService",
                                            code: -1,
                                            userInfo: [NSLocalizedDescriptionKey: "Missing query snapshot."]
                                        )
                                        continuation.resume(throwing: error)
                }
            }
        }
        let logs: [DayLog] = try snapshot.documents.map { doc in
            try decodeDayLog(
                from: doc,
                userId: userId,
                defaultDate: startDate
            )
        }

        return logs
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
        } else {
            data["sessionStart"] = FieldValue.delete()
        }
        
        if let trainingIntensity = dayLog.trainingIntensity {
            data["trainingIntensity"] = trainingIntensity.rawValue
        } else {
            data["trainingIntensity"] = FieldValue.delete()
        }
        
        if let sessionType = dayLog.sessionType {
            data["sessionType"] = sessionType.rawValue
        } else {
            data["sessionType"] = FieldValue.delete()
        }
        
        if let fuelScore = dayLog.fuelScore {
              data["fuelScore"] = [
                  "total":           fuelScore.total,
                  "macroAdherence":  fuelScore.macroAdherence,
                  "timingAdherence": fuelScore.timingAdherence
              ]
          } else {
              data["fuelScore"] = FieldValue.delete()
          }
        
        if let consumed = dayLog.consumedMacros {
            data["consumedMacros"] = [
                "calories": consumed.calories,
                "protein": consumed.protein,
                "carbs": consumed.carbs,
                "fat": consumed.fat
            ]
        } else {
            data["consumedMacros"] = FieldValue.delete()
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
    
 
    private static func dayId(for date: Date, userId: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        let dayString = formatter.string(from: date)
        return "\(userId)_\(dayString)"
    }

    /// Safely convert Firestore numeric fields (Int/Double/NSNumber) to Double.
    private static func double(from any: Any?, default defaultValue: Double = 0) -> Double {
        if let d = any as? Double { return d.isFinite ? d : defaultValue }
        if let i = any as? Int { return Double(i) }
        if let n = any as? NSNumber {
            let value = n.doubleValue
            return value.isFinite ? value : defaultValue
        }
        return defaultValue
    }

    private func decodeDayLog(from snapshot: DocumentSnapshot, userId: String, defaultDate: Date) throws -> DayLog {
        guard let data = snapshot.data() else {
            throw NSError(domain: "FirebaseDayLogService", code: 1, userInfo: [NSLocalizedDescriptionKey: "DayLog document missing data."])
        }
        
     
            let storedDate = (data["date"] as? Timestamp)?.dateValue() ?? defaultDate
            let isTrainingDay = data["isTrainingDay"] as? Bool ?? true
            let sessionStart = (data["sessionStart"] as? Timestamp)?.dateValue()

        
            let intensityRaw = data["trainingIntensity"] as? String
            let trainingIntensity = intensityRaw.flatMap { TrainingIntensity(rawValue: $0) }

        
            let sessionTypeRaw = data["sessionType"] as? String
            let sessionType = sessionTypeRaw.flatMap { SessionType(rawValue: $0) }

         
            let macroDict = data["macroTargets"] as? [String: Any] ?? [:]
            let macroTargets = Macros(
                calories: Self.double(from: macroDict["calories"]),
                protein:  Self.double(from: macroDict["protein"]),
                carbs:    Self.double(from: macroDict["carbs"]),
                fat:      Self.double(from: macroDict["fat"])
            )
        
            let consumedDict = data["consumedMacros"] as? [String: Any]
            let consumedMacros: Macros? = consumedDict.map { dict in
            Macros(
                calories: Self.double(from: dict["calories"]),
                protein:  Self.double(from: dict["protein"]),
                carbs:    Self.double(from: dict["carbs"]),
                fat:      Self.double(from: dict["fat"])
            )
        }

          
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

        
            return DayLog(
                id: snapshot.documentID,
                userId: userId,
                date: storedDate,
                isTrainingDay: isTrainingDay,
                sessionStart: sessionStart,
                trainingIntensity: trainingIntensity,
                sessionType: sessionType,
                macroTargets: macroTargets,
                fuelScore: fuelScore,
                consumedMacros: consumedMacros
            )
    }
}
