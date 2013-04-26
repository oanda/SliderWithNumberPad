//
//  OTPopupView.m
//  SliderWithNumberPad
//
//  Created by Kevin He on 2013-03-08.
//  Copyright (c) 2013 OANDA Corp. All rights reserved.
//

#import "OTPopupView.h"

@interface OTPopupView ()
@property (nonatomic, strong) CAShapeLayer *shapeLayer;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, assign) BOOL hasSetupDefaults;
@property (nonatomic, assign) BOOL isPopupTranslationFromBaseSet;

- (CGPathRef)newPathAroundRect:(CGRect)aRect andOtherRect:(CGRect)otherRect cornerRadius:(CGFloat)cornerRadius;
@end

@implementation OTPopupView
@synthesize popupCenterTranslationFromBase = _popupCenterTranslationFromBase;

- (id)initWithBaseView:(UIView *)baseView andPopupView:(UIView *)popupView
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _baseView = baseView;
        _popupView = popupView;
        _cornerRadius = 0.0f;
        _baseViewPadding = 0.0f;
        _popupViewPadding = 0.0f;
        _shouldSetPopupViewFrame = YES;
    }
    return self;
}

- (void)displayPopup
{
    NSAssert([self.baseView isKindOfClass:[UIView class]] && [self.popupView isKindOfClass:[UIView class]],
             @"baseView and popupView must both be of class UIView");
    NSAssert(self.superview != nil, @"OTPopupView must have a superview before setting frames");
    
    if (!self.hasSetupDefaults) {
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowRadius = 2.0;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOpacity = 0.5;
        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
        
        self.gradientLayer.colors = self.gradientColors;
        self.gradientLayer.locations = self.gradientLocations;
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        
        self.hasSetupDefaults = YES;
    }
    
    CGRect absoluteBaseFrame = [self.superview convertRect:self.baseView.frame fromView:self.baseView.superview];
    absoluteBaseFrame = CGRectInset(absoluteBaseFrame, -self.baseViewPadding, -self.baseViewPadding);
    
    CGRect absolutePopupFrame;
    if (self.shouldSetPopupViewFrame) {
        // Set popup frame centered about the base center point, then transform as appropriate
        CGPoint absoluteBaseCenterPoint = CGPointMake(CGRectGetMidX(absoluteBaseFrame), CGRectGetMidY(absoluteBaseFrame));
        absolutePopupFrame = CGRectMake(absoluteBaseCenterPoint.x - self.popupView.frame.size.width/2.0,
                                        absoluteBaseCenterPoint.y - self.popupView.frame.size.height/2.0,
                                        self.popupView.frame.size.width, self.popupView.frame.size.height);
        absolutePopupFrame = CGRectInset(absolutePopupFrame, -self.popupViewPadding, -self.popupViewPadding);
        absolutePopupFrame = CGRectApplyAffineTransform(absolutePopupFrame, self.popupCenterTranslationFromBase);
        // Convert back to popupView.superview coordinates, inset to where popupView.frame should be
        self.popupView.frame = CGRectInset([self.popupView.superview convertRect:absolutePopupFrame fromView:self.superview],
                                           self.popupViewPadding, self.popupViewPadding);
    } else {
        absolutePopupFrame = [self.superview convertRect:self.popupView.frame fromView:self.popupView.superview];
        absolutePopupFrame = CGRectInset(absolutePopupFrame, -self.popupViewPadding, -self.popupViewPadding);
    }
    
    self.frame = CGRectUnion(absoluteBaseFrame, absolutePopupFrame);
    
    CGRect translatedBaseFrame = [self convertRect:absoluteBaseFrame fromView:self.superview];
    CGRect translatedPopupFrame = [self convertRect:absolutePopupFrame fromView:self.superview];
    
    CGPathRef path = [self newPathAroundRect:translatedBaseFrame andOtherRect:translatedPopupFrame cornerRadius:self.cornerRadius];
    self.shapeLayer.path = path;
    
    // Disable animating changes to layer
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    self.gradientLayer.mask = self.shapeLayer;
    self.gradientLayer.frame = self.bounds;
    
    if (self.gradientLayer.superlayer != self.layer) {
        [self.layer addSublayer:self.gradientLayer];
    }
    self.layer.shadowPath = path;
    
    [CATransaction commit];
    CGPathRelease(path);
}

#pragma mark - Property accessors

- (CAShapeLayer *)shapeLayer
{
    if (!_shapeLayer) {
        _shapeLayer = [CAShapeLayer layer];
    }
    return _shapeLayer;
}

- (CAGradientLayer *)gradientLayer
{
    if (!_gradientLayer) {
        _gradientLayer = [CAGradientLayer layer];
    }
    return _gradientLayer;
}

