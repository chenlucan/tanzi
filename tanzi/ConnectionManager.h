//
//  ConnectionManager.h
//  tanzi
//
//  Created by Lucan Chen on 23/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Connection.h"
#import "SignalingClient.h"

@protocol ConnectionManagerDelegate <NSObject>

-(void)OnConnectionReady:(NSString*)peerid;
-(void)OnNotConnectionReady:(NSString*)peerid;

@end

@interface ConnectionManager : NSObject

@property (nonatomic, weak) id<ConnectionManagerDelegate> delegate;

-(instancetype)initWithSignaling:(SignalingClient *)client;
// triggered by receiving heartbeat, so it's adding Connection which initiates the offer
-(BOOL)AddConnection:(NSString *)otherPeerId
          selfPeerId:(NSString *)selfPeerId
           channelId:(NSString *)channelId;

-(void)OnAnswerICECandidate:(NSDictionary *)msg forPeer:(NSString *)peerid;
-(void)OnAnswerSessionDescription:(NSDictionary *)msg forPeer:(NSString *)peerid;

-(void)SendDict:(NSDictionary *)dict ToPeer:(NSString*)peerId;
-(void)SendFile:(NSData *)fileData ToPeer:(NSString*)peerId;

@end
