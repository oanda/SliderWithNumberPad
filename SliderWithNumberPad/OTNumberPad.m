//
//  OTNumberPad.m
//  SliderWithNumberPad
//
//  Created by Kevin He on 2013-02-22.
//  Copyright (c) 2013 OANDA Corp. All rights reserved.
//

#import "OTNumberPad.h"
#import "OTPopupView.h"

typedef NS_ENUM(NSInteger, NumberButtonContainerTag) {
    NumberButtonContainerTagDefault,
    NumberButtonContainerTagDisableOnErrorState
};

// Square number pad: 201 = 5 + (44 + 5) * 4, where 44 is the button size,
// 4 is number of keys per row/col and 5 is the kNumberPadCellSeparationSize
static NSInteger const kNumberPadPadSize = 201;
static NSInteger const kNumberPadCellButtonSize = 44;
static NSInteger const kNumberPadCellSeparationSize = 5;
static NSInteger const kNumberPadInsetFrameSize = 5;
static float const kButtonCornerRadius = 8.0f;
static float const kButtonTouchInset = -10.0f;

@implementation NumberKeyBundle
@end

@interface OTNumberPadButton : UIButton
@property (nonatomic, strong) CALayer *shadeLayer;
@property (nonatomic, strong) CALayer *disabledCoverLayer;
@end

@implementation OTNumberPadButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel.shadowColor = [UIColor blackColor];
        self.titleLabel.shadowOffset = CGSizeMake(0, 2);
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.layer.cornerRadius = kButtonCornerRadius;
        self.layer.masksToBounds = YES;
        self.layer.shouldRasterize = YES;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    }
    return self;
}

- (CALayer *)shadeLayer
{
    if (!_shadeLayer) {
        _shadeLayer = [CALayer layer];
        _shadeLayer.backgroundColor = [UIColor blackColor].CGColor;
        _shadeLayer.opacity = 0.4f;
    }
    return _shadeLayer;
}

- (CALayer *)disabledCoverLayer
{
    if (!_disabledCoverLayer) {
        _disabledCoverLayer = [CALayer layer];
        _disabledCoverLayer.backgroundColor = [UIColor darkGrayColor].CGColor;
        _disabledCoverLayer.opacity = 0.7f;
    }
    return _disabledCoverLayer;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    if (highlighted) {
        self.shadeLayer.frame = self.bounds;
        [self.layer insertSublayer:self.shadeLayer below:self.titleLabel.layer];
    } else {
        [self.shadeLayer removeFromSuperlayer];
    }
}

- (void)setEnabled:(BOOL)enabled
{
    [super setEnabled:enabled];
    if (enabled) {
        [self.disabledCoverLayer removeFromSuperlayer];
    } else {
        self.disabledCoverLayer.frame = self.bounds;
        [self.layer addSublayer:self.disabledCoverLayer];
    }
}

@end

@interface OTNumberPad ()
@property (nonatomic, strong) NSArray *objectsInPad;
@property (nonatomic, strong) UILabel *editLabel;
@property (nonatomic, strong) UIButton *transparentButton;
@property (nonatomic, strong) OTNumberPadButton *zoomedButton;
@property (nonatomic, strong) OTPopupView *buttonContour;
@property (nonatomic, strong) NSArray *gradientColors;
@property (nonatomic, strong) NSArray *gradientLocations;
@property (nonatomic, assign) NumberPadInputValidityState errorState;
- (void)removeNumberPad;
@end

@implementation OTNumberPad

- (id)initWithFrame:(CGRect)frame withDataSource:(id<OTNumberPadDataSource>)aDataSource andDelegate:(id<OTNumberPadDelegate>)aDelegate
{
    self = [super initWithFrame:frame];
    if (self) {
        _dataSource = aDataSource;
        _delegate = aDelegate;
        
        _numberPadOKKeyString = @"\u2713"; // 'check mark' character
        _numberPadClearKeyString = @"C";
        _numberPadDeleteKeyString = @"\u232B"; // 'erase to the left' character
    }
    return self;
}

- (void)layoutSubviews
{
    if(self.padView == nil) {
        // Load number pad
        [self prepareControl];
    } else if (self.padView.superview != nil) {
        // Opening number pad; Show on screen
        [self makeContour];
        if (!self.editLabel.text) {
            self.editLabel.text = [NSString localizedStringWithFormat:@"%@",[self.dataSource currentNumberForNumberPad:self]];
        }
    }
    // Else the padView has been loaded previously, but is not currently on screen
}

