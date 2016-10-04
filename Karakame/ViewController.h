//
//  ViewController.h
//  Karakame
//
//  Created by Douwe Osinga on 9/27/16.
//  Copyright © 2016 Douwe Osinga. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@class CameraSessionView;

@interface ViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>


- (IBAction)unwindToList:(UIStoryboardSegue *)segue;

@end

