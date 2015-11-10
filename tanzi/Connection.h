//
//  Connection.h
//  tanzi
//
//  Created by Lucan Chen on 26/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SignalingClient.h"



@protocol ConnectionDelegate

-(void)OnConnectionOpened:(NSString *)connection;
-(void)OnConnectionClosed:(NSString *)connection;

@end

@interface Connection : NSObject

@property (nonatomic, weak) id <ConnectionDelegate> delegate;

-(instancetype)initWithSignaling:(SignalingClient *)client
                     OtherPeerId:(NSString *)otherPeerid
                      selfPeerId:(NSString *)selfPeerId
                       ChannelId:(NSString *)channelId
                        delegate:(ConnectionDelegate *)delegate;

-(NSString *)peerid;
-(BOOL)IsOpen;

-(void)OnAnswerICECandidate:(NSDictionary *)msg;
-(void)OnAnswerSessionDescription:(NSDictionary *)msg;

@end