- (NSArray *)gradientColors
{
    if (!_gradientColors) {
        UIColor *clr1 = [UIColor colorWithRed:0.30 green:0.30 blue:0.30 alpha:1.0]; // Top colour
        UIColor *clr2 = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0]; // Middle colour
        UIColor *clr3 = [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0]; // Bottom colour
        _gradientColors = @[(id)clr1.CGColor, (id)clr2.CGColor, (id)clr3.CGColor];
    }
    return _gradientColors;
}

- (NSArray *)gradientLocations
{
    if (!_gradientLocations) {
        _gradientLocations = @[@0.0f, @0.8f, @1.0f];
    }
    return _gradientLocations;
}

- (CGAffineTransform)popupCenterTranslationFromBase
{
    // Return user defined tranform if set
    if (_isPopupTranslationFromBaseSet) {
        return _popupCenterTranslationFromBase;
    }
    
    // Work in rootView coordinates to determine the appropriate translation that will put the popup on screen
    UIView *rootView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
    CGRect baseFrame = [rootView convertRect:self.baseView.frame fromView:self.baseView.superview];
    CGSize popupSize = self.popupView.frame.size;
    
    CGFloat x, y;
    
    // Try putting above base
    x = baseFrame.origin.x - 5;
    y = baseFrame.origin.y - 10 - popupSize.height;
    
    // Center the popup over the base if the base is wider
    if (baseFrame.size.width > popupSize.width) {
        x += (baseFrame.size.width - popupSize.width) / 2.0;
    }
    
    if (y < 0) {
        // Doesn't fit on top, try putting on the left
        x = baseFrame.origin.x - 15 - popupSize.width;
        y = baseFrame.origin.y - 5;
        
        // Check if still too tall
        if (y + popupSize.height > rootView.bounds.size.height) {
            y = rootView.bounds.size.height - popupSize.height;
        }
        
        if ((x < 0 ) || (y < 0) || (x + popupSize.width > rootView.bounds.size.width) || (y + popupSize.height > rootView.bounds.size.height)) {
            // Still doesn't fit, put it on the right
            x = baseFrame.origin.x + baseFrame.size.width + 15;
            y = baseFrame.origin.y - 5;
            
            // Check if still too tall
            if (y + popupSize.height > rootView.bounds.size.height) {
                y = rootView.bounds.size.height - popupSize.height;
            }
        }
        
    } else if ((x < 0) || (x + popupSize.width > rootView.bounds.size.width) || (y + popupSize.height > rootView.bounds.size.height)) {
        // There is enough vertical space, but it doesn't fit horizontally
        x = rootView.bounds.size.width - popupSize.width;
    }
    
    CGPoint absoluteBaseCenterPoint = CGPointMake(CGRectGetMidX(baseFrame), CGRectGetMidY(baseFrame));
    CGPoint absolutePopupCenterPoint = CGPointMake(x + popupSize.width/2.0, y + popupSize.height/2.0);
    
    return CGAffineTransformMakeTranslation(absolutePopupCenterPoint.x - absoluteBaseCenterPoint.x,
                                            absolutePopupCenterPoint.y - absoluteBaseCenterPoint.y);
}

#pragma mark - Property setters

- (void)setPopupCenterTranslationFromBase:(CGAffineTransform)popupCenterTranslationFromBase
{
    _popupCenterTranslationFromBase = popupCenterTranslationFromBase;
    _isPopupTranslationFromBaseSet = YES;
}

#pragma mark - Helper functions

