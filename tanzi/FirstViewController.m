#import "FirstViewController.h"

#import <QBImagePickerController/QBImagePickerController.h>

#import "ConnectionManager.h"

#import "MsgFormatter.h"

#import "SignalingClient.h"

@interface FirstViewController () < UINavigationControllerDelegate, QBImagePickerControllerDelegate, SignalingClientDelegate>
@property (weak, nonatomic) IBOutlet UIButton *btnConnect;
@property (weak, nonatomic) IBOutlet UILabel *labelStatus;
@property (weak, nonatomic) IBOutlet UITextField *txtFieldEmail;
@property (weak, nonatomic) IBOutlet UIButton *btnUpload;

@property (nonatomic, strong) SignalingClient *signaling_;
@property (nonatomic, strong) ConnectionManager *connections_;

// used as public channel for this account
@property(nonatomic, strong) NSString *userId_;
@property(nonatomic, strong) NSString *selfDeviceId_;

@property(nonatomic, strong) QBImagePickerController *pickController;

@property(nonatomic) BOOL channelOpened;

@property(nonatomic, strong) NSMutableData *rc_file_data;
@property(nonatomic, strong) NSMutableString *rc_file_name;
@property(nonatomic) NSUInteger rc_file_size;

@end

@implementation FirstViewController {
}

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super initWithCoder:decoder];
    if (self) {
        self.signaling_ = [[SignalingClient alloc] init];
        self.signaling_.delegate = self;
        self.connections_ = [[ConnectionManager alloc] initWithSignaling:self.signaling_];
        
        self.selfDeviceId_ = [MsgFormatter ToDeviceId];
    }
    return self;
}

