//
//  ModernView.h
//  42x
//
//  Created by Byron Foster on 10/24/12.
//
//

#import <UIKit/UIKit.h>
#include "CalcViewController.h"


@interface ButtonInfo : NSObject
{
	@public
	int num;
	CGRect rect;
	NSString *shiftLabel;
	NSString *label;
	bool isMenu;
	int fontSize;
}

@end

@interface ModernView : UIView
{
	NSArray *buttons;
	IBOutlet CalcViewController* calcViewController;
	float baseFontSize;
}
- (void)calcKeyLayout;
@end
