import UIKit
import MLKit

struct Line {
  let id: Int
  let from: CGPoint
  let to: CGPoint
  let fromBodyPart: PoseLandmarkType
  let toBodyPart: PoseLandmarkType
}

struct Joint {
    var line1: Line?
    var line2: Line?
    var type: PoseLandmarkType
    var angle: Double = 0.0
    var angleInt: Int {
        return Int(angle)
    }
}
