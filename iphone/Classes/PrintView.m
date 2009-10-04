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

#import "PrintView.h"
#import "Settings.h"
#import "PrintViewController.h"
#import "Free42AppDelegate.h"

@implementation PrintView

@synthesize printViewController;
@synthesize offset;

/**
 * Cut/Paste, copy the entire print output directly from file to the clipboard.
 */
- (void)copy:(id)sender {

	// flush file contents to file
	if (printFile) fflush(printFile);

	NSString* fileStr = [NSHomeDirectory() stringByAppendingString:PRINT_FILE_NAME];
	NSString *pout = [NSString stringWithContentsOfFile:fileStr encoding:NSASCIIStringEncoding
												  error:NULL];	
	UIPasteboard *pb = [UIPasteboard generalPasteboard];
	pb.string = pout;	
	[printViewController setViewsHighlight:FALSE];		
}	

/**
 * Necessary to turn on Cut/Paste
 */
- (BOOL) canBecomeFirstResponder {
	return TRUE;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UIMenuController *mc = [UIMenuController sharedMenuController];
	if (mc.menuVisible) 	[printViewController setViewsHighlight:FALSE];	
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	// Test for double tap, if so bring up cut paste menu.
    UITouch *touch = [touches anyObject];	
    if (touch.tapCount == 2 && [self becomeFirstResponder]) {
        CGRect targetRect = (CGRect){ [[touches anyObject] locationInView:self], CGSizeZero};
        UIMenuController *mc = [UIMenuController sharedMenuController];
        [mc setTargetRect:targetRect inView:self];
        [mc setMenuVisible:YES animated:YES];
		[printViewController setViewsHighlight:TRUE];	
    }
}

- (void)drawRect:(CGRect)rect 
{	
	NSMutableData* buf = [printViewController getBuff];
	NSAssert(buf, @"print buffer not initialized");
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	// 5 - 5 pixels of top margin
	// 18 - number of bytes per pixel line
	int adjViewSize = 480/PRINT_VERT_SCALE;  // convert view size to buf cords
	int adjOffset = offset/PRINT_VERT_SCALE;
	const char* beginBuf = (const char*)[buf bytes] + 18*adjOffset;
	int buflength = [buf length]/18;
	int length = buflength - adjOffset;
	if (length > adjViewSize)
		length = adjViewSize;
	if (length > 0)
		[self drawFastBlitDataToContext:ctx 
			data:beginBuf xoffset:15 yoffset:0 height:length 
			byte_width:18];
}


- (void) drawFastBlitDataToContext: 
			(CGContextRef) ctx   // Context to blit to 
			data:(const char*) data  // data buffer to read from, size is in bytes is height*byte_width
			xoffset:(int) xoffset        // horz offset for drawing to the context
			yoffset:(int) yoffset        // vert offset for drawing to the context
			height:(int) height         // pixel height of data in the data buffer.
			byte_width:(int) byte_width     // number of bytes per row
{
	int adjOffset = offset/PRINT_VERT_SCALE;
	BOOL prlcd = [Settings instance].printedPRLCD;
	assert(data);
	// We draw free42's display to the context, then we scale it
	// to fit
	UInt32* ui = (UInt32*)CGBitmapContextGetData(ctx);
	int ty = 0;
	for(int h=0; h < height; h++)
	{
        int tx = xoffset;
		//Commented out the pale blue stripes
		//They get out of sync with the printed text when PRLCD
		//is used -- text lines are 9 pixels high, PRLCD output
		//is 16 pixels high...
		int altclr = (adjOffset++ + 1) % 18;
		for(int w=0; w < byte_width; w++)
		{
			char byte = data[h*byte_width + w];
			for (int bcnt = 0; bcnt < 8; bcnt++)
			{				
				int isset = byte&1;
				int tm = ty*320;
				if (isset)
				{
					// Strange that CG provides no way to set a single
					// pixel, so we draw a rect one pixel in size.
					//					CGContextFillRect(ctx, CGRectMake(xpos,ypos, 1, 1));
					*(ui + tm + tx) = 0;
					*(ui + tm + tx + 1) = 0;
					*(ui + tm + 320 + tx) = 0;
					*(ui + tm + 320 + tx + 1) = 0;
				}
				else if (altclr > 8 && !prlcd)
				{
					*(ui + tm + tx) = 0xD8D8D8;
					*(ui + tm + tx + 1) = 0xD8D8D8;
					*(ui + tm + 320 + tx) = 0xD8D8D8;
					*(ui + tm + 320 + tx + 1) = 0xD8D8D8;			
				}
				
				byte >>= 1;
				tx += 2;
			}
		}
		
		ty += 2;
	}	
}


- (void)dealloc {
	[super dealloc];
}

@end
