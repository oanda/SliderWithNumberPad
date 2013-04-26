//
//  OTValueSlider.h
//  SliderWithNumberPad
//
//  Created by Kevin He on 2013-03-01.
//  Copyright (c) 2013 OANDA Corp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

typedef NS_ENUM(NSUInteger, ValueButtonChangeType) {
    ValueButtonChangeProgrammatic,
    ValueButtonChangeSliderWasTouched
};

@class OTValueSlider;

@protocol OTValueSliderDelegate <NSObject>
- (void)valueSliderDidChange:(OTValueSlider *)valueSlider toValue:(float)value changeType:(ValueButtonChangeType)type;
- (void)valueSliderValueButtonPressed:(OTValueSlider *)valueSlider forEvent:(id)event;
- (void)valueSliderDidFinishChanges:(OTValueSlider *)valueSlider;
@end

@interface OTValueSlider : UIControl<UIGestureRecognizerDelegate>
@property (nonatomic, weak) id<OTValueSliderDelegate> delegate;

- (id)initWithDelegate:(id<OTValueSliderDelegate>)aDelegate;
- (void)setPosition:(NSNumber *)number andTitle:(NSString *)title animated:(BOOL)animated;
- (void)overlayEditViewOnButton:(UIView *)editView;
- (void)removePopup;

@end
