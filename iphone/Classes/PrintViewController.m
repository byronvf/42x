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

#import "PrintViewController.h"
#include "Utils.h"
#include "Free42AppDelegate.h"

static PrintViewController* printViewController;
BOOL printingStarted = FALSE;

// Keep track of the last position we printed so we can conveniently
// place the printer screen at the beginning of this new output.
static int lastPrintPosition = 0;

void shell_print(const char *text, int length,
				 const char *bits, int bytesperline,
				 int x, int y, int width, int height)
{
	NSMutableData* buf = [printViewController printBuff];
	if (!printingStarted)
	{
		printingStarted = TRUE;
		lastPrintPosition = [buf length]/18;
	}
	
	if (bytesperline == 18) {
		// Regular text-mode print command
		if ([buf length] < 18*9*MAX_PRINT_LINES) 
			[buf appendBytes:bits length:18*9];
	} else {
		// PRLCD
		if ([buf length] < 18 * 16 * MAX_PRINT_LINES) {
			for (int i = 0; i < 16; i++) {
				[buf appendBytes:(bits + i * 17) length:17];
				[buf increaseLengthBy:1];
			}
		}
	}
}

@implementation PrintViewController

@synthesize printBuff;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
}

- (void)clearPrinter
{
	[view1 setFrame:CGRectMake(0,0,320,480)];
	[view2 setFrame:CGRectMake(0,480,320,480)];
	[view1 setOffset:0];
	[view2 setOffset:480];
	[printBuff setLength:0];	
	[self display];
}

- (void)rePosition:(UIScrollView*)scrollView force:(BOOL)force
{
	CGPoint offset = [scrollView contentOffset];
	int tilenum = offset.y/480;
	int view1offset, view2offset;
	
	if (tilenum & 1) // If tilenum is odd
	{
		view2offset = tilenum*480;
		view1offset = (tilenum+1)*480;
	}
	else // tilenum is even
	{
		view1offset = tilenum*480;
		view2offset = (tilenum+1)*480;
	}
	
	if (force || [view1 offset] != view1offset)
	{
		[view1 setOffset:view1offset];
		[view1 setFrame:CGRectMake(0, view1offset, 320, 480)];
		[view1 setNeedsDisplay];
	}
	
	if (force || [view2 offset] != view2offset)
	{
		[view2 setOffset:view2offset];
		[view2 setFrame:CGRectMake(0, view2offset, 320, 480)];
		[view2 setNeedsDisplay];
	}		
}

- (void)display
{
	UIScrollView* scrollView = (UIScrollView*)[self view];
	int numVertPixel = [printBuff length]/18;
 	numVertPixel *= PRINT_VERT_SCALE;
	numVertPixel += PRINT_YOFFSET;
 	numVertPixel < 480 ? 480 : numVertPixel;
 	[scrollView setContentSize:CGSizeMake(320, numVertPixel)];
			
	// if this is new printing output, then we want to position the print view
	// on the newely printed lines
	if (lastPrintPosition != 0)
	{
		CGRect frame = [scrollView frame];
		// If there is not enough content to fill the print view, then don't
		// try and reposition.
		int buflength = [printBuff length]/18;
		if (frame.size.height < buflength*PRINT_VERT_SCALE)
		{
			if (frame.size.height > (buflength - lastPrintPosition)*PRINT_VERT_SCALE)
			{
				// If there are not enough lines to fill the print view, then we 
				// position the view so that the end of the content is at the bottom of the 
				// view.
				[scrollView setContentOffset:CGPointMake(0, 
					(buflength*PRINT_VERT_SCALE - frame.size.height)) animated:FALSE];
			}
			else
			{
				// Position the new printed lines at the top of the print view
				[scrollView setContentOffset:CGPointMake(0,
					lastPrintPosition*PRINT_VERT_SCALE) animated:FALSE];
			}
		}
		lastPrintPosition = 0;
	}		

    [self rePosition:(UIScrollView*)[self view] force:TRUE];
	
}

- (void)awakeFromNib
{	
	// Get the navigation item that represent this controller in the 
	// navigation bar, and add our clear button to it
	UIBarButtonItem* clearButton = 
	[[UIBarButtonItem alloc] initWithTitle:@"Clear"
		style:UIBarButtonItemStylePlain target:self action:@selector(clearPrinter)];
	UINavigationItem* item = [self navigationItem];	
	[item setRightBarButtonItem:clearButton animated:FALSE];

	// Initialize the two views we will use to tile the scroll view.
	printViewController = self;
	if (!printBuff) printBuff = [[NSMutableData alloc] init];
	view1 = [[PrintView alloc] initWithFrame:CGRectMake(0,0,320,480)];	
	view2 = [[PrintView alloc] initWithFrame:CGRectMake(0,480,320,480)];
	[view1 setPrintViewController:self];
	[view2 setPrintViewController:self];
	[[self view] addSubview: view1];
	[[self view] addSubview: view2];	
	UIColor* bgColor = [UIColor colorWithRed:0.94 green:0.91 blue:0.82 alpha:1.0];
	[view1 setBackgroundColor:bgColor];
	[view2 setBackgroundColor:bgColor];
	[view1 setNeedsDisplay];
	[view2 setNeedsDisplay];
	
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView 
{
	[self rePosition:scrollView force:FALSE];
}

- (void)blitToView:(UIView *)view  offset:(int)offset
{
	
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */

/*
 If you need to do additional setup after loading the view, override viewDidLoad.
- (void)viewDidLoad {
}
 */


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];	
//	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Memory Allert"
//	    message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] autorelease];	
//	[alert show];
}


- (void)dealloc {
	[printBuff dealloc];
	[super dealloc];
}

@end
