//
//  FirebaseDayLogService.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 07/12/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseDayLogService {
    static let shared = FirebaseDayLogService()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    private func dateString(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: date)
    }
    
    private func daysCollection(for uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("days")
    }
    
    private func defaultTargets(for dayType: String) -> (cal: Double, p: Double, c: Double, f: Double) {
        switch dayType {
        case "hard":
            return (2500, 180, 260, 70)
        case "normal":
            return (2000, 140, 170, 50)
        case "rest":
                   fallthrough
        default:
            return (2000, 160, 180, 60)
      
        }
    }
    
    func loadOrCreateToday(completion: @escaping(Result<DayLog,Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "auth", code: 401, userInfo: [NSLocalizedDescriptionKey : "No user signed in"])))
            return
        }
        
        let uid = user.uid
        let todayId = dateString()
        let docRef = daysCollection(for: uid).document(todayId)
        
        docRef.getDocument{ snapshot, error in
            if let error = error {
                completion(.failure(error))
            }
            
            if let snapshot = snapshot, snapshot.exists, let data = snapshot.data() {
                let log = Self.mapDocument(id: snapshot.documentID, data: data)
                completion(.success(log))
            } else {
                self.createDefaultToday(docRef: docRef, dayId: todayId, completion: completion)
            }
        }
    }
    
    private func createDefaultToday(docRef: DocumentReference, dayId: String, dayType: String = "normal", completion: @escaping(Result<DayLog,Error>) -> Void) {
        
        let targets = defaultTargets(for: dayType)
        
        let data: [String: Any] = [
            "date": dayId,
            "dayType": dayType,
            "targetCalories": targets.cal,
            "targetProtein": targets.p,
                      "targetCarbs": targets.c,
                      "targetFat": targets.f,
                      "totalCalories": 0,
                      "totalProtein": 0,
                      "totalCarbs": 0,
                      "totalFat": 0,
                      "createdAt": FieldValue.serverTimestamp(),
                      "updatedAt": FieldValue.serverTimestamp()
        ]
        
        docRef.setData(data) { err in
            if let err = err {
                completion(.failure(err))
                return
            }
            
            let log = DayLog(id: dayId, dateString: dayId, dayType: dayType, targetCalories: targets.cal, targetProtein: targets.p, targetCarbs: targets.c, targetFat: targets.f, totalCalories: 0, totalProtein: 0, totalCarbs: 0, totalFat: 0)
            completion(.success(log))
        }
    }
    
    private static func mapDocument(id: String, data: [String: Any]) -> DayLog {
        let dateString = data["date"] as? String ?? id
        let dayType = data["dayType"] as? String ?? "normal"
        
        let targetCalories = data["targetCalories"] as? Double ?? 0
               let targetProtein  = data["targetProtein"]  as? Double ?? 0
               let targetCarbs    = data["targetCarbs"]    as? Double ?? 0
               let targetFat      = data["targetFat"]      as? Double ?? 0
               
               let totalCalories = data["totalCalories"] as? Double ?? 0
               let totalProtein  = data["totalProtein"]  as? Double ?? 0
               let totalCarbs    = data["totalCarbs"]    as? Double ?? 0
               let totalFat      = data["totalFat"]      as? Double ?? 0
        
        return DayLog(
                 id: id,
                 dateString: dateString,
                 dayType: dayType,
                 targetCalories: targetCalories,
                 targetProtein: targetProtein,
                 targetCarbs: targetCarbs,
                 targetFat: targetFat,
                 totalCalories: totalCalories,
                 totalProtein: totalProtein,
                 totalCarbs: totalCarbs,
                 totalFat: totalFat
             )
    }
    
    func updateDayType(for log: DayLog, to newDayType: String, completion: @escaping(Result<DayLog,Error>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(NSError(domain: "auth", code: 401, userInfo: [NSLocalizedDescriptionKey : "No user signed in"])))
            return
        }
        let uid = user.uid
        let docRef = daysCollection(for: uid).document(log.id)
        
        let targets = defaultTargets(for: newDayType)
        
        let updateData: [String : Any] = [
            "dayType": newDayType,
            "targetCalories": targets.cal,
            "targetProtein": targets.p,
            "targetCarbs": targets.c,
            "targetFat": targets.f,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        docRef.updateData(updateData) { error in
                if let error = error {
                completion(.failure(error))
            }
            let updateLog = DayLog(id: log.id, dateString: log.dateString, dayType: newDayType, targetCalories: targets.cal, targetProtein: targets.p, targetCarbs: targets.c, targetFat: targets.f, totalCalories: log.totalCalories, totalProtein: log.totalProtein, totalCarbs: log.totalCarbs, totalFat: log.totalFat)
            completion(.success(updateLog))
        }
        
    }
}
