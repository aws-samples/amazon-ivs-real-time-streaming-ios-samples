//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

import UIKit
import AmazonIVSBroadcast

class ParticipantCollectionViewCell: UICollectionViewCell {

    @IBOutlet private var viewPreviewContainer: UIView!
    @IBOutlet private var labelParticipantId: UILabel!
    @IBOutlet private var labelSubscribeState: UILabel!
    @IBOutlet private var labelPublishState: UILabel!
    @IBOutlet private var labelVideoMuted: UILabel!
    @IBOutlet private var labelAudioMuted: UILabel!
    @IBOutlet private var labelAudioVolume: UILabel!

    private var registeredStreams: Set<IVSStageStream> = []
    private var imageDevice: IVSImageDevice? {
        return registeredStreams.lazy.compactMap { $0.device as? IVSImageDevice }.first
    }
    private var audioDevice: IVSAudioDevice? {
        return registeredStreams.lazy.compactMap { $0.device as? IVSAudioDevice }.first
    }

    func set(participant: StageParticipant) {
        labelParticipantId.text = participant.isLocal ? "You (\(participant.participantId ?? "Disconnected"))" : participant.participantId
        labelPublishState.text = participant.publishState.text
        labelSubscribeState.text = participant.subscribeState.text

        let existingAudioStream = registeredStreams.first { $0.device is IVSAudioDevice }
        let existingImageStream = registeredStreams.first { $0.device is IVSImageDevice }

        registeredStreams = Set(participant.streams)

        let newAudioStream = participant.streams.first { $0.device is IVSAudioDevice }
        let newImageStream = participant.streams.first { $0.device is IVSImageDevice }

        // `isMuted != false` covers the stream not existing, as well as being muted.
        labelVideoMuted.text = "Video Muted: \(newImageStream?.isMuted != false)"
        labelAudioMuted.text = "Audio Muted: \(newAudioStream?.isMuted != false)"

        if existingImageStream !== newImageStream {
            // The image stream has changed
            updatePreview()
        }

        if existingAudioStream !== newAudioStream {
            (existingAudioStream?.device as? IVSAudioDevice)?.setStatsCallback(nil)
            audioDevice?.setStatsCallback( { [weak self] stats in
                self?.labelAudioVolume.text = String(format: "Audio Level: %.0f dB", stats.rms)
            })
            // When the audio stream changes, it will take some time to receive new stats. Reset the value temporarily.
            self.labelAudioVolume.text = "Audio Level: -100 dB"
        }
    }

private func updatePreview() {
    // Remove any old previews from the preview container
    viewPreviewContainer.subviews.forEach { $0.removeFromSuperview() }
    if let imageDevice = self.imageDevice {
        if let preview = try? imageDevice.previewView(with: .fit) {
            viewPreviewContainer.addSubviewMatchFrame(preview)
        }
    }
}

}

extension IVSParticipantPublishState {
    var text: String {
        switch self {
        case .notPublished: return "Not Published"
        case .attemptingPublish: return "Attempting to Publish"
        case .published: return "Published"
        @unknown default: fatalError()
        }
    }
}

extension IVSParticipantSubscribeState {
    var text: String {
        switch self {
        case .notSubscribed: return "Not Subscribed"
        case .attemptingSubscribe: return "Attempting to Subscribe"
        case .subscribed: return "Subscribed"
        @unknown default: fatalError()
        }
    }
}
