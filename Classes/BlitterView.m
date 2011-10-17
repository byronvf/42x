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
#import "core_commands1.h"
#import "core_commands2.h"
#import "Free42AppDelegate.h"
#import "PrintViewController.h"
#import "NavViewController.h"
#import "core_keydown.h"
#import "Settings.h"
#import "core_helpers.h"
#import "shell_spool.h"
#import "undo.h"

// Reference to this blitter so we can access from C methods
static BlitterView *blitterView = NULL; 

static BOOL flagUpDown = false;
static BOOL flagShift = false;
static BOOL flagGrad = false;
static BOOL flagRad = false;
static BOOL flagRun = false;

// Height of the annuciator line
#define ASTAT_HEIGHT 18

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

/* 
 * Handle swiping vertically on the right side of the display. We could call methods
 * at a finer grain, for example docmd_rup, or sst(), but there is additional logic
 * we need in keydown and keyup, for example exiting number_entry_mode.
 */
void swipevert(BOOL up)
{
	if (flags.f.prgm_mode)
	{
		// We are in program mode, we want to set ingore_menu to true so that
		// the keydown method ignores the case the menu is up, which would normally
		// be interpredted as a change in menu for key up or down. However, 
		// we want scrolling to work even when the menu is up.
		if (up)
		{
			ignore_menu = TRUE;
			keydown(0, 23); // KEY_DWN
			core_keyup();
			ignore_menu = FALSE;
		}
		else
		{
			ignore_menu = TRUE;
			keydown(0, 18);  // KEY_UP
			core_keyup();
			ignore_menu = FALSE;
		}
	}		
	else
	{
		if (up)
		{
			keydown(0, 9);			
			core_keyup();
		}
		else
		{
			keydown(0, 9);
			// Change the pending command to roll up, so the docmd_rup method is called
			// internally.
			pending_command = CMD_RUP;
			core_keyup();
		}
	}
}	

