//
//  OTValueSlider.m
//  SliderWithNumberPad
//
//  Created by Kevin He on 2013-03-01.
//  Copyright (c) 2013 OANDA Corp. All rights reserved.
//

#import "OTValueSlider.h"
#import "OTPopupView.h"

typedef NS_ENUM(NSUInteger, ValueButtonState) {
    ValueButtonStateNormal,
    ValueButtonStateShowPopup
};

@interface OTValueSlider ()
@property (nonatomic, assign) CGFloat value;
@property (nonatomic, readonly) CGPoint thumbRectCenter;
@property (nonatomic, strong) UISlider *slider;
@property (nonatomic, strong) UIButton *valueButton;
@property (nonatomic, strong) UIView *valueButtonContainer;
@property (nonatomic, strong) OTPopupView *valueButtonContour;
@property (nonatomic, strong) UILabel *valueZoomedLabel;
@end

static NSInteger const kValueButtonWidth = 44;
static float const kButtonCornerRadius = 8.0f;
static NSInteger const kValueZoomedLabelPadding = 15;

@implementation OTValueSlider

- (id)initWithDelegate:(id<OTValueSliderDelegate>)aDelegate
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _delegate = aDelegate;
        _slider = [[UISlider alloc] init];
        _slider.userInteractionEnabled = NO;
        _valueZoomedLabel = [[UILabel alloc] init];
        _valueZoomedLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:20];
        _valueZoomedLabel.textAlignment = UITextAlignmentCenter;
        _valueZoomedLabel.backgroundColor = [UIColor clearColor];
        _valueZoomedLabel.textColor = [UIColor whiteColor];
        _valueZoomedLabel.adjustsFontSizeToFitWidth = YES;
        _valueZoomedLabel.minimumFontSize = 10;
        _valueButtonContainer = [[UIView alloc] initWithFrame:CGRectZero];
        _valueButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _valueButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
        _valueButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        _valueButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _valueButton.titleLabel.minimumFontSize = 10;
        _valueButton.titleLabel.shadowColor = [UIColor blackColor];
        _valueButton.titleLabel.shadowOffset = CGSizeMake(0.0f,-1.0f);
        _valueButton.titleLabel.textAlignment = UITextAlignmentCenter;
        _valueButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        _valueButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        _valueButton.layer.cornerRadius = kButtonCornerRadius;
        _valueButton.layer.masksToBounds = YES;
        _valueButton.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [_valueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _valueButton.backgroundColor = [UIColor darkGrayColor];
        _valueButtonContainer.layer.shadowOffset = CGSizeMake(0, 2);
        _valueButtonContainer.layer.shadowColor = [UIColor blackColor].CGColor;
        _valueButtonContainer.layer.shadowOpacity = 0.5;
        _valueButtonContainer.layer.shadowRadius = kButtonCornerRadius;
        [_valueButton addTarget:self action:@selector(valueButtonPressed:forEvent:) forControlEvents:UIControlEventTouchUpInside];
        _valueButton.exclusiveTouch = NO;
        [_slider addTarget:self action:@selector(configurationChanged:) forControlEvents:UIControlEventValueChanged];
        [[UISlider appearance] setMinimumTrackImage:[[UIImage imageNamed:@"SliderMinTint"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 0)]
                                           forState:UIControlStateNormal];
        [[UISlider appearance] setMaximumTrackImage:[[UIImage imageNamed:@"SliderMaxTint"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)]
                                           forState:UIControlStateNormal];
        UIPanGestureRecognizer *pgr = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
        pgr.delegate = self;
        pgr.minimumNumberOfTouches = 1;
        pgr.maximumNumberOfTouches = 1;
        [_valueButton addGestureRecognizer:pgr];
        
        UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGesture:)];
        lpgr.delegate = self;
        lpgr.minimumPressDuration = 0.0;
        lpgr.cancelsTouchesInView = NO; // Do not cancel UIControlEvents
        [_valueButton addGestureRecognizer:lpgr];
    }
    return self;
}

