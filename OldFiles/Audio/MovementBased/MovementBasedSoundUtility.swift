import AVFoundation
import Foundation
import MLKit

struct Movement {
    
    let type: MovementType
    let landmarksAppliedToMovement: [PoseLandmarkType]
    let actions: MovementAction
    
    let isLoop: Bool
    
    var isMuted = true {
        didSet {
            if isMuted {
                player?.volume = 0.0
            } else {
                player?.volume = 1.0
            }
        }
    }
    var isPlaying = false
    
    let fileName: String
    var player: AVAudioPlayer?
    
    var lastDotsWithAverage: [PoseLandmarkType: CGFloat]?
    
    init(type: MovementType,
         landmarks landmarksAppliedToMovement: [PoseLandmarkType],
         actions availableActions: MovementAction,
         isLoop: Bool,
         fileName: String) {
        self.type = type
        self.landmarksAppliedToMovement = landmarksAppliedToMovement
        self.actions = availableActions
        self.isLoop = isLoop
        self.fileName = fileName
    }
    
}

enum MovementType {
    case head
    case rightWrist
    case leftWrist
    case rightShoulder
    case leftShoulder
}

enum MovementAction {
    case up
    case down
    case upAndDown
}

final class MovementBasedSoundUtility {
    
    private var movements = [Movement]()
    
    private (set) var multiplayerForTriggerSound: CGFloat = 0.1
    private let currentView: UIView
    
    private var heightValueTrigger: CGFloat {
        get {
            currentView.frame.height * multiplayerForTriggerSound
        }
    }
    
    init(with view: UIView) {
        currentView = view
    }
    
    public func toggle(_ value: Bool) {
        if value {
            addMovementsTypes()
            setupLoopsForMovements()
        } else {
            movements = [Movement]()
        }
        
    }
    
    // MARK: - Public
    
    public func setNewValueForMultiplayer(_ float: CGFloat) {
        self.multiplayerForTriggerSound = float
    }
    
    public func process(with dict: [PoseLandmarkType: [CGPoint]]) {
        
        // If no recognized poses just return
        if dict.count == 0 { return }
        
        for (index, movement) in movements.enumerated() {
            processMovement(index, movement, with: dict)
        }
        
        
    }
    
    // MARK: - Private
    
    private func addMovementsTypes() {
        let headMovement = Movement(type: .head, landmarks: [.rightEye, .leftEye, .rightEyeInner, .leftEyeInner], actions: .upAndDown, isLoop: true, fileName: "beat")
        movements.append(headMovement)
        
        let rightWrist = Movement(type: .rightWrist, landmarks: [.rightWrist, .rightPinkyFinger, .rightIndexFinger, .rightThumb], actions: .upAndDown, isLoop: true, fileName: "bass")
        movements.append(rightWrist)
        
        let leftWrist = Movement(type: .leftWrist, landmarks: [.leftWrist, .leftPinkyFinger, .leftIndexFinger, .leftThumb], actions: .upAndDown, isLoop: true, fileName: "synth")
        movements.append(leftWrist)
        
        let rightShoulder = Movement(type: .rightShoulder, landmarks: [.rightShoulder], actions: .up, isLoop: false, fileName: "vox")
        movements.append(rightShoulder)
        
        let leftShoulder = Movement(type: .leftShoulder, landmarks: [.leftShoulder], actions: .up, isLoop: false, fileName: "scratch")
        movements.append(leftShoulder)
    }
    
    private func processMovement(_ index: Int, _ movement: Movement, with dict: [PoseLandmarkType: [CGPoint]]) {
        
        var averageDotsValues = [PoseLandmarkType: CGFloat]()
        
        for (pose, dots) in dict {
            for movementPose in movement.landmarksAppliedToMovement {
                
                // If we find pose which apply to movent
                if pose.rawValue == movementPose.rawValue {
                    averageDotsValues[pose] = averageChangeFromPoseDots(with: dots)
                }
                
            }
        }
        
        guard let lastDots = movement.lastDotsWithAverage else { movements[index].lastDotsWithAverage = averageDotsValues; return }
        
        var averageDotChangedValues = [CGFloat]()
        
        for (lastPose, lastDot) in lastDots {
            for (currentPose, currentDot) in averageDotsValues {
                if currentPose.rawValue == lastPose.rawValue  {
                    
                    let calculatedValue = lastDot - currentDot
                    averageDotChangedValues.append(calculatedValue)
                    
                }
            }
        }
        
        let allDotsAverageChange = averageDotChangedValues.avg()
        
        print("allDotsAverageChange: \(allDotsAverageChange)")
        print("heightValueTrigger: \(heightValueTrigger)")
        
        // For specifying schoulders
        var booferHeightValueTrigger = heightValueTrigger
        if movement.type == .leftShoulder || movement.type == .rightShoulder {
            booferHeightValueTrigger = booferHeightValueTrigger * 0.5
        }
        
        // Checking that is "up" movement and it is available
        if allDotsAverageChange >= booferHeightValueTrigger && (movement.actions == .up || movement.actions == .upAndDown) {
            print("UP-\(movement.type)")
            playUpForMovement(by: index)
        } else if -allDotsAverageChange >= booferHeightValueTrigger && (movement.actions == .down || movement.actions == .upAndDown) {
            print("DOWN-\(movement.type)")
            playDownForMovement(by: index)
        } else {
            print("Nothing")
        }
        
        // Add last dots
        movements[index].lastDotsWithAverage = averageDotsValues
    }
    
    private func averageChangeFromPoseDots(with dots: [CGPoint]) -> CGFloat {
        dots.map { $0.y }.avg()
    }
    
    
    private func playUpForMovement(by index: Int) {
        let movement = movements[index]
        
        if movement.isLoop && movement.isMuted {
            movements[index].isMuted = false
        } else if !movement.isLoop {
            // ZoneBaseAudio.shared.playSound(movement.fileName)
        }
    }
    
    private func playDownForMovement(by index: Int) {
        let movement = movements[index]
        
        if movement.type == .head {
             movements[index].isMuted = false
        }
        
        if movement.isLoop && !movement.isMuted{
            movements[index].isMuted = true
        }
    }
    
    // MARK: - Sound based
    
    private func setupLoopsForMovements() {
        for (index, _) in movements.enumerated() {
            prepareLoopMusicPlayer(for: index)
        }
    }
    
    func prepareLoopMusicPlayer(for index: Int) {
        guard let backgroundMusicFile = Bundle.main.path(forResource: movements[index].fileName, ofType: "wav") else { return }
        do {
            movements[index].player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: backgroundMusicFile))
            movements[index].player?.numberOfLoops = -1
            movements[index].player?.prepareToPlay()
            movements[index].player?.volume = 0.0
            movements[index].player?.play()
        } catch { }
    }
}
