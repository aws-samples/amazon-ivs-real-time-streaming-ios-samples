//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

import UIKit
import AmazonIVSBroadcast

class ViewController: UIViewController {

    enum ChangeType {
        case joined, updated, left
    }

    /// If `canPublish` is `false`, the sample application will not ask for permissions or publish to the Stage
    /// This will be a view-only participant.
    private let canPublish = true

    // MARK: - IBOutlets

    @IBOutlet private var textFieldToken: UITextField!
    @IBOutlet private var buttonJoin: UIButton!
    @IBOutlet private var labelState: UILabel!
    @IBOutlet private var switchPublish: UISwitch!
    @IBOutlet private var collectionViewParticipants: UICollectionView!

    // MARK: - AmazonIVSBroadcast Properties

    private var stage: IVSStage?
    private var streams = [IVSLocalStageStream]()
    private let deviceDiscovery = IVSDeviceDiscovery()

    // MARK: - Sample app state

    private var participants = [StageParticipant]()
    private var connectingOrConnected = false {
        didSet {
            buttonJoin.setTitle(connectingOrConnected ? "Leave" : "Join", for: .normal)
            buttonJoin.tintColor = connectingOrConnected ? .systemRed : .systemBlue
        }
    }

    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        participants.append(StageParticipant(isLocal: true, participantId: nil))
        if canPublish {
            checkPermissions()
        }

        // Change UI based on if this build was created with publishing allowed.
        switchPublish.isOn = canPublish
        switchPublish.isUserInteractionEnabled = canPublish
        switchPublish.alpha = canPublish ? 1 : 0.3

        // We render everything to exactly the frame, so don't allow scrolling.
        collectionViewParticipants.isScrollEnabled = false
        collectionViewParticipants.register(UINib(nibName: "ParticipantCollectionViewCell", bundle: .main), forCellWithReuseIdentifier: "ParticipantCollectionViewCell")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Prevent the screen from turning off during a call.
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    // MARK: - IBActions

    @IBAction private func joinTapped(_ sender: UIButton) {
        if connectingOrConnected {
            // If we're already connected to a Stage, leave it.
            stage?.leave()
        } else {
            guard let token = textFieldToken.text else {
                print("No token")
                return
            }
            // Hide the keyboard after tapping Join
            textFieldToken.resignFirstResponder()
            do {
                // Destroy the old Stage first before creating a new one.
                self.stage = nil
                let stage = try IVSStage(token: token, strategy: self)
                stage.errorDelegate = self
                stage.addRenderer(self)
                try stage.join()
                self.stage = stage
            } catch {
                print("Failed to join stage - \(error)")
            }
        }
    }

    @IBAction private func publishToggled(_ sender: UISwitch) {
        // Because the strategy returns the value of `switchPublish.isOn`, just call `refreshStrategy`.
        stage?.refreshStrategy()
    }

    // MARK: - Utility functions

    private func setupLocalUser() {
        guard canPublish else { return }
        // Gather our camera and microphone once permissions have been granted
        let devices = deviceDiscovery.listLocalDevices()
        streams.removeAll()
        if let camera = devices.compactMap({ $0 as? IVSCamera }).first {
            streams.append(IVSLocalStageStream(device: camera))
            // Use a front camera if available.
            if let frontSource = camera.listAvailableInputSources().first(where: { $0.position == .front }) {
                camera.setPreferredInputSource(frontSource)
            }
        }
        if let mic = devices.compactMap({ $0 as? IVSMicrophone }).first {
            streams.append(IVSLocalStageStream(device: mic))
        }
        participants[0].streams = streams
        participantsChanged(index: 0, changeType: .updated)
    }

    private func participantsChanged(index: Int, changeType: ChangeType) {
        // UICollectionView automatically clears itself out when it gets detached from it's
        // superview it seems (which for us happens when the VC is dismissed).
        // So even though our update/insert/reload calls are in sync, the UICollectionView
        // thinks it has 0 items if this is invoked async after the VC is dismissed.
        guard collectionViewParticipants?.superview != nil else { return }
        switch changeType {
        case .joined:
            collectionViewParticipants?.insertItems(at: [IndexPath(item: index, section: 0)])
        case .updated:
            // Instead of doing reloadItems, just grab the cell and update it ourselves. It saves a create/destroy of a cell
            // and more importantly fixes some UI glitches. We don't support scrolling at all so the index path per cell
            // never changes.
            if let cell = collectionViewParticipants?.cellForItem(at: IndexPath(item: index, section: 0)) as? ParticipantCollectionViewCell {
                cell.set(participant: participants[index])
            }
        case .left:
            collectionViewParticipants?.deleteItems(at: [IndexPath(item: index, section: 0)])
        }
    }

    // MARK: - Permissions Management

    private func checkPermissions() {
        checkOrGetPermission(for: .video) { [weak self] granted in
            guard granted else {
                print("Video permission denied")
                return
            }
            self?.checkOrGetPermission(for: .audio) { [weak self] granted in
                guard granted else {
                    print("Audio permission denied")
                    return
                }
                self?.setupLocalUser()
            }
        }
    }

    private func checkOrGetPermission(for mediaType: AVMediaType, _ result: @escaping (Bool) -> Void) {
        func mainThreadResult(_ success: Bool) {
            DispatchQueue.main.async {
                result(success)
            }
        }
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .authorized: mainThreadResult(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: mediaType) { granted in
                mainThreadResult(granted)
            }
        case .denied, .restricted: mainThreadResult(false)
        @unknown default: mainThreadResult(false)
        }
    }

}

