import Foundation
import UIKit

extension CGRect {
  /// Returns a `Bool` indicating whether the rectangle has any value that is `NaN`.
  func isNaN()  -> Bool {
    return origin.x.isNaN || origin.y.isNaN || width.isNaN || height.isNaN
  }
}

