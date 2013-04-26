//
//  OTMainViewController.h
//  SliderWithNumberPad
//
//  Created by Kevin He on 2013-04-01.
//  Copyright (c) 2013 OANDA Corp. All rights reserved.
//

#import "OTNumberPad.h"
#import "OTValueSlider.h"

@interface OTMainViewController : UIViewController<OTValueSliderDelegate,OTNumberPadDataSource,OTNumberPadDelegate>

@end
