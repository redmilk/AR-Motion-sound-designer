import Foundation
import UIKit
import MLKit
//import AVFAudio
import AVFoundation

struct PlayingZone {
    var zone: Zone
    
    init(_ zone: Zone) {
        self.zone = zone
    }
}

protocol ZoneBasedUtilityDelegate {
    func startRecording()
    func stopRecording()
    func changeSoundForBox(zone: Zone)
}

protocol VolumeValuesDelegate {
    func getVolumeAtStart() -> Float
    func setVolumeAtFinish(newVolume: Float)
}


class ZoneBasedUtility: NSObject {
    
    enum Configuration: String {
        case dotInBox = "dot"
        case lineCrossing = "line"
    }
    var bigSquares = false
    var delegate: ZoneBasedUtilityDelegate?
    var settingsStateDelegate: SettingsStateDelegate?
    var showSoundsMenuDelegate: ShowSoundsMenuDelegate?
    var isRecording: Bool = false
    private var parentView: UIView
    private var adjustVolumeView: AdjustVolumeView?
    private var currentAdjustedZone: Zone?
    private var currentlyAdjustingBG = false
    private var playingZones = [PlayingZone]()
    var currentConfiguration: Configuration = .dotInBox
    // here we add trigger parts of body
    var posesForPlayingSound: [PoseLandmarkType] = [.leftWrist,
                                                    .rightWrist,
                                                    .rightAnkle, .rightHeel, .rightToe, // Left leg
                                                    .leftAnkle, .leftHeel, .leftToe] // Right leg
    
    init(view: UIView) {
        self.parentView = view
        super.init()
        layoutSoundBoxes()
        
        Zone.allCases.forEach { zone in
            self.playingZones.append(PlayingZone(zone))
        }
    }
    
    // MARK: - Public
    
    // Dots
    func process(_ dots: [CGPoint]) {
        
        for playingZone in playingZones {
            let enteredZone = dotsEnteredZone(with: dots, for: playingZone.zone)
            if enteredZone {
                ZoneBaseAudio.shared.playSound(playingZone.zone)
            }
        }
    }
    
    func toggleConfiguration() {
        switch currentConfiguration {
        case .dotInBox:
            currentConfiguration = .lineCrossing
        case .lineCrossing:
            currentConfiguration = .dotInBox
        }
    }
    
    
    func toggleBigSquares() {
        bigSquares = !bigSquares
        clearBoxes()
        layoutSoundBoxes()
    }
    
    // MARK: - View
    