- (void)setFrame:(CGRect)aFrame
{
    [super setFrame:aFrame];
    self.slider.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y + self.bounds.size.height/2.0,
                                   self.bounds.size.width, self.bounds.size.height/2.0);
    self.valueButtonContainer.frame = CGRectMake(self.thumbRectCenter.x - kValueButtonWidth/2.0,
                                                 self.bounds.size.height/2.0, kValueButtonWidth, self.bounds.size.height/2.0);
    self.valueButtonContainer.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.valueButtonContainer.bounds
                                                                            cornerRadius:kButtonCornerRadius].CGPath;
    self.valueButton.frame = self.valueButtonContainer.bounds;
    [self.valueButtonContainer addSubview:self.valueButton];
    
    UIColor *clr0 = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:0.5];
    UIColor *clr1 = [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:0.7];
    UIColor *clr2 = [UIColor colorWithRed:0.30 green:0.30 blue:0.30 alpha:0.7];
    CAGradientLayer *horizontalGradientLayer = [CAGradientLayer layer];
    horizontalGradientLayer.frame = self.valueButton.layer.bounds;
    horizontalGradientLayer.colors = @[(id)clr2.CGColor, (id)clr1.CGColor, (id)clr1.CGColor, (id)clr2.CGColor];
    horizontalGradientLayer.locations = @[@0.0, @0.3, @0.7, @1.0];
    horizontalGradientLayer.startPoint = CGPointMake(0.0, 0.5);
    horizontalGradientLayer.endPoint = CGPointMake(1.0, 0.5);
    [self.valueButton.layer insertSublayer:horizontalGradientLayer below:self.valueButton.titleLabel.layer];
    CAGradientLayer *verticalGradientLayer = [CAGradientLayer layer];
    verticalGradientLayer.frame = self.valueButton.layer.bounds;
    verticalGradientLayer.colors = @[(id)clr2.CGColor, (id)clr0.CGColor, (id)clr2.CGColor];
    verticalGradientLayer.locations = @[@0.0, @0.5, @1.0];
    [self.valueButton.layer insertSublayer:verticalGradientLayer below:horizontalGradientLayer];
    
    [self addSubview:self.slider];
    [self addSubview:self.valueButtonContainer];
}

- (OTPopupView *)valueButtonContour
{
    if (!_valueButtonContour) {
        _valueButtonContour = [[OTPopupView alloc] initWithBaseView:nil andPopupView:nil];
        _valueButtonContour.cornerRadius = kButtonCornerRadius;
        _valueButtonContour.shouldSetPopupViewFrame = NO;
    }
    return _valueButtonContour;
}

#pragma mark - Slider movement

- (void)setValue:(float)value
{
    _value = value;
    [self.slider setValue:value];
}

- (void)setPosition:(NSNumber *)number andTitle:(NSString *)title animated:(BOOL)animated
{
    NSTimeInterval duration = animated?0.2:0.0;
    [UIView animateWithDuration:duration animations:^{
        if (number) {
            self.value = [number doubleValue];
            [_delegate valueSliderDidChange:self toValue:self.slider.value changeType:ValueButtonChangeProgrammatic];
            [self setValueButtonState:ValueButtonStateNormal];
        }
        if (title) {
            [self.valueButton setTitle:title forState:UIControlStateNormal];
        }
    }];
}

#pragma mark - UIControlEvents Callbacks

- (void)valueButtonPressed:(id)sender forEvent:(id)event
{
    [_delegate valueSliderValueButtonPressed:self forEvent:event];
}

- (void)configurationChanged:(id)sender
{
    if([sender isKindOfClass:[UISlider class]]){
        [_delegate valueSliderDidChange:self toValue:self.slider.value changeType:ValueButtonChangeSliderWasTouched];
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    if (([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] &&
         [otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) ||
        ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] &&
         [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]])) {
            return YES;
        }
    
    return NO; // prevents simultaneously recognizing scrollview gestures
}

#pragma mark - UIGestureRecognizers Callbacks

