//
//  Connection.m
//  tanzi
//
//  Created by Lucan Chen on 26/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import "Connection.h"

#include "MsgFormatter.h"

#import <WebRTC/RTCDataChannel.h>
#import <WebRTC/RTCICECandidate.h>
#import <WebRTC/RTCICEServer.h>
#import <WebRTC/RTCMediaConstraints.h>
#import <WebRTC/RTCPair.h>
#import <WebRTC/RTCPeerConnection.h>
#import <WebRTC/RTCPeerConnectionDelegate.h>
#import <WebRTC/RTCPeerConnectionFactory.h>
#import <WebRTC/RTCSessionDescription.h>
#import <WebRTC/RTCSessionDescriptionDelegate.h>

@interface Connection() <RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate, RTCDataChannelDelegate>

@property(nonatomic, weak)   SignalingClient *signaling_;
@property(nonatomic, strong) NSString *otherPeerId_;
@property(nonatomic, strong) NSString *selfPeerId_;
@property(nonatomic, strong) NSString *channelId_;

@property(nonatomic, strong) RTCPeerConnectionFactory *factory_;
@property(nonatomic, strong) RTCPeerConnection *peerConnection_;
@property(nonatomic, strong) RTCDataChannel *dataChannel_;

@property(nonatomic) BOOL channelIsOpen_;

//@property(nonatomic, strong) NSMutableArray *messageQueue;
//@property(nonatomic)         BOOL            offer_answer_done_;

@end

@implementation Connection
-(instancetype)initWithSignaling:(SignalingClient *)client
                     OtherPeerId:(NSString *)otherPeerId
                      selfPeerId:(NSString *)selfPeerId
                       ChannelId:(NSString *)channelId {
    self = [super init];
    if (self) {
        self.signaling_   = client;
        self.otherPeerId_ = otherPeerId;
        self.selfPeerId_  = selfPeerId;
        self.channelId_   = channelId;

        self.factory_ = [[RTCPeerConnectionFactory alloc] init];
        // valid STUN/TURN servers.
        // NSURL *url2 = [NSURL URLWithString:@"turn:turn.bistri.com:80"];
        // NSURL *url3 = [NSURL URLWithString:@"turn:turn.anyfirewall.com:443?transport=tcp"];
        // NSURL *url4 = [NSURL URLWithString:@"stun:stun.anyfirewall.com:3478"];
        // RTCICEServer *server2 = [[RTCICEServer alloc] initWithURI:url2 username:@"homeo" password:@"homeo"];
        // RTCICEServer *server3 = [[RTCICEServer alloc] initWithURI:url3 username:@"webrtc" password:@"webrtc"];
        // RTCICEServer *server4 = [[RTCICEServer alloc] initWithURI:url4 username:@"" password:@""];
        NSURL *url1 = [NSURL URLWithString:@"stun:stun.l.google.com:19302"];
        RTCICEServer *server1 = [[RTCICEServer alloc] initWithURI:url1 username:@"" password:@""];
        NSArray *ice_servers = @[server1];
        self.peerConnection_ = [self.factory_ peerConnectionWithICEServers:ice_servers constraints:nil delegate:self];
        
        // createDataChannel
        RTCDataChannelInit *chInit = [[RTCDataChannelInit alloc] init];
        chInit.isOrdered = YES;
        chInit.maxRetransmits = 32;
        chInit.protocol = @"sctp";
        self.dataChannel_ = [self.peerConnection_ createDataChannelWithLabel:self.otherPeerId_ config:chInit];
        self.dataChannel_.delegate = self;
        
        [self.peerConnection_ createOfferWithDelegate:self constraints:nil];
        
        self.channelIsOpen_ = NO;
//        self.messageQueue = [[NSMutableArray alloc] init];
//        self.offer_answer_done_ = NO;
    }
    return self;
}

-(void)dealloc {
    [self.dataChannel_ close];
    [self.peerConnection_ close];
    NSLog(@"deallocated id[%@]", self.otherPeerId_);
}

