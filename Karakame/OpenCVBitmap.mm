//
// Created by Douwe Osinga on 9/27/16.
// Copyright (c) 2016 Douwe Osinga. All rights reserved.
//

#import "OpenCVBitmap.h"
#include <opencv2/opencv.hpp>

@interface OpenCVBitmap ()
@property(nonatomic) cv::Mat mat;
@property(nonatomic) void *rawData;
@end

@implementation OpenCVBitmap {

}
- (id)initWithSampleBuffer:(CMSampleBufferRef)pBuffer orientation:(AVCaptureVideoOrientation)orientation {
    self = [super init];
    if (self) {
        CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(pBuffer);
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        void *raw = CVPixelBufferGetBaseAddress(pixelBuffer);
        _width = (int) CVPixelBufferGetWidth(pixelBuffer);
        _height = (int) CVPixelBufferGetHeight(pixelBuffer);
        _bytesPerRow = (int) CVPixelBufferGetBytesPerRow(pixelBuffer);
        _bytesPerPixel = (int) (self.bytesPerRow / self.width);
        _orientation = orientation;
        size_t size = (size_t) (self.bytesPerRow * self.height);
        self.rawData = malloc(size);
        self.mat = cv::Mat(self.height, self.width, CV_8UC4, self.rawData);
        memcpy(self.mat.ptr(0), raw, size);
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    }
    return self;
}

- (UIImage *)toUIImage {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Since the format is really BGR, we need to unshuffle the colors:
    size_t size = (size_t) (self.bytesPerRow * self.height);
    uint8_t *unshuffled = (uint8_t *) malloc(size);
    uint8_t *dest = unshuffled;
    for (uint8_t *src = self.mat.ptr(0); src < self.mat.ptr(0) + size; src += 4) {
        *(dest++) = *(src + 2);
        *(dest++) = *(src + 1);
        *(dest++) = *(src);
        *(dest++) = *(src + 3);
    }
    CGContextRef context = CGBitmapContextCreate(unshuffled,
            (size_t) self.width, (size_t) self.height, 8, self.bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast);
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    UIImageOrientation imgOrientation = UIImageOrientationUp;
    switch (self.orientation) {
        case AVCaptureVideoOrientationPortrait:
            imgOrientation = UIImageOrientationRight;
            break;
        case AVCaptureVideoOrientationPortraitUpsideDown:
            imgOrientation = UIImageOrientationLeft;
            break;
        case AVCaptureVideoOrientationLandscapeRight:
            imgOrientation = UIImageOrientationUp;
            break;
        case AVCaptureVideoOrientationLandscapeLeft:
            imgOrientation = UIImageOrientationDown;
            break;
        default:
            imgOrientation = UIImageOrientationUp;
    }
    UIImage *result = [[UIImage alloc] initWithCGImage:imageRef scale:1.0 orientation:imgOrientation];
    free(unshuffled);
    return result;
}

+ (cv::CascadeClassifier)loadCascadeClassifier:(NSString *)string {
    std::string key([string UTF8String]);
    static std::map<std::string, cv::CascadeClassifier> registry;
    std::map<std::string, cv::CascadeClassifier>::iterator it = registry.find(key);
    if (it != registry.end()) {
        return it->second;
    }
    NSString* filePath = [[NSBundle mainBundle] pathForResource:string ofType:@"xml"];
    const cv::CascadeClassifier &res = cv::CascadeClassifier(std::string([filePath UTF8String]));
    registry[key] = res;
    return res;
}

- (void)copyMedian:(NSArray *)array {
    uint8_t *dest = self.mat.ptr(0);
    NSUInteger array_count = array.count;
    uint8_t *srcs[array_count];
    for (NSUInteger i = 0; i < array_count; i++) {
        srcs[i] = ((OpenCVBitmap *) array[i]).self.mat.ptr(0);
    }

    NSUInteger offset = 0;
    for (int xy = 0; xy < self.height * self.width; xy++) {
        for (int b = 0; b < self.bytesPerPixel; b++) {
            uint8_t buffer[array_count];
            offset++;
            for (NSUInteger i = 0; i < array_count; i++) {
                buffer[i] = srcs[i][offset];
            }
            for (int i = 1; i < array_count; i ++) {
                for (int j = i; j >= 1; j--) {
                    if (buffer[j] < buffer[j - 1]) {
                        uint8_t temp = buffer[j];
                        buffer[j] = buffer[j - 1];
                        buffer[j - 1] = temp;
                    }
                }
            }
            dest[offset] = buffer[array_count / 2];
        }
    }
}

// Modify the current bitmap so it lines up with the anchor
- (void) stablizeTo:(OpenCVBitmap *)anchor {
    cv::Mat transfrom = cv::estimateRigidTransform(self.mat, anchor.mat, TRUE);
    cv::Mat output;
    cv::warpAffine(self.mat, output, transfrom, cv::Size(self.width, self.height));
    self.mat = output;
}

- (NSArray *)runDetector:(NSString *)haarFileName {
    cv::CascadeClassifier cf = [OpenCVBitmap loadCascadeClassifier:haarFileName];
    std::vector<cv::Rect> rects;
    cv::Mat gray;
    cv::cvtColor(self.mat, gray, cv::COLOR_BGR2GRAY);
    cf.detectMultiScale(gray, rects, 1.1, 3, CV_HAAR_FIND_BIGGEST_OBJECT, cv::Size(30, 30), cv::Size(200,200));

    NSMutableArray *res = [NSMutableArray new];
    for (int i = 0; i < rects.size(); i++) {
        cv::Rect_<int> &r = rects[i];
        CGRect rect = CGRectMake(r.x, r.y, r.width, r.height);
        [res addObject:[NSValue valueWithCGRect:rect]];
    }
    return [res copy];
}

- (void)dealloc {
    free(self.rawData);
};

@end