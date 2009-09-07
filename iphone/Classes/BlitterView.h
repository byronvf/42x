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

extern int cpuCount;

// size 21 gives us a max size of 20 characters (plus the null terminator) this
// is the same max size of the standard stack display, so we can show any number
// in last x as the stack would display it.
#define LASTXBUF_SIZE 21
extern char lastxbuf[LASTXBUF_SIZE];

@interface BlitterView : UIView {
	
	// keep track of swipe on screen for switching to the print view	
	CGPoint firstTouch;
	BOOL highlight;
	CGRect xRowHighlight;
	CGRect baseRowHighlight;
	BOOL cutPaste;
	BOOL selectAll;
	int statusBarOffset;
	
	IBOutlet CalcViewController* calcViewController;
}

@property BOOL highlight;
@property BOOL cutPaste;
@property BOOL selectAll;
@property int statusBarOffset; // Offset if the status bar is being used

@property (nonatomic, retain) CalcViewController* calcViewController;

- (void) drawAnnunciators;
- (void) annuncNeedsDisplay;
- (void) singleLCD;
- (void) doubleLCD;
- (void) shouldCutPaste;
- (void) showEditMenu;
- (void) drawLastX;
- (void) setDisplayUpdateRow:(int) l h:(int) h;
- (float) getDispVertScale;
- (void) setNumDisplayRows;
- (BOOL) shouldDisplayAnnunc;
- (void)drawScrollBar;

@end
