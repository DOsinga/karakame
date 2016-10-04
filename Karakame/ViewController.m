//
//  ViewController.m
//  Karakame
//
//  Created by Douwe Osinga on 9/27/16.
//  Copyright © 2016 Douwe Osinga. All rights reserved.
//

#import "ViewController.h"
#import "OpenCVBitmap.h"
#import "SettingsViewController.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, strong) NSMutableArray *capturedImages;
@property(nonatomic, strong) NSMutableArray *faceRectangles;

@property(nonatomic, strong) AVCaptureSession *session;
@property(nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property(nonatomic, strong) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property (weak, nonatomic) IBOutlet UIButton *shutterButton;

@property(nonatomic, strong) UIView *cameraUiView;
@property(nonatomic) int numberOfPictures;
@property(nonatomic) float numberOfSeconds;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.spinner.hidden = TRUE;
    self.capturedImages = [NSMutableArray new];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];

    self.faceRectangles = [NSMutableArray new];
    [self setupCaptureSession];
    [[UIApplication sharedApplication] setIdleTimerDisabled: TRUE];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults registerDefaults:@{
            @"numPictures": @(5),
            @"numSeconds": @(3.0),
            @"detect": @(TRUE)
    }];
    self.numberOfPictures = [defaults integerForKey:@"numPictures"];
    [self updateCounter];
}

- (AVCaptureVideoOrientation)orientationFromDevice {
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
        case UIDeviceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
        case UIDeviceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeRight;
        case UIDeviceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeLeft;
        default:
            return AVCaptureVideoOrientationPortrait;
    }
}

// Create and configure a capture session and start it running
- (void)setupCaptureSession {
    NSError *error = nil;

    // Create the session
    self.session = [[AVCaptureSession alloc] init];

    // Find a suitable AVCaptureDevice
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device
                                                                        error:&error];
    [self.session addInput:input];

    self.session.sessionPreset = AVCaptureSessionPreset1920x1080;

    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    [self.stillImageOutput setOutputSettings:outputSettings];
    [self.session addOutput:self.stillImageOutput];

    // Create a VideoDataOutput and add it to the session
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [self.session addOutput:output];

    AVCaptureConnection *conn = [output connectionWithMediaType:AVMediaTypeVideo];
    [conn setVideoOrientation:[self orientationFromDevice]];

    // Specify the pixel format
    output.videoSettings = @{(id) kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};

    if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        [device lockForConfiguration:nil];
        [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        [device unlockForConfiguration];
    }

    NSLog(@"Adding video preview layer");
    self.captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    [self.captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];


    //----- DISPLAY THE PREVIEW LAYER -----
    CGRect layerRect = [[[self view] layer] bounds];
    [self.captureVideoPreviewLayer setBounds:layerRect];
    [self.captureVideoPreviewLayer setPosition:CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect))];
    self.cameraUiView = [[UIView alloc] init];
    [[self view] addSubview:self.cameraUiView];
    [self.view sendSubviewToBack:self.cameraUiView];
    [[self.cameraUiView layer] addSublayer:self.captureVideoPreviewLayer];

    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusGesture:)];
    [self.cameraUiView addGestureRecognizer:singleTapGestureRecognizer];


    //----- START THE CAPTURE SESSION RUNNING -----
    [self.session startRunning];

    // Configure your output.
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [output setSampleBufferDelegate:self queue:queue];
}

- (void)focusGesture:(id)focusGesture {
    if ([focusGesture isKindOfClass:[UITapGestureRecognizer class]]) {
        UITapGestureRecognizer *tap = focusGesture;
        if (tap.state == UIGestureRecognizerStateRecognized) {
            CGPoint location = [tap locationInView:self.cameraUiView];

            [self focusAtPoint:location];
        }
    }
}

