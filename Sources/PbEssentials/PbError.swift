//
//  Created by Piotr Boguslawski on 08/12/2021.
//

/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

public struct PbError : Error, LocalizedError, Codable
{
    public enum CodingKeys: String, CodingKey {
        case when
        case what
    }
    
    public let when : Date
    public let what : String
    public var error : Error?
    
    public var description : String { return "\(when.formatted(.short, time: .medium)): \(what)" }
    public var shortDescription : String { return "\(what)" }
    public var errorDescription : String? { description }
    public var shortErrorDescription : String? { shortDescription }
    public var localizedDescription : String { description }
    public var shortLocalizedDescription : String { shortDescription }
    public var debugDescription : String? { description }
    public var shortDebugDescription : String? { shortDescription }

    public init() {
        self.when = Date.distantPast
        self.what = ""
    }
    
    public init(_ error: Error) {
        if let e = error as? PbError {
            self.when = e.when
            self.what = e.what
        }
        else {
            self.error = error
            self.when = Date()
            self.what = error.localizedDescription
        }
    }
    
    public init(_ error: NSError) {
        self.error = error
        self.when = Date()
        self.what = error.localizedDescription
        // TODO: skonstruowac `what` ze wszystkich danych, ktore dostarcza NSError
    }

    public init(_ error: PbError) {
        self.when = error.when
        self.what = error.what
    }
    
    public init(_ what: String) {
        self.when = Date()
        self.what = what
    }
}

