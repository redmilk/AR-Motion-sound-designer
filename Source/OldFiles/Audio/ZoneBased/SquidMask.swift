
import Foundation

enum SquidSounds: String, CaseIterable {
    case A = "vox A"
    case B = "vox B"
    case C = "boom C"
    case D = "boom D"
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
