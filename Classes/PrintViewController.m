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
#import "Settings.h"
#include "Utils.h"
#include "core_display.h"
#include "Free42AppDelegate.h"
#include "shell_spool.h"

static PrintViewController* printViewController;
BOOL printingStarted = FALSE;

static char printFileStr[1024]; // name of print file
static FILE* printFile = NULL; 

// Keep track of the last position we printed so we can conveniently
// place the printer screen at the beginning of this new output.
static int lastPrintPosition = 0;

static void writer(const char *text, int length)
{
	if (!printFile)	printFile = fopen(printFileStr, "a");
	fwrite(text, 1, length, printFile);
}	

static void newliner()
{
	writer("\n", 1);
}


void shell_print(const char *text, int length,
				 const char *bits, int bytesperline,
				 int x, int y, int width, int height)
{
    shell_spool_txt(text, length, writer, newliner);
    
    assert(printViewController);
    NSMutableData* buf = [printViewController getBuff];
    if (!printingStarted)
    {
		printingStarted = TRUE;
		lastPrintPosition = (int)[buf length]/18;
    }
    
    if (bytesperline == 18) {
		// Regular text-mode print command
		if ([buf length] < 18*9*MAX_PRINT_LINES) 
			[buf appendBytes:bits length:18*9];
    } else {
		// PRLCD
		if ([buf length] < 18 * 8 * dispRows * MAX_PRINT_LINES) {
			for (int i = 0; i <  8*dispRows; i++) {
				[buf appendBytes:(bits + i * 17) length:17];
				[buf increaseLengthBy:1];
				[[Settings instance] setPrintedPRLCD:TRUE];
			}
		}
    }
	
    // If we the print display is showing, then we want to continue to update
    // the display as new print data is added, implying a program is still running
	printViewController.isSeen = FALSE;
    if (printViewController.isShowing)
	{
		printViewController.isSeen = TRUE;
		[printViewController display];
	}
}

@implementation PrintViewController

@synthesize printBuffer;
@synthesize isShowing;
@synthesize isSeen;

- (void)flushFile
{
	if (printFile) fflush(printFile);	
}

- (void)clearPrinter
{
	// Clear print file
	if (printFile) fclose(printFile);
	printFile = fopen(printFileStr, "w");	
		
	[view1 setFrame:CGRectMake(0,0,hsize,vsize)];
	[view2 setFrame:CGRectMake(0,vsize,hsize,vsize)];
	[view1 setOffset:0];
	[view2 setOffset:vsize];
	[[self getBuff] setLength:0];	
	[[Settings instance] setPrintedPRLCD:FALSE];
	[self display];
}

- (void)rePosition:(UIScrollView*)scrollView force:(BOOL)force
{
	CGPoint offset = [scrollView contentOffset];
	int tilenum = offset.y/vsize;
	int view1offset, view2offset;
	
	if (tilenum & 1) // If tilenum is odd
	{
		view2offset = tilenum*vsize;
		view1offset = (tilenum+1)*vsize;
	}
	else // tilenum is even
	{
		view1offset = tilenum*vsize;
		view2offset = (tilenum+1)*vsize;
	}
	
	if (force || [view1 offset] != view1offset)
	{
		[view1 setOffset:view1offset];
		[view1 setFrame:CGRectMake(0, view1offset, hsize, vsize)];
		[view1 setNeedsDisplay];
	}
	
	if (force || [view2 offset] != view2offset)
	{
		[view2 setOffset:view2offset];
		[view2 setFrame:CGRectMake(0, view2offset, hsize, vsize)];
		[view2 setNeedsDisplay];
	}		
}