-(NSString *)peerid {
    return self.otherPeerId_;
}

-(BOOL)IsOpen {
    return self.channelIsOpen_;
}

-(void)OnAnswerICECandidate:(NSDictionary *)msg {
    if (![msg objectForKey:@"MsgType"]) {
        NSLog(@"key MsgType is not present, skip this message");
        return;
    }
    
    NSInteger msgType = [[msg objectForKey:@"MsgType"] integerValue];
    if (msgType != 4) {
        NSLog(@"Wrong MsgType[%ld] received", msgType);
        return;
    }
    
    if (![msg objectForKey:@"DeviceId"]) {
        NSLog(@"key DeviceId is not present, skip this message");
        return;
    }
    
    NSString *deviceId = msg[@"DeviceId"];
    
    if (![deviceId isEqual: self.otherPeerId_]) {
        NSLog(@"Ignoring this message, due to wrong DeviceId: %@", deviceId);
        return;
    }
    
    if ([msg objectForKey:@"ICECandidate"]) {
        NSDictionary *cand = msg[@"ICECandidate"];
        
        NSString *mid = cand[@"sdpMid"];
        NSString *sdp = cand[@"candidate"];
        NSNumber *num = cand[@"sdpMLineIndex"];
        NSInteger mLineIndex = [num integerValue];
        NSLog(@"Added ice candidate mid[%@], mLineIndex[%ld], sdp[%@]", mid, mLineIndex, sdp);
        RTCICECandidate *candidate = [[RTCICECandidate alloc] initWithMid:mid index:mLineIndex sdp:sdp];
        [self.peerConnection_ addICECandidate:candidate];
    }
}

