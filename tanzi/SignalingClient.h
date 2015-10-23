//
//  SignalingClient.h
//  tanzi
//
//  Created by Lucan Chen on 22/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SignalingClientDelegate <NSObject>

-(void)OnMessage:(NSDictionary*)message;

@end

@interface SignalingClient : NSObject

@property (nonatomic, weak) id <SignalingClientDelegate> delegate;

-(void)publish:(NSDictionary*)message to:(NSString *)channel;

@end
