//
//  Helpers.swift
//  MAForexAPP
//
//  Created by Jamie Winfield on 5/14/22.
//

import Foundation

public func GetDate(day: Int) -> String
{
    var dayComponent = DateComponents()
    dayComponent.day = day
    let calendar = Calendar.current
    let date = calendar.date(byAdding: dayComponent, to: Date())!
    let formatter = DateFormatter()
    formatter.locale = .current
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.string(from: date)
}
