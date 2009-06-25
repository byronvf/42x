//
//  MenuView.h
//  Free42
//
//  Created by Byron Foster on 5/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class CalcViewController;
@interface MenuView : UIView {
	IBOutlet CalcViewController* calcViewController;
}
@property (nonatomic, retain) CalcViewController* calcViewController;
@end
