
import UIKit
import AVFoundation
import Amplitude

class OnboardingVC: UIViewController {
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var placeholderView: UIView!
    let countdownDuration: Double = 5.0
    let animationDuration: Double = 1.0
    let shape = CAShapeLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        placeholderView.backgroundColor = .clear
        placeholderView.layer.addSublayer(shape)
        hideViews(true)
        step1Start()
    }
    
    func addCountdownLayer(in view: UIView) {
        
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: view.bounds.midX, y: view.bounds.midY),
                                      radius: view.frame.height / 2,
                                      startAngle: CGFloat(270.001.degreesToRadians),
                                      endAngle: CGFloat(270.0.degreesToRadians),
                                      clockwise: true)

        shape.path = circlePath.cgPath
        shape.lineWidth = 3
        shape.strokeColor = UIColor.white.cgColor
        shape.fillColor = UIColor.clear.cgColor
        shape.strokeStart = 0

        let animation = CABasicAnimation(keyPath: "strokeStart")
        animation.toValue = 1
        animation.duration = countdownDuration
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        shape.add(animation, forKey: "animation")
    }
    
    func hideViews(_ hide: Bool) {
        titleLabel.alpha = hide ? 0 : 1
        image.alpha = hide ? 0 : 1
        placeholderView.alpha = hide ? 0 : 1
    }
    
    func step1Start() {
        titleLabel.text = "Find better lighting"
        self.addCountdownLayer(in: self.placeholderView)
        UIView.animate(withDuration: countdownDuration, animations: {
            self.image.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        })
        UIView.animate(withDuration: animationDuration, animations: {
            self.hideViews(false)
        }, completion: { _ in
            Timer.scheduledTimer(withTimeInterval: self.countdownDuration, repeats: false, block: { _ in
                self.step1Finish()
            })
        })
    }
    
    func step1Finish () {
        
        JiggleAnalytics.logAmplitudeEvent("Onboarding 1 View")
        
        UIView.animate(withDuration: animationDuration, animations: {
            self.hideViews(true)
        }, completion: { _ in
            self.step2Start()
        })
    }
    
    func step2Start() {
        titleLabel.text = "Position your phone"
        image.image = UIImage(named: "position")
        image.transform = .identity
        UIView.animate(withDuration: countdownDuration, animations: {
            self.image.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        })
        self.addCountdownLayer(in: self.placeholderView)
        UIView.animate(withDuration: animationDuration, animations: {
            self.hideViews(false)
        }, completion: { _ in
            Timer.scheduledTimer(withTimeInterval: self.countdownDuration, repeats: false, block: { _ in
                self.step2Finish()
            })
        })
    }
    
    func step2Finish () {
        
        JiggleAnalytics.logAmplitudeEvent("Onboarding 2 View")
        
        UIView.animate(withDuration: animationDuration, animations: {
            self.hideViews(true)
        }, completion: { _ in
            let homeVC = UIStoryboard(.main).instantiate(HomeVC.self)
            UIApplication.shared.delegate?.window??.rootViewController = homeVC
        })
    }
}
