/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

extension Date {
    public func asPathComponent(withMiliseconds: Bool = false) -> String {
        withMiliseconds ? "\(self.timeIntervalSinceReferenceDate)" : "\(Int64(self.timeIntervalSinceReferenceDate))"
    }

    public static func asPathComponent(withMiliseconds: Bool = false) -> String {
        withMiliseconds ? "\(Self.timeIntervalSinceReferenceDate)" : "\(Int64(Self.timeIntervalSinceReferenceDate))"
    }

    public init?(pathComponent: String) {
        if let vi = TimeInterval(pathComponent) {
            self.init(timeIntervalSinceReferenceDate: vi)
        } else {
            return nil
        }
    }

    public func formatted(_ date: DateFormatter.Style = .short, time: DateFormatter.Style = .none) -> String {
        let df = DateFormatter()
        df.dateStyle = date
        df.timeStyle = time
        return df.string(from: self)
    }

    public func easilyReadable(dateTimeSeparator: String = ", ") -> String {
        let df = DateFormatter()
        let cal = Calendar.autoupdatingCurrent

        if cal.isDateInToday(self) {
            df.dateStyle = .none
            df.timeStyle = .short
        } else {
            let now = Date()
            let weekAgo = now.advanced(by: -(604_800))
            if self > weekAgo && self < now {
                let weekday = cal.weekdaySymbols[cal.component(.weekday, from: self) - 1]
                df.dateStyle = .none
                df.timeStyle = .short
                return weekday + dateTimeSeparator + df.string(from: self)
            } else {
                var date = ""
                if cal.component(.year, from: self) == cal.component(.year, from: now) {
                    df.locale = Locale.current
                    df.setLocalizedDateFormatFromTemplate("dMMM")
                    date = df.string(from: self)
                } else {
                    df.dateStyle = .medium
                    df.timeStyle = .none
                    date = df.string(from: self)
                }

                df.dateStyle = .none
                df.timeStyle = .short
                return date + dateTimeSeparator + df.string(from: self)
            }
        }
        return df.string(from: self)
    }

    public func asPathComponentEasilyReadable(time: DateFormatter.Style = .none) -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        let date = df.string(from: self)
        if time == .short || time == .medium {
            df.dateFormat = " HH-mm"
            if time == .medium {
                df.dateFormat += "-ss"
            }
            return (date + df.string(from: self)).asPathComponent()
        }
        return date.asPathComponent()
    }

    public static func asPathComponentEasilyReadable(time: DateFormatter.Style = .none) -> String {
        Date().asPathComponentEasilyReadable(time: time)
    }
}

extension TimeInterval {
    public static func nanoseconds(_ v: Int) -> TimeInterval { return TimeInterval(v) / 1_000_000_000.0 }
    public static func microseconds(_ v: Int) -> TimeInterval { return TimeInterval(v) / 1_000_000.0 }
    public static func miliseconds(_ v: Int) -> TimeInterval { return TimeInterval(v) / 1000.0 }
    public static func seconds(_ v: Int) -> TimeInterval { return TimeInterval(v) }
}
