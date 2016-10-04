//
// Created by Douwe Osinga on 9/27/16.
// Copyright (c) 2016 Douwe Osinga. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVBitmap : NSObject

@property(nonatomic, readonly) int width;
@property(nonatomic, readonly) int height;
@property(nonatomic, readonly) size_t bytesPerRow;
@property(nonatomic, readonly) int bytesPerPixel;
@property(nonatomic, readonly) AVCaptureVideoOrientation orientation;

- (id)initWithSampleBuffer:(CMSampleBufferRef)pBuffer orientation:(AVCaptureVideoOrientation)orientation;

- (UIImage *)toUIImage;

- (void)copyMedian:(NSArray *)array;

- (void)stablizeTo:(OpenCVBitmap *)anchor;

- (NSArray *)runDetector:(NSString *)haarFileName;
@end