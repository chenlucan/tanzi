
#import "FirstViewController.h"

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

#import <QBImagePickerController/QBImagePickerController.h>

#import "SignalingClient.h"

@interface FirstViewController () <RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate, RTCDataChannelDelegate, UINavigationControllerDelegate, QBImagePickerControllerDelegate, SignalingClientDelegate>
@property (weak, nonatomic) IBOutlet UIButton *btnConnect;
@property (weak, nonatomic) IBOutlet UILabel *labelStatus;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldEmail;
@property (weak, nonatomic) IBOutlet UIButton *btnUpload;

@property (nonatomic, strong) SignalingClient *signaling_;

@property(nonatomic, strong) NSString *roleId_;
@property(nonatomic, strong) NSString *userId_;
@property(nonatomic, strong) NSString *peerRoleId_;
@property(nonatomic, strong) NSMutableArray *messageQueue;
@property(nonatomic) BOOL offer_answer_done;
@property(nonatomic, strong) RTCPeerConnection *peerConnection;
@property(nonatomic, strong) RTCPeerConnectionFactory *factory;
@property(nonatomic, strong) RTCDataChannel *dataChannel;
@property(nonatomic, strong) QBImagePickerController *pickController;
@property(nonatomic) BOOL channelOpened;

@property(nonatomic, strong) NSMutableData *rc_file_data;
@property(nonatomic, strong) NSMutableString *rc_file_name;
@property(nonatomic) NSUInteger rc_file_size;

@end

@implementation FirstViewController {
}

-(void)setUserId:(NSString *)uid {
    self.userId_ = uid;
    [self initAndConnect];
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    self.signaling_ = [[SignalingClient alloc] init];
    self.signaling_.delegate = self;
    return self;
}

- (void) initAndConnect {
    // Explanation: uid is for account from authentication
    // it could have multi connections under the same id
    // connection id should be different from userid
    // however, since we only have one connection, no connection is used right now
    
    // todo:
    //  - allow multi connections, diff by conneciton id
    //  - userid has the same lifetime of authentication token, not netowrk status
    //  - network status will affect candidates. Should be handled by webrtc candidate managers
    //  - decouple userid, newconnection, newchannel
    NSMutableString *offerer  = [NSMutableString stringWithString:@"com.lucanchen.offerer"];
    NSMutableString *answerer = [NSMutableString stringWithString:@"com.lucanchen.answerer"];
    
    self.roleId_      = offerer;
    self.peerRoleId_  = answerer;
    self.messageQueue = [[NSMutableArray alloc] init];
    self.offer_answer_done = NO;
    self.dataChannel = nil;
    
    [self connectPeer];
    
    NSLog(@"Client started as roleId:%@, userId:%@", self.roleId_, self.userId_);
}

- (void)applicationWillResignActive:(UIApplication *)application {
  // Terminate any calls when we aren't active.
  [self dismissViewControllerAnimated:NO completion:nil];
}
- (IBAction)onConnect:(id)sender {
    NSLog(@"On connect, id:%@", self.userId_);
    if ([self.userId_ length] != 0) {
        [self connectPeer];
    }
}
- (IBAction)onUpload:(id)sender {
    QBImagePickerController *imagePickerController = [QBImagePickerController new];
    imagePickerController.delegate = self;
    imagePickerController.allowsMultipleSelection = YES;
    imagePickerController.prompt = @"Select the photos you want to upload!";
    imagePickerController.showsNumberOfSelectedAssets = YES;
    
    self.pickController = imagePickerController;
    [self presentViewController:self.pickController animated:YES completion:NULL];
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
    NSLog(@"peerConnection addedStream, signalingState[%u], connectionState[%u], iceGatheringState[%u]",
          peerConnection.signalingState,
          peerConnection.iceConnectionState,
          peerConnection.iceGatheringState);
    [peerConnection addStream:stream];
}

// Triggered when a remote peer close a stream.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
         removedStream:(RTCMediaStream *)stream {
    NSLog(@"peerConnection removedStream, signalingState[%u], iceConnectionState[%u], iceGatheringState%u",
          peerConnection.signalingState,
          peerConnection.iceConnectionState,
          peerConnection.iceGatheringState);
}

// Triggered when renegotiation is needed, for example the ICE has restarted.
- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection {
    NSLog(@"peerConnection removedStream, signalingState[%u], iceConnectionState[%u], iceGatheringState%u",
          peerConnection.signalingState,
          peerConnection.iceConnectionState,
          peerConnection.iceGatheringState);
}