void shell_annunciators(int updn, int shf, int prt, int run, int g, int rad)
{
	flagUpDown = setFlag(flagUpDown, updn);
	flagShift = setFlag(flagShift, shf);
	flagGrad = setFlag(flagGrad, g);
	flagRad = setFlag(flagRad, rad) && !flagGrad;
	flagRun = setFlag(flagRun, run);
	
	
	// If this is being called from Free42 initialization before the view
	// has been loaded.
	if (!blitterView) return;
	
	// Only update the flags region of the display
	[blitterView annuncNeedsDisplay];
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

char lastxbuf[LASTXBUF_SIZE];
short dispflags = 0;

/**
 * The blitterView manages the calculators digital display
 */
@implementation BlitterView
@synthesize calcViewController;
@synthesize highlight;
@synthesize cutPaste;
@synthesize selectAll;
@synthesize statusBarOffset;
@synthesize dispAnnunc;

- (void)setSelectHighlight
{
	// BaseRowHighlight is the starting first row of the display
	selectRect.origin.y = ASTAT_HEIGHT + statusBarOffset;
	if (selectAll)
	{
		selectRect.size.height = dispRows*[self getDispVertScale]*8;
	}
	else
	{
		selectRect.origin.y += (dispRows - 1) * [self getDispVertScale]*8;
		selectRect.size.height = [self getDispVertScale]*8;
	}
}

- (void)awakeFromNib
{
	NSAssert(free42init, @"Free42 has not been initialized");
	
	// Initialization code
	blitterView = self; // We need a reference to this view outside the class
	highlight = FALSE;
	dispAnnunc = TRUE;
	
	// Initialize offsetDisp if we need to compensate for the top statusbar
	statusBarOffset = [[Settings instance] showStatusBar] ? 20 : 0;
	
	// Hightlight for x region
	selectRect = CGRectMake(28, ASTAT_HEIGHT + statusBarOffset, 284, 24);
	
	[self setSelectHighlight];
	firstTouch.x = -1;
	[self shouldCutPaste];
	
}

- (void) annuncNeedsDisplay
{
	if (flagShift)
		[[calcViewController b28] setImage:[UIImage imageNamed:@"glow.png"] forState:NULL];
	else
		[[calcViewController b28] setImage:NULL forState:NULL];

	if (flagUpDown)
		[[calcViewController updnGlowView] setHidden:FALSE];
	else
		[[calcViewController updnGlowView] setHidden:TRUE];
	
	// Only update the flags region of the display
	[self annuciatorNeedsUpdate];
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
		CGContextDrawImage(ctx, CGRectMake(6, 2 + statusBarOffset, 40, 12), 
						   [[UIImage imageNamed:@"imgFlagUpDown.png"] CGImage]);
	
	if (flagShift)
		CGContextDrawImage(ctx, CGRectMake(35, -3 + statusBarOffset, 30, 18),
						   [[UIImage imageNamed:@"imgFlagShift.png"] CGImage]);
	
	if (printingStarted)
		CGContextDrawImage(ctx, CGRectMake(65, -1 + statusBarOffset, 32, 18),
						   [[UIImage imageNamed:@"imgFlagPrint.png"] CGImage]);	
	
	if (flagRun)
		CGContextDrawImage(ctx, CGRectMake(100, -1 + statusBarOffset, 18, 18),
						   [[UIImage imageNamed:@"imgFlagRun.png"] CGImage]);	
	
	if (flagGrad)
		CGContextDrawImage(ctx, CGRectMake(120, -2 + statusBarOffset, 30, 20), 
						   [[UIImage imageNamed:@"imgFlagGrad.png"] CGImage]);
	
	if (flagRad)
		CGContextDrawImage(ctx, CGRectMake(120, -1 + statusBarOffset, 24, 20),
						   [[UIImage imageNamed:@"imgFlagRad.png"] CGImage]);		
}	

- (void)drawFlags
{
	if (![[Settings instance] showFlags]) return;
		
	UIFont *font = [UIFont boldSystemFontOfSize:14];
	if (flags.f.f00) 
		[@"0" drawAtPoint:CGPointMake(166, statusBarOffset-1) withFont:font];
	
	if (flags.f.f01)
		[@"1" drawAtPoint:CGPointMake(175, statusBarOffset-1) withFont:font];

	if (flags.f.f02)
		[@"2" drawAtPoint:CGPointMake(184, statusBarOffset-1) withFont:font];
	
	if (flags.f.f03)
		[@"3" drawAtPoint:CGPointMake(193, statusBarOffset-1) withFont:font];

	if (flags.f.f04)
		[@"4" drawAtPoint:CGPointMake(202, statusBarOffset-1) withFont:font];
	
}

- (void)shouldCutPaste
{
	self.cutPaste = TRUE;
	// If in program mode, or alpha mode, then don't bring up cut and paste
	// since it really doesn't make since.
	if (flags.f.prgm_mode  || core_alpha_menu())
	{
		self.cutPaste = FALSE;
	}
}

- (void)drawLastX
{
	if (![[Settings instance] showLastX]) return;
	
	// a utf8 conversion, we provide room incase we need double byte characters
	int lxbufsize = LASTXBUF_SIZE*2;
	char lxstr[lxbufsize]; 

	// Quick and dirty character conversion... lxbufsize - so we alway have room for
	// a 4 byte char and a null terminator.
    hp2utf8(lastxbuf, strlen(lastxbuf), lxstr, lxbufsize - 4);
	NSString *lval = [[NSString alloc] initWithUTF8String:lxstr];
	NSString *wprefix = @"L ";

	// If the number is very long, then we drop "L " prefix because it will start to crowd
	// The annunciators, and potetially will begin to overlap
	if (strlen(lxstr) > 18)
		wprefix = lval;
	else
		wprefix = [wprefix stringByAppendingString:lval];

	// Draw the lastx register right justified in the upper right hand corner of the LCD in
	// the annunciator row.
	//UIFont *font = [UIFont fontWithName:@"Helvetica" size:15];
	UIFont *font = [UIFont systemFontOfSize:15];
	[wprefix drawInRect:CGRectMake(140, -2 + statusBarOffset, 178, 14) 
			   withFont:font lineBreakMode:UILineBreakModeClip
	 alignment:UITextAlignmentRight];
	
	[lval release];
}

- (void)drawRect:(CGRect)rect 
{	
#ifdef DEBUG	
	NSAssert(calcViewController && calcViewController.displayBuff, 
			 @"viewController not initialized");
#else
	if (calcViewController.displayBuff == NULL) return;	
#endif
	
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	if (highlight)
	{
		CGContextSetRGBFillColor(ctx, 0.60, 0.8, 1.0, 1.0);
        CGContextFillRect(ctx, selectRect);
	}
	
	CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 1.0);
	
    //CGSize offset = {1,0};
	//CGContextSetShadow(ctx, offset, 0);
    //CGColorRef blackColor = [[UIColor blackColor] CGColor];    
    //CGContextSetShadowWithColor(ctx, offset, 0, blackColor);
                                
	// DispRows of 4 or 7 means that we are displaying in program mode with a largeLCD
	if ((rect.origin.y < ASTAT_HEIGHT + statusBarOffset) && self.dispAnnunc)
	{
		[self drawAnnunciators];	
		[self drawLastX];	
		[self drawFlags];		
	}
		
	if (rect.origin.y + rect.size.height > ASTAT_HEIGHT + statusBarOffset)
	{
		float vertScale = [self getDispVertScale];
		
		// 8 - horz pixel offset
		// 18 - vert pixel offset to begin drawing.
		// hMax - pixel height of display
		// 17 - number of bytes per line, each byte is an 8 pixel bit map. 
		// 2.3 - horz scale factor
		// 3.0 - vert scale factor
		
		int hMax = ((rect.origin.y - (ASTAT_HEIGHT + statusBarOffset)) + rect.size.height)/vertScale + 1;
		// If in program mode just display the who thing, we don't try and be smart about
		// the update region.
		if (hMax > dispRows*8 || flags.f.prgm_mode) hMax = dispRows*8;
		int vertoffset = statusBarOffset;
		
		if (self.dispAnnunc)
		{
			vertoffset += ASTAT_HEIGHT;
		}
		else
		{		
			// If in program mode then create a little buffer at the top
			if (dispRows == 7) vertoffset += 3;	
			if (dispRows == 4) vertoffset += 5;
			if (dispRows == 6) vertoffset += 2;
		}

		drawBlitterDataToContext(ctx, calcViewController.displayBuff, 8, vertoffset,
								 hMax, 17, 2.3, vertScale, -1, 17*8, 0);
	}
	
	// Draw printer watermark button 
	if (fuval)
		CGContextFillRect(ctx, rect);
	int poff = dispRows < 4 ? 69 : 123;
	CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 0.3);	
	UIFont *font = [UIFont systemFontOfSize:13];
	[@"P" drawAtPoint:CGPointMake(300, poff) withFont:font];		
	CGContextBeginPath(ctx);
	CGContextAddArc(ctx, 304, poff+8, 8, 0, 2*M_PI, 0);
	CGContextSetLineWidth(ctx, 1);
	CGContextSetRGBStrokeColor(ctx, 0.0, 0.0, 0.0, 0.3);	
	CGContextStrokePath(ctx);
	
	if (flags.f.prgm_mode) [self drawScrollBar];
}

