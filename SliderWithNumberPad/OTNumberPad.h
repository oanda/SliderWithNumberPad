//
//  OTNumberPad.h
//  SliderWithNumberPad
//
//  Created by Kevin He on 2013-02-22.
//  Copyright (c) 2013 OANDA Corp. All rights reserved.
//

#import "OTPadBase.h"

typedef NS_ENUM(NSInteger, NumberPadInputValidityState) {
    NumberPadInputValidNumberState,
    NumberPadInputValidPrefixState,
    NumberPadInputInvalidState
};

@class OTNumberPad, OTNumberPadButton;

@protocol OTNumberPadDataSource <OTPadDataSource>
- (NSNumber *)currentNumberForNumberPad:(OTNumberPad *)numberPad;
@end

@protocol OTNumberPadDelegate <OTPadDelegate>
- (void)numberPadDidAppear:(OTNumberPad *)numberPad withTextEditingLabel:(UILabel *)editLabel;
- (void)numberPad:(OTNumberPad *)numberPad didUpdateNumber:(NSNumber *)number;
- (void)numberPadDismissedForNumberPad:(OTNumberPad *)numberPad;
- (NumberPadInputValidityState)isValidInput:(NSNumber *)number forNumberPad:(OTNumberPad *)numberPad;
- (NSString *)numberPadStringForNumberPad:(OTNumberPad *)numberPad keyPressed:(NSString *)keyString oldText:(NSString *)oldString;
@end

@interface NumberKeyBundle : NSObject
@property (nonatomic, strong) NSString *keyLabel;
@property (nonatomic, strong) UIColor *keyBackgroundColor;
@property (nonatomic, assign) NSInteger keyWidth;
@property (nonatomic, assign) NSInteger keyHeight;
@property (nonatomic, assign) BOOL zoomKeyOnPress;
@end

@interface OTNumberPad : OTPadBase
@property (nonatomic, weak) id<OTNumberPadDataSource> dataSource;
@property (nonatomic, weak) id<OTNumberPadDelegate> delegate;
@property (nonatomic, strong) NSString *numberPadOKKeyString;
@property (nonatomic, strong) NSString *numberPadClearKeyString;
@property (nonatomic, strong) NSString *numberPadDecimalKeyString;
@property (nonatomic, strong) NSString *numberPadDeleteKeyString;

- (id)initWithFrame:(CGRect)frame withDataSource:(id<OTNumberPadDataSource>)aDataSource andDelegate:(id<OTNumberPadDelegate>)aDelegate;
- (void)toggleDisplay;
- (void)updateNumberTextFieldWithNumber:(NSNumber *)number;

@end
