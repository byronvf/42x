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
#import "ConfigViewController.h"

@class PrintViewController;
@class CalcViewController;
@class ServerViewController;

@interface NavViewController : UINavigationController <UINavigationControllerDelegate> {
	
	IBOutlet ConfigViewController* configViewController;
	IBOutlet PrintViewController* printViewController;
	IBOutlet ServerViewController* serverViewController;
	IBOutlet CalcViewController* calcViewController;
}

@property (nonatomic, retain) ConfigViewController* configViewController;
@property (nonatomic, retain) PrintViewController* printViewController;
@property (nonatomic, retain) ServerViewController* serverViewController;
@property (nonatomic, retain) CalcViewController* calcViewController;

- (void)switchToView:(UIViewController*) viewCtrl;
- (void)switchToPrintView;
- (void)switchToServerView;

@end
