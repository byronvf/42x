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
#import "Free42AppDelegate.h"
#import "PrintViewController.h"
#import "NavViewController.h"
#import "CalcViewController.h"


BlitterView *blitterView; // Reference to this blitter so we can access from C methods

static const char *buff;
void shell_blitter(const char *bits, int bytesperline, int x, int y,
				   int width, int height)
{
	// We don't take advantage of the additional clipping information, but
	// I don't think this is an issue given the iPhone's hardware display support.
	buff = bits;
	[blitterView setNeedsDisplay];
}

static BOOL flagUpDown = false;
static BOOL flagShift = false;
static BOOL flagGrad = false;
static BOOL flagRad = false;
static BOOL flagRun = false;
//static BOOL flagPrint = false;

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
	//flagPrint = setFlag(flagPrint, prt);
	[blitterView setNeedsDisplay];
	
	if (shf != -1)
	{
		if (flagShift)
			[[blitterView shiftButton] setImage:[blitterView imgShiftGlow] forState:NULL];
		else
			[[blitterView shiftButton] setImage:NULL forState:NULL];
	}
}

/**
 * Draw Free42's annunciators, such as shift flag, to the top line of the
 * blitter display.
 */
void drawAnnunciators(CGContextRef ctx)
{
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
@synthesize imgShiftGlow;
@synthesize navViewController;
@synthesize shiftButton;


- (void)drawRect:(CGRect)rect {	
	blitterView = self;  // This is a dumb place to initialize this var, but not sure where else...
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 1.0);

	// 8 - horz pixel offset
	// 18 - vert pixel offset to begin drawing.
	// 16 - pixel height of display
	// 17 - number of bytes per line, each byte is an 8 pixel bit map. 
	// 2.3 - horz scale factor
	// 3.0 - vert scale factor
	
	drawBlitterDataToContext(ctx, buff, 8, 18, 16, 17, 2.3, 3.0);
	drawAnnunciators(ctx);	
}


/*
 * The following two event handlers implement the swiping of the display 
 * to switch to the print view.  If the touches are far enough apart, then we switch 
 */

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	// If we are currently in the process of printing, then we don't allow flipping 
	// to the print screen since the iPhone can't keep up with this, and it just 
	// hoses up!  maybe this can be improved at some point.
	if (!printingStarted)
	{
		NSArray* touchArray = [touches allObjects];
		UITouch* touch = [touchArray objectAtIndex:0];
		if (firstTouchXPos == 0)
		{
			firstTouchXPos = [touch locationInView:self].x;
		}
		else if (firstTouchXPos - [touch locationInView:self].x > 60)
		{
			[[self navViewController] switchToPrintView];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	firstTouchXPos = 0;	
}

@end
