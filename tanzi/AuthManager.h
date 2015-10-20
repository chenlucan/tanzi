//
//  AuthManager.h
//  tanzi
//
//  Created by Lucan Chen on 11/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AuthManagerDelegate <NSObject>
- (void)authenticationSuccessWithUserId:(NSString *)userid WithUsername:(NSString *)username;
- (void)authenticationFailed;
@end


@interface AuthManager : NSObject

@property (nonatomic, weak) id <AuthManagerDelegate> delegate;

+(AuthManager*)getInstance;

-(NSString *) UserId;
-(BOOL) isAuthenticated;
-(void) LoginWithFacebook;
-(void) LoginWithNative:(NSString *)username WithPassword:(NSString *)password;
-(void) Logout;

@end
