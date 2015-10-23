//
//  SignalingClient.m
//  tanzi
//
//  Created by Lucan Chen on 22/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import "SignalingClient.h"

#import <PubNub/PubNub.h>

@interface SignalingClient() <PNObjectEventListener>

@property(nonatomic) PubNub *client_;

@end

@implementation SignalingClient

-(instancetype)init {
    self = [super init];
    if (self) {
        PNConfiguration *configuration = [PNConfiguration configurationWithPublishKey:@"pub-c-540d3bfa-dd7a-4520-a9e4-907370d2ce37"
                                                                         subscribeKey:@"sub-c-3af2bc02-2b93-11e5-9bdb-0619f8945a4f"];
        self.client_ = [PubNub clientWithConfiguration:configuration];
        [self.client_ addListener:self];
        [self.client_ subscribeToChannels:@[@"public channel"] withPresence:YES];
    }
    return self;
}

- (void)publish:(NSDictionary*)message to:(NSString *)channel {
    [self.client_ publish:message toChannel:channel withCompletion:^(PNPublishStatus *status) {
        [self processPublishStatus:status];
    }];
}

#pragma mark - PNObjectEventListener
- (void)client:(PubNub *)client didReceiveMessage:(PNMessageResult *)message {
    
}

- (void)client:(PubNub *)client didReceivePresenceEvent:(PNPresenceEventResult *)event {
    
}

- (void)client:(PubNub *)client didReceiveStatus:(PNSubscribeStatus *)status {
    
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

@end
