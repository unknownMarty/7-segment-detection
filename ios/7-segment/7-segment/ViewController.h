//
//  ViewController.h
//  7-segment
//
//  Created by Martijn Mellema on 20-10-14.
//  Copyright (c) 2014 Martijn Mellema. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Availability.h>

#ifndef __IPHONE_4_0
#warning "This project uses features only available in iOS SDK 4.0 and later."
#endif

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

#ifdef __OBJC__
#import <Foundation/Foundation.h>
#endif

@interface ViewController : UIViewController


@end

