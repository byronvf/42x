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
	int fontSize;
} btnlable_struct;


@implementation ModernView

const int SPACING = 1;
const float upperKeysToBottomKeysRatio = .4;
const int LCD_HEIGHT = 90;
//const int LCD_HEIGHT = 150;

btnlable_struct btnlabels[] =
{
	{@"∑+", @"∑-", FALSE, 1},
	{@"1/x", @"y^x", FALSE, 1},
	{@"√x", @"x^2", FALSE, 1},
	{@"LOG", @"10^x", FALSE, 1},
	{@"LN", @"e^x", FALSE, 1},
	{@"XEQ", @"GTO", FALSE, 1},
	{@"STO", @"COMPLEX", FALSE, 1},
	{@"RCL", @"%", FALSE, 1},
	{@"R⬇", @"PI", FALSE, 1},
	{@"SIN", @"ASIN", FALSE, 1},
	{@"COS", @"ACOS", FALSE, 1},
	{@"TAN", @"ATAN", FALSE, 1},
	{@"ENTER", @"ALPHA", TRUE, 1},
	{@"x<>y", @"LAST X", FALSE, 1},
	{@"+/-", @"MODES", TRUE, 1},
	{@"E", @"DISP", TRUE, 1},
	{@"⬅", @"CLEAR", TRUE, 1},
	{@"▲", @"BST", FALSE, 2},
	{@"7", @"SOLVER", TRUE, 2},
	{@"8", @"∫f(x)", TRUE, 2},
	{@"9", @"MATRIX", TRUE, 2},
	{@"÷", @"STAT", TRUE, 3},
	{@"▼", @"SST", FALSE, 2},
	{@"4", @"BASE", TRUE, 2},
	{@"5", @"CONVERT", TRUE, 2},
	{@"6", @"FLAGS", TRUE, 2},
	{@"×", @"PROB", TRUE, 3},
	{@"SHIFT", @"", FALSE, 1},
	{@"1", @"ASSIGN", FALSE, 2},
	{@"2", @"CUSTOM", TRUE, 2},
	{@"3", @"PGM.FCN", TRUE, 2},
	{@"-", @"PRINT", TRUE, 3},
	{@"EXIT", @"OPTIONS", FALSE, 1},
	{@"0", @"TOPFCN", TRUE, 2},
	{@".", @"SHOW", FALSE, 3},
	{@"R/S", @"PRGM", FALSE, 1},
	{@"+", @"CATALOG", TRUE, 3}
};


- (ButtonInfo*) makeButton: (int)col row:(int)row doubleWidth:(bool)dw numCols:(int)numCols numRows:(int)numRows
				  areaRect: (CGRect)area bNum:(int)bnum
{
	NSAssert(row < numRows && col < numCols, @"row or col out of bounds");
	ButtonInfo* bi = [[ButtonInfo alloc] init];
	int btn_top = row*area.size.height/numRows + SPACING + area.origin.y;
	int btn_bot = (row+1)*area.size.height/numRows - SPACING + area.origin.y;
	
	int btn_left = col*area.size.width/numCols + SPACING;
	int btn_right = (col + 1 + (dw?1:0))*area.size.width/numCols - SPACING;
	
	bi = [[ButtonInfo alloc] init];
	bi->rect = CGRectMake(btn_left, btn_top, btn_right-btn_left, btn_bot-btn_top);
	bi->num = bnum;
	bi->label = btnlabels[bnum].label;
	bi->shiftLabel = btnlabels[bnum].shiftLabel;
	bi->isMenu = btnlabels[bnum].isMenu;
	bi->fontSize = btnlabels[bnum].fontSize;
	
	return bi;
}

/*
 Calculate the keybouard layout given the frame size.  We currently call this from calcViewController.viewWillAppear
 */
- (void)calcKeyLayout
{
	CGRect frame = self.frame;
	
	self->baseFontSize = frame.size.width*0.05;
	
	NSMutableArray *mbtns = [[NSMutableArray alloc] init];
	ButtonInfo *bi = NULL;
	
	NSLog(@"key pad nib (%f, %f, %f, %f)", frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
	int bnum = 0;
	
	// Upper 3 rows of buttons
	int upperKeyHeight = (frame.size.height-LCD_HEIGHT)*upperKeysToBottomKeysRatio;
	CGRect buttonArea = CGRectMake(0, LCD_HEIGHT, frame.size.width, upperKeyHeight);
	
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
	
	// Button 4 rows of buttons
	int lowerKeyHeight = frame.size.height - LCD_HEIGHT - upperKeyHeight;
	buttonArea = CGRectMake(0, LCD_HEIGHT+upperKeyHeight, frame.size.width, lowerKeyHeight);
	
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
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[calcViewController keyUp];
}

- (void)drawRect:(CGRect)rect
{
	NSLog(@"Drawing key pad (%f, %f, %f, %f)", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);

	CGContextRef ctx = UIGraphicsGetCurrentContext();
	UIFont *menuFont = [UIFont boldSystemFontOfSize:self->baseFontSize*0.75];
	UIFont *fontSize1 = [UIFont boldSystemFontOfSize:self->baseFontSize];
	UIFont *fontSize2 = [UIFont boldSystemFontOfSize:self->baseFontSize*1.25];
	UIFont *fontSize3 = [UIFont boldSystemFontOfSize:self->baseFontSize*1.5];
	
	//fontnorm = [UIFont fontWithName:@"Arial-BoldMT" size:15];
	//NSLog(@"%@",fontnorm.debugDescription);
	
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
               withFont:menuFont lineBreakMode:NSLineBreakByClipping
              alignment:UITextAlignmentCenter];

		rect.origin.y += rect.size.height + button->rect.size.height/8;
		rect.size.height = button->rect.size.height/2;
		
        CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, .9);
		
		UIFont* drawFont = fontSize1;
		if (button->fontSize == 2)
			drawFont = fontSize2;
		else if (button->fontSize == 3)
			drawFont = fontSize3;
		
        [button->label drawInRect:rect
						 withFont:drawFont lineBreakMode:NSLineBreakByClipping
							 alignment:UITextAlignmentCenter];		
	}
}

@end
