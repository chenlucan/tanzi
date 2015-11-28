
#import "SecondViewController.h"

#import "AuthManager.h"

@interface SecondViewController ()
@property (weak, nonatomic) IBOutlet UILabel *labelName_;
@property (strong, atomic) NSString *username_;

@end

@implementation SecondViewController

- (void)setUserName:(NSString *)name {
    self.username_ = name;
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        self.labelName_.text = name;
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUserName:self.username_];
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onLogout:(id)sender {
    [[AuthManager getInstance] Logout];
}

@end