- (void)prepareControl
{
    self.padView = [[UIView alloc] initWithFrame:CGRectMake(0,0, kNumberPadPadSize, kNumberPadPadSize)];
    self.padView.frame = CGRectInset(self.padView.frame, -kNumberPadInsetFrameSize, -kNumberPadInsetFrameSize);
    
    self.editLabel = [[UILabel alloc] init];
    self.editLabel.userInteractionEnabled = NO;
    self.editLabel.backgroundColor = [UIColor lightGrayColor];
    self.editLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:14];
    self.editLabel.adjustsFontSizeToFitWidth = YES;
    self.editLabel.minimumFontSize = 10;
    self.editLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    self.editLabel.textAlignment = UITextAlignmentCenter;
    self.editLabel.layer.borderColor = [UIColor grayColor].CGColor;
    self.editLabel.layer.borderWidth = 1.0f;
    
    self.zoomedButton = [OTNumberPadButton buttonWithType:UIButtonTypeCustom];
    self.zoomedButton.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:40];
    self.zoomedButton.contentVerticalAlignment = UIControlContentVerticalAlignmentTop;
    [self.zoomedButton addTarget:self action:@selector(numberKeyTapped:event:) forControlEvents:UIControlEventTouchUpInside];
    self.buttonContour = [[OTPopupView alloc] initWithBaseView:nil andPopupView:nil];
    self.buttonContour.userInteractionEnabled = NO; // Let touches fall through to underlying button
    
    self.errorState = NumberPadInputValidNumberState;
    
    [self.objectsInPad enumerateObjectsUsingBlock:^(NSArray *row, NSUInteger rowIndex, BOOL *stop) {
        __block NSUInteger myColIndex = 0;
        [row enumerateObjectsUsingBlock:^(NumberKeyBundle *bundle, NSUInteger colIndex, BOOL *stop) {
            CGRect frame = CGRectMake(kNumberPadInsetFrameSize + kNumberPadCellSeparationSize +
                                        myColIndex * (kNumberPadCellButtonSize + kNumberPadCellSeparationSize),
                                      kNumberPadInsetFrameSize + kNumberPadCellSeparationSize +
                                        rowIndex * (kNumberPadCellButtonSize + kNumberPadCellSeparationSize),
                                      ((kNumberPadCellButtonSize + kNumberPadCellSeparationSize) * bundle.keyWidth) - kNumberPadCellSeparationSize,
                                      ((kNumberPadCellButtonSize + kNumberPadCellSeparationSize) * bundle.keyHeight) - kNumberPadCellSeparationSize);
            UIView *buttonContainer = [[UIView alloc] initWithFrame:frame];
            
            OTNumberPadButton *button = [OTNumberPadButton buttonWithType:UIButtonTypeCustom];
            button.frame = buttonContainer.bounds;
            button.titleLabel.font = [UIFont fontWithName:@"Helvetica-Bold" size:18];
            [button addTarget:self action:@selector(numberKeyTapped:event:) forControlEvents:UIControlEventTouchUpInside];
            [button setTitle:bundle.keyLabel forState:UIControlStateNormal];
            
            CAGradientLayer *gradientLayer = [CAGradientLayer layer];
            gradientLayer.frame = button.layer.bounds;
            gradientLayer.colors = self.gradientColors;
            gradientLayer.locations = self.gradientLocations;
            [button.layer insertSublayer:gradientLayer below:button.titleLabel.layer];
            
            buttonContainer.layer.masksToBounds = NO;
            buttonContainer.layer.shadowColor = [UIColor blackColor].CGColor;
            buttonContainer.layer.shadowOpacity = 0.5;
            buttonContainer.layer.shadowRadius = 2.0;
            buttonContainer.layer.shadowOffset = CGSizeMake(0, 2);
            buttonContainer.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:buttonContainer.bounds cornerRadius:kButtonCornerRadius].CGPath;
            
            if (bundle.zoomKeyOnPress) {
                UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                   action:@selector(handleButtonLongPressGesture:)];
                lpgr.minimumPressDuration = 0.0;
                [button addGestureRecognizer:lpgr];
                buttonContainer.tag = NumberButtonContainerTagDisableOnErrorState;
            }
            
            if (bundle.keyBackgroundColor) {
                button.backgroundColor = bundle.keyBackgroundColor;
            } else {
                button.backgroundColor = [UIColor darkGrayColor];
            }
            
            [buttonContainer addSubview:button];
            [self.padView addSubview:buttonContainer];
            
            myColIndex++;
            if (bundle.keyWidth > 1) {
                // "Skips" spots to accomodate wider keys
                // In the case of keys with height greater than 1, there is no check to see whether it will overlap with a key in the row(s) below
                myColIndex += bundle.keyWidth-1;
            }
        }];
    }];
}

