
import Foundation

enum KungFuSounds: String, CaseIterable {
    case A = "kung-fu 1"
    case B = "kung-fu 3"
    case C = "kung-fu 4"
    case D = "kung-fu 5"
//    case BG = "kung-fu melody"
    
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
        }
    }
}
