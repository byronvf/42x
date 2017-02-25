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
#include "BlitterView.h"
#include "MenuView.h"


@class NavViewController;

extern int callKeydownAgain;
extern bool reval;

@interface CalcViewController : UIViewController {
    IBOutlet UILabel *screen;
    IBOutlet UIButton *b01;
    IBOutlet UIButton *b02;
    IBOutlet UIButton *b03;
    IBOutlet UIButton *b04;
    IBOutlet UIButton *b05;
    IBOutlet UIButton *b06;
    IBOutlet UIButton *b07;
    IBOutlet UIButton *b08;
    IBOutlet UIButton *b09;
    IBOutlet UIButton *b10;
    IBOutlet UIButton *b11;
    IBOutlet UIButton *b12;
    IBOutlet UIButton *b13;
    IBOutlet UIButton *b14;
    IBOutlet UIButton *b15;
    IBOutlet UIButton *b16;
    IBOutlet UIButton *b17;
    IBOutlet UIButton *b18;
    IBOutlet UIButton *b19;
    IBOutlet UIButton *b20;
    IBOutlet UIButton *b21;
    IBOutlet UIButton *b22;
    IBOutlet UIButton *b23;
    IBOutlet UIButton *b24;
    IBOutlet UIButton *b25;
    IBOutlet UIButton *b26;
    IBOutlet UIButton *b27;
    IBOutlet UIButton *b28;
    IBOutlet UIButton *b29;
    IBOutlet UIButton *b30;
    IBOutlet UIButton *b31;
    IBOutlet UIButton *b32;
    IBOutlet UIButton *b33;
    IBOutlet UIButton *b34;
    IBOutlet UIButton *b35;
    IBOutlet UIButton *b36;
    IBOutlet UIButton *b37;
	
	BOOL alphaMenuActive;
	BOOL keyboardToggleActive;
	
	BOOL shutdown;
	
	IBOutlet UITextField* textEntryField;
	
	IBOutlet BlitterView *blitterView;
	IBOutlet UIImageView *updnGlowView;
	IBOutlet NavViewController* navViewController;
	IBOutlet MenuView *menuView;
	IBOutlet UIImageView *fixedMenuView;
	IBOutlet UIImageView *blankButtons;	
	IBOutlet UIView *baseSoftMenuView;	
	IBOutlet UIView *softMenu;	
	IBOutlet PrintViewController* printController;
	
	const char* displayBuff;
	
	BOOL keyPressed;
	BOOL menuShowing;
}

@property BOOL keyPressed;
@property BOOL shutdown;
@property (nonatomic, strong) BlitterView* blitterView;
@property (nonatomic, strong) UIImageView* fixedMenuView;
@property (nonatomic, strong) UIImageView* updnGlowView;
@property (nonatomic, strong) UIImageView* blankButtons;
@property (nonatomic, strong) UIView* baseSoftMenuView;
@property (nonatomic, strong) UIView* softMenu;
@property (nonatomic, strong) MenuView *menuView;
@property (nonatomic, strong) NavViewController* navViewController;
@property (nonatomic, strong) PrintViewController* printController;

@property (nonatomic, strong) UILabel *screen;
@property (nonatomic, strong) UIButton *b01;
@property (nonatomic, strong) UIButton *b02;
@property (nonatomic, strong) UIButton *b03;
@property (nonatomic, strong) UIButton *b04;
@property (nonatomic, strong) UIButton *b05;
@property (nonatomic, strong) UIButton *b06;
@property (nonatomic, strong) UIButton *b07;
@property (nonatomic, strong) UIButton *b08;
@property (nonatomic, strong) UIButton *b09;
@property (nonatomic, strong) UIButton *b10;
@property (nonatomic, strong) UIButton *b11;
@property (nonatomic, strong) UIButton *b12;
@property (nonatomic, strong) UIButton *b13;
@property (nonatomic, strong) UIButton *b14;
@property (nonatomic, strong) UIButton *b15;
@property (nonatomic, strong) UIButton *b16;
@property (nonatomic, strong) UIButton *b17;
@property (nonatomic, strong) UIButton *b18;
@property (nonatomic, strong) UIButton *b19;
@property (nonatomic, strong) UIButton *b20;
@property (nonatomic, strong) UIButton *b21;
@property (nonatomic, strong) UIButton *b22;
@property (nonatomic, strong) UIButton *b23;
@property (nonatomic, strong) UIButton *b24;
@property (nonatomic, strong) UIButton *b25;
@property (nonatomic, strong) UIButton *b26;
@property (nonatomic, strong) UIButton *b27;
@property (nonatomic, strong) UIButton *b28;
@property (nonatomic, strong) UIButton *b29;
@property (nonatomic, strong) UIButton *b30;
@property (nonatomic, strong) UIButton *b31;
@property (nonatomic, strong) UIButton *b32;
@property (nonatomic, strong) UIButton *b33;
@property (nonatomic, strong) UIButton *b34;
@property (nonatomic, strong) UIButton *b35;
@property (nonatomic, strong) UIButton *b36;
@property (nonatomic, strong) UIButton *b37;
@property const char* displayBuff;
@property BOOL menuShowing;

- (IBAction)buttonUp:(UIButton*)sender;
- (IBAction)buttonDown:(UIButton*)sender;
- (void) keyDown: (int) keynum;
- (void) keyUp;
- (void) handlePopupKeyboard:(BOOL)toggle;
- (void) singleLCD;
- (void) doubleLCD;
- (void) fullLCD;
- (void) resetLCD;
- (void) testUpdateLastX: (BOOL) force;
- (void) testUpdateDispFlags;
- (void) runUpdate;
- (void) testShutdown;
- (void) doMenuDisplay: (bool) forceHide menuUpdate:(bool) update;
- (void) hideButtonNum: (int) num hidden:(BOOL)hidden;
- (void) keepRunning;
@end

