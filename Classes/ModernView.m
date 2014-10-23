//
//  ModernView.m
//  42x
//
//  Created by Byron Foster on 10/24/12.
//
//

#import "ModernView.h"

@implementation ButtonInfo
@end

typedef struct
{
	NSString *label;
	NSString *shiftLabel;
	bool isMenu;
} btnlable_struct;


@implementation ModernView

const int SPACING = 1;
const int PIXEL_WIDTH = 320;
const int PIXEL_HEIGHT_TOP_BUTTONS = 170;
const int PIXEL_HEIGHT_BOTTOM_BUTTONS = 220;
const int LCD_HEIGHT = 90;

btnlable_struct btnlabels[] =
{
	{@"∑+", @"∑-", FALSE},
	{@"1/x", @"y^x", FALSE},
	{@"√x", @"x^2", FALSE},
	{@"LOG", @"10^x", FALSE},
	{@"LN", @"e^x", FALSE},
	{@"XEQ", @"GTO", FALSE},
	{@"STO", @"COMPLEX", FALSE},
	{@"RCL", @"%", FALSE},
	{@"R⬇", @"PI", FALSE},
	{@"SIN", @"ASIN", FALSE},
	{@"COS", @"ACOS", FALSE},
	{@"TAN", @"ATAN", FALSE},
	{@"ENTER", @"ALPHA", TRUE},
	{@"x<>y", @"LAST X", FALSE},
	{@"+/-", @"MODES", TRUE},
	{@"E", @"DISP", TRUE},
	{@"⬅", @"CLEAR", TRUE},
	{@"▲", @"BST", FALSE},
	{@"7", @"SOLVER", TRUE},
	{@"8", @"∫f(x)", TRUE},
	{@"9", @"MATRIX", TRUE},
	{@"÷", @"STAT", TRUE},
	{@"▼", @"SST", FALSE},
	{@"4", @"BASE", TRUE},
	{@"5", @"CONVERT", TRUE},
	{@"6", @"FLAGS", TRUE},
	{@"×", @"PROB", TRUE},
	{@"SHIFT", @"", FALSE},
	{@"1", @"ASSIGN", FALSE},
	{@"2", @"CUSTOM", TRUE},
	{@"3", @"PGM.FCN", TRUE},
	{@"-", @"PRINT", TRUE},
	{@"EXIT", @"OPTIONS", FALSE},
	{@"0", @"TOPFCN", TRUE},
	{@".", @"SHOW", FALSE},
	{@"R/S", @"PRGM", FALSE},
	{@"+", @"CATALOG", TRUE}
};


- (ButtonInfo*) makeButton: (int)col row:(int)row doubleWidth:(bool)dw numCols:(int)numCols numRows:(int)numRows
				  areaRect: (CGRect)area bNum:(int)bnum
{
	NSAssert(row < numRows && col < numCols, @"row or col out of bounds");
	ButtonInfo* bi = [[ButtonInfo alloc] init];
	int btn_top = row*area.size.height/numRows + SPACING + area.origin.y;
	int btn_bot = (row+1)*area.size.height/numRows - SPACING + area.origin.y;
	
	int btn_left = col*PIXEL_WIDTH/numCols + SPACING;
	int btn_right = (col + 1 + (dw?1:0))*PIXEL_WIDTH/numCols - SPACING;
	
	bi = [[ButtonInfo alloc] init];
	bi->rect = CGRectMake(btn_left, btn_top, btn_right-btn_left, btn_bot-btn_top);
	bi->num = bnum;
	bi->label = btnlabels[bnum].label;
	bi->shiftLabel = btnlabels[bnum].shiftLabel;
	bi->isMenu = btnlabels[bnum].isMenu;
	
	return bi;
}

