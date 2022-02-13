/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Combine
import Foundation

public protocol PbProgress {
    var total: Int { get set }
    var completed: Int { get set }
    var description: String { get set }
}

extension PbProgress {
    public var percent: Int {
        total != 0 ? Int((Double(completed) / Double(total) * 100.0).rounded()) : 0
    }

    public mutating func step(_ step: Int, of total: Int, _ description: String = "") {
        self.total = total
        self.completed = step
        self.description = description
    }

    public mutating func start(total: Int) {
        self.total = total
        self.completed = 0
        self.description = ""
    }

    public mutating func inc(by: Int = 1) {
        self.completed += by
    }

    public mutating func description(_ description: String = "") {
        self.description = description
    }

    public mutating func clear() {
        self.total = 0
        self.completed = 0
        self.description = ""
    }

    public mutating func update(from: PbProgress) {
        self.total = from.total
        self.completed = from.completed
        self.description = from.description
    }
}

public struct PbSimpleProgress: PbProgress {
    public var total: Int = 0
    public var completed: Int = 0
    public var description: String = ""

    public init(total: Int = 0, completed: Int = 0, description: String = "") {
        self.total = total
        self.completed = completed
        self.description = description
    }
}

public class PbObservableProgress: PbProgress, PbObservableObject {
    @PbPublished public var total: Int = 0
    @PbPublished public var completed: Int = 0
    @PbPublished public var description: String = ""

    public init(total: Int = 0, completed: Int = 0, description: String = "") {
        self.total = total
        self.completed = completed
        self.description = description
    }

    @discardableResult
    public func onChange<T>(publishTo observableObject: T?) -> PbObservableProgress
    where T: PbObservableObject, T.ObjectWillChangePublisher == ObservableObjectPublisher {
        return onChange { observableObject?.objectWillChange.send() }
    }

    @discardableResult
    public func onChange(action: @escaping () -> Void) -> PbObservableProgress {
        subscriptions.append(
            objectWillChange
                .sink {
                    action()
                }
        )
        return self
    }

    private var subscriptions: [AnyCancellable?] = []

    deinit {
        subscriptions.enumerated().forEach({
            $0.element?.cancel()
            subscriptions[$0.offset] = nil
        })
    }
}
