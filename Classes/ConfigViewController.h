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

#define CONFIG_PRINT_BUF @"printBuf"
#define CONFIG_KEY_CLICK_ON @"keyClickOn"
#define CONFIG_BEEP_ON @"beepOn"
#define CONFIG_KEYBOARD @"keyboardOn"
#define CONFIG_AUTO_PRINT_ON @"autoPrintOn"
#define CONFIG_MENU_KEYS_BUF @"menuKeys"
#define CONFIG_DISP_ROWS @"dispRows"
#define CONFIG_PERSIST_VERSION @"persistVersion"
#define CONFIG_SHOW_LASTX @"showLastX"
#define CONFIG_PRLCD @"prlcd"
#define CONFIG_DROP_FIRST_CLICK @"dropFirstClick"
#define CONFIG_SHOW_FLAGS @"showFlags"

@interface ConfigViewController : UITableViewController {
	UISwitch* clickSoundSwitch;
	UISwitch* beepSoundSwitch;
	UISwitch* keyboardSwitch;
	UISwitch* bigStackSwitch;
	UISwitch* menuKeysSwitch;
	UISwitch* lastXSwitch;
	UISwitch* autoPrintSwitch;
	UISwitch* RPLEnterSwitch;
	UISwitch* dropSwitch;
	UISwitch* flagsSwitch;
	UISwitch* singMatrixSwitch;
    UISwitch* matrixOutOfRangeSwitch;
	
	UIButton* gotoServerButton;
	UIButton* aboutButton;
	
	IBOutlet NavViewController* navViewController;
}

@property (nonatomic, strong) UISwitch* clickSoundSwitch;
@property (nonatomic, strong) UISwitch* autoPrintSwitch;
@property (nonatomic, strong) UISwitch* lastXSwitch;
@property (nonatomic, strong) UISwitch* menuKeysSwitch;
@property (nonatomic, strong) UISwitch* beepSoundSwitch;
@property (nonatomic, strong) UISwitch* keyboardSwitch;
@property (nonatomic, strong) UISwitch* bigStackSwitch;
@property (nonatomic, strong) UISwitch* RPLEnterSwitch;
@property (nonatomic, strong) UISwitch* dropSwitch;
@property (nonatomic, strong) UISwitch* flagsSwitch;
@property (nonatomic, strong) UISwitch* singMatrixSwitch;
@property (nonatomic, strong) UISwitch* matrixOutOfRangeSwitch;
@property (nonatomic, strong) UIButton* gotoServerButton;
@property (nonatomic, strong) UIButton* aboutButton;
@property (nonatomic, strong) NavViewController* navViewController;

- (UISwitch*)makeSwitch;
- (void)switchChange:(UISwitch*)sender;

@end
