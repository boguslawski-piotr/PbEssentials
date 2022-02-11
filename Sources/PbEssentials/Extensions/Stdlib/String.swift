import Foundation

public extension String
{
    func asPathComponent() -> String {
        return self.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
    }
}

public extension String
{
    func satisfy(regexPattern: String, options: NSRegularExpression.Options = [], matchingOptions: NSRegularExpression.MatchingOptions = []) throws -> Bool {
        let regex = try NSRegularExpression(pattern: regexPattern, options: options)
        let nom = regex.numberOfMatches(in: self, options: matchingOptions, range: .init(location: 0, length: self.count))
        return nom > 0
    }
}
