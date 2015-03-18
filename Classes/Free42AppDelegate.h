// Copyright Base2 Corporation 2009
//
// This file is part of 42s.
//
// 42s is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// 42s is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with 42s.  If not, see <http://www.gnu.org/licenses/>.

#import <UIKit/UIKit.h>
#import "CalcViewController.h"
#import "NavViewController.h"


#define PRINT_FILE_NAME @"/Documents/print.txt"

@class CalcViewController;

// Set this to true when we are in sleep mode
extern BOOL isSleeping;

@interface Free42AppDelegate : NSObject <UIApplicationDelegate> {
	IBOutlet UIWindow *window;
	IBOutlet NavViewController *navViewController;

	// these are only used for the iPad
	IBOutlet CalcViewController *calcCtrl;
	IBOutlet UIView *keyPadHolderView;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) NavViewController *navViewController;
@property (nonatomic, retain) CalcViewController *calcCtrl;
@property (nonatomic, retain) UIView *keyPadHolderView;

- (void)initializeIpad;
- (void)initializeIphone;

@end


extern BOOL free42init;

static BOOL isPad() {
#ifdef UI_USER_INTERFACE_IDIOM
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#else
    return NO;
#endif
}
