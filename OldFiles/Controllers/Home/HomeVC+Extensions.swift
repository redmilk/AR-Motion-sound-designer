
import UIKit
import AVFoundation
import Amplitude

// MARK: - Navigation
extension HomeVC {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToSettingsVC" {
            let controller = segue.destination as! SettingsVC
            controller.delegate = self
        }
    }
}

//MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension HomeVC: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        setActiveFrameProcessing(with: sampleBuffer)
        
        guard isRecording else { return }
        
        let writable = canWrite()
        
        if writable, sessionAtSourceTime == nil {
            // Start Writing
            sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            videoWriter.startSession(atSourceTime: sessionAtSourceTime)
        }
        
        if output == videoDataOutput {
            if videoWriterInput.isReadyForMoreMediaData {
                videoWriterInput.append(sampleBuffer)
            }
        } else if writable, output == audioDataOutput, audioWriterInput.isReadyForMoreMediaData {
            audioWriterInput.append(sampleBuffer)
        }
    }
}

extension HomeVC: AVCaptureFileOutputRecordingDelegate {
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if error == nil {
            var filesToShare = [Any]()
            filesToShare.append(outputFileURL)
            let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
}

// MARK: - Delegates
extension HomeVC: SettingsDelegate {

    func toggleConfiguration() {
        configuration = self.configuration == .zone ? .movement : .zone
    }
    
    func toggleZoneUtility() {
        self.zoneBasedSoundUtility?.toggleConfiguration()
    }
    
    func toggleZoneForcePlay() {
        ZoneBaseAudio.shared.isForcePlaying = !ZoneBaseAudio.shared.isForcePlaying
    }
    
    func toggleDrawSkeleton() {
        self.drawSkeleton = !self.drawSkeleton
    }
    
    func toggleBeat() {
        ZoneBaseAudio.shared.playBeatSetting = !ZoneBaseAudio.shared.playBeatSetting
    }
    
    func toggleBigSquares() {
        self.zoneBasedSoundUtility?.toggleBigSquares()
    }
    
    func toggleHeadphones() {
        var enableHeadphones = UserDefaults.standard.bool(forKey: "enableHeadphones")
        enableHeadphones = !enableHeadphones
        UserDefaults.standard.set(enableHeadphones, forKey: "enableHeadphones")
    }
    
    func toggleAverageDots() {
        var averageDotsSmooth = UserDefaults.standard.bool(forKey: "averageDots")
        averageDotsSmooth = !averageDotsSmooth
        UserDefaults.standard.set(averageDotsSmooth, forKey: "averageDots")
    }
    
}

extension HomeVC: ZoneBasedUtilityDelegate {

    func startRecording() {
        startRecord()
    }
    
    func stopRecording() {
        stopRecord()
    }
    
    func changeSoundForBox(zone: Zone) {
        guard !settingsButton.isHidden else { return }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let soundPickerVC = storyboard.instantiateViewController(withIdentifier: "SoundPickerVC") as? SoundPickerVC else { return }
        soundPickerVC.selectedFileName = UserDefaults.standard.string(forKey: zone.keyValue) ?? "" 
        soundPickerVC.zone = zone
        present(soundPickerVC, animated: true)
    }
}

extension HomeVC {
    func canWrite() -> Bool {
        return isRecording && videoWriter != nil && videoWriter.status == .writing
    }
    
