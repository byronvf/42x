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
#import "core_display.h"
#import "core_globals.h"
#import "Free42AppDelegate.h"
#import "PrintViewController.h"
#import "NavViewController.h"
#import "core_keydown.h"
#import "core_helpers.h"

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


void core_copy_reg(char *buf, int buflen, vartype *reg) {
    int len = vartype2string(reg, buf, buflen - 1);
    buf[len] = 0;
    if (reg->type == TYPE_REAL || reg->type == TYPE_COMPLEX) {
		/* Convert small-caps 'E' to regular 'e' */
		while (--len >= 0)
			if (buf[len] == 24)
				buf[len] = 'e';
    }
}

/**
 * The blitterView manages the calculators digital display
 */
@implementation BlitterView
@synthesize calcViewController;
@synthesize shiftButton;
@synthesize highlight;
@synthesize cutPaste;
@synthesize selectAll;
- (void)setXHighlight
{
	// BaseRowHighlight is the starting first row of the display
	// 3 for the display scale factor of 3
	// 8 each row contains 8 pixel columns
	xRowHighlight = baseRowHighlight;
	xRowHighlight.origin.y += (dispRows - (core_menu() && ! menuKeys ? 2 : 1))*3*8;
}

- (void)awakeFromNib
{	
	// Initialization code
	blitterView = self; // We need a reference to this view outside the class
	highlight = FALSE;
	
	baseRowHighlight = CGRectMake(28, 18, 284, 24); // Hightlight for x region
	[self setXHighlight];
	firstTouch.x = -1;
	[self shouldCutPaste];
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

	// We call UIImage directly since it caches the images.  This fixes a crash
	// that would occur when the system would run low on memory and the pointer
	// to the image stored in a variable would no longer be valid.
	
	if (flagUpDown)
		CGContextDrawImage(ctx, CGRectMake(6, 2, 40, 12), 
						   [[UIImage imageNamed:@"imgFlagUpDown.png"] CGImage]);
	
	if (flagShift)
		CGContextDrawImage(ctx, CGRectMake(50, -3, 30, 18),
						   [[UIImage imageNamed:@"imgFlagShift.png"] CGImage]);
	
	if (printingStarted)
		CGContextDrawImage(ctx, CGRectMake(80, -1, 32, 18),
						   [[UIImage imageNamed:@"imgFlagPrint.png"] CGImage]);	
	
	if (flagRun)
		CGContextDrawImage(ctx, CGRectMake(115, -1, 18, 18),
						   [[UIImage imageNamed:@"imgFlagRun.png"] CGImage]);	
	
	if (flagGrad)
		CGContextDrawImage(ctx, CGRectMake(155, -2, 30, 20), 
						   [[UIImage imageNamed:@"imgFlagGrad.png"] CGImage]);
	
	if (flagRad)
		CGContextDrawImage(ctx, CGRectMake(185, -1, 24, 20),
						   [[UIImage imageNamed:@"imgFlagRad.png"] CGImage]);		
}	

- (void)shouldCutPaste
{
	self.cutPaste = TRUE;
	if (flags.f.prgm_mode)
	{
		self.cutPaste = FALSE;
	}
}

- (void)drawRect:(CGRect)rect 
{	
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	if (highlight)
	{
		CGContextSetRGBFillColor(ctx, 0.60, 0.8, 1.0, 1.0);
		if (selectAll)
		{
			// Make selection area larger for select all
			CGRect rect = xRowHighlight;
			int newy = 16;
			rect.size.height = rect.size.height + (rect.origin.y - newy);
			rect.origin.y = newy;
			CGContextFillRect(ctx,rect);
		}
        CGContextFillRect(ctx, xRowHighlight);
	}
	
	CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 1.0);

	if (rect.origin.y < 18) 
		[self drawAnnunciators];	
	
	if (rect.origin.y + rect.size.height > 18)
	{
		float vertScale = 3.0;
		if (dispRows > 2 && flags.f.prgm_mode) vertScale = 2.5;
		
		// 8 - horz pixel offset
		// 18 - vert pixel offset to begin drawing.
		// hMax - pixel height of display
		// 17 - number of bytes per line, each byte is an 8 pixel bit map. 
		// 2.3 - horz scale factor
		// 3.0 - vert scale factor
				
		int hMax = ((rect.origin.y - 18) + rect.size.height)/vertScale;
		if (hMax > dispRows*8) hMax = dispRows*8;
		drawBlitterDataToContext(ctx, calcViewController.displayBuff, 8, 18, hMax, 17, 2.3, vertScale, -1, 17*8, 0);
	}
	
	if (rect.origin.y + rect.size.height > 121)
	{
		CGRect borderLine = CGRectMake(0, 122, 320, 4);
		CGContextFillRect(ctx, borderLine);
	}
	
}

