//
//  OTMainViewController.m
//  SliderWithNumberPad
//
//  Created by Kevin He on 2013-04-01.
//  Copyright (c) 2013 OANDA Corp. All rights reserved.
//

#import "OTMainViewController.h"

@interface OTMainViewController ()
- (BOOL)isPopupOnScreen:(UIView *)popup;
- (void)moveSliderToValue:(NSNumber*)value animated:(BOOL)animated;
@property (nonatomic, strong) IBOutlet UIView *container;
@property (nonatomic, strong) IBOutlet UILabel *valueDisplay;
@property (nonatomic, strong) OTValueSlider *slider;
@property (nonatomic, strong) OTNumberPad *numberPad;
@property (nonatomic, strong) NSNumber *currentNumber;
@property (nonatomic, strong) NSArray *availableOptions;
@property (nonatomic, strong) NSString *numberPadDecimalKeyString;
@end

@implementation OTMainViewController

#pragma mark - Constants
static NSInteger const kSliderInsetWidth = 10;

#pragma mark - View Lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Possible values for the slider - this does not affect input to the number pad
    NSMutableArray *numbersArray = [[NSMutableArray alloc] init];
    for (NSUInteger i = 1; i <= 100; i++) {
        [numbersArray addObject:@(i)];
    }
    self.availableOptions = [NSArray arrayWithArray:numbersArray];
    
    // Default slider value
    self.currentNumber = @50;
    
    // Init numberPad and slider
    self.numberPad = [[OTNumberPad alloc] initWithFrame:CGRectZero withDataSource:self andDelegate:self];
    self.numberPad.exclusiveTouch = YES;
    [self.container addSubview:self.numberPad];
    
    self.slider = [[OTValueSlider alloc] initWithDelegate:self];
    [self.container addSubview:self.slider];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // Inset the slider from the container
    // The thumb is designed to extend outside the slider bounds when dragged to either end
    self.slider.frame = CGRectMake(self.container.bounds.origin.x+kSliderInsetWidth,
                                   self.container.bounds.origin.y,
                                   self.container.bounds.size.width-2*kSliderInsetWidth,
                                   self.container.bounds.size.height);
    
    // This will be used as the "baseView" area for OTPopupView
    self.numberPad.frame = CGRectMake(self.container.bounds.origin.x,
                                      self.container.bounds.origin.y+self.container.bounds.size.height/2.0,
                                      self.container.bounds.size.width,
                                      self.container.bounds.size.height/2.0);
    
    // Set slider to current value
    [self  moveSliderToValue:self.currentNumber animated:NO];
}

#pragma mark - Property setters
- (void)setCurrentNumber:(NSNumber *)currentNumber
{
    // Set the currentNumber property and update the displayed label text
    _currentNumber = currentNumber;
    self.valueDisplay.text = [currentNumber stringValue];
}

#pragma mark - Utility methods
- (BOOL)isPopupOnScreen:(UIView *)popup
{
    // Determine if the given UIView is a "popup", i.e. when its superview is the rootView
    UIView *rootView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
    if (popup.superview == rootView) {
        return YES;
    } else {
        return NO;
    }
}

- (void)moveSliderToValue:(NSNumber*)value animated:(BOOL)animated
{
    // Find first value in availableOptions that is greater than our number, then subtract 1 from index
    // If value is beyond the maximum shown on slider, set slider to maximum position; vice-versa for minimum
    NSUInteger seekIndex = [self.availableOptions indexOfObjectPassingTest:^BOOL(NSNumber *obj, NSUInteger idx, BOOL *stop) {
        if( [obj doubleValue] > [value doubleValue] ){
            *stop = YES;
            return YES;
        }else{
            return NO;
        }
    }];
    
    if (seekIndex == NSNotFound) {
        seekIndex = [self.availableOptions count];
    } else if (seekIndex > 0) {
        seekIndex--;
    }
    
    [self.slider setPosition:@((double)seekIndex / (double)[self.availableOptions count]) andTitle:[value stringValue] animated:animated];
    self.currentNumber = value;
}

#pragma mark - OTNumberPadDataSource
- (NSNumber *)currentNumberForNumberPad:(OTNumberPad *)numberPad
{
    if (self.numberPad == numberPad) {
        // Returns the current number - used when number pad is first opened
        return self.currentNumber;
    }
    return nil;
}

