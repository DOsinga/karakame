//
//  SettingsViewController.h
//  Karakame
//
//  Created by Douwe Osinga on 9/30/16.
//  Copyright © 2016 Douwe Osinga. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UITextField *secondsField;
@property (weak, nonatomic) IBOutlet UITextField *numberOfPictures;
@property (weak, nonatomic) IBOutlet UISwitch *detectObjectsSwitch;
@end
