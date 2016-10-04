//
//  SettingsViewController.m
//  Karakame
//
//  Created by Douwe Osinga on 9/30/16.
//  Copyright © 2016 Douwe Osinga. All rights reserved.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.secondsField.text = [NSString stringWithFormat:@"%1.1f", [defaults floatForKey:@"numSeconds"]];
    self.numberOfPictures.text = [NSString stringWithFormat:@"%d", [defaults integerForKey:@"numPictures"]];
    self.detectObjectsSwitch.on = [defaults boolForKey:@"detect"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