    private lazy var soundBoxA = SoundBox(inactiveColor: #colorLiteral(red: 0.3529411765, green: 0.768627451, blue: 0.8509803922, alpha: 0.5), activeColor: #colorLiteral(red: 0.3529411765, green: 0.768627451, blue: 0.8509803922, alpha: 0.8), borderColor: #colorLiteral(red: 0.3529411765, green: 0.768627451, blue: 0.8509803922, alpha: 1), maskedCorners: .layerMaxXMaxYCorner, zone: .A)
    private lazy var soundBoxB = SoundBox(inactiveColor: #colorLiteral(red: 0.7254901961, green: 0.8, blue: 0.4, alpha: 0.5), activeColor: #colorLiteral(red: 0.7254901961, green: 0.8, blue: 0.4, alpha: 0.8), borderColor: #colorLiteral(red: 0.7254901961, green: 0.8, blue: 0.4, alpha: 1), maskedCorners: .layerMinXMaxYCorner, zone: .B)
    private lazy var soundBoxC = SoundBox(inactiveColor: #colorLiteral(red: 0.9764705882, green: 0.7215686275, blue: 0.1019607843, alpha: 0.5), activeColor: #colorLiteral(red: 0.9764705882, green: 0.7215686275, blue: 0.1019607843, alpha: 0.8), borderColor: #colorLiteral(red: 0.9764705882, green: 0.7215686275, blue: 0.1019607843, alpha: 1), maskedCorners: .layerMaxXMinYCorner, zone: .C)
    private lazy var soundBoxD = SoundBox(inactiveColor: #colorLiteral(red: 0.7921568627, green: 0.2588235294, blue: 0.3137254902, alpha: 0.5), activeColor: #colorLiteral(red: 0.7921568627, green: 0.2588235294, blue: 0.3137254902, alpha: 0.8), borderColor: #colorLiteral(red: 0.7921568627, green: 0.2588235294, blue: 0.3137254902, alpha: 1), maskedCorners: .layerMinXMinYCorner, zone: .D)
    private lazy var soundBoxE = SoundBox(inactiveColor: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 0.5), activeColor: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 0.7963134766), borderColor: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1), maskedCorners: [.layerMaxXMaxYCorner, .layerMinXMaxYCorner], zone: .E)
    private lazy var soundBoxF = SoundBox(inactiveColor: #colorLiteral(red: 0.7254901961, green: 0.8, blue: 0.4, alpha: 0.5), activeColor: #colorLiteral(red: 0.7254901961, green: 0.8, blue: 0.4, alpha: 0.8), borderColor: #colorLiteral(red: 0.7254901961, green: 0.8, blue: 0.4, alpha: 1), maskedCorners: [.layerMaxXMaxYCorner, .layerMaxXMinYCorner], zone: .F)
    private lazy var soundBoxG = SoundBox(inactiveColor: #colorLiteral(red: 0.9764705882, green: 0.7215686275, blue: 0.1019607843, alpha: 0.5), activeColor: #colorLiteral(red: 0.9764705882, green: 0.7215686275, blue: 0.1019607843, alpha: 0.8), borderColor: #colorLiteral(red: 0.9764705882, green: 0.7215686275, blue: 0.1019607843, alpha: 1), maskedCorners: [.layerMaxXMaxYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMinYCorner], zone: .G)
    private lazy var soundBoxH = SoundBox(inactiveColor: #colorLiteral(red: 0.7921568627, green: 0.2588235294, blue: 0.3137254902, alpha: 0.5), activeColor: #colorLiteral(red: 0.7921568627, green: 0.2588235294, blue: 0.3137254902, alpha: 0.8), borderColor: #colorLiteral(red: 0.7921568627, green: 0.2588235294, blue: 0.3137254902, alpha: 1), maskedCorners: [.layerMinXMaxYCorner, .layerMinXMinYCorner], zone: .H)
    private lazy var soundBoxI = SoundBox(inactiveColor: #colorLiteral(red: 0.3529411765, green: 0.768627451, blue: 0.8509803922, alpha: 0.5), activeColor: #colorLiteral(red: 0.3529411765, green: 0.768627451, blue: 0.8509803922, alpha: 0.8), borderColor: #colorLiteral(red: 0.3529411765, green: 0.768627451, blue: 0.8509803922, alpha: 1), maskedCorners: [.layerMaxXMaxYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMinYCorner], zone: .I)
    private lazy var soundBoxJ = SoundBox(inactiveColor: #colorLiteral(red: 0.7254901961, green: 0.8, blue: 0.4, alpha: 0.5), activeColor: #colorLiteral(red: 0.7254901961, green: 0.8, blue: 0.4, alpha: 0.8), borderColor: #colorLiteral(red: 0.7254901961, green: 0.8, blue: 0.4, alpha: 1), maskedCorners: [.layerMaxXMinYCorner, .layerMaxXMaxYCorner], zone: .J)
    private lazy var soundBoxK = SoundBox(inactiveColor: #colorLiteral(red: 0.9764705882, green: 0.7215686275, blue: 0.1019607843, alpha: 0.5), activeColor: #colorLiteral(red: 0.9764705882, green: 0.7215686275, blue: 0.1019607843, alpha: 0.8), borderColor: #colorLiteral(red: 0.9764705882, green: 0.7215686275, blue: 0.1019607843, alpha: 1), maskedCorners: [.layerMinXMaxYCorner, .layerMinXMinYCorner], zone: .K)
    
    private lazy var boxesWithMenu = [soundBoxA, soundBoxB, soundBoxC, soundBoxD, soundBoxE, soundBoxF, soundBoxG, soundBoxH, soundBoxI, soundBoxJ, soundBoxK]
    
    private lazy var recordButton: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.borderWidth = 4
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var redDotView: UIView = {
        let redView = UIView()
        redView.backgroundColor = #colorLiteral(red: 0.9176470588, green: 0.262745098, blue: 0.2078431373, alpha: 1)
        redView.layer.borderWidth = 4
        redView.layer.borderColor = UIColor.clear.cgColor
        redView.clipsToBounds = true
        return redView
    }()
    
    private lazy var redSquareView: UIView = {
        let redView = UIView()
        redView.backgroundColor = #colorLiteral(red: 0.9176470588, green: 0.262745098, blue: 0.2078431373, alpha: 1)
        redView.layer.borderWidth = 4
        redView.layer.borderColor = UIColor.clear.cgColor
        redView.clipsToBounds = true
        return redView
    }()
    
}

// MARK: - Layout
extension ZoneBasedUtility {
    
    func clearBoxes() {
        soundBoxA.removeFromSuperview()
        soundBoxB.removeFromSuperview()
        soundBoxC.removeFromSuperview()
        soundBoxD.removeFromSuperview()
    }
    
    func layoutSoundBoxes() {
        let multiplier: CGFloat = bigSquares ? 0.5 : 0.35
        // Setup A box
        parentView.addSubview(soundBoxA)
        soundBoxA.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            soundBoxA.topAnchor.constraint(equalTo: parentView.topAnchor),
            soundBoxA.leftAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.leftAnchor),
            soundBoxA.heightAnchor.constraint(equalTo: bigSquares ? parentView.heightAnchor : parentView.widthAnchor, multiplier: multiplier),
            soundBoxA.widthAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier)
        ])
        
        // Setup B box
        parentView.addSubview(soundBoxB)
        soundBoxB.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            soundBoxB.topAnchor.constraint(equalTo: parentView.topAnchor),
            soundBoxB.rightAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.rightAnchor),
            soundBoxB.heightAnchor.constraint(equalTo: bigSquares ? parentView.heightAnchor : parentView.widthAnchor, multiplier: multiplier),
            soundBoxB.widthAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier)
        ])
        
