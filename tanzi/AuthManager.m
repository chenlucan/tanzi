//
//  AuthManager.m
//  tanzi
//
//  Created by Lucan Chen on 11/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import "AuthManager.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>
#import <FBSDKLoginKit/FBSDKLoginKit.h>

enum LoginSource {
    LoginSource_None,
    LoginSource_FB,
    LoginSource_Native
};

@interface AuthManager()

@property (nonatomic, strong) NSString *UserId_;
@property (nonatomic) enum LoginSource source_;
@property (atomic, strong) FBSDKLoginManager *fbLoginMgr_;

@end



@implementation AuthManager

static AuthManager *instance;

+(AuthManager*)getInstance {
    @synchronized(self)
    {
        if(instance == nil)
        {
            instance = [AuthManager new];
            instance.source_ = LoginSource_None;
        }
    }
    return instance;
}

-(NSString *)UserId {
    return self.UserId_;
}

-(BOOL) isAuthenticated {
    if ([FBSDKAccessToken currentAccessToken]) {
        self.source_ = LoginSource_FB;
        return YES;
    }
    return  NO;
}

-(void) LoginWithFacebook {
    self.source_ = LoginSource_FB;
    if (!self.fbLoginMgr_) {
        self.fbLoginMgr_ = [[FBSDKLoginManager alloc] init];
    }

    [self.fbLoginMgr_ logInWithReadPermissions:@[@"public_profile"]
                 fromViewController:nil
                            handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        if (error) {
             NSLog(@"Process error");
             [self.delegate authenticationFailed];
         } else if (result.isCancelled) {
             NSLog(@"Cancelled");
             [self.delegate authenticationFailed];
         } else {
             NSLog(@"Logged in");
             if (result.token.userID) {
                 [self.delegate authenticationSuccessWithUserId:result.token.userID WithUsername:result.token.userID];
             }
         }
     }];
}

-(void) LoginWithNative:(NSString *)username WithPassword:(NSString *)password {
    self.source_ = LoginSource_Native;
}

-(void) Logout {
    // so i know how to logout
    assert(self.source_ != LoginSource_None);
    if (!self.fbLoginMgr_) {
        self.fbLoginMgr_ = [[FBSDKLoginManager alloc] init];
        [self.fbLoginMgr_ logOut];
        NSLog(@"Creating FBLoginManager before logging out");
    }

    [self.delegate authenticationFailed];
}

@end
