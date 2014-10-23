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
}

@end

@interface ModernView : UIView
{
	NSArray *buttons;
	IBOutlet CalcViewController* calcViewController;
}

- (ButtonInfo*) makeButton: (int)col  row:(int)row doubleSize:(bool)ds numCols:(int)numCols
				   numRows:(int)numRows pixelWidth:(int)pwidth pixelHeight:(int)pheight
				   bNum:(int)bnum;

@end
