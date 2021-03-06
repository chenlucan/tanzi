//
//  AppDelegate.m
//  tanzi
//
//  Created by Lucan Chen on 9/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import "AppDelegate.h"
#import "AuthManager.h"
#import "KeychainItemWrapper.h"
#import "FirstViewController.h"
#import "SecondViewController.h"

#import <FBSDKCoreKit/FBSDKCoreKit.h>

#import <Fabric/Fabric.h>
#import <DigitsKit/DigitsKit.h>

@interface AppDelegate () <AuthManagerDelegate>
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[FBSDKApplicationDelegate sharedInstance] application:application
                             didFinishLaunchingWithOptions:launchOptions];
    
    [AuthManager getInstance].delegate = self;
    [[AuthManager getInstance] CheckAuthentication];
    
//    if ([AuthManager getInstance].isAuthenticated) {
//        if (!self.mainWindowHolder_) {
//            self.window.rootViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
//            self.mainWindowHolder_ = self.window.rootViewController;
//        }
//    } else {
//        UIViewController* rootController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"LoginViewController"];
//        UINavigationController* navigation = [[UINavigationController alloc] initWithRootViewController:rootController];
//        self.window.rootViewController = navigation;
//    }
    [Fabric with:@[[Digits class]]];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    return [[FBSDKApplicationDelegate sharedInstance] application:application
                                                          openURL:url
                                                sourceApplication:sourceApplication
                                                       annotation:annotation];
}

#pragma mark - AuthManagerDelegate
- (void)authenticationSuccessWithUserId:(NSString *)userid {
    self.window.rootViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    
    if ([userid length] > 0) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            NSLog(@"user[%@] is authenticated successfully", userid);
            UITabBarController* tbc = (UITabBarController*)self.window.rootViewController;
            for (UIViewController *v in tbc.viewControllers)
            {
                if ([v isKindOfClass:[FirstViewController class]]) {
                    FirstViewController* fv = (FirstViewController *)v;
                    [fv setUserId:userid];
                }
            }
        });
    }
}

- (void)authenticationSuccessWithUsername:(NSString *)username {
    if ([username length] > 0) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            NSLog(@"user name[%@] is authenticated successfully", username);
            if ([self.window.rootViewController isKindOfClass:[UITabBarController class]]) {
                UITabBarController* tbc = (UITabBarController*)self.window.rootViewController;
                for (UIViewController *v in tbc.viewControllers)
                {
                    if ([v isKindOfClass:[SecondViewController class]]) {
                        SecondViewController* sv = (SecondViewController *)v;
                        [sv setUserName:username];
                    }
                }
            }
        });
    }
}

- (void)authenticationFailed {
    self.window.rootViewController = nil;
    
    UIViewController* rootController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"LoginViewController"];
    UINavigationController* navigation = [[UINavigationController alloc] initWithRootViewController:rootController];
    self.window.rootViewController = navigation;
}

@end
