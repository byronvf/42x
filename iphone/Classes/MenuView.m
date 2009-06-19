//
//  MenuView.m
//  Free42
//
//  Created by Byron Foster on 5/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MenuView.h"
#import "Utils.h"
#import "CalcViewController.h"

extern int dispRows;

@implementation MenuView

@synthesize calcViewController;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGContextSetRGBFillColor(ctx, 0.85, 0.85, 0.85, 1.0);	
	
	// 136 - size in bytes of one row.
	// 17*2 - absorb a couple of pixel rows	
	const char* menuBuff = calcViewController.displayBuff + dispRows*136 + 17*2;
	
	// 32 - vert pixel offset to begin drawing.
	// 5  - pixel height of display
	// 17 - number of bytes per line, each byte is an 8 pixel bit map. 
	// 2.0 - horz scale factor
	// 3.0 - vert scale factor
		
	int horzoff = 14;	
	for (int i=0; i<6; i++)
	{
  	  drawBlitterDataToContext(ctx, menuBuff, horzoff, 28, 5, 17, 2.0, 3.0, i*22, (i+1)*22-1, 1);
	  horzoff += 6;
	}
}

- (void)dealloc {
    [super dealloc];
}

@end
