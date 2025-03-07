//
//  ViewController.swift
//  LiveStreamTest
//
//

import UIKit
import AgoraRtcKit
import AVFoundation

class ViewController: UIViewController {
    
    var videoCallButton: UIButton =  UIButton(type: .system)
    var joinStreamButton: UIButton =  UIButton(type: .system)
    var startStreamButton: UIButton = UIButton(type: .system)
    
    lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [startStreamButton,joinStreamButton,videoCallButton])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupCenterButton(action: navigateToStreamViewController, title: "Start Stream", button: startStreamButton)
        setupCenterButton(action: navigateToStreamViewController, title: "Join Stream", button: joinStreamButton)
        setupCenterButton(action: navigateToNextViewController, title: "Video Call", button: videoCallButton)
        
    }
    
    func setupUI() {
        view.addSubview(stackView)
        joinStreamButton.tag = 1
        startStreamButton.tag = 2
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
    }
    
    func setupCenterButton(action: @escaping (_ tag: Int) -> Void, title: String, button: UIButton) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addAction(UIAction { _ in
            action(button.tag)
        }, for: .touchUpInside)
    }
    
    func navigateToNextViewController(tag: Int) {
        let destinationVC = VideoCallViewController()
        self.navigationController?.pushViewController(destinationVC, animated: true)
        
    }
    
    func navigateToStreamViewController(tag: Int) {
        let destinationVC = tag == 2 ? ScreenShareMain() : JoinStreamViewController()
        self.navigationController?.pushViewController(destinationVC, animated: true)
        
    }
}