-(void)setUserId:(NSString *)uid {
    self.userId_ = uid;
    // here's the public channel for this account
    [self.signaling_ setPublicChannel:uid];
    [self.signaling_ subscribe:uid];
    NSLog(@"got userid[%@] as public channel", self.userId_);
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
    
    [self connectPeer];
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

// MsgType == 1
-(void)OnHeartbeat:(NSDictionary *)msg fromChannel:(NSString *)channelid {
    if (![self.userId_ isEqualToString:channelid]) {
        NSLog(@"Not supposed to received Heartbeat message from other users, self.userid:%@, channelid:%@", self.userId_, channelid);
        return;
    }
    if (![msg objectForKey:@"MsgType"]) {
        NSLog(@"Error: key[MsgType] is not present");
        return;
    }
    if (![msg objectForKey:@"DeviceId"]) {
        NSLog(@"Error: key[DeviceId] is not present");
        return;
    }
    
    NSString *deviceid = [msg objectForKey:@"DeviceId"];
    
    // (todo) logic to decide when to initiate a connection
    // currently every hb msg will initiate a try to build connection
    [self.connections_ AddConnection:deviceid selfPeerId:self.selfDeviceId_ channelId:channelid];
}

// MsgType == 4
-(void)OnAnswerICECandidate:(NSDictionary *)msg fromChannel:(NSString *)channelid {
    if (![msg objectForKey:@"DeviceId"]) {
        NSLog(@"key DeviceId is not present, skip this message");
        return;
    }
    NSString *deviceId = msg[@"DeviceId"];
    [self.connections_ OnAnswerICECandidate:msg forPeer:deviceId];
}

// MsgType == 5
-(void)OnAnswerSessionDescription:(NSDictionary *)msg fromChannel:(NSString *)channelid {
    if (![msg objectForKey:@"DeviceId"]) {
        NSLog(@"key DeviceId is not present, skip this message");
        return;
    }
    NSString *deviceId = msg[@"DeviceId"];
    //(todo): the same peer may be sending msg through our private channel at the same time as well
    // currently our connections are all offerer. If this msg is an offer from another peer, connection does not know this
    // Right now it can only rely on that msg from this
    [self.connections_ OnAnswerSessionDescription:msg forPeer:deviceId];
}

#pragma mark - SignalingClientDelegate
- (void)OnMessage:(NSDictionary*)message fromChannel:(NSString *)channelid{
    NSDictionary *msg = message;

    if (![msg objectForKey:@"MsgType"]) {
        NSLog(@"key MsgType is not present, wrong message format");
        return;
    }
    
    NSInteger type     = [msg[@"MsgType"] integerValue];
    NSString *receiver = [msg objectForKey:@"ToDeviceId"] ? msg[@"ToDeviceId"] : @"";
    
    if ([receiver length] != 0) {
        if (![receiver isEqual:self.selfDeviceId_]) {
            NSLog(@"Ignoring this message, its destination is [%@], while self deviceid is[%@]", receiver, self.selfDeviceId_);
            return;
        }
    } else {
        if (type != 1) {
            NSLog(@"Wrong message format, key [ToDeviceId] is not present in MsgType[%ld]", type);
            return;
        }
    }
    
    switch (type) {
        case 1:
            // hb
            [self OnHeartbeat:msg fromChannel:channelid];
            break;
        case 2:
            // offer ICE
            // (todo) we don't accpet offer yet
            break;
        case 3:
            // offer sdp
            // (todo) we don't accept offer yet
            break;
        case 4:
            // answer ICE
            [self OnAnswerICECandidate:msg fromChannel:channelid];
            break;
        case 5:
            // answer sdp
            [self OnAnswerSessionDescription:msg fromChannel:channelid];
            break;
        default:
            NSLog(@"Not supported MsgType: %ld, msg:%@", type, msg.description);
            break;
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

//            [self sendData:imageData name:cDateTimeNoSpace];
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
//- (void) sendData:(NSData *)imgData name:(NSString *)name {
//    // max size we could send 66528 bytes
//    // 8 bytes  - length - NSUInteger
//    // 1 byte   - type - currently only support '0 - File'
//    // 19 bytes - name/creationDate
//    // (TODO) seqNo?, can we increase the max size?
//    // so payload is 66528 - 9 - 19 = 66500
//    NSUInteger max = 66500;
//    
//    NSMutableString * name19 = [name mutableCopy];
//    if (name.length > 19) {
//        name19 = [[name19 substringToIndex:19] mutableCopy];
//    } else if (name.length < 19) {
//        [name19 appendString:@"0000000000000000000"];
//        name19 = [[name19 substringToIndex:19] mutableCopy];
//    }
//    
//    NSUInteger len = imgData.length;
//    NSUInteger loop = len / max;
//    if (len % max) {
//        loop++;
//    }
//    for (NSUInteger i = 1; i <= loop; ++i) {
//        if (max * i < len) {
//            // send max bytes
//            NSData *package = [imgData subdataWithRange:NSMakeRange((i-1)*max, max)];
//            [self send:package type:0 totalLength:len name:name19];
//        } else {
//            // last package to send
//            NSData *package = [imgData subdataWithRange:NSMakeRange((i-1)*max, len - (i-1)*max)];
//            [self send:package type:0 totalLength:len name:name19];
//        }
//    }
//}

//- (void) send: (NSData *)payload type: (char)type totalLength: (NSUInteger)totalLength name:(NSString *)name {
//    if (name.length != 19) {
//        NSLog(@"name length has to be 19!");
//        return;
//    }
//    // data: totalLength|type|name|payload
//    // name.length has to be 19, otherwise substring or append '0'
//    NSData *lenData = [NSData dataWithBytes:&totalLength length:sizeof(totalLength)];
//    NSData *typeData = [NSData dataWithBytes:&type length:sizeof(type)];
//    NSData *nameData = [name dataUsingEncoding:NSUTF8StringEncoding];
//    
//    NSMutableData *payloadMutable = [lenData mutableCopy];
//    [payloadMutable appendData:typeData];
//    [payloadMutable appendData:nameData];
//    [payloadMutable appendData:payload];
//    
//    RTCDataBuffer *imgBuf = [[RTCDataBuffer alloc] initWithData:payloadMutable isBinary:YES];
//    [self.dataChannel sendData:imgBuf];
//}

-(void) connectPeer {
    if ([self.userId_ length] == 0) {
        NSLog(@"Could not connect to peer with empty user id.");
        return;
    }
    self.channelOpened = NO;
    self.pickController = nil;
}
@end
