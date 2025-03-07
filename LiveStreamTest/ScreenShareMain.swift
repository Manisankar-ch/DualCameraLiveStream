//
//  ScreenShareMain.swift
//  LiveStreamTest
//
//
import UIKit

import AgoraRtcKit
import ReplayKit


class ScreenShareMain: UIViewController {
    
    let appId = ""
    
    let channelName = "Test"
    let token = ""
    
    
    var agoraKit: AgoraRtcEngineKit!
    
    var captureSession: AVCaptureMultiCamSession!
    var frontPreviewLayer: AVCaptureVideoPreviewLayer!
    var rearPreviewLayer: AVCaptureVideoPreviewLayer!
    
    
    
    var localFrontCameraView: UIView = {
        let view = UIView()
        view.backgroundColor = .red
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var localRearCameraView: UIView = {
        let view = UIView()
        view.backgroundColor = .blue
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var screenParams: AgoraScreenCaptureParameters2 = {
        let params = AgoraScreenCaptureParameters2()
        params.captureVideo = true
        params.captureAudio = true
        let audioParams = AgoraScreenAudioParameters()
        audioParams.captureSignalVolume = 50
        params.audioParams = audioParams
        let videoParams = AgoraScreenVideoParameters()
        videoParams.dimensions = screenShareVideoDimension()
        videoParams.frameRate = .fps30
        videoParams.bitrate = AgoraVideoBitrateStandard
        params.videoParams = videoParams
        return params
    }()
    
    private lazy var option: AgoraRtcChannelMediaOptions = {
        let option = AgoraRtcChannelMediaOptions()
        option.clientRoleType = .broadcaster
        option.publishCameraTrack = true
        option.publishMicrophoneTrack = true
        return option
    }()
    
    private var systemBroadcastPicker: RPSystemBroadcastPickerView?
    
    // indicate if current instance has joined channel
    var isJoined: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMultiCamSession()
        
        // set up agora instance when view loaded
        let config = AgoraRtcEngineConfig()
        config.appId = appId
        config.areaCode = .global
        config.channelProfile = .liveBroadcasting
        agoraKit = AgoraRtcEngineKit.sharedEngine(with: config, delegate: self)
        // Configuring Privatization Parameters
        Util.configPrivatization(agoraKit: agoraKit)
        
        // make myself a broadcaster
        agoraKit.setClientRole(GlobalSettings.shared.getUserRole())
        
        agoraKit.enableAudio()
        let resolution = (GlobalSettings.shared.getSetting(key: "resolution")?.selectedOption().value as? CGSize) ?? .zero
        let fps = (GlobalSettings.shared.getSetting(key: "fps")?.selectedOption().value as? AgoraVideoFrameRate) ?? .fps15
        let orientation = (GlobalSettings.shared.getSetting(key: "orientation")?
            .selectedOption().value as? AgoraVideoOutputOrientationMode) ?? .fixedPortrait
        agoraKit.setVideoEncoderConfiguration(AgoraVideoEncoderConfiguration(size: resolution,
                                                                             frameRate: fps,
                                                                             bitrate: AgoraVideoBitrateStandard,
                                                                             orientationMode: orientation,
                                                                             mirrorMode: .auto))
        
        let result = self.agoraKit.joinChannel(byToken: token, channelId: channelName, uid: SCREEN_SHARE_UID, mediaOptions: self.option)
        self.agoraKit.muteRemoteAudioStream(UInt(SCREEN_SHARE_BROADCASTER_UID), mute: true)
        self.agoraKit.muteRemoteVideoStream(UInt(SCREEN_SHARE_BROADCASTER_UID), mute: true)
        if result != 0 {
            // Usually happens with invalid parameters
            // Error code description can be found at:
            // en: https://api-ref.agora.io/en/video-sdk/ios/4.x/documentation/agorartckit/agoraerrorcode
            // cn: https://doc.shengwang.cn/api-ref/rtc/ios/error-code
            print("joinChannel call failed: \(result), please check your params")
        }
    }
    
    func prepareSystemBroadcaster() {
        if #available(iOS 12.0, *) {
            let frame = CGRect(x: 0, y: 0, width: 60, height: 60)
            systemBroadcastPicker = RPSystemBroadcastPickerView(frame: frame)
            systemBroadcastPicker?.showsMicrophoneButton = false
            systemBroadcastPicker?.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin]
            let bundleId = Bundle.main.bundleIdentifier ?? ""
            systemBroadcastPicker?.preferredExtension = "\(bundleId).LiveStreamBroadCast"
            
        } else {
            print("Minimum support iOS version is 12.0")
        }
    }
    
    private func screenShareVideoDimension() -> CGSize {
        let screenSize = UIScreen.main.bounds
        var boundingSize = CGSize(width: 540, height: 960)
        let mW: CGFloat = boundingSize.width / screenSize.width
        let mH: CGFloat = boundingSize.height / screenSize.height
        if mH < mW {
            boundingSize.width = boundingSize.height / screenSize.height * screenSize.width
        } else if mW < mH {
            boundingSize.height = boundingSize.width / screenSize.width * screenSize.height
        }
        return boundingSize
    }
    
    override func willMove(toParent parent: UIViewController?) {
        if parent == nil {
            // leave channel when exiting the view
            // deregister packet processing
            if isJoined {
                agoraKit.disableAudio()
                agoraKit.disableVideo()
                agoraKit.leaveChannel { (stats) -> Void in
                    print( "left channel, duration: \(stats.duration)")
                }
                AgoraRtcEngineKit.destroy()
            }
        }
    }
    
    
    func setupUI() {
        
        // Create the local video view covering the full screen
        localRearCameraView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height - 100))
        
        // Create the remote video view positioned in the top-right corner
        localFrontCameraView = UIView(frame: CGRect(x: self.view.bounds.width - 135, y: 50, width: 135, height: 240))
        
        // Add video views to the main view
        self.view.addSubview(localRearCameraView)
        self.view.addSubview(localFrontCameraView)
        
        let startButton = createButton(title: "Start", action: #selector(startScreenCapture))
        let stopButton = createButton(title: "Stop", action: #selector(stopScreenCapture))
        
        
        
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.addArrangedSubview(startButton)
        stackView.addArrangedSubview(stopButton)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
    }
    
    func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        return button
    }
    @objc func stopScreenCapture(_ sender: Any) {
        agoraKit.stopScreenCapture()
        option.publishScreenCaptureVideo = false
        option.publishScreenCaptureAudio = false
        option.publishCameraTrack = true
        agoraKit.updateChannel(with: option)
    }
    
    @objc func startScreenCapture(_ sender: Any) {
        guard !UIScreen.main.isCaptured else { return }
        agoraKit.startScreenCapture(screenParams)
        prepareSystemBroadcaster()
        guard let picker = systemBroadcastPicker else { return }
        for view in picker.subviews where view is UIButton {
            (view as? UIButton)?.sendActions(for: .allEvents)
            break
        }
    }
    
}

