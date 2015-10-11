//
//  AuthManager.h
//  tanzi
//
//  Created by Lucan Chen on 11/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AuthManager : NSObject

+(AuthManager*)getInstance;

-(NSString *) UserId;
-(BOOL) isAuthenticated;
-(void) AuthenticateUser:(NSString *)username WithPassword:(NSString *)password;

@end