const int SCROLL_SPEED = 15;
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
	else if (firstTouch.x > 260 && !mode_running)
	{
		cutPaste = FALSE;
		CGPoint newPoint = [touch locationInView:self];
		int len = newPoint.y - firstTouch.y;
		if (len > SCROLL_SPEED)
		{
			keydown(0, flags.f.prgm_mode ? 23 : 9);
			core_keyup();
			len -= SCROLL_SPEED;
		}
		else if (len < -SCROLL_SPEED)
		{
			if (flags.f.prgm_mode)
			{
				keydown(0, 18);
				core_keyup();
			}
			else
			{
				keydown(0, 9);
				core_keyup();
				keydown(0, 9);
				core_keyup();
				keydown(0, 9);
				core_keyup();
			}				
			len += SCROLL_SPEED;	
		}
				
		firstTouch.y = newPoint.y - len;
	}
	else if (!calcViewController.keyPressed)
	{
		// changing the display mode causes a call to Free42's redisplay method.
		// However redisplay is not intended to be called bettween a keydown and
		// a keyup method calls.  So we don't allow it here.  This fixes a crash that
		// occurred while switching to four line mode, and pressing the "EXIT" key
		// at the same time.
		
		if (firstTouch.y - [touch locationInView:self].y < -30 && dispRows == 2)
		{
			[calcViewController fourLineDisp];
		}
		else if (firstTouch.y - [touch locationInView:self].y > 30 && dispRows >= 4)
		{
			[calcViewController twoLineDisp];
		}	
	}
	
	if (!printingStarted && firstTouch.x - [touch locationInView:self].x > 60)
	{
		// If we are currently in the process of printing, then we don't allow flipping 
		// to the print screen since the iPhone can't keep up with this, and it just 
		// hoses up!  maybe this can be improved at some point.
		firstTouch.x = -1;
		[[[self calcViewController] navViewController] switchToPrintView];		
	}	
	
}

/**
 * Set the blitter in two line display mode
 */
- (void) twoLineDisp
{
	dispRows = 2;
	firstTouch.x == -1;
	CGRect bounds = self.bounds;
	CGPoint cent = self.center;
	bounds.size.height = 68;
	cent.y = bounds.size.height/2;
	self.bounds = bounds;
	self.center = cent;
	redisplay();
	[self setNeedsDisplay];	
}

/**
 * Set the blitter in four line display mode
 */
- (void) fourLineDisp
{
	if (flags.f.prgm_mode)
		dispRows = 5;
	else
		dispRows = 4;
	firstTouch.x == -1;
	CGRect bounds = self.bounds;
	CGPoint cent = self.center;
	bounds.size.height = 126;
	cent.y = bounds.size.height/2;
	self.bounds = bounds;
	self.center = cent;
	redisplay();
	[self setNeedsDisplay];
}

- (void)selectAll:(id)sender {
	if (highlight)
	{
		// The user selected all, so show edit menu again with new selection
		// and highlight the entire stack.
		selectAll = TRUE;
		[self showEditMenu];
		[self setNeedsDisplay];		
	}
	
}

