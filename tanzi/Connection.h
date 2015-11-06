//
//  Connection.h
//  tanzi
//
//  Created by Lucan Chen on 26/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "SignalingClient.h"

@interface Connection : NSObject

-(instancetype)initWithSignaling:(SignalingClient *)client
                     OtherPeerId:(NSString *)otherPeerid
                      selfPeerId:(NSString *)selfPeerId
                       ChannelId:(NSString *)channelId;
-(NSString *)peerid;
-(BOOL)IsOpen;

-(void)OnAnswerICECandidate:(NSDictionary *)msg;
-(void)OnAnswerSessionDescription:(NSDictionary *)msg;

@end