- (void)focusAtPoint:(CGPoint)point {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];;
    CGSize frameSize = self.cameraUiView.bounds.size;
    CGPoint pointOfInterest = CGPointMake(point.y / frameSize.height, 1.f - (point.x / frameSize.width));

    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {

        //Lock camera for configuration if possible
        NSError *error;
        if ([device lockForConfiguration:&error]) {

            if ([device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
                [device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
            }

            if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
                [device setFocusMode:AVCaptureFocusModeAutoFocus];
                [device setFocusPointOfInterest:pointOfInterest];
            }

            if([device isExposurePointOfInterestSupported] && [device isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
                [device setExposurePointOfInterest:pointOfInterest];
                [device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            }

            [device unlockForConfiguration];

        }
    }
}


- (void)orientationChanged:(NSNotification *)notification{
    float angle = 0;
    switch ([[UIDevice currentDevice] orientation]) {
        case UIDeviceOrientationLandscapeLeft:
            angle = M_PI_2;
            break;
        case UIDeviceOrientationLandscapeRight:
            angle = -M_PI_2;
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        default:;
    }
    [UIView animateWithDuration:0.6 animations:^{
        self.shutterButton.transform = CGAffineTransformMakeRotation(angle);
    }];
}

- (void)viewDidLayoutSubviews {
    self.shutterButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.shutterButton.layer.borderWidth = 4;
    self.shutterButton.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.3];
    self.shutterButton.layer.cornerRadius = self.shutterButton.bounds.size.width / 2;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *)processImages:(NSMutableArray *)array {
    OpenCVBitmap *first = array[0];

    NSUInteger middleIndex = [array count] / 2;
    for (NSUInteger i = 0; i < [array count]; i++) {
        if (i != middleIndex) {
            [array[i] stablizeTo:array[middleIndex]];
        }
    }

    [first copyMedian:array];
    return [first toUIImage];
}

- (void)capturedSampleBuffer:(CMSampleBufferRef) imageSampleBuffer orientation:(AVCaptureVideoOrientation)orientation {
    OpenCVBitmap *bm = [[OpenCVBitmap alloc] initWithSampleBuffer:imageSampleBuffer orientation:orientation];
    [self updateCounter];
    [self.capturedImages addObject:bm];
    if (self.capturedImages.count == self.numberOfPictures) {
        self.spinner.hidden = FALSE;
        [self.spinner startAnimating];
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
        dispatch_async(queue, ^{
            UIImage *res = [self processImages:self.capturedImages];
            dispatch_sync(dispatch_get_main_queue(), ^{
                UIImageWriteToSavedPhotosAlbum(res, self, @selector(imageSaved:withError:andContext:), nil);
                [self.capturedImages removeAllObjects];
                [self updateCounter];
            });
        });
    } else {
        [NSTimer scheduledTimerWithTimeInterval:self.numberOfSeconds
                                         target:self
                                       selector:@selector(takeAnotherImage:)
                                       userInfo:nil
                                        repeats:FALSE];
    }
}

- (void)imageSaved:(UIImage *)image withError:(NSError *)error andContext:(void*)context {
    NSString *msg;
    if (error) {
        msg = @"Could not safe the image";
    } else {
        msg = @"Image has been saved!";
    }
    self.spinner.hidden = TRUE;
    [self.spinner stopAnimating];

    UIAlertController *uac = [UIAlertController alertControllerWithTitle:@"Karakame"
                                                                 message:msg
                                                          preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction* ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [uac addAction:ok];
    [self presentViewController:uac animated:TRUE completion:nil];
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {
    if (!self.shutterButton.enabled || ![[NSUserDefaults standardUserDefaults] boolForKey:@"detect"]) {
        // We are processing
        return;
    }
    OpenCVBitmap *bm = [[OpenCVBitmap alloc] initWithSampleBuffer:sampleBuffer
                                                      orientation:[self orientationFromDevice]];
    NSArray *faces = [bm runDetector:@"haarcascade_fullbody"];
    dispatch_sync(dispatch_get_main_queue(), ^{
        for (UIView *box in self.faceRectangles) {
            [box removeFromSuperview];
        }
        if ([faces count]) {
            [self.faceRectangles removeAllObjects];
            for (NSValue *nds in faces) {
                CGRect rect = nds.CGRectValue;
                float xm = self.view.bounds.size.width / bm.width;
                float ym = self.view.bounds.size.height / bm.height;
                rect = CGRectMake(rect.origin.x * xm, rect.origin.y * ym,
                                  rect.size.width * xm, rect.size.height * ym
                );
                UIView *myBox  = [[UIView alloc] initWithFrame:rect];
                myBox.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
                myBox.layer.borderColor = [UIColor blackColor].CGColor;
                myBox.layer.borderWidth = 2;
                [self.faceRectangles addObject:myBox];
                [self.view addSubview:myBox];
            }
            NSLog(@"Faces: %d", [faces count]);
        }
    });
}

- (void) captureStillImage {
    for (AVCaptureConnection *connection in self.stillImageOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:
                        ^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
                            [self.self capturedSampleBuffer: imageSampleBuffer orientation:connection.videoOrientation];
                        }];
            }
        }
    }
}

- (void)takeAnotherImage:(id)takeAnotherImage {
    [self captureStillImage];
}

- (void)updateCounter {
    [self.shutterButton setTitle:[NSString stringWithFormat:@"%lu", self.numberOfPictures - self.capturedImages.count]
            forState:UIControlStateNormal];
}

- (IBAction)shutterButtonPressed:(UITapGestureRecognizer *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.numberOfPictures = [defaults integerForKey:@"numPictures"];
    self.numberOfSeconds = [defaults floatForKey:@"numSeconds"];
    [self captureStillImage];
    self.shutterButton.enabled = FALSE;
}


- (IBAction)unwindToList:(UIStoryboardSegue *)segue {
    
}

- (IBAction)saveSettings:(UIStoryboardSegue *)segue {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    SettingsViewController *vc = [segue sourceViewController];
    [defaults setBool:vc.detectObjectsSwitch.on forKey:@"detect"];
    self.numberOfPictures = [vc.numberOfPictures.text intValue];
    [self updateCounter];
    [defaults setInteger:self.numberOfPictures forKey:@"numPictures"];
    [defaults setDouble:[vc.secondsField.text floatValue] forKey:@"numSeconds"];
    [defaults synchronize];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}


@end
