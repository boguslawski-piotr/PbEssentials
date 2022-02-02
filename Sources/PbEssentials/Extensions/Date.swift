/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

public extension Date
{
    @inlinable
    var shortWithTime : String {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df.string(from: self)
    }
    
    @inlinable
    var shortWithTimeWithSeconds : String {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .medium
        return df.string(from: self)
    }

    var easilyReadable : String {
        let df = DateFormatter()
        let cal = Calendar.autoupdatingCurrent
        
        if cal.isDateInToday(self) {
            df.dateStyle = .none
            df.timeStyle = self > Date().advanced(by: -60) ? .medium : .short
        }
        else {
            let weekAgo = Date().advanced(by: -(604_800))
            if self > weekAgo {
                let weekday = cal.weekdaySymbols[cal.component(.weekday, from: self) - 1]
                df.dateStyle = .none
                df.timeStyle = .short
                let time = df.string(from: self)
                return weekday + ", " + time
            }
            else {
//                if cal.component(.year, from: self) == cal.component(.year, from: Date()) {
//                    df.dateFormat = DateFormatter.dateFormat(fromTemplate: "dMMMhhmm", options: 0, locale: cal.locale)
//                }
//                else {
                    df.dateStyle = .medium
                    df.timeStyle = .short
//                }
            }
        }
        return df.string(from: self)
    }
}

public extension TimeInterval
{
    static func nanoseconds(_ v : Int) -> TimeInterval  { return TimeInterval(v) / 1_000_000_000.0 }
    static func microseconds(_ v : Int) -> TimeInterval { return TimeInterval(v) / 1_000_000.0 }
    static func miliseconds(_ v : Int) -> TimeInterval  { return TimeInterval(v) / 1000.0 }
    static func seconds(_ v : Int) -> TimeInterval      { return TimeInterval(v) }
}
