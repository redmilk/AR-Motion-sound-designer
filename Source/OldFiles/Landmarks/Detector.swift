public enum Detector: String {
    case onDeviceBarcode = "On-Device Barcode Scanner"
    case onDeviceFace = "On-Device Face Detection"
    case onDeviceText = "On-Device Text Recognition"
    case onDeviceObjectProminentNoClassifier = "ODT, single, no labeling"
    case onDeviceObjectProminentWithClassifier = "ODT, single, labeling"
    case onDeviceObjectMultipleNoClassifier = "ODT, multiple, no labeling"
    case onDeviceObjectMultipleWithClassifier = "ODT, multiple, labeling"
    case onDeviceObjectCustomProminentNoClassifier = "ODT, custom, single, no labeling"
    case onDeviceObjectCustomProminentWithClassifier = "ODT, custom, single, labeling"
    case onDeviceObjectCustomMultipleNoClassifier = "ODT, custom, multiple, no labeling"
    case onDeviceObjectCustomMultipleWithClassifier = "ODT, custom, multiple, labeling"
    case poseAccurate = "Pose, accurate"
    case poseFast = "Pose, fast"
}