        setupBoxC(constant: 0, multiplier: multiplier)
        setupBoxD(constant: 0, multiplier: multiplier)
        setupBoxE(constant: 0, multiplier: multiplier)
        setupBoxF(constant: parentView.frame.width * multiplier / 2, multiplier: multiplier)
        setupBoxG(constant: 0, multiplier: multiplier)
        setupBoxH(constant: parentView.frame.width * multiplier / 2, multiplier: multiplier)
        setupBoxI(constant: 0, multiplier: multiplier)
        setupBoxJ(constant: parentView.frame.width * multiplier, multiplier: multiplier)
        setupBoxK(constant: parentView.frame.width * multiplier, multiplier: multiplier)
        
        parentView.layoutIfNeeded()
        setupRecordButton()
        setupBoxesAndBGMenu(boxesWithMenu)
    }
    
    func setupBoxC(constant: CGFloat, multiplier: CGFloat) {
        soundBoxC.removeFromSuperview()
        parentView.addSubview(soundBoxC)
        soundBoxC.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            soundBoxC.leftAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.leftAnchor),
            soundBoxC.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: constant),
            soundBoxC.heightAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier),
            soundBoxC.widthAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier)
        ])
    }
    
    func setupBoxD(constant: CGFloat, multiplier: CGFloat) {
        soundBoxD.removeFromSuperview()
        parentView.addSubview(soundBoxD)
        soundBoxD.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            soundBoxD.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: constant),
            soundBoxD.rightAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.rightAnchor),
            soundBoxD.heightAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier),
            soundBoxD.widthAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier)
        ])
    }
    
    func setupBoxE(constant: CGFloat, multiplier: CGFloat) {
        soundBoxE.removeFromSuperview()
        parentView.addSubview(soundBoxE)
        soundBoxE.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            soundBoxE.topAnchor.constraint(equalTo: parentView.topAnchor, constant: constant),
            soundBoxE.rightAnchor.constraint(equalTo: soundBoxB.safeAreaLayoutGuide.leftAnchor),
            soundBoxE.leftAnchor.constraint(equalTo: soundBoxA.safeAreaLayoutGuide.rightAnchor),
            soundBoxE.heightAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier),
        ])
    }
    
    func setupBoxF(constant: CGFloat, multiplier: CGFloat) {
        soundBoxF.removeFromSuperview()
        parentView.addSubview(soundBoxF)
        soundBoxF.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            soundBoxF.topAnchor.constraint(equalTo: soundBoxA.safeAreaLayoutGuide.bottomAnchor, constant: constant),
            soundBoxF.leftAnchor.constraint(equalTo: parentView.leftAnchor),
            soundBoxF.heightAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier / 2),
            soundBoxF.widthAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier / 2)
        ])
    }
    
    func setupBoxG(constant: CGFloat, multiplier: CGFloat) {
        soundBoxG.removeFromSuperview()
        parentView.addSubview(soundBoxG)
        soundBoxG.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            soundBoxG.topAnchor.constraint(equalTo: soundBoxF.safeAreaLayoutGuide.topAnchor, constant: constant),
            soundBoxG.leftAnchor.constraint(equalTo: soundBoxF.safeAreaLayoutGuide.rightAnchor),
            soundBoxG.heightAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier / 2),
            soundBoxG.widthAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier / 2)
        ])
    }
    
    func setupBoxH(constant: CGFloat, multiplier: CGFloat) {
        soundBoxH.removeFromSuperview()
        parentView.addSubview(soundBoxH)
        soundBoxH.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            soundBoxH.topAnchor.constraint(equalTo: soundBoxA.safeAreaLayoutGuide.bottomAnchor, constant: constant),
            soundBoxH.rightAnchor.constraint(equalTo: parentView.rightAnchor),
            soundBoxH.heightAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier / 2),
            soundBoxH.widthAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier / 2)
        ])
    }
    
    func setupBoxI(constant: CGFloat, multiplier: CGFloat) {
        soundBoxI.removeFromSuperview()
        parentView.addSubview(soundBoxI)
        soundBoxI.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            soundBoxI.topAnchor.constraint(equalTo: soundBoxH.safeAreaLayoutGuide.topAnchor, constant: constant),
            soundBoxI.rightAnchor.constraint(equalTo: soundBoxH.safeAreaLayoutGuide.leftAnchor),
            soundBoxI.heightAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier / 2),
            soundBoxI.widthAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier / 2)
        ])
    }
    
    func setupBoxJ(constant: CGFloat, multiplier: CGFloat) {
        soundBoxJ.removeFromSuperview()
        parentView.addSubview(soundBoxJ)
        soundBoxJ.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            soundBoxJ.bottomAnchor.constraint(equalTo: soundBoxC.safeAreaLayoutGuide.topAnchor, constant: -constant),
            soundBoxJ.leftAnchor.constraint(equalTo: parentView.leftAnchor),
            soundBoxJ.heightAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier),
            soundBoxJ.widthAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier)
        ])
    }
    
    func setupBoxK(constant: CGFloat, multiplier: CGFloat) {
        soundBoxK.removeFromSuperview()
        parentView.addSubview(soundBoxK)
        soundBoxK.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            soundBoxK.bottomAnchor.constraint(equalTo: soundBoxD.safeAreaLayoutGuide.topAnchor, constant: -constant),
            soundBoxK.rightAnchor.constraint(equalTo: parentView.rightAnchor),
            soundBoxK.heightAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier),
            soundBoxK.widthAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier)
        ])
    }
    
    func setupBoxesAndBGMenu(_ boxes: [SoundBox]) {
            if #available(iOS 13.0, *) {
                boxes.forEach { box in
                    box.addInteraction(UIContextMenuInteraction(delegate: self))
                }
                parentView.addInteraction(UIContextMenuInteraction(delegate: self))
            } else {
                setupSoundBoxGestures()
            }
    }

    
    func setupSoundBoxGestures() {
        let soundBoxATap = UITapGestureRecognizer(target: self, action: #selector(onSoundBoxATap))
        soundBoxA.isUserInteractionEnabled = true
        soundBoxA.addGestureRecognizer(soundBoxATap)
        
        let soundBoxBTap = UITapGestureRecognizer(target: self, action: #selector(onSoundBoxBTap))
        soundBoxB.isUserInteractionEnabled = true
        soundBoxB.addGestureRecognizer(soundBoxBTap)
        
        let soundBoxCTap = UITapGestureRecognizer(target: self, action: #selector(onSoundBoxCTap))
        soundBoxC.isUserInteractionEnabled = true
        soundBoxC.addGestureRecognizer(soundBoxCTap)
        
        let soundBoxDTap = UITapGestureRecognizer(target: self, action: #selector(onSoundBoxDTap))
        soundBoxD.isUserInteractionEnabled = true
        soundBoxD.addGestureRecognizer(soundBoxDTap)
        
        let soundBoxETap = UITapGestureRecognizer(target: self, action: #selector(onSoundBoxETap))
        soundBoxE.isUserInteractionEnabled = true
        soundBoxE.addGestureRecognizer(soundBoxETap)
        
        let soundBoxFTap = UITapGestureRecognizer(target: self, action: #selector(onSoundBoxFTap))
        soundBoxF.isUserInteractionEnabled = true
        soundBoxF.addGestureRecognizer(soundBoxFTap)
        
        let soundBoxGTap = UITapGestureRecognizer(target: self, action: #selector(onSoundBoxGTap))
        soundBoxG.isUserInteractionEnabled = true
        soundBoxG.addGestureRecognizer(soundBoxGTap)
        
        let soundBoxHTap = UITapGestureRecognizer(target: self, action: #selector(onSoundBoxHTap))
        soundBoxH.isUserInteractionEnabled = true
        soundBoxH.addGestureRecognizer(soundBoxHTap)
        
        let soundBoxITap = UITapGestureRecognizer(target: self, action: #selector(onSoundBoxITap))
        soundBoxI.isUserInteractionEnabled = true
        soundBoxI.addGestureRecognizer(soundBoxITap)
        
        let soundBoxJTap = UITapGestureRecognizer(target: self, action: #selector(onSoundBoxJTap))
        soundBoxJ.isUserInteractionEnabled = true
        soundBoxJ.addGestureRecognizer(soundBoxJTap)
        
        let soundBoxKTap = UITapGestureRecognizer(target: self, action: #selector(onSoundBoxKTap))
        soundBoxK.isUserInteractionEnabled = true
        soundBoxK.addGestureRecognizer(soundBoxKTap)
    }
    
    func setupRecordButton(withMultiplier multiplier: CGFloat = 0.35) {
        
        parentView.addSubview(recordButton)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            recordButton.bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor),
            recordButton.centerXAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.centerXAnchor),
            recordButton.heightAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier * 0.6),
            recordButton.widthAnchor.constraint(equalTo: parentView.widthAnchor, multiplier: multiplier * 0.6)
        ])
        
        recordButton.addSubview(redDotView)
        redDotView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            redDotView.centerXAnchor.constraint(equalTo: recordButton.safeAreaLayoutGuide.centerXAnchor),
            redDotView.centerYAnchor.constraint(equalTo: recordButton.safeAreaLayoutGuide.centerYAnchor),
            redDotView.heightAnchor.constraint(equalTo: recordButton.widthAnchor, multiplier: 0.8),
            redDotView.widthAnchor.constraint(equalTo: recordButton.widthAnchor, multiplier: 0.8)
        ])
        
        
        recordButton.addSubview(redSquareView)
        redSquareView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            redSquareView.centerXAnchor.constraint(equalTo: recordButton.safeAreaLayoutGuide.centerXAnchor),
            redSquareView.centerYAnchor.constraint(equalTo: recordButton.safeAreaLayoutGuide.centerYAnchor),
            redSquareView.heightAnchor.constraint(equalTo: recordButton.widthAnchor, multiplier: 0.6),
            redSquareView.widthAnchor.constraint(equalTo: recordButton.widthAnchor, multiplier: 0.6)
        ])
        redSquareView.isHidden = true
        
        recordButton.layoutIfNeeded()
        
        recordButton.layer.cornerRadius = recordButton.frame.size.height / 2
        redDotView.layer.cornerRadius = redDotView.frame.size.height / 2
        
        let recordTap = UITapGestureRecognizer(target: self, action: #selector(toggleRecording))
        recordButton.isUserInteractionEnabled = true
        recordButton.addGestureRecognizer(recordTap)
        
    }
    
    @objc func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    @objc func onSoundBoxATap() {
        delegate?.changeSoundForBox(zone: .A)
    }
    
    @objc func onSoundBoxBTap() {
        delegate?.changeSoundForBox(zone: .B)
    }
    
    @objc func onSoundBoxCTap() {
        delegate?.changeSoundForBox(zone: .C)
    }
    
    @objc func onSoundBoxDTap() {
        delegate?.changeSoundForBox(zone: .D)
    }
    
    @objc func onSoundBoxETap() {
        delegate?.changeSoundForBox(zone: .E)
    }
    
    @objc func onSoundBoxFTap() {
        delegate?.changeSoundForBox(zone: .F)
    }
    
    @objc func onSoundBoxGTap() {
        delegate?.changeSoundForBox(zone: .G)
    }
    
    @objc func onSoundBoxHTap() {
        delegate?.changeSoundForBox(zone: .H)
    }
    
    @objc func onSoundBoxITap() {
        delegate?.changeSoundForBox(zone: .I)
    }
    
    @objc func onSoundBoxJTap() {
        delegate?.changeSoundForBox(zone: .J)
    }
    
    @objc func onSoundBoxKTap() {
        delegate?.changeSoundForBox(zone: .K)
    }
    
    func startRecording() {
        isRecording = true
        redDotView.isHidden = true
        redSquareView.isHidden = false
        delegate?.startRecording()
    }
    
    func stopRecording() {
        isRecording = false
        redDotView.isHidden = false
        redSquareView.isHidden = true
        delegate?.stopRecording()
    }
}

// MARK: - Dot
private extension ZoneBasedUtility {
    
    private func dotsEnteredZone(with dots: [CGPoint], for zone: Zone) -> Bool {
        switch zone {
        case .A:
            return dotsEnteredBox(for: soundBoxA, with: dots)
        case .B:
            return dotsEnteredBox(for: soundBoxB, with: dots)
        case .C:
            return dotsEnteredBox(for: soundBoxC, with: dots)
        case .D:
            return dotsEnteredBox(for: soundBoxD, with: dots)
        case .E:
            return dotsEnteredBox(for: soundBoxE, with: dots)
        case .F:
            return dotsEnteredBox(for: soundBoxF, with: dots)
        case .G:
            return dotsEnteredBox(for: soundBoxG, with: dots)
        case .H:
            return dotsEnteredBox(for: soundBoxH, with: dots)
        case .I:
            return dotsEnteredBox(for: soundBoxI, with: dots)
        case .J:
            return dotsEnteredBox(for: soundBoxJ, with: dots)
        case .K:
            return dotsEnteredBox(for: soundBoxK, with: dots)
        }
    }
    
    
    private func dotsEnteredBox(for boxView: SoundBox, with dots: [CGPoint]) -> Bool {
        for dot in dots {
            let isDotInZone = dot.x >= boxView.frame.minX &&
            dot.x <= boxView.frame.maxX &&
            dot.y >= boxView.frame.minY &&
            dot.y <= boxView.frame.maxY
            
            if isDotInZone {
                if !boxView.isActive {
                    boxView.isActive = true
                    return true
                } else {
                    return false
                }
            }
        }
        boxView.isActive = false
        return false
    }
}

// MARK: - Public extension
extension ZoneBasedUtility {
    
    func liftBottomBoxes() {
//        let multiplier: CGFloat = 0.35
        
        recordButton.isHidden = true
        
        // Lift C box
//        setupBoxC(constant: -130, multiplier: multiplier)
        
        // Lift D box
//        setupBoxD(constant: -130, multiplier: multiplier)
        
        //        parentView.layoutIfNeeded()
    }
    
    func putDownBottomBoxes() {
//        let multiplier: CGFloat = 0.35
        
        recordButton.isHidden = false
        
        // Lift C box
//        setupBoxC(constant: 0, multiplier: multiplier)
        
        // Lift D box
//        setupBoxD(constant: 0, multiplier: multiplier)
        
        //        parentView.layoutIfNeeded()
    }
}

extension ZoneBasedUtility: UIContextMenuInteractionDelegate, VolumeValuesDelegate {
    
    @available(iOS 13.0, *)
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let settingsState = settingsStateDelegate?.settingsState else {return nil}
        
        switch settingsState {
        case .active:
            break
        case .inactive:
            return nil
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: {
            suggestedActions in
            
            let adjustVolumeView = AdjustVolumeView.fromNib()
            self.adjustVolumeView = adjustVolumeView
            adjustVolumeView.delegate = self
            
            if let soundBox = interaction.view as? SoundBox {
                self.currentAdjustedZone = soundBox.zone
                self.currentlyAdjustingBG = false
            } else {
                // in case user needs CameraView menu
                self.currentlyAdjustingBG = true
                
                let changeSoundAction =
                    UIAction(title: "Change sound",
                             image: UIImage(systemName: "megaphone.fill")) { action in
                        self.showSoundsMenuDelegate?.selectSound()
                    }
                let changeVolumeAction =
                    UIAction(title: "Change volume",
                             image: UIImage(systemName: "dial.max.fill")) { action in

                        UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.addSubview(adjustVolumeView)
                        adjustVolumeView.start()

                        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissVolumeAdjust))
                        adjustVolumeView.addGestureRecognizer(tapGesture)
                }
                return UIMenu(title: "Sound Menu", children: [changeSoundAction, changeVolumeAction])
            }
            
            
            

            let changeSoundAction =
                UIAction(title: "Change sound",
                         image: UIImage(systemName: "megaphone.fill")) { action in
                    
                    self.delegate?.changeSoundForBox(zone: self.currentAdjustedZone ?? .A)
                }
            let changeVolumeAction =
                UIAction(title: "Change volume",
                         image: UIImage(systemName: "dial.max.fill")) { action in
                    
                    UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.addSubview(adjustVolumeView)
                    adjustVolumeView.start()
                    
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissVolumeAdjust))
                    adjustVolumeView.addGestureRecognizer(tapGesture)
            }
            return UIMenu(title: "Sound Menu", children: [changeSoundAction, changeVolumeAction])
        })
    }
    
    @objc func dismissVolumeAdjust() {
        self.adjustVolumeView?.end()
    }
    
    func getVolumeAtStart() -> Float {
        if !currentlyAdjustingBG {
            return ZoneBaseAudio.shared.getVolumeForZone(for: currentAdjustedZone!)
        }
        return ZoneBaseAudio.shared.getVolumeForBG()
    }
    
    func setVolumeAtFinish(newVolume: Float) {
        if !currentlyAdjustingBG {
            let key = "volume" + currentAdjustedZone!.keyValue
            UserDefaults.standard.setValue(newVolume, forKey: key)
        } else {
            ZoneBaseAudio.shared.setVolumeForBG(newVolume: newVolume)
        }
    }
}

