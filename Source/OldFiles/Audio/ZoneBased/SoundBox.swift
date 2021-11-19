import UIKit

class SoundBox: UIView {
    var inactiveColor: UIColor
    var activeColor: UIColor
    var isActive = false {
        didSet {
            backgroundColor = isActive ? activeColor : inactiveColor
        }
    }
    var zone: Zone
    
    required init(inactiveColor: UIColor, activeColor: UIColor, borderColor: UIColor, maskedCorners: CACornerMask, zone: Zone) {
        self.inactiveColor = inactiveColor
        self.activeColor = activeColor
        self.zone = zone
        
        super.init(frame: .zero)
        self.backgroundColor = inactiveColor
        self.layer.borderWidth = 4
        self.layer.borderColor = borderColor.cgColor
        self.layer.cornerRadius = 10
        self.layer.maskedCorners = [maskedCorners]
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
