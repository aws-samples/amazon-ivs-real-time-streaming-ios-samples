platform :ios, '14.0'

workspace 'RealTimeSamples'

# All of the following projects consume the AmazonIVSBroadcast framework as clients
abstract_target 'IVSClients' do
    pod 'AmazonIVSBroadcast/Stages', '1.33.0'

    target 'BasicRealTime' do
        project 'BasicRealTime/BasicRealTime.xcodeproj'
    end

    target 'RealTimePlayer' do
        project 'RealTimePlayer/RealTimePlayer.xcodeproj'
    end
end
