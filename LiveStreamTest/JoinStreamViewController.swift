//
//  JoinStreamViewController.swift
//  LiveStreamTest
//
//


import UIKit
import AgoraRtcKit

class JoinStreamViewController: UIViewController {
    
    var agoraKit: AgoraRtcEngineKit?
    var remoteVideoView: UIView!
    
    let token = ""
    let appId = ""
    let channelName = "Test"

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupRemoteVideoView()
        setupAgoraEngine()
    }

    private func setupRemoteVideoView() {
        remoteVideoView = UIView()
        remoteVideoView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(remoteVideoView)

        NSLayoutConstraint.activate([
            remoteVideoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            remoteVideoView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            remoteVideoView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            remoteVideoView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupAgoraEngine() {
        agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: appId, delegate: self)
        agoraKit?.enableVideo()
        agoraKit?.setChannelProfile(.liveBroadcasting)
        agoraKit?.setClientRole(.audience)

        agoraKit?.joinChannel(byToken: token, channelId: channelName, info: nil, uid: 0) { (channel, uid, elapsed) in
            print("Audience joined the stream")
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        agoraKit?.leaveChannel(nil)
        AgoraRtcEngineKit.destroy()
    }
}

extension JoinStreamViewController: AgoraRtcEngineDelegate {
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("Remote user joined: \(uid)")
        
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.view = remoteVideoView
        videoCanvas.renderMode = .hidden
        agoraKit?.setupRemoteVideo(videoCanvas)
    }
}
