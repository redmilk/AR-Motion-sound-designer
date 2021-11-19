
struct SoundSet {
    var soundNames = [String]()
    var beatName = ""
}

enum Mechanic {
    case square
    case gestures
}

enum MaskType {
    case jiggle
    case kungfu
    case waves
}

struct Mask {
    var maskType: MaskType
    var soundSet: SoundSet
    var mechanic: Mechanic
    var isEditable: Bool = false
}
