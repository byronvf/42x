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
	
	IBOutlet UITextField* textEntryField;
	
	IBOutlet BlitterView *blitterView;
	IBOutlet UIImageView *bgImageView;	
	IBOutlet NavViewController* navViewController;
	IBOutlet MenuView *menuView;
	IBOutlet UIImageView *blankButtonsView;
	
	const char* displayBuff;
	
	BOOL keyPressed;
}

@property BOOL keyPressed;
@property (nonatomic, retain) BlitterView* blitterView;
@property (nonatomic, retain) UIImageView* bgImageView;
@property (nonatomic, retain) UIImageView* blankButtonsView;
@property (nonatomic, retain) MenuView *menuView;
@property (nonatomic, retain) NavViewController* navViewController;
@property (nonatomic, retain) UILabel *screen;
@property (nonatomic, retain) UIButton *b01;
@property (nonatomic, retain) UIButton *b02;
@property (nonatomic, retain) UIButton *b03;
@property (nonatomic, retain) UIButton *b04;
@property (nonatomic, retain) UIButton *b05;
@property (nonatomic, retain) UIButton *b06;
@property (nonatomic, retain) UIButton *b07;
@property (nonatomic, retain) UIButton *b08;
@property (nonatomic, retain) UIButton *b09;
@property (nonatomic, retain) UIButton *b10;
@property (nonatomic, retain) UIButton *b11;
@property (nonatomic, retain) UIButton *b12;
@property (nonatomic, retain) UIButton *b13;
@property (nonatomic, retain) UIButton *b14;
@property (nonatomic, retain) UIButton *b15;
@property (nonatomic, retain) UIButton *b16;
@property (nonatomic, retain) UIButton *b17;
@property (nonatomic, retain) UIButton *b18;
@property (nonatomic, retain) UIButton *b19;
@property (nonatomic, retain) UIButton *b20;
@property (nonatomic, retain) UIButton *b21;
@property (nonatomic, retain) UIButton *b22;
@property (nonatomic, retain) UIButton *b23;
@property (nonatomic, retain) UIButton *b24;
@property (nonatomic, retain) UIButton *b25;
@property (nonatomic, retain) UIButton *b26;
@property (nonatomic, retain) UIButton *b27;
@property (nonatomic, retain) UIButton *b28;
@property (nonatomic, retain) UIButton *b29;
@property (nonatomic, retain) UIButton *b30;
@property (nonatomic, retain) UIButton *b31;
@property (nonatomic, retain) UIButton *b32;
@property (nonatomic, retain) UIButton *b33;
@property (nonatomic, retain) UIButton *b34;
@property (nonatomic, retain) UIButton *b35;
@property (nonatomic, retain) UIButton *b36;
@property (nonatomic, retain) UIButton *b37;
@property const char* displayBuff;

- (IBAction)buttonUp:(UIButton*)sender;
- (IBAction)buttonDown:(UIButton*)sender;
- (void)handlePopupKeyboard:(BOOL)toggle;
- (void) twoLineDisp;
- (void) fourLineDisp;
- (void)testUpdateLastX;
	
@end