    func addWatermark(inputURL: URL, outputURL: URL, handler: @escaping (_ exportSession: AVAssetExportSession?) -> Void) {
        let mixComposition = AVMutableComposition()
        let asset = AVAsset(url: inputURL)
        let videoTrack = asset.tracks(withMediaType: .video)[0]
        let timerange = CMTimeRange(start: .zero, duration: asset.duration)
        
        let compositionVideoTrack:AVMutableCompositionTrack = mixComposition.addMutableTrack(withMediaType: AVMediaType.video, preferredTrackID: CMPersistentTrackID(kCMPersistentTrackID_Invalid))!

        do {
            try compositionVideoTrack.insertTimeRange(timerange, of: videoTrack, at: .zero)
            compositionVideoTrack.preferredTransform = videoTrack.preferredTransform
        } catch {
            print(error)
        }

         let watermarkFilter = CIFilter(name: "CISourceOverCompositing")!
        var watermarkImage = CIImage(image: UIImage(named: "watermark")!)
        watermarkImage = watermarkImage?.transformed(by: CGAffineTransform(scaleX: 0.6, y: 0.6))
         let videoComposition = AVVideoComposition(asset: asset) { (filteringRequest) in
             let source = filteringRequest.sourceImage.clampedToExtent()
             watermarkFilter.setValue(source, forKey: "inputBackgroundImage")
             let transform = CGAffineTransform(translationX: filteringRequest.sourceImage.extent.width - (watermarkImage?.extent.width)! - 2, y: 0)
             watermarkFilter.setValue(watermarkImage?.transformed(by: transform), forKey: "inputImage")
             filteringRequest.finish(with: watermarkFilter.outputImage!, context: nil)
         }

         guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1920x1080) else {
             handler(nil)

             return
         }

         exportSession.outputURL = outputURL
         exportSession.outputFileType = AVFileType.mov
         exportSession.shouldOptimizeForNetworkUse = true
         exportSession.videoComposition = videoComposition
         exportSession.exportAsynchronously { () -> Void in
             handler(exportSession)
         }
    }
}

extension HomeVC {
    
    func addSoundFromTimestamps(to videoURL: URL, soundTimestamps: Dictionary<Double, SoundForTimestamp>, handler: @escaping (URL) -> Void){
        let mixComposition = AVMutableComposition()
        var parametersArray: [AVMutableAudioMixInputParameters] = []
        
        if let mutableCompositionVideoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid), let mutableCompositionAudioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
            
            //adding video to composition
            let videoAsset = AVAsset(url: videoURL)
            let compositionTimeRange = CMTimeRangeMake(start: CMTimeMake(value: 0, timescale: 1), duration: videoAsset.duration)
            if let videoAssetTrack = videoAsset.tracks(withMediaType: .video).first {
                do {
                    mutableCompositionVideoTrack.preferredTransform = videoAssetTrack.preferredTransform
                    try mutableCompositionVideoTrack.insertTimeRange(compositionTimeRange, of: videoAssetTrack, at: CMTimeMake(value: 0, timescale: 1))
                } catch {
                    print(error)
                }
            }
            
            //looped BG sound insertion
            mutableCompositionAudioTrack.insertEmptyTimeRange(compositionTimeRange)
            if let bgSound = bgSound {
                let bgAsset = AVAsset(url: bgSound.url)
                if let bgAssetTrack = bgAsset.tracks(withMediaType: .audio).first {
                    var startPieceOfBG = CMTimeMake(value: 0, timescale: 1)
                    while (startPieceOfBG < compositionTimeRange.end) {
                        do {
                            //insertion shouldn't get out of composition borders
                            let bgTimeRangeDuration = min(bgAsset.duration, CMTimeSubtract(compositionTimeRange.end, startPieceOfBG))
                            let bgTimeRange = CMTimeRangeMake(start: CMTimeMake(value: 0, timescale: 1), duration: bgTimeRangeDuration)
                            try mutableCompositionAudioTrack.insertTimeRange(bgTimeRange, of: bgAssetTrack, at: startPieceOfBG)
                            startPieceOfBG = CMTimeAdd(startPieceOfBG, bgAsset.duration)
                            
                            //adjust volume
                            let parameters = AVMutableAudioMixInputParameters(track: mutableCompositionAudioTrack)
                            parameters.setVolume(bgSound.volume, at: CMTimeMake(value: 0, timescale: 1))
                            parametersArray.append(parameters)
                        } catch {
                            print(error)
                        }
                    }
                }
            }
            
