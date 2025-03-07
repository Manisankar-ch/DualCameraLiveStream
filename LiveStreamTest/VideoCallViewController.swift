//
//  VideoCallViewController.swift
//  LiveStreamTest
//
//

import UIKit
import AgoraRtcKit
import AVFoundation

class VideoCallViewController: UIViewController {
    
    var captureSession: AVCaptureMultiCamSession!
    var frontPreviewLayer: AVCaptureVideoPreviewLayer!
    var rearPreviewLayer: AVCaptureVideoPreviewLayer!
    
    let appId = ""

    let channelName = "Test"
    let token = ""
    
    // UI view for displaying the local video stream
    var localView: UIView!
    // UI view for displaying the remote video stream
    var remoteView: UIView!
    
    var videoButton: UIButton!
    var microphoneButton: UIButton!
    var cameraSwitchButton: UIButton!
    var endCallButton: UIButton!
    
    var isVideoMuted: Bool = false
    var isAudioMuted: Bool = false
    
    // Instance of the Agora RTC engine
    var agoraKit: AgoraRtcEngineKit!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
  
      
        // Initialize the Agora engine
        initializeAgoraVideoSDK()
        setupUI()
        setupToolbar()
        setupLocalVideo()
        joinChannel()
        
    }
    // Clean up resources when the view controller is deallocated
    deinit {
        agoraKit.stopPreview()
        agoraKit.leaveChannel(nil)
        AgoraRtcEngineKit.destroy()
    }
    
    // Initializes the Video SDK instance
    func initializeAgoraVideoSDK() {
        // Create an instance of AgoraRtcEngineKit and set the delegate
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: appId, delegate: self)
    }
    
    // Sets up the UI layout for local and remote video views
    func setupUI() {
        // Create the local video view covering the full screen
        remoteView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height - 100))
        
        // Create the remote video view positioned in the top-right corner
        localView = UIView(frame: CGRect(x: self.view.bounds.width - 135, y: 50, width: 135, height: 240))
        
        // Add video views to the main view
        self.view.addSubview(remoteView)
        self.view.addSubview(localView)
      
    }
    
    
    func setupToolbar() {
        let toolbarHeight: CGFloat = 50
        let toolbar = UIView()
        toolbar.backgroundColor = .darkGray
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)
        
        // Constraints
        NSLayoutConstraint.activate([
            toolbar.heightAnchor.constraint(equalToConstant: toolbarHeight),
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
        ])
        
        // Add buttons to the toolbar
        addButtons(to: toolbar)
    }
    
    func addButtons(to toolbar: UIView) {
        // Button titles and actions
        let buttonsInfo: [(title: String, imageName: String, action: Selector)] = [
            ("", "video",#selector(toggleVideo)),
            ("","mic", #selector(toggleAudio)),
            ("", "camera.rotate.fill", #selector(switchCamera)),
            ("", "xmark",#selector(endCall))
        ]
        
        let buttonWidth = view.bounds.width / CGFloat(buttonsInfo.count)
        let buttonHeight: CGFloat = 50
        
        for (index, buttonInfo) in buttonsInfo.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(buttonInfo.title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.setImage(UIImage(systemName: buttonInfo.imageName), for: .normal)
            button.frame = CGRect(x: CGFloat(index) * buttonWidth, y: 0, width: buttonWidth, height: buttonHeight)
            button.addTarget(self, action: buttonInfo.action, for: .touchUpInside)
            toolbar.addSubview(button)
            switch(index) {
            case 0:
                videoButton = button
            case 1:
                microphoneButton = button
            case 2:
                cameraSwitchButton = button
            case 3:
                endCallButton = button
            default:
                break
            }
        }
    }

    @objc func toggleVideo() {
        isVideoMuted.toggle()
        agoraKit.muteLocalVideoStream(isVideoMuted)
        localView.isHidden = isVideoMuted
        videoButton.setImage(!isVideoMuted ? UIImage(systemName: "video") : UIImage(systemName: "video.slash"), for: .normal)
    }

    @objc func toggleAudio() {
        isAudioMuted.toggle()
        agoraKit.muteLocalAudioStream(isAudioMuted)
        microphoneButton.setImage(!isAudioMuted ? UIImage(systemName: "mic") : UIImage(systemName: "mic.slash"), for: .normal)
        // Update UI accordingly
    }

    @objc func endCall() {
        print("Call end")
        agoraKit.stopPreview()
        agoraKit.leaveChannel(nil)
        navigationController?.popViewController(animated: true)
    }

    @objc func switchCamera() {
        agoraKit.switchCamera()
    }

    
    func setupLocalVideo() {
        // Enable video functionality
        agoraKit.enableVideo()
        
        // Set the default camera to the back camera
        let captureConfig = AgoraCameraCapturerConfiguration()
        captureConfig.cameraDirection = .front
        agoraKit.setCameraCapturerConfiguration(captureConfig)
        
        // Configure local video feed
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.view = localView // Show local video in remoteView
        videoCanvas.uid = 0  // Local user's UID
        videoCanvas.renderMode = .hidden
        agoraKit.setupLocalVideo(videoCanvas)
        
        // Start the video preview
        agoraKit.startPreview()
    }
    
    
    // Join the channel with specified options
    func joinChannel() {
        let options = AgoraRtcChannelMediaOptions()
        // In a live streaming use-case, set the channel use-case to liveBroadcasting
        options.channelProfile = .liveBroadcasting
        // Set the user role as broadcaster (default is audience)
        options.clientRoleType = .broadcaster
        // Publish audio captured by microphone
        options.publishMicrophoneTrack = true
        // Publish video captured by camera
        options.publishCameraTrack = true
        // Auto subscribe to all audio streams
        options.autoSubscribeAudio = true
        // Auto subscribe to all video streams
        options.autoSubscribeVideo = true
        // Set the audience ultra-low latency level
        options.audienceLatencyLevel = .ultraLowLatency
        // If you set uid=0, the engine generates a uid internally; on success, it triggers didJoinChannel callback
        // Join the channel with a temporary token
        agoraKit.joinChannel(
            byToken: token,
            channelId: channelName,
            uid: 0,
            mediaOptions: options
        )
    }
    
    func setupRemoteVideo(uid: UInt, view: UIView?) {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.view = view // Assign view for joining, set to nil for leaving
        videoCanvas.renderMode = .hidden
        agoraKit.setupRemoteVideo(videoCanvas)
    }
}
// Extension for handling Agora SDK callbacks
extension VideoCallViewController: AgoraRtcEngineDelegate {
    
    // Triggered when the local user successfully joins a channel
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("Successfully joined channel: \(channel) with UID: \(uid)")
    }
    
    // Triggered when a remote user joins the channel
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("Another user joined the channel:  with UID: \(uid)")
            setupRemoteVideo(uid: uid, view: remoteView)
    }
    // Triggered when a remote user leaves the channel
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        print("Another user left the channel:  with UID: \(uid)")
    }
}
