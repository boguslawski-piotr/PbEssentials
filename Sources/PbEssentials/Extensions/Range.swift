/// Swift PbEssentials
/// Copyright (c) Piotr Boguslawski
/// MIT license, see License.md file for details.

import Foundation

public extension Range where Bound == Int {
    init(min: Int, max: Int) {
        self.init(uncheckedBounds: (min, max))
    }
}

public extension Range where Bound == Float {
    init(min: Float, max: Float) {
        self.init(uncheckedBounds: (min, max))
    }
}

public extension Range where Bound == Double {
    init(min: Double, max: Double) {
        self.init(uncheckedBounds: (min, max))
    }
}

public extension Range where Bound == CGFloat {
    init(min: CGFloat, max: CGFloat) {
        self.init(uncheckedBounds: (min, max))
    }
}