// Called any time the ICEConnectionState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
  iceConnectionChanged:(RTCICEConnectionState)newState {
    NSLog(@"peerConnection iceConnectionChanged");
    switch (newState) {
        case RTCICEConnectionNew:
            NSLog(@"peerConnection iceConnectionChanged RTCICEConnectionNew");
            break;
        case RTCICEConnectionChecking:
            NSLog(@"peerConnection iceConnectionChanged RTCICEConnectionChecking");
            break;
        case RTCICEConnectionConnected:
            NSLog(@"peerConnection iceConnectionChanged RTCICEConnectionConnected");
            break;
        case RTCICEConnectionCompleted:
            NSLog(@"peerConnection iceConnectionChanged RTCICEConnectionCompleted");
            break;
        case RTCICEConnectionFailed:
            NSLog(@"peerConnection iceConnectionChanged RTCICEConnectionFailed");
            break;
        case RTCICEConnectionDisconnected:
            NSLog(@"peerConnection iceConnectionChanged RTCICEConnectionDisconnected");
            break;
        case RTCICEConnectionClosed:
            NSLog(@"peerConnection iceConnectionChanged RTCICEConnectionClosed");
            break;
        default:
            break;
    }
}

// Called any time the ICEGatheringState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
   iceGatheringChanged:(RTCICEGatheringState)newState {
    NSLog(@"peerConnection iceGatheringChanged");
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
    NSDictionary* dataDict = @{
        @"userID" : self.roleId_,
        @"candidate": @{
            @"sdpMLineIndex" : [NSNumber numberWithInteger:candidate.sdpMLineIndex],
            @"sdpMid"        : candidate.sdpMid,
            @"candidate"     : candidate.sdp
        }
    };
    NSLog(@"peerConnection gotICECandidate, sdpMid[%@], sdpMLineIndex[%@], candidate[%@]",
          dataDict[@"candidate"][@"sdpMid"],
          dataDict[@"candidate"][@"sdpMLineIndex"],
          dataDict[@"candidate"][@"candidate"]);
    if (!self.offer_answer_done) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.messageQueue addObject:dataDict];
        });
    } else {
        [self.signaling_ publish:dataDict to:self.userId_];
    }
}

// New data channel has been opened.
- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel {
    NSLog(@"peerConnection didOpenDataChannel");
}

#pragma mark - RTCSessionDescriptionDelegate

// Called when creating a session.
- (void)peerConnection:(RTCPeerConnection *)peerConnection didCreateSessionDescription:(RTCSessionDescription *)sdp error:(NSError *)error {
    [peerConnection setLocalDescriptionWithDelegate:self sessionDescription:sdp];

    NSDictionary *json = @{
                           @"type" : sdp.type,
                           @"sdp"  : sdp.description
                         };
    NSDictionary *dataDict = @{
                               @"userID":self.roleId_,
                               @"fullPart":json
                             };
    [self.signaling_ publish:dataDict to:self.userId_];
}

// Called when setting a local or remote description.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didSetSessionDescriptionWithError:(NSError *)error {
}

#pragma mark - SignalingClientDelegate
- (void)OnMessage:(NSDictionary*)message {
    NSDictionary *msg = message;
    if (![msg objectForKey:@"userID"]) {
        NSLog(@"key userID is not present, skip this message");
        return;
    }
    NSString *userID = msg[@"userID"];
    if (![userID  isEqual: self.peerRoleId_]) {
        NSLog(@"Ignoring this message, due to wrong userID: %@", userID);
        return;
    }
    if ([msg objectForKey:@"participant"] && msg[@"participant"]) {
        
    }
    if ([msg objectForKey:@"candidate"]) {
        NSDictionary *cand = msg[@"candidate"];
        
        NSString *mid = cand[@"sdpMid"];
        NSString *sdp = cand[@"candidate"];
        NSNumber *num = cand[@"sdpMLineIndex"];
        NSInteger mLineIndex = [num integerValue];
        NSLog(@"Added ice candidate mid[%@], mLineIndex[%ld], sdp[%@]", mid, mLineIndex, sdp);
        RTCICECandidate *candidate = [[RTCICECandidate alloc] initWithMid:mid index:mLineIndex sdp:sdp];
        [self.peerConnection addICECandidate:candidate];
    }
    if ([msg objectForKey:@"fullPart"]) {
        NSString *sdpStr = msg[@"fullPart"];
        NSError *jsonError;
        NSData *objectData = [sdpStr dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:objectData
                                                             options:NSJSONReadingMutableContainers
                                                               error:&jsonError];
        if (jsonError) {
            NSLog(@"data to dict error, code: %ld", jsonError.code);
        } else {
            NSLog(@"data to dict success, json[type]: %@", json[@"type"]);
            NSLog(@"data to dict success, json[sdp]: %@",  json[@"sdp"]);
        }
        
        RTCSessionDescription *sdp = [[RTCSessionDescription alloc] initWithType:json[@"type"]
                                                                             sdp:json[@"sdp"]];
        [self.peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:sdp];
        self.offer_answer_done = YES;
        
        for (NSDictionary *dataDict in self.messageQueue) {
            [self.signaling_ publish:dataDict to:self.userId_];
        }
        [self.messageQueue removeAllObjects];
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
            self.channelOpened = YES;
            self.btnUpload.enabled = YES;
            [self.btnUpload setTitle:@"Upload" forState:UIControlStateNormal];
            self.labelStatus.alpha = 0.5;
            self.labelStatus.textColor = [UIColor greenColor];
            self.labelStatus.text = @"Connected";
            [self.view setNeedsDisplay];
            break;
        case kRTCDataChannelStateClosing:
            NSLog(@"channelDidChangeState closing");
            break;
        case kRTCDataChannelStateClosed:
            NSLog(@"channelDidChangeState closed");
            self.channelOpened = NO;
            self.btnUpload.enabled = NO;
            [self.btnUpload setTitle:@"Login and Connect" forState:UIControlStateNormal];
            break;
        default:
            break;
    }
}