- (void)handlePanGesture:(UIPanGestureRecognizer *)panGesture
{
    switch (panGesture.state) {
        case UIGestureRecognizerStateChanged:
            if (CGRectContainsPoint(self.valueZoomedLabel.bounds, [panGesture locationInView:self.valueZoomedLabel])) {
                [self valueButtonPressed:nil forEvent:nil];
                
                // Cancel gesture to avoid continually calling valueButtonPressed:forEvent: if the user does not let go
                panGesture.enabled = NO;
                panGesture.enabled = YES;
            } else {
                CGFloat value = [panGesture locationInView:self].x / self.slider.bounds.size.width;
                self.value = value;
                [self.slider sendActionsForControlEvents:UIControlEventValueChanged];
                [self setValueButtonState:ValueButtonStateShowPopup];
            }
            break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
            [self setValueButtonState:ValueButtonStateNormal];
            [_delegate valueSliderDidFinishChanges:self];
            break;
            
        default:
            break;
    }
}

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)longPressGesture
{
    switch (longPressGesture.state) {
        case UIGestureRecognizerStateBegan:
            [self setValueButtonState:ValueButtonStateShowPopup];
            break;
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded:
            [self setValueButtonState:ValueButtonStateNormal];
            break;
            
        default:
            // Do nothing
            break;
    }
}

#pragma mark - Helper functions

- (CGPoint)thumbRectCenter
{
    CGRect tractRect = [self.slider trackRectForBounds:self.slider.bounds];
    CGRect thumbRect = [self.slider thumbRectForBounds:self.slider.bounds trackRect:tractRect value:self.slider.value];
    CGPoint thumbRectCenter = CGPointMake(thumbRect.origin.x + thumbRect.size.width/2.0,
                                          thumbRect.origin.y + thumbRect.size.height/2.0);
    return thumbRectCenter;
}

- (void)setValueButtonState:(ValueButtonState)state
{
    switch (state) {
        case ValueButtonStateNormal:
            [self removePopup];
            self.valueButtonContainer.frame = CGRectMake(self.thumbRectCenter.x - kValueButtonWidth/2.0,
                                                         self.bounds.size.height/2.0, kValueButtonWidth, self.bounds.size.height/2.0);
            self.valueButtonContainer.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.valueButtonContainer.bounds
                                                                                    cornerRadius:kButtonCornerRadius].CGPath;
            break;
            
        case ValueButtonStateShowPopup:
            self.valueButtonContainer.frame = CGRectMake(self.thumbRectCenter.x - kValueButtonWidth/4.0,
                                                         self.bounds.size.height/2.0, kValueButtonWidth/2.0, self.bounds.size.height/2.0);
            self.valueButtonContainer.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.valueButtonContainer.bounds
                                                                                    cornerRadius:kButtonCornerRadius].CGPath;
            self.valueZoomedLabel.frame = CGRectMake(self.valueButtonContainer.frame.origin.x-kValueZoomedLabelPadding,
                                                     self.valueButtonContainer.frame.origin.y-self.valueButtonContainer.frame.size.height-kValueZoomedLabelPadding*2.0,
                                                     self.valueButtonContainer.frame.size.width+kValueZoomedLabelPadding*2.0,
                                                     self.valueButtonContainer.frame.size.height+kValueZoomedLabelPadding*1.8);
            UIView *rootView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
            self.valueZoomedLabel.frame = [rootView convertRect:self.valueZoomedLabel.frame fromView:self];
            self.valueZoomedLabel.text = self.valueButton.titleLabel.text;
            if (self.valueZoomedLabel.superview != rootView) {
                [rootView addSubview:self.valueZoomedLabel];
            }
            self.valueButtonContour.baseView = self.valueButtonContainer;
            self.valueButtonContour.popupView = self.valueZoomedLabel;
            if (self.valueButtonContour.superview != rootView) {
                [rootView insertSubview:self.valueButtonContour belowSubview:self.valueZoomedLabel];
            }
            [self.valueButtonContour displayPopup];
            break;
    }
}

- (void)overlayEditViewOnButton:(UIView *)editView
{
    editView.frame = self.valueButton.bounds;
    editView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.valueButton addSubview:editView];
}

- (void)removePopup
{
    // Cancel gesture recognizers to prevent continued user input after popups removed
    // (Does not cause infinite loop - this only transitions to Cancelled state if gesture
    // recognizer is currently recognizing)
    for (UIGestureRecognizer *gestureRecognizer in self.valueButton.gestureRecognizers) {
        gestureRecognizer.enabled = NO;
        gestureRecognizer.enabled = YES;
    }
    // These views are subviews of rootView
    [self.valueZoomedLabel removeFromSuperview];
    [self.valueButtonContour removeFromSuperview]; self.valueButtonContour = nil;
}

- (void)dealloc
{
    [self removePopup];
}

@end
