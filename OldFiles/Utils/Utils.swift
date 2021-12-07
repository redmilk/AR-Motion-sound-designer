
import UIKit

extension UIStoryboard {
    
    enum Name: String {
        case main   = "Main"
        case onboarding = "Onboarding"
    }
    
    convenience init(_ name: Name, bundle: Bundle? = nil) {
        self.init(name: name.rawValue, bundle: bundle)
    }
    
    func instantiate<T: UIViewController>(_ type: T.Type) -> T {
        instantiateViewController(withIdentifier: String(describing: type)) as! T
    }
    
}

extension BinaryInteger {
    var degreesToRadians: CGFloat { CGFloat(self) * .pi / 180 }
}

extension FloatingPoint {
    var degreesToRadians: Self { self * .pi / 180 }
    var radiansToDegrees: Self { self * 180 / .pi }
}

extension UIView {
    class func fromNib(named: String? = nil) -> Self {
        let name = named ?? "\(Self.self)"
        guard
            let nib = Bundle.main.loadNibNamed(name, owner: nil, options: nil)
            else { fatalError("missing expected nib named: \(name)") }
        guard
            let view = nib.first as? Self
            else { fatalError("view of type \(Self.self) not found in \(nib)") }
        return view
    }
    
    func show(_ show: Bool, completion: (() -> Void)?) {
        alpha = show ? 0 : 1
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = show ? 1 : 0
        }, completion: { _ in
            completion?()
        })
    }
}
