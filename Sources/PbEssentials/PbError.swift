//
//  Created by Piotr Boguslawski on 08/12/2021.
//

import Foundation

public class PbError : Error, LocalizedError
{
    public let when : Date
    public let what : String
    public let error : Error?
    
    public var description : String { return "\(when.shortWithTimeWithSeconds): \(what)" }
    public var shortDescription : String { return "\(what)" }
    public var errorDescription : String? { description }
    public var shortErrorDescription : String? { shortDescription }
    public var localizedDescription : String { description }
    public var shortLocalizedDescription : String { shortDescription }
    public var debugDescription : String? { description }
    public var shortDebugDescription : String? { shortDescription }

    public init() {
        self.error = nil
        self.when = Date.distantPast
        self.what = ""
    }
    
    public init(_ error : Error) {
        if let e = error as? PbError {
            self.error = nil
            self.when = e.when
            self.what = e.what
        }
        else {
            self.error = error
            self.when = Date()
            self.what = error.localizedDescription
        }
    }
    
    public init(_ error : PbError) {
        self.error = nil
        self.when = error.when
        self.what = error.what
    }
    
    public init(_ what : String) {
        self.error = nil
        self.when = Date()
        self.what = what
    }
}