#pragma mark - OTNumberPadDelegate
- (void)numberPadDidAppear:(OTNumberPad *)numberPad withTextEditingLabel:(UILabel *)editLabel
{
    if (self.numberPad == numberPad) {
        // Overlay the edit label on top of the slider thumb and put the slider view
        // as a subview of rootView to allow user interaction in the full popup area
        [self.slider overlayEditViewOnButton:editLabel];
        UIView *rootView = [UIApplication sharedApplication].keyWindow.rootViewController.view;
        self.slider.frame = [rootView convertRect:self.slider.frame fromView:self.slider.superview];
        [rootView addSubview:self.slider];
    }
}

- (void)numberPad:(OTNumberPad *)numberPad didUpdateNumber:(NSNumber *)number
{
    if (self.numberPad == numberPad) {
        // When the number pad updates the number, move the slider
        [self moveSliderToValue:number animated:YES];
    }
}

- (NumberPadInputValidityState)isValidInput:(NSNumber *)number forNumberPad:(OTNumberPad *)numberPad
{
    // Validate input as needed.
    
    return NumberPadInputValidNumberState;
}

- (NSString *)numberPadStringForNumberPad:(OTNumberPad *)numberPad keyPressed:(NSString *)keyString oldText:(NSString *)oldString
{
    NSNumberFormatter *formatter =  [[NSNumberFormatter alloc] init];
    NSNumber *keyNumber = [formatter numberFromString:keyString];
    NSString *newString;
    if (keyNumber) {
        // If the key pressed is a number, append it to the existing input
        newString = [NSString stringWithFormat:@"%@%@",oldString,keyString];
    } else if ([keyString isEqualToString:numberPad.numberPadDecimalKeyString]) {
        // Test to ensure we still have a valid number (i.e. only one decimal point allowed)
        NSString *thisString = [NSString stringWithFormat:@"%@%@",oldString,keyString];
        NSNumber *thisNumber = [formatter numberFromString:thisString];
        if (thisNumber) {
            newString = thisString;
        } else if ([thisString isEqualToString:numberPad.numberPadDecimalKeyString]) {
            // Try to be helpful and add the 0 if decimal point is the first key pressed
            newString = [NSString stringWithFormat:@"0%@",thisString];
        } else {
            // New string is not a number, and not starting a new number
            newString = oldString;
        }
    } else if ([keyString isEqualToString:numberPad.numberPadClearKeyString]) {
        // Clear the text field
        newString = @"";
    } else if ([keyString isEqualToString:numberPad.numberPadOKKeyString]) {
        // Dismiss the number pad
        [numberPad toggleDisplay];
    } else if ([keyString isEqualToString:numberPad.numberPadDeleteKeyString]) {
        // Delete one char
        NSUInteger stringLength = [oldString length];
        if (stringLength >= 1) {
            newString = [oldString substringToIndex:stringLength-1];
        } else {
            // If the old string is empty, make the new string empty as well
            newString = oldString;
        }
    } else {
        NSAssert(NO, @"Unhandled keyString in OTChartConfigPanel");
        // In production, simply clear the field
        newString = @"";
    }
    
    return newString;
}

- (void)numberPadDismissedForNumberPad:(OTNumberPad *)numberPad
{
    if (self.numberPad == numberPad) {
        // Put the slider back into the container
        self.slider.frame = [self.container convertRect:self.slider.frame fromView:self.slider.superview];
        [self.container addSubview:self.slider];
    }
}

#pragma mark - OTValueSliderDelegate
- (void)valueSliderDidChange:(OTValueSlider *)valueSlider toValue:(float)value changeType:(ValueButtonChangeType)type
{
    if (self.slider == valueSlider) {
        int seekIndex = value * ([self.availableOptions count]-1);
        self.currentNumber = self.availableOptions[seekIndex];
        // Do not set slider position here as this gets called when slider position changes
        [self.slider setPosition:nil andTitle:[self.availableOptions[seekIndex] stringValue] animated:YES];
        if (type == ValueButtonChangeSliderWasTouched && [self isPopupOnScreen:self.slider]) {
            [self.numberPad toggleDisplay];
        }
    }
}

- (void)valueSliderValueButtonPressed:(OTValueSlider *)valueSlider forEvent:(id)event
{
    if (self.slider == valueSlider) {
        [self.numberPad toggleDisplay];
    }
}

- (void)valueSliderDidFinishChanges:(OTValueSlider *)valueSlider
{
    // Call numberPad updateNumberTextFieldWithNumber: here if slider can be dragged while number pad is on screen
}

@end
