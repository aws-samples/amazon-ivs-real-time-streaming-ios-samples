<a href="https://docs.aws.amazon.com/ivs/"><img align="right" width="128px" src="./ivs-logo.svg"></a>

# Amazon IVS Real-Time Streaming iOS Sample Apps

This repository contains sample apps which demonstrate how to build an iOS app using Amazon IVS Real-Time Streaming.

## More Documentation

+ [Release Notes](https://docs.aws.amazon.com/ivs/latest/userguide/release-notes.html)
+ [iOS SDK Guide](https://docs.aws.amazon.com/ivs/latest/userguide/broadcast-ios.html)

## Setup

1. Clone the repository to your local machine.
1. Open `RealTimeSamples.xcworkspace`. There are 2 applications included in the workspace.

### BasicRealTime

This application demonstrates how to use the Real-Time SDK to create a video conferencing app with a fluid and responsive grid layout for up to 12 participants.

1. Since the simulator doesn't support the use of cameras, there are a couple changes you need to build for device.
    1. Have an active Apple Developer account in order to build to physical devices.
    1. Modify the Bundle Identifier for the `BasicRealTime` target.
    1. Choose a Team for the `BasicRealTime` target.
1. You can now build and run the projects on a device.

### RealTimePlayer

This application demonstrates how to use the Real-Time SDK to create a video player with real time latency. This application can be used in the simulator because it does not require camera access, but in order to use Picture in Picture a real device must be used.

## License
This project is licensed under the MIT-0 License. See the LICENSE file.
