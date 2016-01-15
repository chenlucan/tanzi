//
//  LoginViewController.m
//  tanzi
//
//  Created by Lucan Chen on 20/10/15.
//  Copyright © 2015 Dynasty. All rights reserved.
//

#import "LoginViewController.h"

#import "AuthManager.h"

@interface LoginViewController ()
@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onPhoneNumberLogin:(id)sender {
    [[AuthManager getInstance] LoginWithPhoneNumber];
}


- (IBAction)onFBLogin:(id)sender {
    [[AuthManager getInstance] LoginWithFacebook];
}

@end
