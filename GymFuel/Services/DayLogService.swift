//
//  DayLogService.swift
//  GymFuel
//
//  Created by Ahmad Ali Tariq on 12/12/2025.
//
import Foundation

protocol DayLogService {
    
    func fetchDayLog(for userId: String, date: Date) async throws -> DayLog?
    
    func fetchDayLogs(
         for userId: String,
         from startDate: Date,
         to endDate: Date
     ) async throws -> [DayLog]
    
    func saveDayLog(_ dayLog: DayLog) async throws
}
