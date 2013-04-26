//
//  OTPopupView.h
//  SliderWithNumberPad
//
//  Created by Kevin He on 2013-03-08.
//  Copyright (c) 2013 OANDA Corp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface OTPopupView : UIView

@property (nonatomic, strong) UIView *baseView;
@property (nonatomic, strong) UIView *popupView;
@property (nonatomic, strong) NSArray *gradientColors;
@property (nonatomic, strong) NSArray *gradientLocations;
@property (nonatomic, assign) CGFloat cornerRadius;
@property (nonatomic, assign) CGFloat baseViewPadding;
@property (nonatomic, assign) CGFloat popupViewPadding;
@property (nonatomic, assign) CGAffineTransform popupCenterTranslationFromBase;
@property (nonatomic, assign) BOOL shouldSetPopupViewFrame;

- (id)initWithBaseView:(UIView *)baseView andPopupView:(UIView *)popupView;
- (void)displayPopup;

@end