char cbuf[30];
- (void)copy:(id)sender {
	if (highlight)
	{
		if (selectAll)
		{
			NSMutableString *nums = [NSMutableString stringWithCapacity:100];
			NSString *str = NULL;
			
			core_copy_reg(cbuf, 30, reg_t);
			str = [NSString stringWithCString:cbuf encoding:NSASCIIStringEncoding];
			[nums appendString:str];
			[nums appendString:@"\n"];
			
			core_copy_reg(cbuf, 30, reg_z);
			str = [NSString stringWithCString:cbuf encoding:NSASCIIStringEncoding];
			[nums appendString:str];
			[nums appendString:@"\n"];
			
			core_copy_reg(cbuf, 30, reg_y);
			str = [NSString stringWithCString:cbuf encoding:NSASCIIStringEncoding];
			[nums appendString:str];
			[nums appendString:@"\n"];
			
			core_copy_reg(cbuf, 30, reg_x);
			str = [NSString stringWithCString:cbuf encoding:NSASCIIStringEncoding];
			[nums appendString:str];
			[nums appendString:@"\n"];
			
			UIPasteboard *pb = [UIPasteboard generalPasteboard];
			pb.string = nums;
			selectAll = FALSE;
		}
		else
		{		
			core_copy(cbuf, 30);
			NSString *copyStr = [NSString stringWithCString:cbuf encoding:NSASCIIStringEncoding];
			UIPasteboard *pb = [UIPasteboard generalPasteboard];
			pb.string = copyStr;		
		}
		
		highlight = FALSE;
		[self setNeedsDisplay];
	}	
}

/*
 *  Handle paste
 */
- (void)paste:(id)sender {
	if (highlight)
	{	
		UIPasteboard *pb = [UIPasteboard generalPasteboard];
	
		// Handle multiple numbers.  We split by control character such
		// as newlines and tabs, then disregard any blank lines, we feed the 
		// trimmed results to Free42

		NSArray *nums = [pb.string componentsSeparatedByCharactersInSet:
						 [NSCharacterSet controlCharacterSet]];
		NSEnumerator *enumerator = [nums objectEnumerator];
		id num;
		while(num = [enumerator nextObject])
		{
			NSString *trimmed = [num stringByTrimmingCharactersInSet:
								[NSCharacterSet whitespaceCharacterSet]];
			// Ignore blank lines
			if ([trimmed length] != 0)
			{
				// returns null if string can't be converted losslessly
				const char* buf = [trimmed cStringUsingEncoding:NSASCIIStringEncoding];
				if (buf != NULL)
					core_paste([trimmed cStringUsingEncoding:NSASCIIStringEncoding]);
			}
		}
		
		[self setNeedsDisplay];
		highlight = FALSE;
	}
}

/**
 * Necessary to turn on cut / paste
 */
- (BOOL) canBecomeFirstResponder {
	return TRUE;
}

/**
 * Event handler called for cut/paste.  We use this to show only "Copy" 
 * If the user selected "selectAll" on the first menu.
 */
- (BOOL) canPerformAction:(SEL)action withSender:(id)sender
{
	if (selectAll && (action == @selector(selectAll:) || action == @selector(paste:)))
		return FALSE;
	return [super canPerformAction:action withSender:sender];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UIMenuController *mc = [UIMenuController sharedMenuController];
	if (mc.menuVisible) mc.menuVisible = FALSE;
	selectAll = FALSE;
	if (highlight)
	{
		[self setNeedsDisplayInRect:xRowHighlight];
		highlight = FALSE;
	}
}

/**
 * We use this to show the cut paste edit menu.  The perform selector after delay
 * allows us to bring up the menu again with the new menu items if the user selects
 * "selectAll". Why this works I'm not sure, snagged it from the forums.
 */
- (void)showEditMenu {
	
	UIMenuController *mc = [UIMenuController sharedMenuController];
	if (!mc.menuVisible) {
        //CGRect targetRect = (CGRect){ [[touches anyObject] locationInView:self], CGSizeZero };
		[self setXHighlight];
        [mc setTargetRect:xRowHighlight inView:self];
        [mc setMenuVisible:YES animated:YES];
	} else {
		[self performSelector:@selector(showEditMenu) withObject:nil afterDelay:0.0];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self shouldCutPaste];
	
	// If double tap, then bring up cut paste menu.  
	
    UITouch *touch = [touches anyObject];
    if ([[touches anyObject] locationInView:self].x < 260 
		     && cutPaste && touch.tapCount == 2 && [self becomeFirstResponder]) {
		[self setXHighlight];
		[self setNeedsDisplayInRect:xRowHighlight];
		[self showEditMenu];
		highlight = TRUE;
    }
	// Reset the swipe mode.
	firstTouch.x = -1;
}

@end
