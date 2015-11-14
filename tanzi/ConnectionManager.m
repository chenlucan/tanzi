//
//  ConnectionManager.m
//  tanzi
//
//  Created by Lucan Chen on 23/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import "ConnectionManager.h"

#include "Connection.h"

@interface ConnectionManager() <ConnectionDelegate>
@property(nonatomic, weak)   SignalingClient    *signaling_;
@property(nonatomic, strong) NSMutableDictionary<NSString*, Connection*> *connections_;

@end

@implementation ConnectionManager

-(instancetype)initWithSignaling:(SignalingClient *)client {
    self = [super init];
    if (self) {
        self.signaling_    = client;
        self.connections_  = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(BOOL)AddConnection:(NSString *)otherPeerId
          selfPeerId:(NSString *)selfPeerId
           channelId:(NSString *)channelId {
    // deleting Connection crashes app
    // (todo) find a way to delete closed Connection
    
    if ([self.connections_ objectForKey:otherPeerId]) {
        NSLog(@"Connection with otherPeerId[%@] already exists", otherPeerId);
        return NO;
    }
    // hardcode only accept 1 connection currently
    if ([self.connections_ count] >= 1) {
        NSLog(@"ConnectionManager is already full, could not add more.");
        return NO;
    }
    Connection* conn = [[Connection alloc] initWithSignaling:self.signaling_
                                                 OtherPeerId:otherPeerId
                                                  selfPeerId:selfPeerId
                                                   ChannelId:channelId];
    conn.delegate = self;
    [self.connections_ setObject:conn forKey:otherPeerId];
    
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


-(void)SendDict:(NSDictionary *)dict ToPeer:(NSString*)peerId {
    for (NSString *peerid in self.connections_) {
        [self.connections_[peerid] SendDict:dict];
    }
}

-(void)SendFile:(NSData *)fileData ToPeer:(NSString*)peerId {
    for (NSString *peerid in self.connections_) {
        [self.connections_[peerid] SendData:fileData];
    }
}

#pragma mark - ConnectionDelegate
-(void)OnConnectionOpened:(Connection*)connection {
    [self.delegate OnConnectionReady:[connection peerid]];
}

-(void)OnConnectionClosed:(Connection*)connection {
    [self.delegate OnNotConnectionReady:[connection peerid]];
    
    // deleting Connection crashes app
    // (todo) find a way to delete closed Connection
    
//    dispatch_async(dispatch_get_main_queue(), ^(void) {
//        // its called from Connection
//        // because we need delete this Connection,
//        // we have to enqueue into main queue
//        // otherwise this call will return back to deallocated Connection object
//        [self.connections_ removeObjectForKey:[connection peerid]];
//        NSLog(@"Removed connection with id[%@]", [connection peerid]);
//    });
}
@end
