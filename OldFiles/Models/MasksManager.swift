
import Foundation

class MaskManager: NSObject {
    
    static let shared = MaskManager()
    
    var masks = [Mask]()
    var currentMask: Mask? {
        didSet {
            
        }
    }
    
    private override init() {
        super.init()
        
        setupMasks()
    }
    
    func setupMasks() {
        let jiggleMask = Mask(maskType: .jiggle, soundSet: SoundSet(soundNames: ["jiggle1", "jiggle2", "jiggle3", "jiggle4"], beatName: "jiggleBeat"), mechanic: .square)
        let kungFuMask = Mask(maskType: .kungfu, soundSet: SoundSet(soundNames: ["kungfu1", "kungfu2", "kungfu3", "kungfu4"], beatName: "kungFuBeat"), mechanic: .gestures)
        let waveMask = Mask(maskType: .waves, soundSet: SoundSet(soundNames: ["bass", "scratch", "synth", "vox"], beatName: "beat"), mechanic: .square, isEditable: true)
        masks.append(contentsOf: [jiggleMask, kungFuMask, waveMask])
    }
    
    func loadMask(maskType: MaskType) {
        currentMask = masks.first(where: { $0.maskType == maskType } )!
    }
}

