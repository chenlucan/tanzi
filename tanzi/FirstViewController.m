
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

#import <PubNub/PubNub.h>

#import <QBImagePickerController/QBImagePickerController.h>

@interface FirstViewController () <RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate, PNObjectEventListener, RTCDataChannelDelegate, UINavigationControllerDelegate, QBImagePickerControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *btnConnect;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldEmail;
@property (weak, nonatomic) IBOutlet UIButton *btnUpload;

@property(nonatomic, strong) NSString *userID;
@property(nonatomic, strong) NSString *email;
@property(nonatomic, strong) NSString *other_userID;
@property(nonatomic, strong) NSMutableArray *messageQueue;
@property(nonatomic) BOOL offer_answer_done;
@property(nonatomic, strong) RTCPeerConnection *peerConnection;
@property(nonatomic, strong) RTCPeerConnectionFactory *factory;
@property(nonatomic, strong) RTCDataChannel *dataChannel;
@property(nonatomic, strong) QBImagePickerController *pickController;
@property(nonatomic) PubNub *client;
@property(nonatomic) BOOL channelOpened;

@property(nonatomic, strong) NSMutableData *rc_file_data;
@property(nonatomic, strong) NSMutableString *rc_file_name;
@property(nonatomic) NSUInteger rc_file_size;

@end

@implementation FirstViewController {
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    [self initWithId:@"lucan"];
    return self;
}

- (void) initWithId:(NSString *)uid {
    if (self.peerConnection) {
        NSLog(@"already have RTCPeerConnection, return");
        return;
    }
    NSMutableString *offerer  = [NSMutableString stringWithString:@"com.lucanchen.offerer"];
    NSMutableString *answerer = [NSMutableString stringWithString:@"com.lucanchen.answerer"];

    // todo: rename to role
    self.userID       = offerer;
    self.other_userID = answerer;
    // todo: rename to id
    self.email        = @"lucan"; // hardcode for prototype
    self.messageQueue = [[NSMutableArray alloc] init];
    self.offer_answer_done = NO;
    self.dataChannel = nil;
    
    NSLog(@"Client started as role:%@, id:%@", self.userID, self.email);
}

-(void)viewDidAppear:(BOOL)animated {
}
-(void)viewDidLoad {
}

- (void)applicationWillResignActive:(UIApplication *)application {
  // Terminate any calls when we aren't active.
  [self dismissViewControllerAnimated:NO completion:nil];
}
- (IBAction)onConnect:(id)sender {
    if ([self.email length] != 0) {
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
        @"userID" : self.userID,
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
        [self.client publish:dataDict toChannel:self.email withCompletion:^(PNPublishStatus *status) {
            [self processPublishStatus:status];
        }];
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

    NSDictionary *json = @{@"type" : sdp.type,
                           @"sdp"  : sdp.description
                           };
    NSDictionary *dataDict = @{@"userID":self.userID,
                                @"fullPart":json
                                };
    [self.client publish:dataDict toChannel:self.email withCompletion:^(PNPublishStatus *status) {
        [self processPublishStatus:status];
    }];
//    NSLog(@"==============================900 >>>> description, length %ld", sdp.description.length);
//    NSString* sdpPart1 = [sdp.description substringWithRange:NSMakeRange(0, 900)];
//    NSString* sdpPart2 = [sdp.description substringWithRange:NSMakeRange(900, sdp.description.length-900)];
//
//    NSDictionary *dataDict1 = @{
//        @"userID":self.userID,
//        @"firstPart":sdpPart1
//    };
//    NSDictionary *dataDict2 = @{
//        @"userID":self.userID,
//        @"secondPart":sdpPart2
//    };
    
//    NSData *data1 = [NSJSONSerialization dataWithJSONObject:dataDict1
//        options:NSJSONWritingPrettyPrinted
//        error:nil];
//    
//    NSData *data2 = [NSJSONSerialization dataWithJSONObject:dataDict2
//        options:NSJSONWritingPrettyPrinted
//        error:nil];
//
//    NSString *dataStr1 = [[NSString alloc]initWithData:data1
//                                              encoding: NSUTF8StringEncoding];
//    
//    NSString *dataStr2 = [[NSString alloc]initWithData:data2
//                                              encoding: NSUTF8StringEncoding];
//    [self.client publish:dataDict1 toChannel:self.email withCompletion:^(PNPublishStatus *status) {
//        
//    }];
//    [self.client publish:dataDict2 toChannel:self.email withCompletion:^(PNPublishStatus *status) {
//        
//    }];
//    NSLog(@"==========sending two parts offer");
}

// Called when setting a local or remote description.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didSetSessionDescriptionWithError:(NSError *)error {
}

#pragma mark - PNObjectEventListener

/**
 @brief  Notify listener about new message which arrived from one of remote data object's live feed
 on which client subscribed at this moment.
 
 @param client  Reference on \b PubNub client which triggered this callback method call.
 @param message Reference on \b PNResult instance which store message information in \c data
 property.
 
 @since 4.0
 */
