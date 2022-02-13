/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

public struct PbError : Error, LocalizedError, Codable
{
    public var description : String { return "\(when.formatted(.short, time: .medium)): \(what)" }
    public var shortDescription : String { return "\(what)" }
    public var errorDescription : String? { description }
    public var shortErrorDescription : String? { shortDescription }
    public var localizedDescription : String { description }
    public var shortLocalizedDescription : String { shortDescription }
    public var debugDescription : String? { description }
    public var shortDebugDescription : String? { shortDescription }

    public init(_ what: String) {
        self.when = Date()
        self.what = what
    }

    public init(_ error: Error) {
        if let e = error as? PbError {
            self.when = e.when
            self.what = e.what
        } else {
            self.when = Date()
            self.what = error.localizedDescription
            self.error = error
        }
    }
    
    public enum CodingKeys: String, CodingKey {
        case when
        case what
    }
    
    private let when : Date
    private let what : String
    private var error : Error?
}

