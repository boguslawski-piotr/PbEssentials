
// MARK: Debug tools

public func dbg(_ items: Any..., function : String = #function, line : Int = #line) {
#if DEBUG
    print("DBG:", "\(function): \(line):", "", terminator: "")
    for item in items {
        print(item, "", terminator: "")
    }
    print(terminator: "\n")
#endif
}