-(void)OnAnswerSessionDescription:(NSDictionary *)msg {
    if (![msg objectForKey:@"MsgType"]) {
        NSLog(@"key MsgType is not present, skip this message");
        return;
    }
    
    NSInteger msgType = [[msg objectForKey:@"MsgType"] integerValue];
    if (msgType != 5) {
        NSLog(@"Wrong MsgType[%ld] received", msgType);
        return;
    }
    
    if (![msg objectForKey:@"DeviceId"]) {
        NSLog(@"key DeviceId is not present, skip this message");
        return;
    }
    
    NSString *deviceId = msg[@"DeviceId"];
    if (![deviceId isEqual: self.otherPeerId_]) {
        NSLog(@"Ignoring this message, due to wrong DeviceId: %@", deviceId);
        return;
    }
    
    if ([msg objectForKey:@"SessionDescription"]) {
        NSString *sdpStr = msg[@"SessionDescription"];
        NSError *jsonError;
        NSData *sdpData  = [sdpStr dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *sdpJson = [NSJSONSerialization JSONObjectWithData:sdpData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&jsonError];
        if (jsonError) {
            NSLog(@"data to dict error, code: %ld", jsonError.code);
            return;
        } else {
            NSLog(@"data to dict success, json[type]: %@", sdpJson[@"type"]);
            NSLog(@"data to dict success, json[sdp]: %@",  sdpJson[@"sdp"]);
        }
        
        RTCSessionDescription *sdp = [[RTCSessionDescription alloc] initWithType:sdpJson[@"type"]
                                                                             sdp:sdpJson[@"sdp"]];
        [self.peerConnection_ setRemoteDescriptionWithDelegate:self sessionDescription:sdp];
        
        
        
//        self.offer_answer_done_ = YES;
//        for (NSDictionary *data in self.messageQueue) {
//            [self.signaling_ publish:data to:self.channelId_];
//        }
//        [self.messageQueue removeAllObjects];
    }
}


-(void)SendDict:(NSDictionary *)dict {
    NSError *error;
    NSData *dictData2 = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    
    RTCDataBuffer * buffer3 = [[RTCDataBuffer alloc] initWithData:dictData2 isBinary:NO];
    [self.dataChannel_ sendData:buffer3];
}

-(void)SendData:(NSData *)data {
    RTCDataBuffer * buffer = [[RTCDataBuffer alloc] initWithData:data isBinary:YES];
    [self.dataChannel_ sendData:buffer];
}

#pragma mark - RTCPeerConnectionDelegate
// Triggered when the SignalingState changed.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
 signalingStateChanged:(RTCSignalingState)stateChanged {
    NSLog(@"peerConnection signalingStateChanged beginning");
    switch (stateChanged) {
        case RTCSignalingStable:
            NSLog(@"peerConnection signalingStateChanged stable");
            break;
        case RTCSignalingHaveLocalOffer:
            NSLog(@"peerConnection signalingStateChanged HavelLocalOffer");
            break;
        case RTCSignalingHaveLocalPrAnswer:
            NSLog(@"peerConnection signalingStateChanged HavelLocalPrAnswer");
            break;
        case RTCSignalingHaveRemoteOffer:
            NSLog(@"peerConnection signalingStateChanged HaveRemoteOffer");
            break;
        case RTCSignalingHaveRemotePrAnswer:
            NSLog(@"peerConnection signalingStateChanged HaveRemotePrAnswer");
            break;
        case RTCSignalingClosed:
            NSLog(@"peerConnection signalingStateChanged Closed");
            break;
        default:
            break;
    }
}

// Triggered when media is received on a new stream from remote peer.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
           addedStream:(RTCMediaStream *)stream {
//    https://tech.appear.in/2015/05/25/Getting-started-with-WebRTC-on-iOS/
    
//    // Create a new render view with a size of your choice
//    RTCEAGLVideoView *renderView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(100, 100)];
//    [stream.videoTracks.lastObject addRenderer:self.renderView];
//    
//    // RTCEAGLVideoView is a subclass of UIView, so renderView
//    // can be inserted into your view hierarchy where it suits your application.
}

// Triggered when a remote peer close a stream.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
         removedStream:(RTCMediaStream *)stream {}

// Triggered when renegotiation is needed, for example the ICE has restarted.
- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection {}

// Called any time the ICEConnectionState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
  iceConnectionChanged:(RTCICEConnectionState)newState {
    NSLog(@"peerConnection iceConnectionChanged");
    switch (newState) {
        case RTCICEConnectionNew:
            NSLog(@"peerConnection iceConnectionChanged RTCICEConnectionNew");
            // in progress of finalizing connection
            // don't do anything, just return;
            break;
        case RTCICEConnectionChecking:
            NSLog(@"peerConnection iceConnectionChanged RTCICEConnectionChecking");
            // in progress of finalizing connection
            // don't do anything, just return;
            break;
        case RTCICEConnectionConnected:
            NSLog(@"peerConnection iceConnectionChanged RTCICEConnectionConnected");
            // in progress of finalizing connection
            // trying to find the best connection
            [self.delegate OnConnectionOpened:self];
            break;
        case RTCICEConnectionCompleted:
            NSLog(@"peerConnection iceConnectionChanged RTCICEConnectionCompleted");
            [self.delegate OnConnectionOpened:self];
            break;
        case RTCICEConnectionFailed:
            NSLog(@"peerConnection iceConnectionChanged RTCICEConnectionFailed");
            // failed to connect
            [self.delegate OnConnectionClosed:self];
            break;
        case RTCICEConnectionDisconnected:
            NSLog(@"peerConnection iceConnectionChanged RTCICEConnectionDisconnected");
            [self.delegate OnConnectionClosed:self];
            break;
        case RTCICEConnectionClosed:
            NSLog(@"peerConnection iceConnectionChanged RTCICEConnectionClosed");
            [self.delegate OnConnectionClosed:self];
            break;
        default:
            break;
    }
    
}

// Called any time the ICEGatheringState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
   iceGatheringChanged:(RTCICEGatheringState)newState {
    switch (newState) {
        case RTCICEGatheringNew:
            NSLog(@"peerConnection iceGatheringChanged RTCICEGatheringNew");
            break;
        case RTCICEGatheringGathering:
            NSLog(@"peerConnection iceGatheringChanged RTCICEGatheringGathering");
            break;
        case RTCICEGatheringComplete:
            NSLog(@"peerConnection iceGatheringChanged RTCICEGatheringComplete");
            break;
        default:
            break;
    }
}

// New Ice candidate have been found.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
       gotICECandidate:(RTCICECandidate *)candidate {
    NSDictionary *data = [MsgFormatter ToOfferICECandidate:self.selfPeerId_ ToDeviceId:self.otherPeerId_ index:candidate.sdpMLineIndex mid:candidate.sdpMid candidate:candidate.sdp];
    [self.signaling_ publish:data to:self.channelId_];
//    NSLog(@"peerConnection gotICECandidate, sdpMid[%@], sdpMLineIndex[%@], candidate[%@]",
//          data[@"candidate"][@"sdpMid"],
//          data[@"candidate"][@"sdpMLineIndex"],
//          data[@"candidate"][@"candidate"]);
//    if (!self.offer_answer_done_) {
//        [self.messageQueue addObject:data];
//    } else {
//        [self.signaling_ publish:data to:self.channelId_];
//    }
}

// New data channel has been opened.
- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel {
    NSLog(@"peerConnection didOpenDataChannel 1");
    if (dataChannel == self.dataChannel_) {
        self.channelIsOpen_ = YES;
        NSLog(@"peerConnection didOpenDataChannel 2");
    }
}

#pragma mark - RTCSessionDescriptionDelegate
// Called when creating a session.
- (void)peerConnection:(RTCPeerConnection *)peerConnection didCreateSessionDescription:(RTCSessionDescription *)sdp error:(NSError *)error {
    [peerConnection setLocalDescriptionWithDelegate:self sessionDescription:sdp];
//    NSDictionary *data = [MsgFormatter ToOfferSessionDescription:self.selfPeerId_ ToDeviceId:self.otherPeerId_ type:sdp.type sdp:sdp.description];
//    [self.signaling_ publish:data to:self.channelId_];
}

// Called when setting a local or remote description.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didSetSessionDescriptionWithError:(NSError *)error {
    // simplied version - ios client does not accept offer, only create offer
    // https://tech.appear.in/2015/05/25/Getting-started-with-WebRTC-on-iOS/
    
    // If we have a local offer OR answer we should signal it
    if (peerConnection.signalingState == RTCSignalingHaveLocalOffer || peerConnection.signalingState == RTCSignalingHaveLocalPrAnswer) {
        // Send offer/answer through the signaling channel of our application
        NSString *type = self.peerConnection_.localDescription.type;
        NSString *sdp  = self.peerConnection_.localDescription.description;
        
        [self.signaling_ publish:[MsgFormatter ToOfferSessionDescription:self.selfPeerId_ ToDeviceId:self.otherPeerId_ type:type sdp:sdp] to:self.channelId_];
    }
}

#pragma mark - RTCDataChannelDelegate
// Called when the data channel state has changed.
- (void)channelDidChangeState:(RTCDataChannel*)channel {
    NSLog(@"RTCDataChannel channelDidChangeState beginning");
    switch (channel.state) {
        case kRTCDataChannelStateConnecting:
            NSLog(@"channelDidChangeState connecting");
            break;
        case kRTCDataChannelStateOpen:
            NSLog(@"channelDidChangeState open");
            break;
        case kRTCDataChannelStateClosing:
            NSLog(@"channelDidChangeState closing");
            break;
        case kRTCDataChannelStateClosed:
            if (self.dataChannel_ == channel) {
                self.channelIsOpen_ = NO;
                NSLog(@"channelDidChangeState closed");
            }
            break;
        default:
            break;
    }
}

// Called when a data buffer was successfully received.
- (void)channel:(RTCDataChannel*)channel
didReceiveMessageWithBuffer:(RTCDataBuffer*)buffer{}

@end
