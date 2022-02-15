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

public extension PbProgress {
    var percent: Int {
        total != 0 ? Int((Double(completed) / Double(total) * 100.0).rounded()) : 0
    }

    mutating func step(_ step: Int, of total: Int, _ description: String = "") {
        self.total = total
        completed = step
        self.description = description
    }

    mutating func start(total: Int) {
        self.total = total
        completed = 0
        description = ""
    }

    mutating func inc(by: Int = 1) {
        completed += by
    }

    mutating func description(_ description: String = "") {
        self.description = description
    }

    mutating func clear() {
        total = 0
        completed = 0
        description = ""
    }

    mutating func update(from: PbProgress) {
        total = from.total
        completed = from.completed
        description = from.description
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
    public func onChange<T>(publishTo observableObject: T?) -> Self where T: PbObservableObject, T.ObjectWillChangePublisher == ObservableObjectPublisher {
        onChange { observableObject?.objectWillChange.send() }
    }

    @discardableResult
    public func onChange(action: @escaping () -> Void) -> Self {
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
        subscriptions.enumerated().forEach {
            $0.element?.cancel()
            subscriptions[$0.offset] = nil
        }
    }
}