- (void)client:(PubNub *)client didReceiveMessage:(PNMessageResult *)message {
    NSDictionary *msg = message.data.message;
    if (![msg objectForKey:@"userID"]) {
        NSLog(@"key userID is not present, skip this message");
        return;
    }
    NSString *userID = msg[@"userID"];
    if (![userID  isEqual: self.other_userID]) {
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
            NSLog(@"Sending each icecandidate");
            [self.client publish:dataDict toChannel:self.email withCompletion:^(PNPublishStatus *status) {
                [self processPublishStatus:status];
            }];
        }
        [self.messageQueue removeAllObjects];
    }
    
    // Handle new message stored in message.data.message
    if (message.data.actualChannel) {
        
        // Message has been received on channel group stored in
        // message.data.subscribedChannel
    }
    else {
        
        // Message has been received on channel stored in
        // message.data.subscribedChannel
    }
}

/**
 @brief  Notify listener about new presence events which arrived from one of remote data object's
 presence live feed on which client subscribed at this moment.
 
 @param client Reference on \b PubNub client which triggered this callback method call.
 @param event  Reference on \b PNResult instance which store presence event information in
 \c data property.
 
 @since 4.0
 */
- (void)client:(PubNub *)client didReceivePresenceEvent:(PNPresenceEventResult *)event {
    NSLog(@"PubNub didReceivePresenceEvent: %@", event.data.presenceEvent);
    // Handle presence event event.data.presenceEvent (one of: join, leave, timeout,
    // state-change).
    if (event.data.actualChannel) {
        
        // Presence event has been received on channel group stored in
        // event.data.subscribedChannel
    }
    else {
        
        // Presence event has been received on channel stored in
        // event.data.subscribedChannel
    }
}


///------------------------------------------------
/// @name Status change handler.
///------------------------------------------------

/**
 @brief      Notify listener about subscription state changes.
 @discussion This callback can fire when client tried to subscribe on channels for which it doesn't
 have access rights or when network went down and client unexpectedly disconnected.
 
 @param client Reference on \b PubNub client which triggered this callback method call.
 @param status  Reference on \b PNStatus instance which store subscriber state information.
 
 @since 4.0
 */
- (void)client:(PubNub *)client didReceiveStatus:(PNSubscribeStatus *)status {
    NSLog(@"PubNub didReceiveStatus");
    
    if (status.category == PNUnexpectedDisconnectCategory) {
        // This event happens when radio / connectivity is lost
    }
    
    else if (status.category == PNConnectedCategory) {
        
        // Connect event. You can do stuff like publish, and know you'll get it.
        // Or just use the connected event to confirm you are subscribed for
        // UI / internal notifications, etc
        
        [self.client publish:@"Hello from the PubNub Objective-C SDK" toChannel:@"my_channel"
              withCompletion:^(PNPublishStatus *status) {
                  
                  // Check whether request successfully completed or not.
                  if (!status.isError) {
                      
                      // Message successfully published to specified channel.
                  }
                  // Request processing failed.
                  else {
                      
                      // Handle message publish error. Check 'category' property to find out possible issue
                      // because of which request did fail.
                      //
                      // Request can be resent using: [status retry];
                  }
              }];
    }
    else if (status.category == PNReconnectedCategory) {
        
        // Happens as part of our regular operation. This event happens when
        // radio / connectivity is lost, then regained.
    }
    else if (status.category == PNDecryptionErrorCategory) {
        
        // Handle messsage decryption error. Probably client configured to
        // encrypt messages and on live data feed it received plain text.
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
- (void)showAlertWithMessage:(NSString*)message {
  UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:nil
                                                      message:message
                                                     delegate:nil
                                            cancelButtonTitle:@"OK"
                                            otherButtonTitles:nil];
  [alertView show];
}

- (void)processPublishStatus:(PNPublishStatus *)status {
    switch(status.category) {
        case PNUnknownCategory:
            break;
        case PNAcknowledgmentCategory:
            break;
        case PNAccessDeniedCategory:
            break;
        case PNTimeoutCategory:
            break;
        case PNNetworkIssuesCategory:
            break;
        case PNConnectedCategory:
            break;
        case PNReconnectedCategory:
            break;
        case PNDisconnectedCategory:
            break;
        case PNUnexpectedDisconnectCategory:
            break;
        case PNCancelledCategory:
            break;
        case PNBadRequestCategory:
            break;
        case PNMalformedResponseCategory:
            break;
        case PNDecryptionErrorCategory:
            break;
        case PNTLSConnectionFailedCategory:
            break;
        case PNTLSUntrustedCertificateCategory:
            break;
    }
}

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
    if ([self.email length] == 0) {
        NSLog(@"Email address is empty. Could not connect to peer.");
        return;
    }
    if (self.peerConnection) {
        [self.dataChannel close];
        [self.peerConnection close];
        
        self.dataChannel = nil;
        self.peerConnection = nil;
    }
    PNConfiguration *configuration = [PNConfiguration configurationWithPublishKey:@"pub-c-540d3bfa-dd7a-4520-a9e4-907370d2ce37"
                                                                     subscribeKey:@"sub-c-3af2bc02-2b93-11e5-9bdb-0619f8945a4f"];
    self.client = [PubNub clientWithConfiguration:configuration];
    [self.client addListener:self];
    [self.client subscribeToChannels:@[self.email] withPresence:YES];
    
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
