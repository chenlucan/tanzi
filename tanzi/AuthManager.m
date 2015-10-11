//
//  AuthManager.m
//  tanzi
//
//  Created by Lucan Chen on 11/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import "AuthManager.h"

@interface AuthManager()

@property (nonatomic, strong) NSString *UserId_;

@end


@implementation AuthManager

static AuthManager *instance;

+(AuthManager*)getInstance {
    @synchronized(self)
    {
        if(instance == nil)
        {
            instance = [AuthManager new];
        }
    }
    return instance;
}

-(NSString *)UserId {
    return self.UserId_;
}

-(BOOL) isAuthenticated {
    return YES;
}

-(void) AuthenticateUser:(NSString *)username WithPassword:(NSString *)password {
    // authenticate & authorise user with server
    // get UserId
    // notify client auth results
    self.UserId_ = username;
    [self.delegate authenticatedUserId:self.UserId WithUsername:self.UserId];
}

@end