/**
 * Display the right hand scroll bar used to indicate the current window position
 * in program mode.
 */
- (void)drawScrollBar
{
	NSAssert(free42init, @"Free42 has not been initialized");
	
	int insetTop = 4;
	if (self.dispAnnunc) insetTop += ASTAT_HEIGHT;
	int insetBot = 4;
	
	int offset = insetTop;
	int fullheight = self.bounds.size.height - (insetTop + insetBot);
	
	if ([[Settings instance] showStatusBar])
	{	
		offset += 20;
		fullheight -= 20;
	}
	
	int barheight = fullheight;
	int lines = num_prgm_lines() + 1;
	if (dispRows < lines)
		barheight = dispRows*fullheight/lines;
	
	// barheight is never less then 5 pixels
	if (barheight < 5) barheight = 5;

	int startline = pc2line(pc) - prgm_highlight_row;
	if (startline < 0) startline = 0;  // This shoudn't happen, but just in case
	offset += startline*fullheight/lines;
			
	CGRect bar = CGRectMake(310, offset, 5, barheight);
	
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 0.50);	
	CGContextFillRect(ctx, bar);	
}

- (void)annuciatorNeedsUpdate
{
	if (self.dispAnnunc)
	{
		int v = ASTAT_HEIGHT;
		// If we are not int largeLCD mode, then include the iphone statusbar region
		if ([[Settings instance] showStatusBar]) v += 20;
			
		[blitterView setNeedsDisplayInRect:CGRectMake(0, 0, 320, v)];
	}
}

