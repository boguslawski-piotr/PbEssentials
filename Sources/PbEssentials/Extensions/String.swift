import Foundation

extension String {
    public func asPathComponent() -> String {
        return self.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: "\\", with: "-").replacingOccurrences(of: ":", with: "-")
    }
}

extension String {
    public func satisfy(regexPattern: String, options: NSRegularExpression.Options = [], matchingOptions: NSRegularExpression.MatchingOptions = []) throws
        -> Bool
    {
        let regex = try NSRegularExpression(pattern: regexPattern, options: options)
        let nom = regex.numberOfMatches(in: self, options: matchingOptions, range: .init(location: 0, length: self.count))
        return nom > 0
    }
}

extension String {
    public func replacingVariables(with vars: String...) -> String {
        var result = self
        for (i, `var`) in vars.enumerated() {
            result = result.replacingOccurrences(of: "$\(i)", with: `var`)
        }
        return result
    }
}
