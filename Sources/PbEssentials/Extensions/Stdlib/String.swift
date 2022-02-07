
public extension String
{
    var asPathComponent : String {
        return self.replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-")
    }
}