/*
 * Set the number of display rows given the various display settings.  Free42
 * will use dispRows to determine how many rows to render.
 */
- (void)setNumDisplayRows
{
	self.dispAnnunc = TRUE;
	if (![[Settings instance] showStatusBar])
	{
		dispRows = 3;
		if (self.bounds.size.height > 100)
			dispRows = 6;
		if (flags.f.prgm_mode)
		{
			self.dispAnnunc = FALSE;
			dispRows += 1;
		}
	}
	else
	{
		dispRows = 2;
		if (self.bounds.size.height > 100)
		{
			dispRows = 5;
			if (flags.f.prgm_mode) 
			{
				self.dispAnnunc = FALSE;
				dispRows = 6;
			}
		}
	}
	
	redisplay();
}

/*
 * translate a row that needsd to be updated into a rectangle region
 */
- (void)setDisplayUpdateRow:(int) l h:(int) h
{
	float vscale= [self getDispVertScale];
	
	// Small kludge, if we are just updating the top row, then in the case we are flying the 
	// goose we trim one pixel off the blitter update rect, this prevents the second row
	// of the display from getting the top pixel row from being deleted. this only happens
	// hwne vscale is 2.8
	int hs = (h*8)*vscale + 1;
	if (hs == 23) hs = 22;
	
	// dispRows == 4 means we are in program mode with the status bar off, in draw rect
	// we addjust the top by +5 in this mode to help center the program display in the 
	// LCD, we make the same adjustment here so we draw the entire area.
	if (dispRows == 4) hs += 5;
	if (dispRows == 6 || dispRows == 7) hs += 2;

	int top = [self statusBarOffset] + (l*8)*vscale;	
	if (self.dispAnnunc)
		top += ASTAT_HEIGHT;
			
	[self setNeedsDisplayInRect:CGRectMake(0, top, 320, hs)];	
}

- (float)getDispVertScale
{
	float vertScale = 2.5;
	if (dispRows == 2) vertScale = 3.0;
	else if (dispRows == 3) vertScale = 2.8;
	
	return vertScale;
}

const int TOUCH_RESET = -1;
const int TOUCH_SWIPE_COMPLETE = -2;

const int SCROLL_SPEED = 15;

/**
 * Set the blitter in two line display mode
 */
- (void) singleLCD
{
	//firstTouch.x = TOUCH_RESET;
	CGRect bounds = self.bounds;
	CGPoint cent = self.center;
	bounds.size.height = 89;
	cent.y = bounds.size.height/2;
	self.bounds = bounds;
	self.center = cent;
	[self setNeedsDisplay];	
}

/**
 * Set the blitter in four line display mode
 */
- (void) doubleLCD
{
	//firstTouch.x = TOUCH_RESET;
	CGRect bounds = self.bounds;
	CGPoint cent = self.center;
	bounds.size.height = 145;
	cent.y = bounds.size.height/2;
	self.bounds = bounds;
	self.center = cent;	
	[self setNeedsDisplay];
}