- (void)awakeFromNib
{
	NSMutableArray *mbtns = [[NSMutableArray alloc] init];
	ButtonInfo *bi = NULL;
	
	CGRect rect = [self frame];
	NSLog(@"key pad nib (%f, %f, %f, %f)", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
	int bnum = 0;

	// Upper 3 rows of buttons
	CGRect buttonArea = CGRectMake(0, LCD_HEIGHT,
								   PIXEL_WIDTH, PIXEL_HEIGHT_TOP_BUTTONS);
	for (int row=0; row<3; row++)
	{
		for (int col=0; col<6; col++)
		{
			bool isDoubleWidth = row == 2 && col == 0;
			bi = [self makeButton:col row:row doubleWidth:isDoubleWidth numCols:6 numRows:3
						 areaRect:buttonArea bNum:bnum];
			if (isDoubleWidth) col++;
			
			[mbtns addObject:bi];
			bnum++;
		}
	}

	// Button 4 rows
	buttonArea = CGRectMake(0, LCD_HEIGHT+PIXEL_HEIGHT_TOP_BUTTONS,
						    PIXEL_WIDTH, PIXEL_HEIGHT_BOTTOM_BUTTONS);

	for (int row=0; row<4; row++)
	{
		for (int col=0; col<5; col++)
		{
			bi = [self makeButton:col row:row doubleWidth:false numCols:5 numRows:4
						 areaRect:buttonArea bNum:bnum];
			
			[mbtns addObject:bi];
			bnum++;
		}
	}
		
	buttons = [[NSArray alloc] initWithArray:mbtns];
	NSAssert([buttons count] == 37, @"There should be 37 buttons");
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [[event allTouches] anyObject];
	CGPoint p = [touch locationInView:self];
	
	for (int i=0; i<[buttons count]; i++)
	{
		ButtonInfo *button = [buttons objectAtIndex:i];
		if (p.x >= button->rect.origin.x &&
			p.x <= button->rect.origin.x + button->rect.size.width &&
			p.y >= button->rect.origin.y &&
			p.y <= button->rect.origin.y + button->rect.size.height)
		{
			int keynum = button->num+1;
			[calcViewController keyDown:keynum];
		}
	}
	
	// DEBUG
	NSLog(@"Recieved Event %f, %f", p.x, p.y);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[calcViewController keyUp];
}

- (void)drawRect:(CGRect)rect
{
	NSLog(@"Drawing key pad (%f, %f, %f, %f)", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
	
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	UIFont *fontShift = [UIFont boldSystemFontOfSize:12];
	UIFont *fontnorm = [UIFont boldSystemFontOfSize:14];
	
	for (int i=0; i<[buttons count]; i++)
	{
		ButtonInfo *button = [buttons objectAtIndex:i];
		CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 0.3);
		CGContextFillRect(ctx, button->rect);

        CGContextSetRGBFillColor(ctx, 1.0, 0.70, 0.10, 1.0);
		CGRect rect = button->rect;

		rect.origin.x += 2;
		rect.origin.y += 2;
		rect.size.width -= 4;
		rect.size.height = rect.size.height/2 - rect.size.height/4;
		
		if (button->isMenu)
		{
			CGRect menuRect = rect;
			menuRect.size.height += 4;
			CGContextSetRGBFillColor(ctx, 0.15, 0.15, 0.15, 1.0);
			CGContextFillRect(ctx, menuRect);
		}
		
		
        CGContextSetRGBFillColor(ctx, 1.0, 0.70, 0.10, 1.0);
        [button->shiftLabel drawInRect:rect
               withFont:fontShift lineBreakMode:NSLineBreakByClipping
              alignment:UITextAlignmentCenter];

		rect.origin.y += rect.size.height + button->rect.size.height/8;
		rect.size.height = button->rect.size.height/2;
		
        CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, .9);
        [button->label drawInRect:rect
						 withFont:fontnorm lineBreakMode:NSLineBreakByClipping
							 alignment:UITextAlignmentCenter];
		
		
	}
}

@end
