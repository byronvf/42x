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
#include "PrintViewController.h"
#include "Utils.h"

@implementation PrintView

@synthesize printViewController;
@synthesize offset;

- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		// Initialization code
	}
	return self;
}

- (void)drawRect:(CGRect)rect 
{	
	NSMutableData* buf = [printViewController printBuff];
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
		drawFastBlitDataToContext(ctx, beginBuf, 15, 0, length, 18, adjOffset);
}

- (void)dealloc {
	[super dealloc];
}

@end