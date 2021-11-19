import Foundation
import AVFoundation

class ZoneBaseAudio: NSObject, AVAudioPlayerDelegate {

    static let shared = ZoneBaseAudio()
    private var backgroundMusicPlayer: AVAudioPlayer?
    var delegate: RecordingStartDelegate?

    private override init() {
        super.init()
    }

    var players: [URL: AVAudioPlayer] = [:]
    var duplicatePlayers: [AVAudioPlayer] = []
    var isForcePlaying = false
    var playBeatSetting = true {
        didSet {
            prepareBackgroundMusicPlayer()
        }
    }
    
    func restartBeat() {
        stopBeat()
        prepareBackgroundMusicPlayer()
    }
    
    func stopBeat() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }
    
    func prepareBackgroundMusicPlayer() {
        if !playBeatSetting {
            stopBeat()
            return
        }
        
//        guard let fileName = UserDefaults.standard.string(forKey: "backgroundBeatFileName") else { return }
//        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let beatFileNameURL = documentsUrl.appendingPathComponent(fileName)
        
        var fileNameURL: URL?
        guard let fileName = UserDefaults.standard.string(forKey: "backgroundBeatFileName") else { return }
        if !fileName.hasSuffix(".wav") && !fileName.hasSuffix(".mp3") {
            guard let bundle = Bundle.main.path(forResource: fileName, ofType: "wav") else { return }
            fileNameURL = URL(fileURLWithPath: bundle)
        } else {
            let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            fileNameURL = documentsUrl.appendingPathComponent(fileName)
        }
        
        guard let soundFileNameURL = fileNameURL else { return }
    
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: soundFileNameURL)
            backgroundMusicPlayer?.numberOfLoops = -1
            backgroundMusicPlayer?.volume = getVolumeForBG()
            backgroundMusicPlayer?.prepareToPlay()
            backgroundMusicPlayer?.play()
            delegate?.setBgSound(url: soundFileNameURL, volume: getVolumeForBG())
        } catch let error {
            print(error)
        }
    }

    func playSound(_ zone: Zone) {

//        guard let fileName = UserDefaults.standard.string(forKey: zone.keyValue) else { return }
//        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        let soundFileNameURL = documentsUrl.appendingPathComponent(fileName)
        
        var fileNameURL: URL?
        guard let fileName = UserDefaults.standard.string(forKey: zone.keyValue) else { return }
        if !fileName.hasSuffix(".wav") && !fileName.hasSuffix(".mp3") {
            guard let bundle = Bundle.main.path(forResource: fileName, ofType: "wav") else { return }
            fileNameURL = URL(fileURLWithPath: bundle)
        } else {
            let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            fileNameURL = documentsUrl.appendingPathComponent(fileName)
        }
        
        guard let soundFileNameURL = fileNameURL else { return }
        
        if let player = players[soundFileNameURL]  { //player for sound has been found
            
            if !player.isPlaying { //player is not in use, so use that one
                player.volume = getVolumeForZone(for: zone)
                player.prepareToPlay()
                player.play()
                makeTimestamp(with: soundFileNameURL, and: player.volume)
            } else if isForcePlaying { // player is in use, create a new, duplicate, player and use that instead

                do {
                    let duplicatePlayer = try AVAudioPlayer(contentsOf: soundFileNameURL)

                    duplicatePlayer.delegate = self
                    //assign delegate for duplicatePlayer so delegate can remove the duplicate once it's stopped playing

                    duplicatePlayers.append(duplicatePlayer)
                    //add duplicate to array so it doesn't get removed from memory before finishing

                    duplicatePlayer.volume = getVolumeForZone(for: zone)
                    duplicatePlayer.prepareToPlay()
                    duplicatePlayer.play()
                    makeTimestamp(with: soundFileNameURL, and: player.volume)
                } catch let error {
                    print(error.localizedDescription)
                }

            }
        } else { //player has not been found, create a new player with the URL if possible
            do {
                let player = try AVAudioPlayer(contentsOf: soundFileNameURL)
                players[soundFileNameURL] = player
                player.volume = getVolumeForZone(for: zone)
                player.prepareToPlay()
                player.play()
                makeTimestamp(with: soundFileNameURL, and: player.volume)
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if let index = duplicatePlayers.firstIndex(of: player) {
            duplicatePlayers.remove(at: index)
        }
    }
  
    func getVolumeForZone(for zone: Zone) -> Float{
        let key = "volume" + zone.keyValue
        if UserDefaults.standard.object(forKey: key) == nil {
            return 0.5
        }
        
        let volume = UserDefaults.standard.float(forKey: key)
        return volume
    }
    
    func getVolumeForBG() -> Float{
        let key = "volumeBG"
        if UserDefaults.standard.object(forKey: key) == nil {
            return 0.5
        }
        
        let volume = UserDefaults.standard.float(forKey: key)
        return volume
    }
    
    func setVolumeForBG(newVolume: Float) {
        UserDefaults.standard.setValue(newVolume, forKey: "volumeBG")
        backgroundMusicPlayer?.setVolume(newVolume, fadeDuration: 0)
    }    
    func makeTimestamp(with url: URL, and volume: Float){
        if let recordingStart = delegate?.getRecordingStart {
            let timestamp = NSDate.timeIntervalSinceReferenceDate - recordingStart
            let sound = SoundForTimestamp(url: url, volume: volume, duration: 0)
            delegate?.setSoundTimestamps(timestamp: timestamp, sound: sound)
        }
        
    }

}
