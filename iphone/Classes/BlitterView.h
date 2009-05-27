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

@class CalcViewController;
@class NavViewController;
@class BlitterView;

extern BlitterView *blitterView;
extern int cpuCount;

@interface BlitterView : UIView {

	CGImageRef imgFlagUpDown;
	CGImageRef imgFlagShift;
	CGImageRef imgFlagGrad;
	CGImageRef imgFlagRad;
	CGImageRef imgFlagRun;
	CGImageRef imgFlagPrint;
	NavViewController* navViewController;
	
	UIButton* shiftButton;
	
	// keep track of swipe on screen for switching to the print view
	CGPoint firstTouch;
	BOOL highlight;
	CGRect xRowHighlight;
	CGRect baseRowHighlight;
	BOOL cutPaste;
	
	CalcViewController* calcViewController;
}

@property CGImageRef imgFlagUpDown;
@property CGImageRef imgFlagShift;
@property CGImageRef imgFlagGrad;
@property CGImageRef imgFlagRad;
@property CGImageRef imgFlagRun;
@property CGImageRef imgFlagPrint;
@property BOOL highlight;
@property BOOL cutPaste;
@property (nonatomic, retain) NavViewController* navViewController;
@property (nonatomic, retain) CalcViewController* calcViewController;
@property (nonatomic, retain) UIButton* shiftButton;

- (void) drawAnnunciators;
- (void) annuncNeedsDisplay;
- (void) twoLineDisp;
- (void) fourLineDisp;
- (void) shouldCutPaste;

@end
