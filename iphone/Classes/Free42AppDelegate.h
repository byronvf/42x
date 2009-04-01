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

extern int cpuCount;

@interface Free42AppDelegate : NSObject <UIApplicationDelegate> {
	IBOutlet UIWindow *window;
	IBOutlet CalcViewController *viewController;
	IBOutlet NavViewController *navViewController;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) CalcViewController *viewController;
@property (nonatomic, retain) NavViewController *navViewController;

@end