// Called when a data buffer was successfully received.
- (void)channel:(RTCDataChannel*)channel
didReceiveMessageWithBuffer:(RTCDataBuffer*)buffer{
//    NSString* newStr = [[NSString alloc] initWithData:buffer.data encoding:NSUTF8StringEncoding];
//    NSLog(@"RTCDataChannel_length didReceiveMessageWithBuffer: buffer.data.length: %ld, newStr_length: %ld", buffer.data.length, [newStr length]);
    NSError* error;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:buffer.data
                                                         options:kNilOptions
                                                           error:&error];
    if (error) {
        if (self.rc_file_size && self.rc_file_name) {
            [self.rc_file_data appendData:buffer.data];
            if ([self.rc_file_data length] == self.rc_file_size) {
                // save data
                UIImage *imageToBeSaved = [UIImage imageWithData:self.rc_file_data];
                UIImageWriteToSavedPhotosAlbum(imageToBeSaved, nil, nil, nil);
                NSLog(@"RTCDataChannel didReceiveMessageWithBuffer: saved data to camera roll");

                // then clear
                NSLog(@"RTCDataChannel didReceiveMessageWithBuffer: clear after saving");
                [self.rc_file_data setLength:0];
                self.rc_file_name = [@"" mutableCopy];
                self.rc_file_size = 0;
            } else if ([self.rc_file_data length] > self.rc_file_size) {
                NSLog(@"RTCDataChannel didReceiveMessageWithBuffer: error: received data overflow");
                [self.rc_file_data setLength:0];
                self.rc_file_name = [@"" mutableCopy];
                self.rc_file_size = 0;
            }
            NSLog(@"RTCDataChannel didReceiveMessageWithBuffer, received fileData length: %ld", [self.rc_file_data length]);
            return;
        }
        NSLog(@"RTCDataChannel didReceiveMessageWithBuffer: received data when not suppoed to");
        [self.rc_file_data setLength:0];
        self.rc_file_name = [@"" mutableCopy];
        self.rc_file_size = 0;
    } else {
        if ([json objectForKey:@"type"] && [json[@"type"]  isEqual: @"File"] && [json objectForKey:@"fileName"] && [json objectForKey:@"fileSize"]) {
            self.rc_file_name = json[@"fileName"];
            self.rc_file_size = [json[@"fileSize"] integerValue];
            self.rc_file_data = [[NSMutableData alloc] init];
            [self.rc_file_data setLength:0];
            NSLog(@"RTCDataChannel didReceiveMessageWithBuffer: receive meta data, name: %@, size: %ld", self.rc_file_name, self.rc_file_size);
        } else {
            NSLog(@"RTCDataChannel didReceiveMessageWithBuffer: json object dones not contain correct field: %@", json);
        }
    }
}

