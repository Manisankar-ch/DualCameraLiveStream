//
//  SampleHandler.swift
//  LiveStreamBroadCast
//
//

import ReplayKit
import AgoraReplayKitExtension

class SampleHandler: RPBroadcastSampleHandler, AgoraReplayKitExtDelegate {

    

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        AgoraReplayKitExt.shareInstance().start(self)
        // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
        AgoraReplayKitExt.shareInstance().pause()
    }
    
    override func broadcastResumed() {
        AgoraReplayKitExt.shareInstance().resume()
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
        AgoraReplayKitExt.shareInstance().stop()
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        AgoraReplayKitExt.shareInstance().push(sampleBuffer, with: sampleBufferType)
    }
    
    func broadcastFinished(_ broadcast: AgoraReplayKitExt, reason: AgoraReplayKitExtReason) {
            var tip = ""
            switch reason {
            case AgoraReplayKitExtReasonInitiativeStop:
                tip = "AgoraReplayKitExtReasonInitiativeStop"

            case AgoraReplayKitExtReasonConnectFail:
                tip = "AgoraReplayKitExReasonConnectFail"

            case AgoraReplayKitExtReasonDisconnect:
                tip = "AgoraReplayKitExReasonDisconnect"

            default: break
            }

            let error = NSError(domain: NSCocoaErrorDomain,
                                code: 0,
                                userInfo: [NSLocalizedFailureReasonErrorKey: tip])
            self .finishBroadcastWithError(error as Error)
        }
}