- (CGPathRef)newPathAroundRect:(CGRect)aRect andOtherRect:(CGRect)otherRect cornerRadius:(CGFloat)cornerRadius
{
    NSAssert(CGRectIntersectsRect(aRect, otherRect) == NO, @"aRect and otherRect cannot intersect");
    
    // Rotate to the "up" orientation
    CGFloat rotation;
    if (CGRectGetMaxY(otherRect) <= CGRectGetMinY(aRect)) {
        // aRect below otherRect
        rotation = 0;
    } else if (CGRectGetMinY(otherRect) >= CGRectGetMaxY(aRect)) {
        // aRect above otherRect
        rotation = M_PI;
    } else {
        // aRect beside otherRect
        if (CGRectGetMaxX(otherRect) <= CGRectGetMinX(aRect)) {
            // aRight to the right of otherRect
            rotation = M_PI_2;
        } else {
            // aRect to the left of otherRect
            rotation = 3*M_PI_2;
        }
    }
    CGAffineTransform transform = CGAffineTransformMakeRotation(rotation);
    otherRect = CGRectApplyAffineTransform(otherRect, transform);
    aRect = CGRectApplyAffineTransform(aRect, transform);
    
    // Find path around the rects
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGFloat aRectLeft = CGRectGetMinX(aRect);
    CGFloat aRectRight = CGRectGetMaxX(aRect);
    CGFloat aRectTop = CGRectGetMinY(aRect);
    CGFloat aRectBottom = CGRectGetMaxY(aRect);
    
    CGFloat otherRectLeft = CGRectGetMinX(otherRect);
    CGFloat otherRectRight = CGRectGetMaxX(otherRect);
    CGFloat otherRectTop = CGRectGetMinY(otherRect);
    CGFloat otherRectBottom = CGRectGetMaxY(otherRect);
    
    if (otherRectRight < aRectRight-cornerRadius) {
        CGPathMoveToPoint (path, NULL, aRectRight, aRectTop+cornerRadius);
        CGPathAddArc(path, NULL, aRectRight-cornerRadius, aRectTop+cornerRadius, cornerRadius, 0, 3*M_PI_2, YES);
        CGPathAddLineToPoint(path, NULL, otherRectRight+cornerRadius, aRectTop);
        CGPathAddQuadCurveToPoint(path, NULL, MIN(otherRectRight,aRectRight), MAX(otherRectBottom,aRectTop), otherRectRight, otherRectBottom-cornerRadius);
    } else if (otherRectRight-cornerRadius > aRectRight) {
        CGPathMoveToPoint (path, NULL, aRectRight, aRectTop);
        CGPathAddLineToPoint(path, NULL, aRectRight, otherRectBottom+cornerRadius);
        CGPathAddArc(path, NULL, aRectRight+cornerRadius, otherRectBottom+cornerRadius, cornerRadius, M_PI, 3*M_PI_2, NO);
        CGPathAddLineToPoint(path, NULL, otherRectRight-cornerRadius, otherRectBottom);
        CGPathAddArc(path, NULL, otherRectRight-cornerRadius, otherRectBottom-cornerRadius, cornerRadius, M_PI_2, 0, YES);
    } else {
        CGPathMoveToPoint (path, NULL, aRectRight, aRectTop);
        CGPathAddLineToPoint(path, NULL, aRectRight, otherRectBottom);
        CGPathAddLineToPoint(path, NULL, otherRectRight, otherRectBottom);
    }
    CGPathAddLineToPoint(path, NULL, otherRectRight, otherRectTop+cornerRadius);
    CGPathAddArc(path, NULL, otherRectRight-cornerRadius, otherRectTop+cornerRadius, cornerRadius, 0, 3*M_PI_2, YES);
    CGPathAddLineToPoint(path, NULL, otherRectLeft+cornerRadius, otherRectTop);
    CGPathAddArc(path, NULL, otherRectLeft+cornerRadius, otherRectTop+cornerRadius, cornerRadius, 3*M_PI_2, M_PI, YES);
    if (otherRectLeft < aRectLeft-cornerRadius) {
        CGPathAddLineToPoint(path, NULL, otherRectLeft, otherRectBottom-cornerRadius);
        CGPathAddArc(path, NULL, otherRectLeft+cornerRadius, otherRectBottom-cornerRadius, cornerRadius, M_PI, M_PI_2, YES);
        CGPathAddLineToPoint(path, NULL, aRectLeft-cornerRadius, otherRectBottom);
        CGPathAddArc(path, NULL, aRectLeft-cornerRadius, MIN(otherRectBottom,aRectTop)+cornerRadius, cornerRadius, 3*M_PI_2, 0, NO);
    } else if (otherRectLeft-cornerRadius > aRectLeft)  {
        CGPathAddLineToPoint(path, NULL, otherRectLeft, otherRectBottom-cornerRadius);
        CGPathAddQuadCurveToPoint(path, NULL, otherRectLeft, aRectTop, otherRectLeft-cornerRadius, aRectTop);
        CGPathAddLineToPoint(path, NULL, aRectLeft+cornerRadius, aRectTop);
        CGPathAddArc(path, NULL, aRectLeft+cornerRadius, aRectTop+cornerRadius, cornerRadius, 3*M_PI_2, M_PI, YES);
    } else {
        CGPathAddLineToPoint(path, NULL, otherRectLeft, otherRectBottom);
        CGPathAddQuadCurveToPoint(path, NULL, aRectLeft, MIN(otherRectBottom,aRectTop), aRectLeft, aRectTop);
    }
    CGPathAddLineToPoint (path, NULL, aRectLeft, aRectBottom-cornerRadius);
    CGPathAddArc(path, NULL, aRectLeft+cornerRadius, aRectBottom-cornerRadius, cornerRadius, M_PI, M_PI_2, YES);
    CGPathAddLineToPoint(path, NULL, aRectRight-cornerRadius, aRectBottom);
    CGPathAddArc(path, NULL, aRectRight-cornerRadius, aRectBottom-cornerRadius, cornerRadius, M_PI_2, 0, YES);
    CGPathCloseSubpath(path);
    
    // Rotate back to original orientation and return
    CGAffineTransform invertTransform = CGAffineTransformInvert(transform);
    CGPathRef newPath = CGPathCreateCopyByTransformingPath(path, &invertTransform);
    CGPathRelease(path);
    return newPath;
}

@end
