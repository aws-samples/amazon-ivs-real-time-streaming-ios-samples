//
// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
//

import Foundation
import AmazonIVSBroadcast

struct StageParticipant {
    let isLocal: Bool
    var participantId: String?
    var publishState: IVSParticipantPublishState = .notPublished
    var subscribeState: IVSParticipantSubscribeState = .notSubscribed
    var streams: [IVSStageStream] = []
    var zoomStatus: String = "Zoom: 1.0x"
    var showZoomStatus: Bool = false

    init(isLocal: Bool, participantId: String?) {
        self.isLocal = isLocal
        self.participantId = participantId
    }
}
