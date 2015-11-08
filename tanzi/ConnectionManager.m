//
//  ConnectionManager.m
//  tanzi
//
//  Created by Lucan Chen on 23/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import "ConnectionManager.h"

#include "Connection.h"

@interface ConnectionManager()

@property(nonatomic, weak)   SignalingClient *signaling_;
@property(nonatomic, strong) NSMutableDictionary<NSString*, Connection*> *connections_;

@end

@implementation ConnectionManager

-(instancetype)initWithSignaling:(SignalingClient *)client {
    self = [super init];
    if (self) {
        self.signaling_ = client;
        self.connections_ = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(BOOL)AddConnection:(NSString *)otherPeerId selfPeerId:(NSString *)selfPeerId channelId:(NSString *)channelId {
//    // remove already closed Connection,
//    // so we don't need trigger remove operation from Connection state change
//    for (NSString *c in self.connections_) {
//        if (![self.connections_[c] IsOpen]) {
//            [self.connections_ removeObjectForKey:c ];
//        }
//    }
    
    if ([self.connections_ objectForKey:otherPeerId]) {
        NSLog(@"Connection with otherPeerId[%@] already exists", otherPeerId);
        return NO;
    }
    // hardcode only accept 1 connection currently
    if ([self.connections_ count] >= 1) {
        NSLog(@"ConnectionManager is already full, could not add more.");
        return NO;
    }
    [self.connections_ setObject:[[Connection alloc] initWithSignaling:self.signaling_
                                                            OtherPeerId:otherPeerId
                                                             selfPeerId:selfPeerId
                                                              ChannelId:channelId]
                          forKey:otherPeerId];
    return YES;
}

-(void)OnAnswerICECandidate:(NSDictionary *)msg forPeer:(NSString *)peerid {
    Connection *conn = [self.connections_ objectForKey:peerid];
    if (!conn) {
        NSLog(@"Connection with PeerId[%@] does not exists", peerid);
        return;
    }
    [conn OnAnswerICECandidate:msg];
}

-(void)OnAnswerSessionDescription:(NSDictionary *)msg forPeer:(NSString *)peerid {
    Connection *conn = [self.connections_ objectForKey:peerid];
    if (!conn) {
        NSLog(@"Connection with PeerId[%@] does not exists", peerid);
        return;
    }
    [conn OnAnswerSessionDescription:msg];
}
@end