#pragma mark - QBImagePickerControllerDelegate
- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didFinishPickingAssets:(NSArray *)assets {
    PHImageManager *imgManager = [PHImageManager defaultManager];
    for (PHAsset *asset in assets) {
        // Do something with the asset
        [imgManager requestImageDataForAsset:asset options:nil resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            if ([info valueForKey:PHImageErrorKey] && info[PHImageErrorKey]) {
                NSLog(@"requestImageDataForAsset PHImageErrorKey");
                return;
            }
            NSLog(@"requestImageDataForAsset %ld", imageData.length);
            NSString *cDateTime = [[asset.creationDate description]substringToIndex:19];
            NSString * cDateTimeNoSpace = [cDateTime stringByReplacingOccurrencesOfString:@" " withString:@"-"];

            [self sendData:imageData name:cDateTimeNoSpace];
        }];
    }
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}
- (void)qb_imagePickerControllerDidCancel:(QBImagePickerController *)imagePickerController {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (BOOL)qb_imagePickerController:(QBImagePickerController *)imagePickerController shouldSelectAsset:(PHAsset *)asset {
    return YES;
}

- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didSelectAsset:(PHAsset *)asset {
    
}
- (void)qb_imagePickerController:(QBImagePickerController *)imagePickerController didDeselectAsset:(PHAsset *)asset {
    
}

# pragma mark - view delegate
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    NSLog(@"touchesBegan:withEvent:");
    [self.view endEditing:YES];
    [super touchesBegan:touches withEvent:event];
}

#pragma mark - Private
- (void) sendData:(NSData *)imgData name:(NSString *)name {
    // max size we could send 66528 bytes
    // 8 bytes  - length - NSUInteger
    // 1 byte   - type - currently only support '0 - File'
    // 19 bytes - name/creationDate
    // (TODO) seqNo?, can we increase the max size?
    // so payload is 66528 - 9 - 19 = 66500
    NSUInteger max = 66500;
    
    NSMutableString * name19 = [name mutableCopy];
    if (name.length > 19) {
        name19 = [[name19 substringToIndex:19] mutableCopy];
    } else if (name.length < 19) {
        [name19 appendString:@"0000000000000000000"];
        name19 = [[name19 substringToIndex:19] mutableCopy];
    }
    
    NSUInteger len = imgData.length;
    NSUInteger loop = len / max;
    if (len % max) {
        loop++;
    }
    for (NSUInteger i = 1; i <= loop; ++i) {
        if (max * i < len) {
            // send max bytes
            NSData *package = [imgData subdataWithRange:NSMakeRange((i-1)*max, max)];
            [self send:package type:0 totalLength:len name:name19];
        } else {
            // last package to send
            NSData *package = [imgData subdataWithRange:NSMakeRange((i-1)*max, len - (i-1)*max)];
            [self send:package type:0 totalLength:len name:name19];
        }
    }
}

- (void) send: (NSData *)payload type: (char)type totalLength: (NSUInteger)totalLength name:(NSString *)name {
    if (name.length != 19) {
        NSLog(@"name length has to be 19!");
        return;
    }
    // data: totalLength|type|name|payload
    // name.length has to be 19, otherwise substring or append '0'
    NSData *lenData = [NSData dataWithBytes:&totalLength length:sizeof(totalLength)];
    NSData *typeData = [NSData dataWithBytes:&type length:sizeof(type)];
    NSData *nameData = [name dataUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableData *payloadMutable = [lenData mutableCopy];
    [payloadMutable appendData:typeData];
    [payloadMutable appendData:nameData];
    [payloadMutable appendData:payload];
    
    RTCDataBuffer *imgBuf = [[RTCDataBuffer alloc] initWithData:payloadMutable isBinary:YES];
    [self.dataChannel sendData:imgBuf];
}

-(void) connectPeer {
    if ([self.userId_ length] == 0) {
        NSLog(@"Could not connect to peer with empty user id.");
        return;
    }
    if (self.peerConnection) {
        [self.dataChannel close];
        [self.peerConnection close];
        
        self.dataChannel = nil;
        self.peerConnection = nil;
    }
    
    self.channelOpened = NO;
    
    self.factory = [[RTCPeerConnectionFactory alloc] init];
    
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
    self.peerConnection = [self.factory peerConnectionWithICEServers:ice_servers constraints:nil delegate:self];
    
    // createDataChannel
    RTCDataChannelInit *chInit = [[RTCDataChannelInit alloc] init];
    chInit.isOrdered = YES;
    chInit.maxRetransmits = 32;
    chInit.protocol = @"sctp";
    self.dataChannel = [self.peerConnection createDataChannelWithLabel:@"sendChannel" config:chInit];
    self.dataChannel.delegate = self;
    [self.peerConnection createOfferWithDelegate:self constraints:nil];
    
    self.pickController = nil;
}
@end
