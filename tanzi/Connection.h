//
//  Connection.h
//  tanzi
//
//  Created by Lucan Chen on 26/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import <Foundation/Foundation.h>

#include "SignalingClient.h"

@class Connection;
@class ConnectionDelegate;

@protocol ConnectionDelegate <NSObject>

@required
-(void)OnConnectionOpened:(Connection*)connection;
-(void)OnConnectionClosed:(Connection*)connection;

@end

@interface Connection : NSObject

@property(nonatomic, weak) id <ConnectionDelegate> delegate;

-(instancetype)initWithSignaling:(SignalingClient *)client
                     OtherPeerId:(NSString *)otherPeerid
                      selfPeerId:(NSString *)selfPeerId
                       ChannelId:(NSString *)channelId;
-(NSString *)peerid;
-(BOOL)IsOpen;

-(void)OnAnswerICECandidate:(NSDictionary *)msg;
-(void)OnAnswerSessionDescription:(NSDictionary *)msg;

-(void)SendDict:(NSDictionary *)dict;
-(void)SendData:(NSData *)data;

@end
