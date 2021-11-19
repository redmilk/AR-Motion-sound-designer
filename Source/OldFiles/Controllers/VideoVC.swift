
import UIKit
import AVFoundation
import Amplitude

class VideoVC: UIViewController {
    
    var player: AVPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
        guard let videoUrl = Bundle.main.url(forResource: "App_short", withExtension: "mp4") else { return }
        player = AVPlayer(url: videoUrl)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.frame
        view.layer.addSublayer(playerLayer)
        NotificationCenter.default.addObserver(self,
                                                  selector: #selector(videoFinishedPlaying),
                                                  name: .AVPlayerItemDidPlayToEndTime,
                                                  object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        player.play()
    }
    
    @objc func videoFinishedPlaying() {
        
        JiggleAnalytics.logAmplitudeEvent("Onboarding Welcome View")
        
        let onboardingVC = UIStoryboard(.onboarding).instantiate(OnboardingVC.self)
        UIApplication.shared.delegate?.window??.rootViewController = onboardingVC
    }
}
