import Foundation
import UIKit

enum Zone: String, CaseIterable {
    case A = "jiggleA.wav"
    case B = "jiggleB.wav"
    case C = "jiggleC.wav"
    case D = "jiggleD.wav"
    case E, F, G, H, I, J, K
    
    var keyValue: String {
        switch self {
        case .A:
            return "AZone"
        case .B:
            return "BZone"
        case .C:
            return "CZone"
        case .D:
            return "DZone"
        case .E:
            return "EZone"
        case .F:
            return "FZone"
        case .G:
            return "GZone"
        case .H:
            return "HZone"
        case .I:
            return "IZone"
        case .J:
            return "JZone"
        case .K:
            return "KZone"
        }
    }
}
