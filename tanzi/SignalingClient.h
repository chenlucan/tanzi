//
//  SignalingClient.h
//  tanzi
//
//  Created by Lucan Chen on 22/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SignalingClientDelegate <NSObject>

-(void)OnMessage:(NSDictionary*)message fromChannel:(NSString *)channelid;

@end

@interface SignalingClient : NSObject

@property (nonatomic, weak) id <SignalingClientDelegate> delegate;

-(void)setPublicChannel:(NSString *)publicChannel;
-(void)subscribe:(NSString *)channelid;
-(void)publish:(NSDictionary*)message to:(NSString *)channel;
-(void)publishToPublicChannel:(NSDictionary*)message;

@end
