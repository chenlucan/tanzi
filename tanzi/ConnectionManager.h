//
//  ConnectionManager.h
//  tanzi
//
//  Created by Lucan Chen on 23/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SignalingClient.h"

@interface ConnectionManager : NSObject

-(instancetype)initWithSignaling:(SignalingClient *)client;
// triggered by receiving heartbeat, so it's adding Connection which initiates the offer
-(BOOL)AddConnection:(NSString *)otherPeerId
          selfPeerId:(NSString *)selfPeerId
           channelId:(NSString *)channelId;
-(void)OnAnswerICECandidate:(NSDictionary *)msg forPeer:(NSString *)peerid;
-(void)OnAnswerSessionDescription:(NSDictionary *)msg forPeer:(NSString *)peerid;

@end