            //sounds from timestamps (played by soundboxes) insertion
            for (timestamp, sound) in soundTimestamps {
                let url = sound.url
                let soundAsset = AVAsset(url: url)
                if let soundAssetTrack = soundAsset.tracks(withMediaType: .audio).first, let mutableCompositionAudioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                    let startOfSound = CMTimeMake(value: Int64(timestamp), timescale: 1)
                    if (startOfSound < compositionTimeRange.end) {
                        do {
                            let soundTimeRangeDuration = min(soundAsset.duration, CMTimeSubtract(compositionTimeRange.end, startOfSound))
                            let soundTimeRange = CMTimeRangeMake(start: CMTimeMake(value: 0, timescale: 1), duration: soundTimeRangeDuration)
                            try mutableCompositionAudioTrack.insertTimeRange(soundTimeRange, of: soundAssetTrack, at: startOfSound)
                            
                            //adjust volume
                            let parameters = AVMutableAudioMixInputParameters(track: mutableCompositionAudioTrack)
                            parameters.setVolume(sound.volume, at: CMTimeMake(value: 0, timescale: 1))
                            parametersArray.append(parameters)
                        } catch {
                            print(error)
                        }
                    }
                }
            }
            
        }
        
        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = parametersArray
        
        //composition export
        exportComposition(composition: mixComposition, audioMix: audioMix) { outputURL in
            handler(outputURL)
        }
    }
    
    func exportComposition(composition: AVMutableComposition, audioMix: AVMutableAudioMix, handler: @escaping (URL) -> Void) {
        if let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) {
            let randNum = Int(arc4random())
            let exportPath = NSTemporaryDirectory().appendingFormat("\(randNum)video.mov") as NSString
            let exportURL = NSURL.fileURL(withPath: exportPath as String) as URL
            exportSession.outputURL = exportURL
            exportSession.outputFileType = AVFileType.mov
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.audioMix = audioMix
            exportSession.exportAsynchronously(completionHandler: { () -> Void in
                DispatchQueue.main.async { () -> Void in
                    if exportSession.status == .completed {
                        handler(exportURL)
                    }
                    else if exportSession.status == .failed {
                        print("Export failed")
                    }
                }
            })
        }
    }
}

extension HomeVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return masks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Mask+MechanicCell", for: indexPath) as! CollectionViewCell
        
        cell.maskName.text = masks[indexPath.item]
        cell.maskLogo.image = maskLogos[indexPath.item]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let chosenMask = masks[indexPath.item]
        
        JiggleAnalytics.logAmplitudeEvent("Mask Selected", with: ["mask name" : masks[indexPath.item]])
        
        switch chosenMask {
        case "Jiggle":
            stopPlayingCurrentZones()
            Zone.allCases.forEach { zone in
                UserDefaults.standard.set(zone.rawValue, forKey: zone.keyValue)
            }
            UserDefaults.standard.set("jiggleBeat", forKey: "backgroundBeatFileName")
            ZoneBaseAudio.shared.prepareBackgroundMusicPlayer()

        case "Squid":
            stopPlayingCurrentZones()
            SquidSounds.allCases.forEach { zone in
                UserDefaults.standard.set(zone.rawValue, forKey: zone.keyValue)
            }
            UserDefaults.standard.set("squidBeat", forKey: "backgroundBeatFileName")
            ZoneBaseAudio.shared.prepareBackgroundMusicPlayer()
        default:
            return
        }
        self.closeMenu(UISwipeGestureRecognizer())
    }
    
    func stopPlayingCurrentZones() {
        ZoneBaseAudio.shared.players.forEach { player in
            player.value.stop()
        }
    }
}

extension HomeVC: SettingsStateDelegate {
    var settingsState: SettingsState {
        return settingsButton.isHidden ? .inactive : .active
    }
}

extension HomeVC: ShowSoundsMenuDelegate {
    func selectSound() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let soundPickerVC = storyboard.instantiateViewController(withIdentifier: "SoundPickerVC") as? SoundPickerVC else { return }
        soundPickerVC.selectedFileName = UserDefaults.standard.string(forKey: "backgroundBeatFileName") ?? ""
        soundPickerVC.output = {
            ZoneBaseAudio.shared.prepareBackgroundMusicPlayer()
        }
        present(soundPickerVC, animated: true)
    }
}

extension HomeVC: RecordingStartDelegate {
    
    var getRecordingStart: Double? {
        return recordingStartTimestamp
    }
    
    func setSoundTimestamps(timestamp: Double, sound: SoundForTimestamp) {
        soundTimestamps[timestamp] = sound
    }
    
    func setBgSound(url: URL, volume: Float) {
        let newBgSound = BgSound(url: url, volume: volume)
        self.bgSound = newBgSound
    }
}
