SliderWithNumberPad
===================

A slider control that shows the input value directly on the slider thumb and has a popup number pad for precision input. Each component can be used separately as desired.

Description
-----------
The provided project files should illustrate usage. In particular, `OTMainViewController.m` demonstrates the data sources and delegates to implement, and the method calls to invoke. These are further described in the sections below.

This project has been tested with Xcode 4.6.1 and iOS 6.1.

To use this control in your own project, include the following files: `OTValueSlider.[hm]`, `OTNumberPad.[hm]`, `OTPopupView.[hm]`, and `OTPadBase.[hm]`. `OTValueSlider` and `OTNumberPad` can be used independent of each other if desired. `OTPopupView` can also be used by itself, but it is a dependency of `OTValueSlider` and `OTNumberPad`. `OTPadBase` is the superclass of `OTNumberPad`.

### OTValueSlider ###
OTValueSlider is a horizontal slider control which shows the value directly on the thumb.

When the user press down on the thumb, a popup indicating the current value is shown. This popup will follow the thumb movement.

In the demo project, the slider has a draggable range of 1 to 100. By using the number pad, the user can set any arbitrary value.

The number pad can be opened by:
* Tapping on the thumb
* While dragging or holding down to the thumb, flicking upwards into the popup number display

The number pad can then be closed by:
* Tapping on the thumb again
* Dragging the thumb
* Tapping anywhere outside the popup

#### Implementation ####
Implement the `OTValueSliderDelegate` protocol in your code:
```objective-c
@protocol OTValueSliderDelegate <NSObject>
- (void)valueSliderDidChange:(OTValueSlider *)valueSlider toValue:(float)value changeType:(ValueButtonChangeType)type;
- (void)valueSliderValueButtonPressed:(OTValueSlider *)valueSlider forEvent:(id)event;
- (void)valueSliderDidFinishChanges:(OTValueSlider *)valueSlider;
@end
```

`ValueButtonChangeType` is defined as follows:
```objective-c
typedef NS_ENUM(NSUInteger, ValueButtonChangeType) {
    ValueButtonChangeProgrammatic,
    ValueButtonChangeSliderWasTouched
};
```
This allows for the delegate to perform different actions depending on how the change was triggered.

Call `initWithDelegate:` to initialize an OTValueSlider.

To change the slider position programmatically, call `setPosition:andTitle:animated:`. The `number` and `title` arguments may be `nil` if you do not want to set one of the values. The `animated` argument specifies whether the transition should be animated.

To overlay an UIView in the slider thumb (for example, the number pad edit label), call `overlayEditViewOnButton:`.

