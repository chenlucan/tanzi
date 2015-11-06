1. Since we're using WebRTC, every client should be able to accept and initiate offer
2. msg definition:

msg HeartBeat {
"MsgType": 1,
"DeviceId": <>
}

msg OfferICECandidate {
    "MsgType": 2,
    "DeviceId": <>
    "ToDeviceId": <>
    "ICECandidate": {
        "sdpMLineIndex": 0,
        "sdpMid":
        "candidate":
    }
}

msg OfferSessionDescription {
    "MsgType": 3,
    "DeviceId": <>
    "ToDeviceId": <>
    "SessionDescription": {
        "type":
        "sdp":
    }
}

msg AnswerICECandidate {
    "MsgType": 4,
    "DeviceId": <>
    "ToDeviceId": <>
    "ICECandidate": {
        "sdpMLineIndex": 0,
        "sdpMid":
        "candidate":
    }
}

msg AnswerSessionDescription {
    "MsgType": 5,
    "DeviceId": <>
    "ToDeviceId": <>
    "SessionDescription": {
        "type":
        "sdp":
    }
}

Enum HwType {
None,
iphone,
Aphone,
Wphne,
Mac,
PC,
Sensor,
AddOn1,
AddOn2,
AddOn3,
AddOn4
}

Enum UseType {
None,
Phone,
Tablet,
Laptop,
Desktop,
AddOn1,
AddOn2,
AddOn3,
AddOn4

}

Enum os {
None,
Ios,
Android,
MacOx,
Windows,
Linux,
AddOn1,
AddOn2,
AddOn3,
AddOn4

}