- (void)toggleDisplay
{
    if (self.padView.superview == nil) {
        UIView *rootView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
        self.transparentButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.transparentButton.backgroundColor = [UIColor clearColor];
        self.transparentButton.frame = rootView.bounds;
        self.transparentButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [rootView addSubview:self.transparentButton];
        UILongPressGestureRecognizer *touchGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTouched:)];
        touchGesture.minimumPressDuration = 0.0;
        [self.transparentButton addGestureRecognizer:touchGesture];
        [rootView addSubview:self.padView];
        [self.delegate numberPadDidAppear:self withTextEditingLabel:self.editLabel];
        [self setNeedsLayout]; // [self makeContour] gets called on layoutSubviews
    } else {
        [self removeNumberPad];
    }
}

// Only need to call this method if the indicated value changes while the number pad is on screen
- (void)updateNumberTextFieldWithNumber:(NSNumber *)number
{
    self.editLabel.text = [NSString localizedStringWithFormat:@"%@",number];
}

- (void)removeNumberPad
{
    [self dismissPad];
    [self.buttonContour removeFromSuperview];
    [self.zoomedButton removeFromSuperview];
    [self.editLabel removeFromSuperview];
    self.editLabel.text = nil; // Load text from delegate next time number pad is opened
    self.errorState = NumberPadInputValidNumberState; // Reset errorState (since we will be loading a presumably valid value next time)
    [self.transparentButton removeFromSuperview];
    [self.delegate numberPadDismissedForNumberPad:self];
}

#pragma mark - Property accessors
- (NSArray *)objectsInPad
{
    if (!_objectsInPad) {
        // Four column number pad
        // Buttons will be displayed in this order
        NSArray *stringArray = @[@[@"7",@"8",@"9",self.numberPadClearKeyString],
                                 @[@"4",@"5",@"6",self.numberPadDeleteKeyString],
                                 @[@"1",@"2",@"3",self.numberPadOKKeyString],
                                 @[@"0",self.numberPadDecimalKeyString]];
        NSMutableArray *bundleArray = [[NSMutableArray alloc] initWithCapacity:[stringArray count]];
        [stringArray enumerateObjectsUsingBlock:^(NSArray *row, NSUInteger idx, BOOL *stop) {
            NSMutableArray *rowArray = [[NSMutableArray alloc] initWithCapacity:[row count]];
            [row enumerateObjectsUsingBlock:^(NSString *string, NSUInteger colIdx, BOOL *stop) {
                NumberKeyBundle *bundle = [[NumberKeyBundle alloc] init];
                bundle.keyLabel = string;
                if ([string isEqualToString:@"0"]) {
                    bundle.keyWidth = 2;
                } else {
                    bundle.keyWidth = 1;
                }
                if ([string isEqualToString:self.numberPadOKKeyString]) {
                    bundle.keyHeight = 2;
                } else {
                    bundle.keyHeight = 1;
                }
                if ([string isEqualToString:self.numberPadClearKeyString] ||
                    [string isEqualToString:self.numberPadDeleteKeyString] ||
                    [string isEqualToString:self.numberPadOKKeyString]) {
                    bundle.zoomKeyOnPress = NO;
                } else {
                    bundle.zoomKeyOnPress = YES;
                }
                if ([string isEqualToString:self.numberPadClearKeyString]) {
                    bundle.keyBackgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.5 alpha:1.0];
                }
                if ([string isEqualToString:self.numberPadDeleteKeyString]) {
                    bundle.keyBackgroundColor = [UIColor colorWithRed:0.5 green:0.0 blue:0.0 alpha:1.0];
                }
                if ([string isEqualToString:self.numberPadOKKeyString]) {
                    bundle.keyBackgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.0 alpha:1.0];
                }
                [rowArray addObject:bundle];
            }];
            [bundleArray addObject:rowArray];
        }];
        _objectsInPad = [bundleArray copy];
    }
    return _objectsInPad;
}

- (NSString *)numberPadDecimalKeyString
{
    if (!_numberPadDecimalKeyString) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        [formatter setLocale:[NSLocale currentLocale]];
        _numberPadDecimalKeyString = [formatter decimalSeparator];
    }
    
    return _numberPadDecimalKeyString;
}

- (NSArray *)gradientColors
{
    if (!_gradientColors) {
        UIColor *clr1 = [UIColor colorWithRed:0.40 green:0.40 blue:0.40 alpha:0.3];
        UIColor *clr2 = [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:0.3];
        UIColor *clr3 = [UIColor colorWithRed:0.40 green:0.40 blue:0.40 alpha:0.3];
        _gradientColors = @[(id)clr1.CGColor, (id)clr2.CGColor, (id)clr3.CGColor];
    }
    return _gradientColors;
}

- (NSArray *)gradientLocations
{
    if (!_gradientLocations) {
        _gradientLocations = @[@0.0, @0.5, @1.0];
    }
    return _gradientLocations;
}

