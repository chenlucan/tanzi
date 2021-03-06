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

#import <DigitsKit/DigitsKit.h>

enum LoginSource {
    LoginSource_None,
    LoginSource_PhoneNumber,
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
        self.UserId_ = [FBSDKAccessToken currentAccessToken].userID;
        self.source_ = LoginSource_FB;
        return YES;
    }
    return  NO;
}

-(void) CheckAuthentication {
    if (self.source_ == LoginSource_FB && [FBSDKAccessToken currentAccessToken]) {
        self.UserId_ = [FBSDKAccessToken currentAccessToken].userID;
        self.source_ = LoginSource_FB;
        [self.delegate authenticationSuccessWithUserId:[FBSDKAccessToken currentAccessToken].userID];
        [self RequestUsername];
    } else if (self.source_ == LoginSource_PhoneNumber && [[Digits sharedInstance] session]) {
        self.UserId_ = [[Digits sharedInstance] session].userID;
        [self.delegate authenticationSuccessWithUserId:self.UserId_];
    } else {
        [self.delegate authenticationFailed];
    }
}

-(void) LoginWithPhoneNumber {
    self.source_ = LoginSource_PhoneNumber;
    [[Digits sharedInstance] authenticateWithCompletion:^(DGTSession *session, NSError *error) {
        if (session && [session.userID length] > 0) {
            NSLog(@"onPhoneNumberLogin, userid[%@]", session.userID);
            self.UserId_ = session.userID;
            [self.delegate authenticationSuccessWithUserId:self.UserId_];
            [self.delegate authenticationSuccessWithUsername:session.phoneNumber];
        }
    }];
}

-(void) LoginWithFacebook {
    self.source_ = LoginSource_FB;
    if (!self.fbLoginMgr_) {
        self.fbLoginMgr_ = [[FBSDKLoginManager alloc] init];
    }
    [self.fbLoginMgr_ logOut]; // http://stackoverflow.com/questions/29408299/ios-facebook-sdk-4-0-login-error-code-304
    [self.fbLoginMgr_ logInWithReadPermissions:@[@"public_profile"]
                 fromViewController:nil
                            handler:^(FBSDKLoginManagerLoginResult *result, NSError *error) {
        if (error) {
             NSLog(@"Process error: %@", error.description);
             [self.delegate authenticationFailed];
         } else if (result.isCancelled) {
             NSLog(@"Cancelled");
             [self.delegate authenticationFailed];
         } else {
             NSLog(@"Logged in, userID[%@]", result.token.userID);
             if (result.token.userID) {
                 [self.delegate authenticationSuccessWithUserId:result.token.userID];
                 [self RequestUsername];
             }
         }
     }];
}

-(void) RequestUsername {
    // For more complex open graph stories, use `FBSDKShareAPI`
    // with `FBSDKShareOpenGraphContent`
    /* make the API call */
    FBSDKGraphRequest *request = [[FBSDKGraphRequest alloc]
                                  initWithGraphPath:@"me"
                                  parameters:nil
                                  HTTPMethod:@"GET"];
    [request startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection,
                                          id result,
                                          NSError *error) {
        if (result) {
            NSDictionary* r = (NSDictionary*)result;
            if (r && [r objectForKey:@"name"]) {
                NSString *name = r[@"name"];
                if ([name length] > 0) {
                    [self.delegate authenticationSuccessWithUsername:name];
                }
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
    if (self.source_ == LoginSource_FB && !self.fbLoginMgr_) {
        self.fbLoginMgr_ = [[FBSDKLoginManager alloc] init];
        [self.fbLoginMgr_ logOut];
        [FBSDKAccessToken setCurrentAccessToken:nil];
        NSLog(@"Creating FBLoginManager before logging out");
    } else if (self.source_ == LoginSource_PhoneNumber) {
        [[Digits sharedInstance] logOut];
    }

    [self.delegate authenticationFailed];
}

@end
