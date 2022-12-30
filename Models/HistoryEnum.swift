//
//  HistoryEnum.swift
//  Life@USTC (iOS)
//
//  Created by TiankaiMa on 2022/12/18.
//

import SwiftUI

/// Used to represent a certain peroid of time
///
/// The concept is generally related to today, say 2000/10/1 for example,
/// When shown to user, we usually take these five segments: (both sides included)
/// Today: 2000/9/30 - 2000/10/1
/// This week: 2000/9/XX - 2020/9/19
/// ...
enum HistoryEnum: Int, CaseIterable {
    case day = 1
    case week = 7
    case month = 30
    case year = 365
    case longerThanAYear = 400

    var representingString: String {
        switch self {
        case .day:
            return "Today"
        case .week:
            return "This Week"
        case .month:
            return "This Month"
        case .year:
            return "This Year"
        case .longerThanAYear:
            return "Longer than a year"
        }
    }

    var coveringDate: any RangeExpression<Date> {
        let base = Date().stripTime()
        switch self {
        case .day:
            return base + DateComponents(day: -1) ... base
        case .week:
            return base + DateComponents(day: -7) ..< base + DateComponents(day: -1)
        case .month:
            return base + DateComponents(month: -1) ..< base + DateComponents(day: -7)
        case .year:
            return base + DateComponents(year: -1) ..< base + DateComponents(month: -1)
        case .longerThanAYear:
            return Date(timeIntervalSince1970: 0) ..< base + DateComponents(year: -1)
        }
    }

    var coveringDateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none

        let base = Date().stripTime()
        var from: Date
        var to: Date

        switch self {
        case .day:
            from = base + DateComponents(day: -1)
            to = base + DateComponents(day: 0)
        case .week:
            from = base + DateComponents(day: -7)
            to = base + DateComponents(day: -2)
        case .month:
            from = base + DateComponents(month: -1)
            to = base + DateComponents(day: -8)
        case .year:
            from = base + DateComponents(year: -1)
            to = base + DateComponents(month: -1, day: -1)
        case .longerThanAYear:
            to = base + DateComponents(year: -1, day: -1)
            return "Before \(dateFormatter.string(from: to))"
        }
        return dateFormatter.string(from: from) + " - " + dateFormatter.string(from: to)
    }
}

func + (lhs: Date, rhs: DateComponents) -> Date {
    return Calendar.current.date(byAdding: rhs, to: lhs)!
}

extension Date {
    /// Remove hour&minute&second components from a given Date
    func stripTime() -> Date {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: self)
        return Calendar.current.date(from: components)!
    }
}