- (void)displayPlotView
{
	UIScrollView* scrollView = (UIScrollView*)[self view];
	int numVertPixel = (int)[[self getBuff] length]/18;
 	numVertPixel *= PRINT_VERT_SCALE;
	numVertPixel += PRINT_YOFFSET;
 	numVertPixel = MAX(vsize, numVertPixel);
 	[scrollView setContentSize:CGSizeMake(hsize, numVertPixel)];
			
	// if this is new printing output, then we want to position the print view
	// on the newely printed lines
	if (lastPrintPosition != 0)
	{
		CGRect frame = [scrollView frame];
		// If there is not enough content to fill the print view, then don't
		// try and reposition.
		int buflength = (int)[[self getBuff] length]/18;
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

/**
 * Used to show the print views as blue during cut/paste to indicate that the
 * whole print output will be copied to the clipboard.  Calling with selected 
 * False return the display to the normal color.
 */
- (void)setViewsHighlight:(BOOL)selected
{
	UIColor* bgColor = NULL;
	if (selected)
	{
		bgColor = [UIColor colorWithRed:0.60 green:0.80 blue:1.0 alpha:1.0];
	}
	else
	{
		bgColor = [UIColor colorWithRed:0.94 green:0.91 blue:0.82 alpha:1.0];
	}
	[view1 setBackgroundColor:bgColor];
	[view2 setBackgroundColor:bgColor];
}

-(void)displayTextView
{
	// Experimental, but not being used at the moment.
	/*
	if (printFile) fflush(printFile);
	
	NSString* fileStr = [NSHomeDirectory() stringByAppendingString:PRINT_FILE_NAME];
	NSString *pout = [NSString stringWithContentsOfFile:fileStr encoding:NSASCIIStringEncoding
												  error:NULL];	
	textView.text = pout;
	textView.font = [UIFont fontWithName:@"Courier-Bold" size:16];
	textView.editable = FALSE;
	UIColor* bgColor = [UIColor colorWithRed:0.94 green:0.91 blue:0.82 alpha:1.0];
	[textView setBackgroundColor:bgColor];	
	[self setView:textView];	
	 */
}

-(void)display
{
	[self displayPlotView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView 
{
	[self rePosition:scrollView force:FALSE];
}

- (NSMutableData*) getBuff
{
	if (printBuffer == NULL)
	{
		printBuffer = [[NSMutableData alloc] init];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		if ([defaults objectForKey:CONFIG_PRINT_BUF])
		{
			NSData *data = [defaults dataForKey:CONFIG_PRINT_BUF];
			[printBuffer setData:data];
		}		
		
	}
	return printBuffer;		
}

- (void)awakeFromNib {
    // Get the navigation item that represent this controller in the 
    // navigation bar, and add our clear button to it
    [super awakeFromNib];
    UIBarButtonItem* clearButton = 
    [[UIBarButtonItem alloc] initWithTitle:@"Clear"
				     style:UIBarButtonItemStylePlain target:self action:@selector(clearPrinter)];
    UINavigationItem* item = [self navigationItem];	
    [item setRightBarButtonItem:clearButton animated:FALSE];
        
    strcpy(printFileStr, [[NSHomeDirectory() stringByAppendingString:PRINT_FILE_NAME] UTF8String]);	
    // Initialize the two views we will use to tile the scroll view.
    printViewController = self;
	
	isSeen = TRUE;  // WE should probably persist this at some point
}

- (void)viewDidLoad {
	
	view1 = [[PrintView alloc] initWithFrame:CGRectMake(0,0,hsize,vsize)];	
	view2 = [[PrintView alloc] initWithFrame:CGRectMake(0,vsize,hsize,vsize)];
	[view1 setPrintViewController:self];
	[view2 setPrintViewController:self];
    [self setViewsHighlight:FALSE];
	[[self view] addSubview: view1];
	[[self view] addSubview: view2];	
	[view1 setNeedsDisplay];
	[view2 setNeedsDisplay];
}

- (void)viewDidUnload {
	[self releasePrintBuffer];
	[view1 release];
	view1 = NULL;
	[view2 release];
	view2 = NULL;
}

- (void)releasePrintBuffer
{
	if (printBuffer != NULL)
	{
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setObject:printBuffer forKey:CONFIG_PRINT_BUF];	
		[printBuffer release];		
		printBuffer = NULL;
	}
	
	if (printFile) fclose(printFile);
	printFile = NULL;	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
