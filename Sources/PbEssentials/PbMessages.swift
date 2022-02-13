/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

/// Simplified interface for Foundation.NotificationCenter.
final public class PbMessages<Sender> where Sender: Identifiable {
    private let notificationCenter: NotificationCenter?
    private let sender: Sender?

    public init(_ sender: Sender?, notificationCenter: NotificationCenter? = NotificationCenter.default) {
        self.notificationCenter = notificationCenter
        self.sender = sender
    }

    deinit {
        cancelSubscriptions(for: subscriptions.compactMap({ $0.name }), from: subscriptions.compactMap({ $0.sender }))
    }

    public func send(_ name: String, data: Any? = nil) {
        var data_ = [Int: Any]()
        data_[0] = data
        notificationCenter?.post(Notification(name: NSNotification.Name(name), object: sender, userInfo: data_))
    }

    public func read(_ name: String, using block: @escaping (Any?) -> Void) {
        read(name, from: sender, using: block)
    }

    public func read(_ name: String, from sender: Sender?, using block: @escaping (Any?) -> Void) {
        var observer: NSObjectProtocol?
        observer = notificationCenter?.addObserver(forName: NSNotification.Name(name), object: sender, queue: .main) { msg in
            let data = msg.userInfo?[0]
            block(data)
            self.notificationCenter?.removeObserver(observer!, name: NSNotification.Name(name), object: sender)
        }
    }

    private var subscriptions: [(name: String, sender: Sender?, observer: Any?)] = []

    public func subscribe(to name: String, using block: @escaping (Any?) -> Void) {
        subscribe(to: name, from: sender, using: block)
    }

    public func subscribe(to name: String, from sender: Sender?, using block: @escaping (Any?) -> Void) {
        subscriptions.append(
            (
                name, sender,
                notificationCenter?.addObserver(forName: NSNotification.Name(name), object: sender, queue: .main) { msg in
                    let data = msg.userInfo?[0]
                    block(data)
                }
            )
        )
    }

    public func cancelSubscriptions(for names: [String]) {
        cancelSubscriptions(for: names, from: Array(repeating: sender, count: names.count))
    }

    public func cancelSubscriptions(for names: [String], from senders: [Sender?]) {
        assert(names.count == senders.count)
        guard !subscriptions.isEmpty else { return }
        guard !names.isEmpty else { return }

        // TODO: uproscic ten ponizszy algorytm?

        for n in 0...names.count - 1 {
            for o in 0...subscriptions.count - 1 {
                if subscriptions[o].name == names[n] {
                    if subscriptions[o].sender?.id == senders[n]?.id {
                        notificationCenter?.removeObserver(subscriptions[o].observer!, name: NSNotification.Name(subscriptions[o].name), object: senders[n])
                        subscriptions[o].observer = nil
                        subscriptions[o].name = ""
                    }
                }
            }
        }

        subscriptions.removeAll(where: { $0.observer == nil })
    }
}

open class UsesMessages: Identifiable, Equatable {
    public let id: UUID

    public init() {
        self.id = UUID()
    }

    public init(with id: UUID) {
        self.id = id
    }

    public init(basedOn obj: UsesMessages) {
        self.id = obj.id
    }

    public static func == (lhs: UsesMessages, rhs: UsesMessages) -> Bool {
        lhs.id == rhs.id
    }

    open lazy var messages = PbMessages(self)
    open lazy var localMessages = PbMessages(self, notificationCenter: NotificationCenter())
}