#pragma mark - Property setters
- (void)setErrorState:(NumberPadInputValidityState)errorState
{
    if (_errorState == errorState) {
        return;
    }
    _errorState = errorState;
    BOOL shouldEnableButtons;
    switch (errorState) {
        case NumberPadInputValidNumberState:
            self.editLabel.textColor = [UIColor blackColor];
            shouldEnableButtons = YES;
            break;
            
        case NumberPadInputValidPrefixState:
            self.editLabel.textColor = [UIColor blueColor];
            shouldEnableButtons = YES;
            break;
        
        case NumberPadInputInvalidState:
            self.editLabel.textColor = [UIColor redColor];
            shouldEnableButtons = NO;
            break;
    }
    for (UIView *container in self.padView.subviews) {
        if (container.tag == NumberButtonContainerTagDisableOnErrorState) {
            for (OTNumberPadButton *button in container.subviews) {
                button.enabled = shouldEnableButtons;
            }
        }
    }
}

#pragma mark - UIControlEvents Callbacks

- (void)numberKeyTapped:(id)sender event:(id)event
{
    NSAssert([sender isKindOfClass:[UIButton class]], @"Sender is not of type UIButton");
    UIButton *button = sender;
    NSString *string = button.titleLabel.text;
    
    NSString *newString = [self.delegate numberPadStringForNumberPad:self keyPressed:string oldText:self.editLabel.text];
    self.editLabel.text = newString;
    NumberPadInputValidityState state = NumberPadInputValidNumberState;
    
    NSNumberFormatter *formatter =  [[NSNumberFormatter alloc] init];
    NSNumber *newNumber = [formatter numberFromString:newString];
    // Do not attempt to validate if, for example, number field has been cleared
    if (newNumber) {
        state = [self.delegate isValidInput:newNumber forNumberPad:self];
        if (state == NumberPadInputValidNumberState) {
                [self.delegate numberPad:self didUpdateNumber:newNumber];
        }
    }
    self.errorState = state;
}

#pragma mark - UIGestureRecognizer Callbacks

// For invisible background button
- (void)backgroundTouched:(UILongPressGestureRecognizer *)gestureRecognizer
{
    NSAssert([gestureRecognizer.view isKindOfClass:[UIButton class]], @"Gesture recognizer is not attached to a UIButton");
    CGPoint point = [gestureRecognizer locationInView:self];
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan && !CGRectContainsPoint(self.bounds, point))  {
        [self removeNumberPad];
    }
}

// For button in number pad
- (void)handleButtonLongPressGesture:(UILongPressGestureRecognizer *)gestureRecognizer
{
    NSAssert([gestureRecognizer.view isKindOfClass:[UIButton class]], @"Gesture recognizer is not attached to a UIButton");
    UIButton *thisButton = (UIButton *)(gestureRecognizer.view);
    
    if (!thisButton.enabled) {
        return;
    }
    
    CGRect frame = CGRectMake(thisButton.frame.origin.x - (kNumberPadCellButtonSize + kNumberPadCellSeparationSize) / 4.0,
                              thisButton.frame.origin.y - (thisButton.frame.size.height + kNumberPadCellSeparationSize),
                              thisButton.frame.size.width + (kNumberPadCellButtonSize + kNumberPadCellSeparationSize) / 4.0 * 2.0,
                              thisButton.frame.size.height);
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *rootView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
        [self.zoomedButton setTitle:thisButton.titleLabel.text forState:UIControlStateNormal];
        [self.zoomedButton setFrame:[rootView convertRect:frame fromView:thisButton.superview]];
        [rootView addSubview:self.zoomedButton];
        thisButton.selected = YES;
        self.buttonContour.baseView = thisButton;
        self.buttonContour.popupView = self.zoomedButton;
        self.buttonContour.cornerRadius = kButtonCornerRadius;
        self.buttonContour.shouldSetPopupViewFrame = NO;
        [rootView insertSubview:self.buttonContour belowSubview:self.zoomedButton];
        [self.buttonContour displayPopup];
    } else if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        CGRect allowedBounds = CGRectInset(self.buttonContour.bounds, kButtonTouchInset, kButtonTouchInset);
        if (!CGRectContainsPoint(allowedBounds, [gestureRecognizer locationInView:self.buttonContour])) {
            thisButton.selected = NO;
            [self.buttonContour removeFromSuperview];
            [self.zoomedButton removeFromSuperview];
        }
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        if (thisButton.isSelected) {
            thisButton.selected = NO;
            [thisButton sendActionsForControlEvents:UIControlEventTouchUpInside];
            [self.buttonContour removeFromSuperview];
            [self.zoomedButton removeFromSuperview];
        }
    }
    [self setNeedsDisplayInRect:CGRectUnion(thisButton.frame, frame)];
}

#pragma mark -

- (void)dealloc
{
    [self removeNumberPad];
}

@end
