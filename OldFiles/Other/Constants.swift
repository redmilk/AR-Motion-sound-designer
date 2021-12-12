import UIKit

struct Constant {
    
    // For CameraVC
    static let alertControllerTitle = "Vision Detectors"
    static let alertControllerMessage = "Select a detector"
    static let cancelActionTitleText = "Cancel"
    static let videoDataOutputQueueLabel = "com.google.mlkit.visiondetector.VideoDataOutputQueue"
    static let sessionQueueLabel = "com.google.mlkit.visiondetector.SessionQueue"
    static let noResultsMessage = "No Results"
    static let localModelFile = (name: "bird", type: "tflite")
    static let labelConfidenceThreshold: Float = 0.75
    static let smallDotRadius: CGFloat = 4.0
    static let bigDotRadius: CGFloat = 70.0
    static let lineWidth: CGFloat = 3.0
    static let originalScale: CGFloat = 1.0
    static let padding: CGFloat = 10.0
    static let resultsLabelHeight: CGFloat = 200.0
    static let resultsLabelLines = 5
    
    //Average dots filter
    static let lastDotsNumber = 3
    
    // MLKitExtensions
    static let jpegCompressionQuality: CGFloat = 0.8
    
    // Utility constants
    static let circleImageAlpha: CGFloat = 1.0
    static let circleViewAlpha: CGFloat = 0.7
    static let rectangleViewAlpha: CGFloat = 0.3
    static let shapeViewAlpha: CGFloat = 0.3
    static let rectangleViewCornerRadius: CGFloat = 10.0
    
    // Analytics keys
    static let segmentWriteKey = "vHQFDZMTjIS6fpAVsctTrlh0ubKBvmtx"
    static let amplitudeApiKey = "fea210088708d4749f3520c79d56061b"
    static let appsFlyerDevKey = "4reqDkMpTSShBu4UmQesD6"
    static let appsFlyerAppId = "id1590011462"
    
    //static var allSettings = [SettingsOption]()
}
