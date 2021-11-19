
import UIKit

class ProcessingView: UIView {

    func start() {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview!.topAnchor),
            bottomAnchor.constraint(equalTo: superview!.bottomAnchor),
            leadingAnchor.constraint(equalTo: superview!.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview!.trailingAnchor),
        ])
        
        show(true, completion: { })
    }
    
    func end() {
        show(true, completion: {
            self.removeFromSuperview()
        })
    }
    
}
