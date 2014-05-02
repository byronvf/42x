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
const int PIXEL_WIDTH_TOP_BUTTONS = 170;
const int PIXEL_WIDTH_BOTTOM_BUTTONS = 220;
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

- (void)awakeFromNib
{
	NSMutableArray *mbtns = [[NSMutableArray alloc] init];
	ButtonInfo *bi = NULL;
	
	CGRect rect = [self frame];
	NSLog(@"key pad nib (%f, %f, %f, %f)", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
	
	int bnum = 0;
	for (int col=0; col<3; col++)
	{
		int btn_top = col*PIXEL_WIDTH_TOP_BUTTONS/3 + SPACING
		+ LCD_HEIGHT;
		int btn_bot = (col+1)*PIXEL_WIDTH_TOP_BUTTONS/3 - SPACING
		+ LCD_HEIGHT;
		
		for (int row=0; row<6; row++)
		{
			int btn_left = row*PIXEL_WIDTH/6 + SPACING;
			int btn_right = (row + 1)*PIXEL_WIDTH/6 - SPACING;

			if (col == 2 && row == 1)
			{
				bi->rect = CGRectMake(bi->rect.origin.x, bi->rect.origin.y,
									  btn_right-bi->rect.origin.x, btn_bot-bi->rect.origin.y);
			}
			else
			{
				bi = [[ButtonInfo alloc] init];
				bi->rect = CGRectMake(btn_left, btn_top, btn_right-btn_left, btn_bot-btn_top);
				bi->num = bnum;
				bi->label = btnlabels[bnum].label;
				bi->shiftLabel = btnlabels[bnum].shiftLabel;
				bi->isMenu = btnlabels[bnum].isMenu;
				[mbtns addObject:bi];
				bnum++;
			}
			
		}
	}
	
	for (int col=0; col<4; col++)
	{
		int btn_top = col*PIXEL_WIDTH_BOTTOM_BUTTONS/4 + SPACING
		+ LCD_HEIGHT + PIXEL_WIDTH_TOP_BUTTONS;
		int btn_bot = (col+1)*PIXEL_WIDTH_BOTTOM_BUTTONS/4 - SPACING
		+ LCD_HEIGHT + PIXEL_WIDTH_TOP_BUTTONS;
		
		for (int row=0; row<5; row++)
		{
			int btn_left = row*PIXEL_WIDTH/5 + SPACING;
			int btn_right = (row + 1)*PIXEL_WIDTH/5 - SPACING;

			bi = [[ButtonInfo alloc] init];
			bi->rect = CGRectMake(btn_left, btn_top, btn_right-btn_left, btn_bot-btn_top);
			bi->num = bnum;
			bi->label = btnlabels[bnum].label;
			bi->shiftLabel = btnlabels[bnum].shiftLabel;
			bi->isMenu = btnlabels[bnum].isMenu;
			[mbtns addObject:bi];
			bnum++;
		}
		
	}
		
	buttons = [[NSArray alloc] initWithArray:mbtns];
	NSAssert([buttons count] == 37, @"There should be 37 buttons");
	
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
