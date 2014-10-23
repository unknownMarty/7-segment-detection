//
//  ViewController.m
//  7-segment
//
//  Created by Martijn Mellema on 20-10-14.
//  Copyright (c) 2014 Martijn Mellema. All rights reserved.
//

#import "ViewController.h"
#import <opencv2/core/core_c.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#include "openCVFindDigits.h"
#import <QuartzCore/QuartzCore.h>
ViewController* delegate;


using namespace cv;


@interface ViewController ()

@end

@implementation ViewController
{
    IBOutlet UIView *imageView;
    __weak IBOutlet UIButton *button;
    AVPlayer* avPlayer;
    NSMutableArray* arrImages;
    AVPlayerLayer* avPlayerLayer;
    
    UIImageView* snapShotView;
    UIImageView* openCVOutput;
    openCVFindDigits findDigits;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    delegate = self;
    arrImages = [NSMutableArray array];
        
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *moviePath = [bundle pathForResource:@"IMG_0391" ofType:@"MOV"];
    NSURL *movieURL = [NSURL fileURLWithPath:moviePath];
    
    
    
    AVAsset *avAsset = [AVAsset assetWithURL:movieURL];
    AVPlayerItem *avPlayerItem = [[AVPlayerItem alloc] initWithAsset:avAsset];
    
    avPlayer = [[AVPlayer alloc] initWithPlayerItem:avPlayerItem];
    
    
    CMTime interval = CMTimeMake(33, 1000);  // 30fps
    [avPlayer addPeriodicTimeObserverForInterval:interval queue:nil usingBlock: ^(CMTime time) {
        // get image
        [delegate doImageProcess:nil];
    }];
    
    
    
    avPlayerLayer =[AVPlayerLayer playerLayerWithPlayer:avPlayer];
    
   

    avPlayerLayer.needsDisplayOnBoundsChange = YES;
    avPlayerLayer.videoGravity  = AVLayerVideoGravityResizeAspectFill  ;

        [avPlayerLayer setFrame:imageView.frame];//self.view.frame];
    imageView.autoresizesSubviews = false;
     avPlayerLayer.frame =  CGRectMake(0,0, imageView.frame.size.width,imageView.frame.size.height);

    [imageView.layer addSublayer:avPlayerLayer];
    
    [avPlayer seekToTime:kCMTimeZero];
    
    avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:[avPlayer currentItem]];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    AVPlayerItem *p = [notification object];
    [p seekToTime:kCMTimeZero];
}


- (void)doImageProcess:(UIImage *)theImage {

    [snapShotView removeFromSuperview];
    snapShotView = nil;
    UIImage * snapshotImage = [self snapshot:imageView];
    snapShotView = [[UIImageView alloc] initWithImage:snapshotImage];
 //   [self.view addSubview:  snapShotView];
    
    if(snapshotImage.size.width > 0 && snapshotImage.size.height > 0)
    {
        findDigits.findDigits([self cvMatFromUIImage:snapShotView.image]);
        
        Mat testImage = findDigits.getShownImage();
        
        [openCVOutput removeFromSuperview];
        openCVOutput = nil;
        openCVOutput = [[UIImageView alloc] initWithImage:[self UIImageFromCVMat:testImage]];

        [self.view addSubview:  openCVOutput];
        
        testImage.release();
    }
}

- (UIImage *)snapshot:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:YES];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


-(void) viewDidAppear:(BOOL)animated
{
   [avPlayer play];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}


- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    return cvMat;
}



-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

@end
