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
#import <AudioToolbox/AudioServices.h>

@class NavViewController;

@interface ConfigViewController : UITableViewController {
	UISwitch* clickSoundSwitch;
	UISwitch* beepSoundSwitch;
	UISwitch* keyboardSwitch;
	UISwitch* bigStackSwitch;
	UISwitch* menuKeysSwitch;
	UISwitch* lastXSwitch;
	UISwitch* statusBarSwitch;
	
	UIButton* gotoServerButton;
	UIButton* aboutButton;
	
	IBOutlet NavViewController* navViewController;
}

@property (nonatomic, retain) UISwitch* clickSoundSwitch;
@property (nonatomic, retain) UISwitch* statusBarSwitch;
@property (nonatomic, retain) UISwitch* lastXSwitch;
@property (nonatomic, retain) UISwitch* menuKeysSwitch;
@property (nonatomic, retain) UISwitch* beepSoundSwitch;
@property (nonatomic, retain) UISwitch* keyboardSwitch;
@property (nonatomic, retain) UISwitch* bigStackSwitch;
@property (nonatomic, retain) UIButton* gotoServerButton;
@property (nonatomic, retain) UIButton* aboutButton;
@property (nonatomic, retain) NavViewController* navViewController;

- (UISwitch*)makeSwitch;
- (void)switchChange:(UISwitch*)sender;

@end