/// agora rtc engine delegate events
extension ScreenShareMain: AgoraRtcEngineDelegate {
    /// callback when warning occured for agora sdk, warning can usually be ignored, still it's nice to check out
    /// what is happening
    /// Warning code description can be found at:
    /// en: https://api-ref.agora.io/en/voice-sdk/ios/3.x/Constants/AgoraWarningCode.html
    /// cn: https://docs.agora.io/cn/Voice/API%20Reference/oc/Constants/AgoraWarningCode.html
    /// @param warningCode warning code of the problem
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
        print("warning: \(warningCode)")
    }
    
    /// callback when error occured for agora sdk, you are recommended to display the error descriptions on demand
    /// to let user know something wrong is happening
    /// Error code description can be found at:
    /// en: https://api-ref.agora.io/en/video-sdk/ios/4.x/documentation/agorartckit/agoraerrorcode
    /// cn: https://doc.shengwang.cn/api-ref/rtc/ios/error-code
    /// @param errorCode error code of the problem
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        
    }
    
    /// callback when the local user joins a specified channel.
    /// @param channel
    /// @param uid uid of local user
    /// @param elapsed time elapse since current sdk instance join the channel in ms
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        self.isJoined = true
        
    }
    
    /// callback when a remote user is joinning the channel, note audience in live broadcast mode will NOT trigger this event
    /// @param uid uid of remote joined user
    /// @param elapsed time elapse since current sdk instance join the channel in ms
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        
        
        // Only one remote video view is available for this
        // tutorial. Here we check if there exists a surface
        // view tagged as this uid.
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        // the view to be binded
        //        videoCanvas.view = remoteVideo.videoView
        videoCanvas.renderMode = .fit
        agoraKit.setupRemoteVideo(videoCanvas)
    }
    
    /// callback when a remote user is leaving the channel, note audience in live broadcast mode will NOT trigger this event
    /// @param uid uid of remote joined user
    /// @param reason reason why this user left, note this event may be triggered when the remote user
    /// become an audience in live broadcasting profile
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        
        
        // to unlink your view from sdk, so that your view reference will be released
        // note the video will stay at its last frame, to completely remove it
        // you will need to remove the EAGL sublayer from your binded view
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        // the view to be binded
        videoCanvas.view = nil
        videoCanvas.renderMode = .hidden
        agoraKit.setupRemoteVideo(videoCanvas)
    }
    func rtcEngine(_ engine: AgoraRtcEngineKit,
                   localVideoStateChangedOf state: AgoraVideoLocalState,
                   reason: AgoraLocalVideoStreamReason,
                   sourceType: AgoraVideoSourceType) {
        switch (state, sourceType) {
        case (.capturing, .screen):
            option.publishScreenCaptureVideo = !UIScreen.main.isCaptured
            option.publishScreenCaptureAudio = !UIScreen.main.isCaptured
            option.publishCameraTrack = UIScreen.main.isCaptured
            agoraKit.updateChannel(with: option)
            
            // 开始屏幕共享后, 如果想自动隐藏系统界面, 需要配置scheme, 使用scheme唤醒自身的方式关闭系统界面
            // If you want to hide the system interface automatically after you start screen sharing,
            // you need to configure scheme and use scheme to wake up the system interface
            UIApplication.shared.open(URL(string: "APIExample://") ?? URL(fileURLWithPath: "APIExample://"))
            
        default: break
        }
    }
    
    /// Reports the statistics of the current call. The SDK triggers this callback once every two seconds after the user joins the channel.
    /// @param stats stats struct
    func rtcEngine(_ engine: AgoraRtcEngineKit, reportRtcStats stats: AgoraChannelStats) {
        //        localVideo.statsInfo?.updateChannelStats(stats)
    }
    
    /// Reports the statistics of the uploading local audio streams once every two seconds.
    /// @param stats stats struct
    func rtcEngine(_ engine: AgoraRtcEngineKit, localAudioStats stats: AgoraRtcLocalAudioStats) {
    }
    
    /// Reports the statistics of the video stream from each remote user/host.
    /// @param stats stats struct
    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteVideoStats stats: AgoraRtcRemoteVideoStats) {
    }
    
    /// Reports the statistics of the audio stream from each remote user/host.
    /// @param stats stats struct for current call statistics
    func rtcEngine(_ engine: AgoraRtcEngineKit, remoteAudioStats stats: AgoraRtcRemoteAudioStats) {
    }
}





extension ScreenShareMain {
    func setupMultiCamSession() {
        captureSession = AVCaptureMultiCamSession()
        
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            print("Multi-camera not supported on this device.")
            return
        }
        
        // Setup Front Camera
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("No camera found")
            return
        }
        let frontInput = try! AVCaptureDeviceInput(device: frontCamera)
        captureSession.addInput(frontInput)
        
        let frontOutput = AVCaptureVideoDataOutput()
        captureSession.addOutput(frontOutput)
        
        // Setup Rear Camera
        guard let rearCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("No camera found")
            return
        }
        let rearInput = try! AVCaptureDeviceInput(device: rearCamera)
        captureSession.addInput(rearInput)
        
        let rearOutput = AVCaptureVideoDataOutput()
        captureSession.addOutput(rearOutput)
        
        // Preview Layers
        frontPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        frontPreviewLayer.frame = localFrontCameraView.bounds
        localFrontCameraView.layer.addSublayer(frontPreviewLayer)
        
        rearPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        rearPreviewLayer.frame = localRearCameraView.bounds
        localRearCameraView.layer.addSublayer(rearPreviewLayer)
        captureSession.startRunning()
    }
}