- (void)selectAll:(id)sender {
	if (highlight)
	{
		// The user selected all, so show edit menu again with new selection
		// and highlight the entire stack.
		selectAll = TRUE;
		[self showEditMenu];
		[self setSelectHighlight];
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

			if (dispRows > 5 && bigstack_head != NULL && bigstack_head->next != NULL)
			{
				core_copy_reg(cbuf, 30, bigstack_head->next->var);
				str = [NSString stringWithCString:cbuf encoding:NSASCIIStringEncoding];
				[nums appendString:str];
				[nums appendString:@"\n"];
			}

			if (dispRows > 4 && bigstack_head != NULL)
			{
				core_copy_reg(cbuf, 30, bigstack_head->var);
				str = [NSString stringWithCString:cbuf encoding:NSASCIIStringEncoding];
				[nums appendString:str];
				[nums appendString:@"\n"];
			}

			if (dispRows > 3)
			{
				core_copy_reg(cbuf, 30, reg_t);
				str = [NSString stringWithCString:cbuf encoding:NSASCIIStringEncoding];
				[nums appendString:str];
				[nums appendString:@"\n"];
			}
			
			if (dispRows > 2)
			{
				core_copy_reg(cbuf, 30, reg_z);
				str = [NSString stringWithCString:cbuf encoding:NSASCIIStringEncoding];
				[nums appendString:str];
				[nums appendString:@"\n"];
			}
			
			if (dispRows > 1)
			{
				core_copy_reg(cbuf, 30, reg_y);
				str = [NSString stringWithCString:cbuf encoding:NSASCIIStringEncoding];
				[nums appendString:str];
				[nums appendString:@"\n"];
			}
			
			if (dispRows > 0)
			{				
				core_copy_reg(cbuf, 30, reg_x);
				str = [NSString stringWithCString:cbuf encoding:NSASCIIStringEncoding];
				[nums appendString:str];
				[nums appendString:@"\n"];
			}
			
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
		while((num = [enumerator nextObject]) != NULL)
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
		[self setNeedsDisplayInRect:selectRect];
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
		[self setSelectHighlight];
        [mc setTargetRect:selectRect inView:self];
        [mc setMenuVisible:YES animated:YES];
	} else {
		[self performSelector:@selector(showEditMenu) withObject:nil afterDelay:0.0];
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
	if (firstTouch.x == TOUCH_RESET)
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
			swipevert(TRUE);
			len -= SCROLL_SPEED;
		}
		else if (len < -SCROLL_SPEED)
		{
			swipevert(FALSE);
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
		
		if (firstTouch.y - [touch locationInView:self].y < -30 && self.bounds.size.height < 100)
		{
			[calcViewController doubleLCD];
		}
		else if (firstTouch.y - [touch locationInView:self].y > 30 && self.bounds.size.height > 100)
		{
			[calcViewController singleLCD];
		}	
	}
	
	if (!flags.f.prgm_mode && firstTouch.x != TOUCH_SWIPE_COMPLETE &&
		firstTouch.x - [touch locationInView:self].x > 60)
	{
			// If we are currently in the process of printing, then we don't allow flipping 
			// to the print screen since the iPhone can't keep up with this, and it just 
			// hoses up!  maybe this can be improved at some point.
		firstTouch.x = TOUCH_SWIPE_COMPLETE;
			//[[[self calcViewController] navViewController] switchToPrintView];
		docmd_undo(NULL);		
		mode_number_entry = FALSE;
		redisplay();
	}
	else if (!flags.f.prgm_mode && firstTouch.x != TOUCH_SWIPE_COMPLETE &&
			 firstTouch.x - [touch locationInView:self].x < -60)
	{
		firstTouch.x = TOUCH_SWIPE_COMPLETE;
		docmd_redo(NULL);
		mode_number_entry = FALSE;
		redisplay();		
	}
	
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self shouldCutPaste];
	
	// If double tap, then bring up cut paste menu.  
	
    UITouch *touch = [touches anyObject];
	CGPoint p = [[touches anyObject] locationInView:self];
    if (p.x < 260 && cutPaste && touch.tapCount == 2 && [self becomeFirstResponder]) {
		[self setSelectHighlight];
		[self setNeedsDisplayInRect:selectRect];
		[self showEditMenu];
		highlight = TRUE;
    }
	else if (p.x < 260 && touch.tapCount == 1)
	{
		[calcViewController handlePopupKeyboard:true];
	}
	else if (p.x > 280 && ((dispRows < 4 && p.y > 70) || p.y > 110) 
			 && touch.tapCount == 1)
	{
		// If we are currently in the process of printing, then we don't allow flipping 
		// to the print screen since the iPhone can't keep up with this, and it just 
		// hoses up!  maybe this can be improved at some point.
		[[[self calcViewController] navViewController] switchToPrintView];		
	}
	
	// Reset the swipe mode.
	firstTouch.x = TOUCH_RESET;
}


- (void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
	// We can can get motion events while coming out of sleep.. to avoid this
	// we test if we are sleeping or not.
	if (!flags.f.prgm_mode && !mode_running && !flags.f.alpha_mode && !isSleeping)
	{
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Clear Stack?"
			message:NULL delegate:self cancelButtonTitle:@"Yes" otherButtonTitles:nil] autorelease];	
		[alert addButtonWithTitle:@"No"];
		[alert show];
	}
}

- (void)alertView: (UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 0)  // Shake event
	{
		//docmd_clst(NULL);
		//mode_number_entry = FALSE;
		//redisplay();
		pending_command = CMD_CLST;
        flags.f.message = 0;
        flags.f.two_line_message = 0;
		core_keyup();
		
	}
}

@end
