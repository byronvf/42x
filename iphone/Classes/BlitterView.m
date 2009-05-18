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

#import "BlitterView.h"
#import "Utils.h"
#import "core_main.h"
#import "Free42AppDelegate.h"
#import "PrintViewController.h"
#import "NavViewController.h"
#import "CalcViewController.h"

BlitterView *blitterView; // Reference to this blitter so we can access from C methods

static BOOL flagUpDown = false;
static BOOL flagShift = false;
static BOOL flagGrad = false;
static BOOL flagRad = false;
static BOOL flagRun = false;

/**
 * Returns the new value of 'flag' based on the value of 'code' based
 * on values passed in from shell_annuciators
 */ 
BOOL setFlag(BOOL flag, int code)
{
	if (code == 1)
		return TRUE;
	else if (code == 0)
		return FALSE;
	else // flag == -1
		return flag;
}

void shell_annunciators(int updn, int shf, int prt, int run, int g, int rad)
{
	flagUpDown = setFlag(flagUpDown, updn);
	flagShift = setFlag(flagShift, shf);
	flagGrad = setFlag(flagGrad, g);
	flagRad = setFlag(flagRad, rad) && !flagGrad;
	flagRun = setFlag(flagRun, run);

	// Only update the flags region of the display
	[blitterView annuncNeedsDisplay];
		
	if (shf != -1)
	{
		if (flagShift)
		{
			[[blitterView shiftButton] setImage:[UIImage imageNamed:@"glow.png"] forState:NULL];
		}
		else
			[[blitterView shiftButton] setImage:NULL forState:NULL];
	}
}

/**
 * The blitterView manages the calculators digital display
 */
@implementation BlitterView

@synthesize imgFlagUpDown;
@synthesize imgFlagShift;
@synthesize imgFlagGrad;
@synthesize imgFlagRad;
@synthesize imgFlagRun;
@synthesize imgFlagPrint;
@synthesize navViewController;
@synthesize shiftButton;
@synthesize highlight;

- (void)awakeFromNib
{	
	// Initialization code
	blitterView = self; // We need a reference to this view outside the class
	imgFlagUpDown = [[UIImage imageNamed:@"imgFlagUpDown.png"] CGImage];
	imgFlagShift = [[UIImage imageNamed:@"imgFlagShift.png"] CGImage];
	imgFlagGrad = [[UIImage imageNamed:@"imgFlagGrad.png"] CGImage];
	imgFlagRad = [[UIImage imageNamed:@"imgFlagRad.png"] CGImage];
	imgFlagRun = [[UIImage imageNamed:@"imgFlagRun.png"] CGImage];
	imgFlagPrint = [[UIImage imageNamed:@"imgFlagPrint.png"] CGImage];
	highlight = FALSE;
	xRowHighlight = CGRectMake(28, 42, 284, 24); // Hightlight for x region
}


- (void) annuncNeedsDisplay
{
	// Only update the flags region of the display
	[blitterView setNeedsDisplayInRect:CGRectMake(0, 0, 320, 18)];	
}

/**
 * Draw Free42's annunciators, such as shift flag, to the top line of the
 * blitter display.
 */
- (void) drawAnnunciators
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 1.0);

	if (flagUpDown)
		CGContextDrawImage(ctx, CGRectMake(6, 2, 40, 12), [blitterView imgFlagUpDown]);
	
	if (flagShift)
		CGContextDrawImage(ctx, CGRectMake(50, -3, 30, 18), [blitterView imgFlagShift]);
	
	if (printingStarted)
		CGContextDrawImage(ctx, CGRectMake(80, -1, 32, 18), [blitterView imgFlagPrint]);	
	
	if (flagRun)
		CGContextDrawImage(ctx, CGRectMake(115, -1, 18, 18), [blitterView imgFlagRun]);	
	
	if (flagGrad)
		CGContextDrawImage(ctx, CGRectMake(155, -2, 30, 20), [blitterView imgFlagGrad]);
	
	if (flagRad)
		CGContextDrawImage(ctx, CGRectMake(185, -1, 24, 20), [blitterView imgFlagRad]);		
}	

- (void)drawRect:(CGRect)rect 
{	
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	if (highlight)
	{
		CGContextSetRGBFillColor(ctx, 0.60, 0.8, 1.0, 1.0);
        CGContextFillRect(ctx, xRowHighlight);
	}
	
	CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 1.0);

	if (rect.origin.y < 18) 
		[self drawAnnunciators];	
	
	if (rect.origin.y + rect.size.height > 18)
	{
		// 8 - horz pixel offset
		// 18 - vert pixel offset to begin drawing.
		// hMax - pixel height of display
		// 17 - number of bytes per line, each byte is an 8 pixel bit map. 
		// 2.3 - horz scale factor
		// 3.0 - vert scale factor
				
		int hMax = ((rect.origin.y - 18) + rect.size.height)/3;
		if (hMax > 16) hMax = 16;
		drawBlitterDataToContext(ctx, displayBuff, 8, 18, hMax, 17, 2.3, 3.0, -1, 17*8, 0);
	}
	
}


/*
 * The following two event handlers implement the swiping of the display 
 * to switch to the print view.  If the touches are far enough apart, then we switch 
 */
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	NSArray* touchArray = [touches allObjects];
	UITouch* touch = [touchArray objectAtIndex:0];
	if (firstTouch.x == -1)
	{
		firstTouch = [touch locationInView:self];
		return;
	}
	
	if (!printingStarted && firstTouch.x - [touch locationInView:self].x > 50)
	{
		// If we are currently in the process of printing, then we don't allow flipping 
		// to the print screen since the iPhone can't keep up with this, and it just 
		// hoses up!  maybe this can be improved at some point.
		firstTouch.x = -1;
		[[self navViewController] switchToPrintView];		
	}
	
	if (firstTouch.y - [touch locationInView:self].y < -50)
	{
		//self.frame.size.height = 100;
		//CGRect tmp = self.bounds;
		//tmp.size.height = 100;
		//self.bounds = tmp;
		//[self setNeedsDisplay];
	}
}

char cbuf[30];
- (void)copy:(id)sender {
	core_copy(cbuf, 30);
	NSString *copyStr = [NSString stringWithCString:cbuf encoding:NSASCIIStringEncoding];
	UIPasteboard *pb = [UIPasteboard generalPasteboard];
	pb.string = copyStr;
	[self setNeedsDisplayInRect:xRowHighlight];
	highlight = FALSE;
}

- (void)paste:(id)sender {
	UIPasteboard *pb = [UIPasteboard generalPasteboard];
	core_paste([pb.string cStringUsingEncoding:NSASCIIStringEncoding]);
	[self setNeedsDisplayInRect:xRowHighlight];
	highlight = FALSE;
}

- (BOOL) canBecomeFirstResponder {
	return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UIMenuController *mc = [UIMenuController sharedMenuController];
	if (mc.menuVisible) mc.menuVisible = FALSE;	
	[self setNeedsDisplayInRect:xRowHighlight];
	highlight = FALSE;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    if (touch.tapCount == 2 && [self becomeFirstResponder]) {
        //CGRect targetRect = (CGRect){ [[touches anyObject] locationInView:self], CGSizeZero };
        UIMenuController *mc = [UIMenuController sharedMenuController];
        [mc setTargetRect:xRowHighlight inView:self];
        [mc setMenuVisible:YES animated:YES];
		[self setNeedsDisplayInRect:xRowHighlight];
		highlight = TRUE;
    }
			
	// Reset the swipe mode.
	firstTouch.x = -1;
}

@end
