//
//  OTPadBase.m
//  SliderWithNumberPad
//
//  Created by Kevin He on 2013-02-27.
//  Copyright (c) 2013 OANDA Corp. All rights reserved.
//

#import "OTPadBase.h"
#import "OTPopupView.h"

@implementation OTPadBase

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _contour = [[OTPopupView alloc] initWithBaseView:nil andPopupView:nil];
    }
    return self;
}

- (void)makeContour
{
    [self.contour removeFromSuperview];
    self.contour.baseView = self;
    self.contour.popupView = self.padView;
    self.contour.cornerRadius = 10.0f;
    self.contour.baseViewPadding = 5.0f;
    [self.padView.superview insertSubview:self.contour belowSubview:self.padView];
    [self.contour displayPopup];
}

- (void)dismissPad
{
    [self.padView removeFromSuperview];
    [self.contour removeFromSuperview];
}

@end
