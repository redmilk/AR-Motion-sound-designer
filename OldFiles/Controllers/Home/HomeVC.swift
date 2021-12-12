//import AVFoundation
//import AVKit
//import CoreVideo
//import MLKit
//import Vision
//import UIKit
//import Amplitude
//
//enum Configuration: String {
//    case zone = "Zone based"
//    case movement = "Movement based"
//}
//
//enum SettingsState {
//    case active
//    case inactive
//}
//
//protocol SettingsStateDelegate {
//    var settingsState: SettingsState {get}
//}
//
//protocol RecordingStartDelegate {
//    var getRecordingStart: Double? {get}
//    func setSoundTimestamps(timestamp: Double, sound: SoundForTimestamp)
//    func setBgSound(url: URL, volume: Float)
//}
//
//protocol ShowSoundsMenuDelegate {
//    func selectSound()
//}
//
//struct SoundForTimestamp {
//    var url: URL
//    var volume: Float
//    var duration: Double
//}
//
//struct BgSound {
//    var url: URL
//    var volume: Float
//}
//
//class HomeVC: UIViewController {
//
//    //MARK: - View
//
//    @IBOutlet weak var swipeUpView: UIView!
//    @IBOutlet weak var settingsButton: UIButton!
//    @IBOutlet weak var feedbackButton: UIButton!
//    @IBOutlet weak var cameraView: UIView!
//
//    @IBOutlet var masksMenu: UICollectionView!
//    @IBOutlet var bottomConstraint: NSLayoutConstraint!
//
//    //MARK: - Variables
//
//    private var currentDetector: Detector = .poseAccurate
//    private var isUsingFrontCamera = true
//    private var previewLayer: AVCaptureVideoPreviewLayer!
//    lazy var captureSession = AVCaptureSession()
//    lazy var videoDataOutput = AVCaptureVideoDataOutput()
//    lazy var audioDataOutput = AVCaptureAudioDataOutput()
//    lazy var sessionQueue = DispatchQueue(label: Constant.sessionQueueLabel)
//    private var lastFrame: CMSampleBuffer?
//
//    private var timeInterval: TimeInterval = 0.5
//    private var recordingTimer: Timer?
//    var recordingStartTimestamp: Double?
//    var soundTimestamps: [Double: SoundForTimestamp] = [:]
//    var bgSound: BgSound?
//
//    var drawSkeleton = false
//    var enableHeadphones: Bool {
//        UserDefaults.standard.bool(forKey: "enableHeadphones")
//    }
//    //Menu bar with masks
//    let masks = ["Jiggle", "Squid"]
//    let maskLogos = [
//        UIImage(named: "Sound_1_logo"),
//        UIImage(named: "Sound_2_logo")
//    ]
//
//    // Zone based Sounds
//    var zoneBasedSoundUtility: ZoneBasedUtility?
//
//    // Movement based sounds
//    private var movementBasedSoundUtility: MovementBasedSoundUtility?
//
//    // For changing amount of processed or skipped frames its need to change one of this values
//    private var countOfFramesForProcessing = 1
//    private var countOfFramesForSkipping = 1
//
//    private var currentProcessedFrameNumber = 0
//    private var currentSkippedFrameNumber = 0
//
//    /// Serial queue used for synchronizing access to `_poseDetector`. This is needed because Swift
//    /// lacks ObjC-style synchronization and the detector is accessed on different threads across
//    /// initialization, usage, and deallocation. Note that just using the main queue for
//    /// synchronization from the getter/setter overrides is unsafe because it could allow a deadlock
//    /// if the `poseDetector` property were accessed on the main thread.
//    private let poseDetectorQueue = DispatchQueue(label: "com.google.mlkit.pose")
//
//    /// The detector used for detecting poses. The pose detector's lifecycle is managed manually, so
//    /// it is initialized on-demand via the getter override and set to `nil` when a new detector is
//    /// chosen.
//    private var _poseDetector: PoseDetector? = nil
//    private var poseDetector: PoseDetector? {
//        get {
//            var detector: PoseDetector? = nil
//            poseDetectorQueue.sync {
//                if _poseDetector == nil {
//                    let options = PoseDetectorOptions()
//                    options.detectorMode = .stream
//                    //                    options.performanceMode = (currentDetector == .poseFast ? .fast : .accurate);
//                    //_poseDetector = PoseDetector.poseDetector(options: options)
//                }
//                detector = _poseDetector
//            }
//            return detector
//        }
//        set(newDetector) {
//            poseDetectorQueue.sync {
//                _poseDetector = newDetector
//            }
//        }
//    }
//
//    // Variables for detecting frame pose
//
//    private var lastFileName = ""
//
//    private let imagePickerController = UIImagePickerController() // Need for presenting media controller
//
//    private let outputQueue = DispatchQueue(label: Constant.videoDataOutputQueueLabel)
//
//    private var frameRate : Float = 0.0
//    private var framesCount : Float = 0.0
//
//    // Variables for average dots smoothing
//    var averageDotsSmooth : Bool {
//        UserDefaults.standard.bool(forKey: "averageDots")
//    }
//    private var lastThreeDots = [String:[CGPoint]]()
//
//    // Test putting files into threads
//    private var frameProcessingTimeInterval: TimeInterval = 0.1
//
//    private var currentFrameWidth = 0
//    private var currentFrameHeight = 0
//
//    private let frameQueueCount = 100 // Value need to set from 2. Could reduce property to 30 or 15 for less RAM usage
//
//    private var isActiveFrameProcessing = true
//
//    // var movieOutput = AVCaptureMovieFileOutput()
//    private(set) lazy var isRecording = false
//    var videoWriter: AVAssetWriter!
//    var videoWriterInput: AVAssetWriterInput!
//    var audioWriterInput: AVAssetWriterInput!
//    var sessionAtSourceTime: CMTime!
//    var output : AVAssetReaderTrackOutput? // nil gets original sample data without overhead for decompression
//    var reader : AVAssetReader?
//
//    var fileUploader: FileUploader?
//
//    private lazy var annotationOverlayView: UIView = {
//        precondition(isViewLoaded)
//        let annotationOverlayView = UIView(frame: .zero)
//        annotationOverlayView.translatesAutoresizingMaskIntoConstraints = false
//        return annotationOverlayView
//    }()
//
//    //MARK: - App cycle methods
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        fileUploader = FileUploader()
//        settingsButton.isHidden = UserDefaults.standard.object(forKey: "settingsButtonHidden") != nil ? UserDefaults.standard.bool(forKey: "settingsButtonHidden") : true
//        settingsButton.layer.cornerRadius = 5
//        settingsButton.layer.masksToBounds = true
//        feedbackButton.tintColor = .white
//        feedbackButton.setTitle("", for: .normal)
//        swipeUpView.backgroundColor = .clear
//
//        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//        setupCameraPreview()
//
//        setUpAnnotationOverlayView()
//        setUpCaptureSessionOutput()
//        prepareAudioSession()
//        ZoneBaseAudio.shared.prepareBackgroundMusicPlayer()
//        ZoneBaseAudio.shared.delegate = self
//        askMicroPhonePermission(completion: { _ in
//                                    self.setUpCaptureSessionInputs()
//                                })
//
//        // Zone based sound setup
//        zoneBasedSoundUtility = ZoneBasedUtility(view: cameraView)
//        zoneBasedSoundUtility?.delegate = self
//        zoneBasedSoundUtility?.settingsStateDelegate = self
//        zoneBasedSoundUtility?.showSoundsMenuDelegate = self
//
//        // movementBasedSoundUtility setup
//        movementBasedSoundUtility = MovementBasedSoundUtility(with: cameraView)
//        //CollectionView setup
//        masksMenu.delegate = self
//        masksMenu.dataSource = self
//        masksMenu.backgroundColor = UIColor.clear.withAlphaComponent(0.6)
//        bottomConstraint.constant = -130
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//
//        startSession()
//    }
//
//    func askMicroPhonePermission(completion: @escaping (_ success: Bool)-> Void) {
//        switch AVAudioSession.sharedInstance().recordPermission {
//        case AVAudioSession.RecordPermission.granted:
//            completion(true)
//        case AVAudioSession.RecordPermission.denied:
//            completion(false) //show alert if required
//        case AVAudioSession.RecordPermission.undetermined:
//            AVAudioSession.sharedInstance().requestRecordPermission({ (granted) in
//                if granted {
//                    completion(true)
//                } else {
//                    completion(false) // show alert if required
//                }
//            })
//        default:
//            completion(false)
//        }
//    }
//
//    func prepareAudioSession() {
//        do {
//            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.mixWithOthers, .allowBluetooth, .allowAirPlay, .allowBluetoothA2DP] )
//            try AVAudioSession.sharedInstance().setActive(true)
//        } catch {
//            print("Issue with Audio Session")
//        }
//    }
//
//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        stopSession()
//    }
//
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        previewLayer.frame = cameraView.frame
//    }
//    private func setUpAnnotationOverlayView() {
//        cameraView.addSubview(annotationOverlayView)
//        NSLayoutConstraint.activate([
//            annotationOverlayView.topAnchor.constraint(equalTo: cameraView.topAnchor),
//            annotationOverlayView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
//            annotationOverlayView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),
//            annotationOverlayView.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor),
//        ])
//    }
//
//    private func removeDetectionAnnotations() {
//        for annotationView in annotationOverlayView.subviews {
//            annotationView.removeFromSuperview()
//        }
//    }
//
//    func setActiveFrameProcessing(with sampleBuffer: CMSampleBuffer){
//
//        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
////            print("Failed to get image buffer from sample buffer.")
//            return
//        }
//
//        lastFrame = sampleBuffer
//
//        if isNeedToSkipFrame() && isActiveFrameProcessing {
//
//            let visionImage = VisionImage(buffer: sampleBuffer)
//            let orientation = UIUtilities.imageOrientation(
//                fromDevicePosition: isUsingFrontCamera ? .front : .back
//            )
//
//            visionImage.orientation = orientation
//            let imageWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
//            let imageHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))
//            detectPose(in: visionImage, width: imageWidth, height: imageHeight)
//        }
//    }
//
//    private func isNeedToSkipFrame() -> Bool {
//        if currentProcessedFrameNumber == countOfFramesForProcessing {
//
//            if currentSkippedFrameNumber == countOfFramesForSkipping {
//                currentSkippedFrameNumber = 0
//                currentProcessedFrameNumber = 0
//            } else {
//                currentSkippedFrameNumber += 1
//            }
//            return true
//        } else {
//            currentProcessedFrameNumber += 1
//            return false
//        }
//    }
//
//    @IBAction func didTapSettingsButton(_ sender: Any) {
//        performSegue(withIdentifier: "goToSettingsVC", sender: self)
//    }
//
//    @IBAction func feedbackButtonTapped(_ sender: Any) {
//        let feedbackView = FeedbackView.fromNib()
//        feedbackView.alpha = 0
//        feedbackView.controller = self
//        view.addSubview(feedbackView)
//        feedbackView.start()
//    }
//
//    var configuration: Configuration = .zone {
//        didSet {
//            switch configuration {
//
//            case .movement:
//                movementBasedSoundUtility?.toggle(true)
//            case .zone:
//                movementBasedSoundUtility?.toggle(false)
//            }
//        }
//    }
//
//    @objc private func openMenu(_ sender: UISwipeGestureRecognizer) {
//        UIView.animate(withDuration: 0.25, animations: {() in
//            self.bottomConstraint.constant = 0
//            self.zoneBasedSoundUtility?.liftBottomBoxes()
//            self.swipeUpView.isHidden = true
//            self.view.layoutIfNeeded()
//        })
//    }
//
//    @objc public func closeMenu(_ sender: UISwipeGestureRecognizer) {
//        UIView.animate(withDuration: 0.25, animations: {() in
//            self.bottomConstraint.constant = -130
//            self.zoneBasedSoundUtility?.putDownBottomBoxes()
//            self.swipeUpView.isHidden = false
//            self.view.layoutIfNeeded()
//        })
//    }
//    //MARK: - On-Device Detections
//
//    private func detectPose(in image: VisionImage, width: CGFloat, height: CGFloat) {
//        if let poseDetector = self.poseDetector {
//            var poses: [Pose]
//            do {
//                poses = try poseDetector.results(in: image)
//            } catch let error {
//                print("Failed to detect poses with error: \(error.localizedDescription).")
//                return
//            }
//            
//            guard !poses.isEmpty else {
////                print("Pose detector returned no results.")
//                return
//            }
//
//            DispatchQueue.main.sync {
//                self.removeDetectionAnnotations()
//                // Pose detected. Currently, only single person detection is supported.
//                poses.forEach { pose in
//
//                    var dots = [CGPoint]()
//
//                    for (_, (startLandmarkType, endLandmarkTypesArray)) in UIUtilities.poseConnections().enumerated() {
//                        let startLandmark = pose.landmark(ofType: startLandmarkType)
//                        for endLandmarkType in endLandmarkTypesArray {
//                            let endLandmark = pose.landmark(ofType: endLandmarkType)
//                            let startLandmarkPoint = normalizedPoint(
//                                fromVisionPoint: startLandmark.position, width: width, height: height, type: startLandmark.type)
//                            let endLandmarkPoint = normalizedPoint(
//                                fromVisionPoint: endLandmark.position, width: width, height: height, type: endLandmark.type)
//
//                            // Drawing skeleton
//                            if drawSkeleton {
//                                UIUtilities.addLineSegment(
//                                    fromPoint: startLandmarkPoint,
//                                    toPoint: endLandmarkPoint,
//                                    inView: self.annotationOverlayView,
//                                    color: UIColor.green,
//                                    width: Constant.lineWidth)
//                            }
//
//                        }
//
//                        // Zone Based - by dot
//                        zoneBasedSoundUtility?.posesForPlayingSound.enumerated().forEach { index, poseType in
//                            if startLandmarkType.rawValue == poseType.rawValue {
//                                for endLandmarkType in endLandmarkTypesArray {
//                                    let landmark = pose.landmark(ofType: endLandmarkType)
//                                    dots.append(normalizedPoint(fromVisionPoint: landmark.position, width: width, height: height, type: landmark.type))
//                                }
//                            }
//                        }
//                    }
//
//                    zoneBasedSoundUtility?.process(dots)
//
//                    // Landmarks
//                    for landmark in pose.landmarks {
//                        let landmarkPoint = normalizedPoint(
//                            fromVisionPoint: landmark.position, width: width, height: height, type: landmark.type)
//
//                        if landmark.type == .leftAnkle ||
//                            landmark.type == .rightAnkle ||
//                            landmark.type == .leftIndexFinger ||
//                            landmark.type == .rightIndexFinger {
//                            UIUtilities.addCircleImage(
//                                atPoint: landmarkPoint,
//                                to: self.annotationOverlayView,
//                                radius: Constant.bigDotRadius
//                            )
//                        }
//
//                        if drawSkeleton {
//                            UIUtilities.addCircle(
//                                atPoint: landmarkPoint,
//                                to: self.annotationOverlayView,
//                                color: UIColor.blue,
//                                radius: Constant.smallDotRadius
//                            )
//                        }
//                    }
//                }
//            }
//        }
//    }
//
//    // MARK: - Video session management
//
//    private func setUpCaptureSessionOutput() {
//        sessionQueue.async {
//            self.captureSession.beginConfiguration()
//            // When performing latency tests to determine ideal capture settings,
//            // run the app in 'release' mode to get accurate performance metrics
//            self.captureSession.sessionPreset = AVCaptureSession.Preset.medium
//
//            // let output = AVCaptureVideoDataOutput()
//            self.videoDataOutput.videoSettings = [
//                (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA,
//            ]
//            self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
//            let outputQueue = DispatchQueue(label: Constant.videoDataOutputQueueLabel)
//            self.videoDataOutput.setSampleBufferDelegate(self, queue: outputQueue)
//            guard self.captureSession.canAddOutput(self.videoDataOutput) else {
//                print("Failed to add capture session output.")
//                return
//            }
//            self.captureSession.addOutput(self.videoDataOutput)
//
//            if !self.enableHeadphones && self.captureSession.canAddOutput(self.audioDataOutput) {
//                self.audioDataOutput.setSampleBufferDelegate(self, queue: outputQueue)
//                self.captureSession.addOutput(self.audioDataOutput)
//            } else {
//                self.captureSession.removeOutput(self.audioDataOutput)
//            }
//
//            // self.captureSession.addOutput(self.movieOutput)
//            self.captureSession.commitConfiguration()
//        }
//    }
//
//    private func setUpCaptureSessionInputs() {
//        sessionQueue.async {
//            self.captureSession.beginConfiguration()
//            self.addVideoInput()
//            self.addAudioInput()
//            self.captureSession.commitConfiguration()
//        }
//    }
//
//    private func addVideoInput() {
//        let cameraPosition: AVCaptureDevice.Position = self.isUsingFrontCamera ? .front : .back
//        guard let device = self.captureDevice(forPosition: cameraPosition) else {
//            print("Failed to get capture device for camera position: \(cameraPosition)")
//            return
//        }
//        do {
//            let currentInputs = self.captureSession.inputs
//            for input in currentInputs {
//                self.captureSession.removeInput(input)
//            }
//
//            let input = try AVCaptureDeviceInput(device: device)
//            guard self.captureSession.canAddInput(input) else {
//                print("Failed to add capture session input.")
//                return
//            }
//            self.captureSession.addInput(input)
//        } catch {
//            print("Failed to create capture device input: \(error.localizedDescription)")
//        }
//    }
//
//    private func addAudioInput() {
//        guard let audioDevice = AVCaptureDevice.default(for: .audio) else { return }
//        do {
//            let audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
//            if self.captureSession.canAddInput(audioDeviceInput) {
//                self.captureSession.addInput(audioDeviceInput)
//            } else {
//                print("Failed to add audio input.")
//                return
//            }
//        } catch {
//            print("Failed to create audio device input.")
//        }
//    }
//
//    private func setupCameraPreview() {
//
//        self.previewLayer.videoGravity = .resizeAspectFill
//        self.previewLayer.frame = self.cameraView.layer.frame
//        self.cameraView.layer.addSublayer(self.previewLayer)
//
//        let longTap = UILongPressGestureRecognizer(target: self, action: #selector(longTap(sender:)))
//        longTap.minimumPressDuration = 5
//        longTap.allowableMovement = 50
//        cameraView.addGestureRecognizer(longTap)
//
//        // Swipe up gesture setup
//        let swipeUpGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(openMenu(_:)))
//        swipeUpGestureRecognizer.direction = .up
//        cameraView.addGestureRecognizer(swipeUpGestureRecognizer)
//
//        //Swipe down gesture setup
//        let swipeDownGestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(closeMenu(_:)))
//        swipeDownGestureRecognizer.direction = .down
//        cameraView.addGestureRecognizer(swipeDownGestureRecognizer)
//    }
//
//    @objc func longTap(sender: UILongPressGestureRecognizer) {
//        guard sender.state == .began else { return }
//        settingsButton.isHidden = !settingsButton.isHidden
//        UserDefaults.standard.set(settingsButton.isHidden, forKey: "settingsButtonHidden")
//        UserDefaults.standard.synchronize()
//    }
//
//    private func captureDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
//        if #available(iOS 10.0, *) {
//            let discoverySession = AVCaptureDevice.DiscoverySession(
//                deviceTypes: [.builtInWideAngleCamera],
//                mediaType: .video,
//                position: .unspecified
//            )
//            return discoverySession.devices.first { $0.position == position }
//        }
//        return nil
//    }
//
//    func setupWriter() {
//        do {
//            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//            let fileUrl = paths[0].appendingPathComponent("\(Date().timeIntervalSince1970).mov")
//            try? FileManager.default.removeItem(at: fileUrl)
//            videoWriter = try AVAssetWriter(url: fileUrl, fileType: .mov)
//
//            // Video Input
//            let settings = videoDataOutput.recommendedVideoSettingsForAssetWriter(writingTo: .mp4)
//            videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
//            var transform = CGAffineTransform(rotationAngle: -.pi/2)
//            transform = transform.scaledBy(x: -1, y: 1)
//            videoWriterInput.transform = transform
//
//            videoWriterInput.expectsMediaDataInRealTime = true
//            if videoWriter.canAdd(videoWriterInput) {
//                videoWriter.add(videoWriterInput)
//            }
//
//            // Audio Input
//            audioWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: [
//                AVFormatIDKey: kAudioFormatMPEG4AAC,
//                AVNumberOfChannelsKey: 1,
//                AVSampleRateKey: 44100,
//                AVEncoderBitRateKey: 64000,
//            ])
//            audioWriterInput.expectsMediaDataInRealTime = true
//            if videoWriter.canAdd(audioWriterInput) {
//                videoWriter.add(audioWriterInput)
//            }
//
//            videoWriter.startWriting()
//        } catch let error {
//            debugPrint(error.localizedDescription)
//        }
//    }
//
//    func startRecord() {
//        guard !isRecording else { return }
//
//        showCountDown()
//    }
//
//    func showCountDown() {
//
//        let countdownView = CountdownView.fromNib()
//        countdownView.alpha = 0
//        countdownView.completion = {
//            JiggleAnalytics.logAmplitudeEvent("Session Start")
//            ZoneBaseAudio.shared.restartBeat()
//            self.sessionAtSourceTime = nil
//            self.setupWriter()
//            self.isRecording = true
//            self.recordingTimer = Timer.scheduledTimer(timeInterval: 15.0, target: self, selector: #selector(self.stopRecordingOnTimer), userInfo: nil, repeats: false)
//            self.recordingStartTimestamp = NSDate.timeIntervalSinceReferenceDate
//        }
//        view.addSubview(countdownView)
//        countdownView.start()
//    }
//
//    @objc func stopRecordingOnTimer() {
//        zoneBasedSoundUtility?.stopRecording()
//    }
//
//    func stopRecord() {
//        guard isRecording else { return }
//
//        JiggleAnalytics.logAmplitudeEvent("Session Complete")
//        let processingView = ProcessingView.fromNib()
//        view.addSubview(processingView)
//        processingView.start()
//
//        isRecording = false
//        recordingStartTimestamp = nil
//        videoWriter.finishWriting { [weak self] in
//            self?.sessionAtSourceTime = nil
//            guard let url = self?.videoWriter.outputURL else { return }
//
//            guard let stamps = self?.soundTimestamps else { return }
//            self?.addSoundFromTimestamps(to: url, soundTimestamps: stamps) { url in
//                self?.soundTimestamps = [:]
//
//                let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//                let fileUrl = paths[0].appendingPathComponent("\(Date().timeIntervalSince1970).mov")
//                try? FileManager.default.removeItem(at: fileUrl)
//
//                self?.addWatermark(inputURL: url, outputURL: fileUrl, handler: { exportSession in
//                    guard let session = exportSession else { return }
//
//                    switch session.status {
//                    case .completed:
//                        var filesToShare = [Any]()
//                        filesToShare.append(fileUrl)
//                        filesToShare.append("https://jiggle.ai/app")
//                        let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)
//                        activityViewController.completionWithItemsHandler = { activity, success, items, error in
//                            if !success { return }
//
//                            JiggleAnalytics.logAmplitudeEvent("Share Video")
//                        }
//
//                        if let targetUrl = URL(string: "http://104.248.30.185:3000/upload") {
//                            self?.fileUploader?.uploadTestVideo(at: url, to: targetUrl) { result in
//
//                                switch result {
//                                case .success:
//                                    print("VIDEO UPLOADED")
//                                case .failure(let error):
//                                    print(error.localizedDescription)
//                                }
//
//                                DispatchQueue.main.async {
//                                    processingView.end()
//                                    self?.present(activityViewController, animated: true, completion: nil)
//                                }
//                            }
//                        }
//                    default:
//                        return
//                    }
//                })
//            }
//        }
//
//    }
//
//    private func startSession() {
//        sessionQueue.async {
//            self.captureSession.startRunning()
//        }
//    }
//
//    private func stopSession() {
//        sessionQueue.async {
//            self.captureSession.stopRunning()
//        }
//    }
//
//
//    //MARK: - Points methods
//
//    private func normalizedPoint(
//        fromVisionPoint point: VisionPoint,
//        width: CGFloat,
//        height: CGFloat,
//        type: PoseLandmarkType
//    ) -> CGPoint {
//        let cgPoint = CGPoint(x: point.x, y: point.y)
//        var normalizedPoint = CGPoint(x: cgPoint.x / width, y: cgPoint.y / height)
//        normalizedPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
//
//        if averageDotsSmooth {
//            return averageDot(newDot: normalizedPoint, type: type)
//        }
//
//        return normalizedPoint
//    }
//
//    private func averageDot(newDot: CGPoint, type: PoseLandmarkType) -> CGPoint {
//        let numberOfLastDots = Constant.lastDotsNumber
//
//        var lastThreeDotsOfType = lastThreeDots[type.rawValue]
//        if lastThreeDotsOfType == nil {
//            lastThreeDotsOfType = [CGPoint](repeating: CGPoint(x:0, y:0), count: numberOfLastDots)
//        }
//
//        for i in stride(from: numberOfLastDots-1, to: 0, by: -1) {
//            if let prev = lastThreeDotsOfType?[i-1] {
//                lastThreeDotsOfType?[i] = prev
//            }
//        }
//        lastThreeDotsOfType?[0] = newDot
//        lastThreeDots[type.rawValue] = lastThreeDotsOfType
//
//        var sumX = 0.0, sumY = 0.0, countX = 0, countY = 0
//
//        if let lastThreeDotsOfType = lastThreeDotsOfType {
//            for i in 0..<numberOfLastDots {
//
//                let dot = lastThreeDotsOfType[i]
//
//                sumX += Double(dot.x)
//                sumY += Double(dot.y)
//
//                if dot.x != CGFloat(0.0) {
//                    countX += 1
//                }
//                if dot.y != CGFloat(0.0) {
//                    countY += 1
//                }
//            }
//        }
//
//        return CGPoint(x: sumX/Double(countX), y: sumY/Double(countY))
//    }
//}
