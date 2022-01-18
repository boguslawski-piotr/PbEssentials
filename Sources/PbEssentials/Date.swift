//
//  Created by Piotr Boguslawski on 10/01/2022.
//

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
}

public extension TimeInterval
{
    static func nanoseconds(_ v : Int) -> TimeInterval  { return TimeInterval(v) / 1_000_000_000.0 }
    static func microseconds(_ v : Int) -> TimeInterval { return TimeInterval(v) / 1_000_000.0 }
    static func miliseconds(_ v : Int) -> TimeInterval  { return TimeInterval(v) / 1000.0 }
    static func seconds(_ v : Int) -> TimeInterval      { return TimeInterval(v) }
}