// MARK: - IVSStageStrategy

extension ViewController: IVSStageStrategy {
    func stage(_ stage: IVSStage, streamsToPublishForParticipant participant: IVSParticipantInfo) -> [IVSLocalStageStream] {
        // Return the camera and microphone to be published.
        // This is only called if `shouldPublishParticipant` returns true.
        return streams
    }

    func stage(_ stage: IVSStage, shouldPublishParticipant participant: IVSParticipantInfo) -> Bool {
        return switchPublish.isOn
    }

    func stage(_ stage: IVSStage, shouldSubscribeToParticipant participant: IVSParticipantInfo) -> IVSStageSubscribeType {
        // Subscribe to both audio and video for all publishing participants.
        return .audioVideo
    }
}

// MARK: - IVSStageRenderer

extension ViewController: IVSStageRenderer {

    func stage(_ stage: IVSStage, didChange connectionState: IVSStageConnectionState, withError error: Error?) {
        labelState.text = connectionState.text
        connectingOrConnected = connectionState != .disconnected
    }

    func stage(_ stage: IVSStage, participantDidJoin participant: IVSParticipantInfo) {
        if participant.isLocal {
            // If this is the local participant joining the Stage, update the first participant in our array because we
            // manually added that participant when setting up our preview
            participants[0].participantId = participant.participantId
            participantsChanged(index: 0, changeType: .updated)
        } else {
            // If they are not local, add them to the array as a newly joined participant.
            participants.append(StageParticipant(isLocal: false, participantId: participant.participantId))
            participantsChanged(index: (participants.count - 1), changeType: .joined)
        }
    }

    func stage(_ stage: IVSStage, participantDidLeave participant: IVSParticipantInfo) {
        if participant.isLocal {
            // If this is the local participant leaving the Stage, update the first participant in our array because
            // we want to keep the camera preview active
            participants[0].participantId = nil
            participantsChanged(index: 0, changeType: .updated)
        } else {
            // If they are not local, find their index and remove them from the array.
            if let index = participants.firstIndex(where: { $0.participantId == participant.participantId }) {
                participants.remove(at: index)
                participantsChanged(index: index, changeType: .left)
            }
        }
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didChange publishState: IVSParticipantPublishState) {
        // Update the publishing state of this participant
        mutatingParticipant(participant.participantId) { data in
            data.publishState = publishState
        }
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didChange subscribeState: IVSParticipantSubscribeState) {
        // Update the subscribe state of this participant
        mutatingParticipant(participant.participantId) { data in
            data.subscribeState = subscribeState
        }
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didChangeMutedStreams streams: [IVSStageStream]) {
        // We don't want to take any action for the local participant because we track those streams locally
        if participant.isLocal { return }
        // For remote participants, notify the UICollectionView that they have updated. There is no need to modify
        // the `streams` property on the `StageParticipant` because it is the same `IVSStageStream` instance. Just
        // query the `isMuted` property again.
        if let index = participants.firstIndex(where: { $0.participantId == participant.participantId }) {
            participantsChanged(index: index, changeType: .updated)
        }
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didAdd streams: [IVSStageStream]) {
        // We don't want to take any action for the local participant because we track those streams locally
        if participant.isLocal { return }
        // For remote participants, add these new streams to that participant's streams array.
        mutatingParticipant(participant.participantId) { data in
            data.streams.append(contentsOf: streams)
        }
    }

    func stage(_ stage: IVSStage, participant: IVSParticipantInfo, didRemove streams: [IVSStageStream]) {
        // We don't want to take any action for the local participant because we track those streams locally
        if participant.isLocal { return }
        // For remote participants, remove these streams from that participant's streams array.
        mutatingParticipant(participant.participantId) { data in
            let oldUrns = streams.map { $0.device.descriptor().urn }
            data.streams.removeAll(where: { stream in
                return oldUrns.contains(stream.device.descriptor().urn)
            })
        }
    }

    // A helper function to find a participant by its ID, mutate that participant, and then update the UICollectionView accordingly.
    private func mutatingParticipant(_ participantId: String?, modifier: (inout StageParticipant) -> Void) {
        guard let index = participants.firstIndex(where: { $0.participantId == participantId }) else {
            fatalError("Something is out of sync, investigate if this was a sample app or SDK issue.")
        }

        var participant = participants[index]
        modifier(&participant)
        participants[index] = participant
        participantsChanged(index: index, changeType: .updated)
    }

}

// MARK: - UICollectionViewDataSource

extension ViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return participants.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ParticipantCollectionViewCell", for: indexPath) as? ParticipantCollectionViewCell {
            cell.set(participant: participants[indexPath.row])
            return cell
        } else {
            fatalError("Couldn't load custom cell type 'ParticipantCollectionViewCell'")
        }
    }

}

// MARK: - IVSErrorDelegate

extension ViewController: IVSErrorDelegate {
    func source(_ source: IVSErrorSource, didEmitError error: Error) {
        print("\(source) emitted error - \(error)")
    }
}

// MARK: - Extensions

extension IVSStageConnectionState {
    var text: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        @unknown default: fatalError()
        }
    }
}
