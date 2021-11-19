
import UIKit

class CountdownView: UIView {

    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var jiggleImage: UIImageView!
    
    var completion: (() -> Void)?
    var timer: Timer?
    var countdown: Int = 3
    
    func start() {
        jiggleImage.alpha = 0
        timerLabel.alpha = 0
        
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: superview!.topAnchor),
            bottomAnchor.constraint(equalTo: superview!.bottomAnchor),
            leadingAnchor.constraint(equalTo: superview!.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview!.trailingAnchor),
        ])
        
        show(true, completion: {
            self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.updateCountdown), userInfo: nil, repeats: true)
            self.timer?.fire()
        })
    }
    
    @objc func updateCountdown() {
        switch countdown {
        case 1...3:
            updateLabel(countdown)
        case 0:
            showJiggle()
        default:
            show(false, completion: {
                self.timer?.invalidate()
                self.timer = nil
                self.completion?()
                self.removeFromSuperview()
            })
        }
        
        countdown -= 1
    }
    
    func updateLabel(_ countdown: Int) {
        timerLabel.text = "\(countdown)"
        UIView.animate(withDuration: 0.3, animations: {
            self.timerLabel.alpha = 1
        }, completion: { _ in
            UIView.animate(withDuration: 0.7, animations: {
                self.timerLabel.alpha = 0
            })
        })
    }
    
    func showJiggle() {
        UIView.animate(withDuration: 0.3, animations: {
            self.jiggleImage.alpha = 1
            self.jiggleImage.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }, completion: { _ in
            UIView.animate(withDuration: 0.3, delay: 0.4, options: [], animations: {
                self.jiggleImage.alpha = 0
                self.jiggleImage.transform = CGAffineTransform(scaleX: 2, y: 2)
            }, completion: nil)
        })
    }
}
