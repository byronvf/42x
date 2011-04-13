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
#import "core_globals.h"
#import "core_main.h"
#import "core_display.h"
#import "core_variables.h"
#import "core_helpers.h"

extern int dispRows;

@implementation MenuView

@synthesize calcViewController;

- (id)initWithFrame:(CGRect)frame {
    if (self == [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}


- (BOOL)keyIsDirectory: (int)i
{
    if (mode_plainmenu == MENU_CATALOG && get_cat_section() == CATSECT_TOP
        && i < 5)
        return TRUE;
    
	int* menu = get_front_menu();
	if (menu == NULL) return FALSE;
	const menu_item_spec *mi = menus[*menu].child + i;
	int id = mi->menuid;

	if (id&0xF000)
	{
		int cmd = id&0xFFF;
		switch (cmd)
		{
			case CMD_EDIT:
			case CMD_SIMQ:
			case CMD_A_THRU_F:
			return TRUE;
		}
	}
	else
	{
		switch (id)
		{
			case MENU_ALPHA_ABCDE1:
			case MENU_ALPHA_ABCDE2:
            case MENU_ALPHA_FGHI:
            case MENU_ALPHA_JKLM:
			case MENU_ALPHA_NOPQ1:
			case MENU_ALPHA_NOPQ2:
            case MENU_ALPHA_RSTUV1:
			case MENU_ALPHA_RSTUV2:
            case MENU_ALPHA_WXYZ:
			case MENU_ALPHA_PAREN:
            case MENU_ALPHA_ARROW:
            case MENU_ALPHA_COMP:
            case MENU_ALPHA_MATH:
            case MENU_ALPHA_PUNC1:
            case MENU_ALPHA_PUNC2:
            case MENU_ALPHA_MISC1:
            case MENU_ALPHA_MISC2:
			case MENU_STAT_CFIT:
            case MENU_BASE_LOGIC:				
				
            return TRUE;
		}
	}
	
	return FALSE;
}

- (void)drawDirectoryMark: (CGContextRef)ctx key:(int) i
{
	int x = 23 + i*50;
	int y = 3;
	CGPoint A = {x, y};
	CGPoint B = {x+20, y};
	CGPoint C = {x+10, y+8};
	CGPoint points[3] = {A, B, C};
	CGContextBeginPath(ctx);
	CGContextAddLines(ctx, points, 3);	
	CGContextClosePath(ctx);
	CGContextSetRGBFillColor(ctx, 1.0, 0.67, 0.23, 1.0);
	CGContextFillPath(ctx);
}

#define CONT_CHAR 26  // The HP continuation char, 

// Convert a vartype to a small string we can show on the key display
// return string will not be null terminated
int vartype2small_string(vartype* v, char* vstr, int length)
{
    int len = 0;
    if (v->type == TYPE_COMPLEXMATRIX || v->type == TYPE_REALMATRIX)
    {
        // We need to make another string so we have a little more space to work with
        char xvstr[length+1];
        
        // modify the matrix string so it is more compact
        len = vartype2string(v, xvstr, length+1)-1;
        // after the space shift everything down a character
        for (int i=1; i<len; i++)
        {
            xvstr[i] = xvstr[i+1];
            if (xvstr[i] == ' ')
            {
                xvstr[i] = ']';
                len = i+1;
                // If we have room we place an i at the end to indicate a complex
                // matrix
                if (v->type == TYPE_COMPLEXMATRIX && len < length-1)
                {
                    len++;
                    xvstr[i+1] = 'i';
                }
                break;
            }
        }
        
        if (xvstr[len] == CONT_CHAR)
            xvstr[length-2] = CONT_CHAR;
        
        for (int i=0; i<len; i++)
            vstr[i] = xvstr[i];
        
    }
    else if (v->type == TYPE_REAL)
    {        
        phloat f = ((vartype_real *) v)->x;
        len = phloat2string(f, vstr, length,
                             1, // Decimal mode
                             length,
                             3, // Display mode all
                             FALSE); // no decimal seperator
        if (vstr[len-1] == CONT_CHAR && (f > 10000 || f < 0.01)
                                     && (f < -10000 || f > -.01))
        {            
            int digits = length - 4;
            if (f < 0) digits--;
            if (f > 9999999999.0) digits--;
            
            // doesn't fit.. switch to SCI mode
            len = phloat2string(f, vstr, length,
                                1, // Decimal mode
                                digits,
                                1, // Display mode sci
                                FALSE); // no decimal seperator            
        }
        
        
        
    }
    else
    {
        len = vartype2string(v, vstr, length-1); // -1 to make room for null 
    }

    return len;
}

- (void) superscript: (CGContextRef)ctx  key:(int)i
{
    const int dispsize = 7;   
    
    int catsect = get_cat_section();
    if (catsect == CATSECT_VARS_ONLY || 
        (catsect == CATSECT_PGM_SOLVE && mode_appmenu == MENU_VARMENU) ||
        (catsect == CATSECT_PGM_INTEG && mode_appmenu == MENU_VARMENU) ||
        catsect == CATSECT_CPX ||
        catsect == CATSECT_REAL ||
        catsect == CATSECT_MAT)
    {
        int length = 0;
        char* text = NULL;
        
        if (mode_appmenu == MENU_VARMENU)
        {
            int itemindex = find_menu_key(i+1);
            length = varmenu_labellength[itemindex];
            text = varmenu_labeltext[itemindex];
        }
        else
        {
            int itemindex = get_cat_item(i);
            length = vars[itemindex].length;
            text = vars[itemindex].name;
        }
        
        vartype *v = recall_var(text, length); 
        if (v != NULL)
        {
            char vstr[dispsize];
            int len = vartype2small_string(v, vstr, dispsize);                
            char vutf8[dispsize*2];
            hp2utf8(vstr, len, vutf8, dispsize*2);
            NSString *str = [[NSString alloc] initWithUTF8String:vutf8];
            UIFont *font = [UIFont boldSystemFontOfSize:13];
            CGContextSetRGBFillColor(ctx, 1.0, 0.80, 0.23, 1.0);
            [str drawInRect:CGRectMake(5 + i*51, -2, 55, 24) 
                        withFont:font lineBreakMode:UILineBreakModeClip
                        alignment:UITextAlignmentCenter];
            [str release];
        }
    }
    else
    {    
        if ([self keyIsDirectory:i])
            [self drawDirectoryMark:ctx key:i];
    }
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
	CGContextSetRGBFillColor(ctx, 0.90, 0.90, 0.90, 1.0);
    UIFont *font = [UIFont boldSystemFontOfSize:14];
	
	
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
        if (menu_items[i].length > 0)
        {
            if (menu_items[i].highlight)
                CGContextSetRGBFillColor(ctx, 0.50, 1.0, 0.50, 1.0);
            else
                CGContextSetRGBFillColor(ctx, 0.90, 0.90, 0.90, 1.0);
                
            //drawBlitterDataToContext(ctx, menuBuff, horzoff, 28, 5, 17, 2.0, 3.0, i*22, (i+1)*22-1, 1);
            horzoff += 6;
        
            char utf8[MENU_ITEM_CHAR_LENGTH*3];
            hp2utf8(menu_items[i].chars, menu_items[i].length, utf8, MENU_ITEM_CHAR_LENGTH*3);
            NSString *str = [[NSString alloc] initWithUTF8String:utf8];        
            [str drawInRect:CGRectMake(13 + i*50, 25, 44, 20) 
                   withFont:font lineBreakMode:UILineBreakModeClip
                  alignment:UITextAlignmentCenter];
        
            [str release];
            [self superscript:ctx key:i];
        }
	}
	
}


- (void)dealloc {
    [super dealloc];
}

@end
