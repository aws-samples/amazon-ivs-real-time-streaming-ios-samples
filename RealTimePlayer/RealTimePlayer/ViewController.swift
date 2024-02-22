//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

import AmazonIVSBroadcast
import AVKit
import UIKit

class ViewController: UIViewController {
    
    // MARK: - IBOutlets

    @IBOutlet private var textFieldToken: UITextField!
    @IBOutlet private var buttonJoin: UIButton!
    @IBOutlet private var previewViewContainer: UIView!
    @IBOutlet private var buttonPiP: UIButton!

    // MARK: - AmazonIVSBroadcast Properties

    private var stage: IVSStage?

    // MARK: - Sample app state

    private var connectingOrConnected = false {
        didSet {
            buttonJoin.setTitle(connectingOrConnected ? "Leave" : "Join", for: .normal)
            buttonJoin.tintColor = connectingOrConnected ? .systemRed : .systemBlue
        }
    }

    // PiP related properties. This can be done multiple ways, but we've found this to be an easy and responsive solution.
    private var pipPossibleObserver: NSKeyValueObservation?
    private var pipActiveObserver: NSKeyValueObservation?
    private var pipController: AVPictureInPictureController? {
        didSet {
            if pipController != oldValue {
                pipPossibleObserver?.invalidate()
                pipPossibleObserver = nil
            }

            guard let pipController = pipController else {
                updatePipButton()
                buttonPiP.isEnabled = false
                return
            }

            pipPossibleObserver = pipController.observe(\.isPictureInPicturePossible, options: [.initial, .new]) { [weak self] (pipController, change) in
                self?.buttonPiP.isEnabled = change.newValue ?? false
            }
            pipActiveObserver = pipController.observe(\.isPictureInPictureActive, options: [.initial, .new]) { [weak self] (pipController, change) in
                self?.updatePipButton()
            }
        }
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register a tap recognizer so the keyboard closes if you tap the background.
        let tap = UITapGestureRecognizer(target: self, action: #selector(overlayTapped))
        previewViewContainer.addGestureRecognizer(tap)

        // When using Stages as a player, it's recommended to use the subscribeOnly preset.
        IVSStageAudioManager.sharedInstance().setPreset(.subscribeOnly)

        // Set the initial state of the PiP button
        updatePipButton()
        buttonPiP.isEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - IBActions

    @IBAction private func joinTapped(_ sender: UIButton?) {
        if connectingOrConnected {
            // If we're already connected to a Stage, leave it.
            stage?.leave()
        } else {
            guard let token = textFieldToken.text else {
                print("No text found in the token text field")
                return
            }
            // Hide the keyboard after tapping Join
            textFieldToken.resignFirstResponder()
            do {
                // This could be optimized by checking if the token has changed and not recreating the IVSStage object if it is the same token.
                let stage = try IVSStage(token: token, strategy: self)
                stage.addRenderer(self)
                try stage.join()
                self.stage = stage
            } catch {
                print("Failed to join stage - \(error)")
            }
        }
    }

    @IBAction private func tokenPasteButtonTapped(_ sender: Any) {
        textFieldToken.text = UIPasteboard.general.string
    }

    @IBAction private func pipTapped(_ sender: Any) {
        guard let pip = pipController, pip.isPictureInPicturePossible else { return }
        if pip.isPictureInPictureActive {
            pip.stopPictureInPicture()
        } else {
            pip.startPictureInPicture()
        }
    }

    @objc private func overlayTapped() {
        // Hide the keyboard
        view.endEditing(false)
    }

    // MARK: - Misc Utilities

    private func updatePipButton() {
        let isActive = pipController?.isPictureInPictureActive == true
        let image = isActive ? AVPictureInPictureController.pictureInPictureButtonStopImage(compatibleWith: buttonPiP.traitCollection)
                             : AVPictureInPictureController.pictureInPictureButtonStartImage(compatibleWith: buttonPiP.traitCollection)
        let text = isActive ? "Stop PiP" : "Start PiP"
        buttonPiP.setImage(image, for: .normal)
        buttonPiP.setTitle(text, for: .normal)
    }
}

// MARK: - IVSStageStrategy

// When using Stages an a player, this is the recommended strategy. No not publish, and return an empty array of streams.
extension ViewController: IVSStageStrategy {
    func stage(_ stage: IVSStage, streamsToPublishForParticipant participant: IVSParticipantInfo) -> [IVSLocalStageStream] {
        return []
    }

    func stage(_ stage: IVSStage, shouldPublishParticipant participant: IVSParticipantInfo) -> Bool {
        return false
    }

    func stage(_ stage: IVSStage, shouldSubscribeToParticipant participant: IVSParticipantInfo) -> IVSStageSubscribeType {
        // This could also be .audioOnly for use cases that do not want to stream video.
        return .audioVideo
    }
}

// MARK: - IVSStageRenderer

extension ViewController: IVSStageRenderer {

    func stage(_ stage: IVSStage, didChange connectionState: IVSStageConnectionState, withError error: Error?) {
        // Note that there is no error handling in this sample application. Look for `error` to be non-nil and update your UI accordingly.
        connectingOrConnected = connectionState != .disconnected
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didAdd streams: [IVSStageStream]) {
        // For this sample application, we expect that there is only 1 publishing participant for the joined Stage.
        if let imageDevice = streams
            .compactMap({ $0.device as? IVSImageDevice })
            .first
        {
            // For the publishing participant, create a preview video for them and attach it to our container view.
            let preview = try! imageDevice.previewView()
            previewViewContainer.addSubviewMatchFrame(preview)
            // Then we can create a AVPictureInPictureController from that preview view.
            pipController = AVPictureInPictureController(ivsImagePreviewView: preview)!
        }
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didRemove streams: [IVSStageStream]) {
        // Only remove the most recently added view (the preview view)
        previewViewContainer.subviews.last?.removeFromSuperview()
        pipController = nil
    }
}
