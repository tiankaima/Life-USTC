//
//  CurriculumDelegate.swift
//  Life@USTC
//
//  Created by Tiankai Ma on 2023/2/24.
//

import EventKit
import SwiftUI
import SwiftyJSON

class CurriculumDelegate: CacheAsyncDataDelegate {
    typealias D = [Course]

    var lastUpdate: Date?
    var timeInterval: Double?
    var cacheName: String = "UstcUgAASCurriculumCache"
    var timeCacheName: String = "UstcUgAASLastUpdatedCurriculum"

    var ustcUgAASClient: UstcUgAASClient
    var cache = JSON()
    static var shared = CurriculumDelegate(.shared)

    func parseCache() async throws -> [Course] {
        var result: [Course] = []
        for (_, subJson): (String, JSON) in cache["studentTableVm"]["activities"] {
            var classPositionString = subJson["room"].stringValue
            if classPositionString == "" {
                classPositionString = subJson["customPlace"].stringValue
            }
            let tmp = Course(dayOfWeek: Int(subJson["weekday"].stringValue)!,
                             startTime: Int(subJson["startUnit"].stringValue)!,
                             endTime: Int(subJson["endUnit"].stringValue)!,
                             name: subJson["courseName"].stringValue,
                             classIDString: subJson["courseCode"].stringValue,
                             classPositionString: classPositionString,
                             classTeacherName: subJson["teachers"][0].stringValue,
                             weekString: subJson["weeksStr"].stringValue)

            result.append(tmp)
        }
        return Course.clean(result)
    }

    func forceUpdate() async throws {
        if try await !ustcUgAASClient.requireLogin() {
            throw BaseError.runtimeError("UstcUgAAS Not logined")
        }
        let (_, response) = try await URLSession.shared.data(from: URL(string: "https://jw.ustc.edu.cn/for-std/course-table")!)

        let match = response.url?.absoluteString.matches(of: try! Regex(#"\d+"#))
        var tableID = "0"
        if let match {
            if !match.isEmpty {
                tableID = String(match.first!.0)
            }
        }

        let (data, _) = try await URLSession.shared.data(from: URL(string: "https://jw.ustc.edu.cn/for-std/course-table/semester/\(UstcUgAASClient.getSemesterID())/print-data/\(tableID)?weekIndex=")!)
        cache = try JSON(data: data)
        lastUpdate = Date()
        try saveCache()
    }

    func saveToCalendar() async throws {
        let courses = try await retrive()
        try await Course.saveToCalendar(courses,
                                        name: UstcUgAASClient.semesterName,
                                        startDate: UstcUgAASClient.semesterStartDate)
    }

    init(_ client: UstcUgAASClient) {
        ustcUgAASClient = client
        exceptionCall {
            try self.loadCache()
        }
    }
}
