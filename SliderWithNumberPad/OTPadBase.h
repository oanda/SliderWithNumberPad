//
//  OTPadBase.h
//  SliderWithNumberPad
//
//  Created by Kevin He on 2013-02-27.
//  Copyright (c) 2013 OANDA Corp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
@class OTPopupView;

@protocol OTPadDataSource <NSObject>
@end

@protocol OTPadDelegate <NSObject>
@end

@interface OTPadBase : UIControl
@property (nonatomic, strong) UIView *padView;
@property (nonatomic, strong) OTPopupView *contour;

- (void)makeContour;
- (void)dismissPad;

@end