Call `removePopup` to ensure the popup (which is attached to the `rootViewController`'s view) is removed when the slider's parent view disappears.

### OTNumberPad ###
OTNumberPad is a popup number pad which can be placed anywhere on the screen.

The text display label can be positioned separately. In the demo project, it is placed inside the slider thumb.

The keys are customizable for label, background color, width, height, and whether to zoom on touch. (See the interface for `NumberKeyBundle`) By default, the number keys will zoom on touch, and the function keys are colored.

The decimal key is automatically localized for the user's current locale.

If the user taps the thumb or begins to drag the slider, the number pad is closed.

By default, the number keys will **append** to the current value. The **C** button clears the input field, but does not update the **Current Value** field. This is useful when sending the value to an object that requires a numeric state.

#### Implementation ####
Implement the `OTNumberPadDataSource` and the `OTNumberPadDelegate` protocols in your code:
```objective-c
@protocol OTNumberPadDataSource <OTPadDataSource>
- (NSNumber *)currentNumberForNumberPad:(OTNumberPad *)numberPad;
@end
```
```objective-c
@protocol OTNumberPadDelegate <OTPadDelegate>
- (void)numberPadDidAppear:(OTNumberPad *)numberPad withTextEditingLabel:(UILabel *)editLabel;
- (void)numberPad:(OTNumberPad *)numberPad didUpdateNumber:(NSNumber *)number;
- (void)numberPadDismissedForNumberPad:(OTNumberPad *)numberPad;
- (NumberPadInputValidityState)isValidInput:(NSNumber *)number forNumberPad:(OTNumberPad *)numberPad;
- (NSString *)numberPadStringForNumberPad:(OTNumberPad *)numberPad keyPressed:(NSString *)keyString oldText:(NSString *)oldString;
@end
```

`NumberPadInputValidityState` is defined as follows:
```objective-c
typedef NS_ENUM(NSInteger, NumberPadInputValidityState) {
    NumberPadInputValidNumberState,
    NumberPadInputValidPrefixState,
    NumberPadInputInvalidState
};
```
The delegate should return one of the states for any given number. `NumberPadInputValidNumberState` is the default "valid" state; `NumberPadInputValidPrefixState` should be returned when a number is not valid by itself, but could become a valid value as more digits are entered; and `NumberPadInputInvalidState` should be returned when the number is invalid, with no possibility of a valid value being formed after more digits are entered.

Call `initWithFrame:withDataSource:andDelegate:` to initialize an OTNumberPad. The frame is used as the 'base' area from which the popup number pad is positioned (in this case, the slider area).

To show and hide the number pad, call `toggleDisplay`.

To update the number edit label, call `updateNumberTextFieldWithNumber:`.

The `NumberKeyBundle` interface defines each "button" object to be used in the number pad:
```objective-c
@interface NumberKeyBundle : NSObject
@property (nonatomic, strong) NSString *keyLabel;
@property (nonatomic, strong) UIColor *keyBackgroundColor;
@property (nonatomic, assign) NSInteger keyWidth;
@property (nonatomic, assign) NSInteger keyHeight;
@property (nonatomic, assign) BOOL zoomKeyOnPress;
@end
```
`keyLabel` will be used as the button text label. `keyWidth` and `keyHeight` are required (ordinarily, set to `1`). The other properties are optional, and can be set if desired. By default, if no `keyBackgroundColor` is specified, `[UIColor darkGrayColor]` is used.

To customize the number pad popup size, or the button size or positioning inside the popup, change these constants at the top of `OTNumberPad.m`:
```objective-c
static NSInteger const kNumberPadPadSize = 201;
static NSInteger const kNumberPadCellButtonSize = 44;
static NSInteger const kNumberPadCellSeparationSize = 5;
static NSInteger const kNumberPadInsetFrameSize = 5;
static float const kButtonCornerRadius = 8.0f;
static float const kButtonTouchInset = -10.0f;
```

To customize the available buttons, simply update the `objectsInPad` property accessor at line 259 in `OTNumberPad.m`.

### OTPopupView ###
OTPopupView positions a popup and draws the necessary background gradient inside a contour around the popup and another view.

Here, it is used to automatically position the number pad in a different orientations, and to draw a contour around the slider and the number pad. It is also used to position the "zoomed" button when a number is pressed.

#### Implementation ####
The interface for `OTPopupView` is very straightforward:
```objective-c
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
```

Call `initWithBaseView:andPopupView:` to initialize an OTPopupView. The `baseView` should be an existing view on screen, and the `popupView` will be positioned from the `baseView` based on the `popupCenterTranslationFromBase` property. By default, the popup will be positioned to the top, left, or right of the base view as needed. Override the `popupCenterTranslationFromBase` property to set a custom popup position relative to the base view.
Similarly, each of the other properties can be set to override the defaults. None of the properties _need_ to be manually set if the default appearance is desired.

_After_ setting up all the properties, call `displayPopup` to show the popup.

### OTPadBase ###
OTPadBase is the superclass to OTNumberPad. It can be subclassed to make similar popup objects. Set the `padView` and `contour` properties to the desired popup UIView and the background OTPopupView, respectively. Then call `makeContour` to position and show the popup and `dismissPad` to hide.

Requirements
------------
* It is necessary to link the QuartzCore framework.
* These components use ARC. If you are not using ARC, set the `-fobjc-arc` compiler flag on these files.
* NSDictionary and NSArray subscripting is used. This requires Xcode 4.5 and iOS 6.0 or later SDK, but is deployable back to iOS 5.
* It is assumed that assertions will be disabled in the release build. If you do not do so in your project, you may wish to remove the NSAssert statements to avoid unnecessary crashes.

Screenshots
-----------
<img src="screenshots/default.png?raw=true" alt="Default view" title="Default view" height="568" width="320" />
<img src="screenshots/thumbpressed.png?raw=true" alt="Thumb dragged" title="Thumb dragged" height="568" width="320" />
<img src="screenshots/numberpad.png?raw=true" alt="Number pad opened" title="Number pad opened" height="568" width="320" />
<img src="screenshots/numberpressed.png?raw=true" alt="Number pressed" title="Number pressed" height="568" width="320" />
