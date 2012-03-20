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
@synthesize label1;
@synthesize label2;
@synthesize label3;
@synthesize label4;
@synthesize label5;
@synthesize label6;

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
    else if (*menu == MENU_CONVERT3 || *menu == MENU_CONVERT4)
    {
        return menus[id].child[i].title_length != 0;			
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
            case MENU_PGM_XCOMP0:
            case MENU_PGM_XCOMPY:
                
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
        char xvstr[length+2];
        
        // modify the matrix string so it is more compact
        len = vartype2string(v, xvstr, length+2)-1;
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
        
        if (xvstr[len-1] == CONT_CHAR)
            xvstr[length-1] = CONT_CHAR;
        
        for (int i=0; i<len; i++)
            vstr[i] = xvstr[i];
        
    }
    else if (v->type == TYPE_REAL)
    {        
        phloat f = ((vartype_real *) v)->x;
        
        // adjust displaying smaller fractional values without an exponent
        // I think that 42S's display should have done it the same way.
        if (f <= -0.01 && f > -1.0)
        {
            Phloat adj = pow(10, length-1); 
            f = floor(f*adj);
            f = f/adj;
        }
        else if (f >= 0.01 && f < 1.0)
        {
            Phloat adj = pow(10, length); 
            f = floor(f*adj);
            f = f/adj;
        }
        
        len = phloat2string(f, vstr, length,
                             1, // Decimal mode
                             length,
                             3, // Display mode all
                             FALSE); // no decimal seperator
        
        // If the converted string 
        if (vstr[len-1] == CONT_CHAR && (f >= 100000 || f <= -10000 
                                     || (f < 0.01 && f > -0.01)))
        {            
            int digits = length - 4;
            if (f < 0) digits--; // make room for the minus sign
            if (fabs(f) < 1.0) digits--; // make room for a negative exponent
            if (f >= 10000000000.0) digits--; //make room for a double digit exp
            
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
    const int dispsize = 7; // number of characters to display for menu superscript
    int length = 0;
    const char* text = NULL;
    
    int catsect = get_cat_section();
    if (catsect == CATSECT_VARS_ONLY || 
        catsect == CATSECT_CPX ||
        catsect == CATSECT_REAL ||
        catsect == CATSECT_MAT)
    {
        int itemindex = get_cat_item(i);
        length = vars[itemindex].length;
        text = vars[itemindex].name;
    }
    else if ((catsect == CATSECT_PGM_SOLVE && mode_appmenu == MENU_VARMENU) ||
        (catsect == CATSECT_PGM_INTEG && mode_appmenu == MENU_VARMENU))
    {
        int itemindex = find_menu_key(i+1);
        length = varmenu_labellength[itemindex];
        text = varmenu_labeltext[itemindex];
    }
    else if (catsect == CATSECT_PGM_INTEG && mode_appmenu == MENU_INTEG_PARAMS)
    {
        switch (i)
        {
            case 0: text = "LLIM"; length = 4; break;
            case 1: text = "ULIM"; length = 4; break;
            case 2: text = "ACC" ; length = 3; break;            
        }    
    }
    else if (mode_plainmenu >= MENU_CUSTOM1 && mode_plainmenu <= MENU_CUSTOM3)
    {
        int r = mode_plainmenu - MENU_CUSTOM1;
        length = custommenu_length[r][i];
        text = custommenu_label[r][i];
        int prgm;
        int4 pc;
        // If we find the label in the global program labels, then 
        // the custom menu will always execute the program when key is pressed, so we 
        // don't want to show a variable value.
        if (find_global_label(text, length, &prgm, &pc))
            length = 0; 
    }
    
    int menu = MENU_NONE;
    if (get_front_menu() != NULL)
        menu = *get_front_menu();
    
    NSString *str = NULL;
    if (length != 0)
    {
        vartype *v = recall_var(text, length); 
        if (v != NULL)
        {
            char vstr[dispsize];
            int len = vartype2small_string(v, vstr, dispsize);                
            char vutf8[dispsize*2];
            hp2utf8(vstr, len, vutf8, dispsize*2);
            str = [[NSString alloc] initWithUTF8String:vutf8];
            [str autorelease];
        }
    }
    else if (menu == MENU_TOP_FCN)
    {
        switch (i)
        {
            case 0: str = @"∑-"; break;
            case 1: str = @"y^x"; break;
            case 2: str = @"x²"; break;
            case 3: str = @"10^x"; break;
            case 4: str = @"e^x"; break;
            case 5: str = @"GTO"; break;
        }
        
    }
    else if (menu == MENU_BASE_A_THRU_F)
    {
        switch (i)
        {
            case 0: str = @"AND"; break;
            case 1: str = @"OR"; break;
            case 2: str = @"XOR"; break;
            case 3: str = @"NOT"; break;
            case 4: str = @"BIT?"; break;
            case 5: str = @"ROTXY"; break;
        }
        
    }
    else if (menu == MENU_STAT1)
    {
        switch (i)
        {
            case 0: str = @"∑-"; break;
        }
        
    }
    else if (menu == MENU_PGM_FCN1)
    {
        switch (i)
        {
            case 5: str = @"GTO"; break;
        }
        
    }
    
    if (str != NULL)
    {
        UIFont *font = [UIFont boldSystemFontOfSize:13];
        CGContextSetRGBFillColor(ctx, 1.0, 0.80, 0.23, 1.0);
        [str drawInRect:CGRectMake(5 + i*51, -2, 55, 24) 
               withFont:font lineBreakMode:UILineBreakModeClip
              alignment:UITextAlignmentCenter];
    }
    else
    {    
        if ([self keyIsDirectory:i])
            [self drawDirectoryMark:ctx key:i];
    }
}

- (NSString*)getKeyLabel: (int)i
{
	char utf8[MENU_ITEM_CHAR_LENGTH*3];
	hp2utf8(menu_items[i].chars, menu_items[i].length, utf8, MENU_ITEM_CHAR_LENGTH*3);
	NSString *str = [[[NSString alloc] initWithUTF8String:utf8] autorelease];
	return str;
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
	CGContextSetRGBFillColor(ctx, 1.0, 0.70, 0.30, 1.0);
	for (int i=0; i<6; i++)
	{
        if (menu_items[i].length > 0)
        {
            if (menu_items[i].highlight)
            {                
                CGContextFillRect(ctx, CGRectMake(16+i*50, 42, 38, 2));
            }
			
            [self superscript:ctx key:i];
		}
	}
	
	label1.text = [self getKeyLabel:0];
	label2.text = [self getKeyLabel:1];
	label3.text = [self getKeyLabel:2];
	label4.text = [self getKeyLabel:3];
	label5.text = [self getKeyLabel:4];
	label6.text = [self getKeyLabel:5];	
}


- (void)dealloc {
    [super dealloc];
}

@end
