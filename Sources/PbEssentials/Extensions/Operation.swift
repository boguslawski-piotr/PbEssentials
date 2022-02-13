/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

extension Operation {
    @inlinable
    open func sleep(nanoseconds duration: UInt64) throws {
        try sleep(for: TimeInterval(Double(duration) / 1_000_000_000.0))
    }

    @inlinable
    open func sleep(for ti: TimeInterval) throws {
        if !sleep(for: ti, checkingCancellation: true) {
            throw CancellationError()
        }
    }

    open func sleep(for ti: TimeInterval, checkingCancellation: Bool) -> Bool {
        if !checkingCancellation {
            Thread.sleep(forTimeInterval: ti)
        } else {
            assert(ti >= 1.0 / 1000.0)
            let startedAt = Date()
            repeat {
                guard !isCancelled else { return false }
                Thread.sleep(forTimeInterval: 1.0 / 1000.0)
            } while DateInterval(start: startedAt, end: Date()).duration < ti
        }
        return !isCancelled
    }
}

extension OperationQueue {
    @inlinable
    public static func + (left: OperationQueue, right: Foundation.Operation) -> OperationQueue {
        left.addOperation(right)
        return left
    }

    @inlinable
    public static func += (left: OperationQueue, right: Foundation.Operation) {
        left.addOperation(right)
    }
}
