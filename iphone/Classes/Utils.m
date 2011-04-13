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

#include <math.h>
#import "Utils.h"

// TODO make safe against overwriting!!!

void hp2utf8(char* src, int slen, char* dst, int dlen)
{
    int idx = 0;
    int scnt = 0;
    for (unsigned char *c = (unsigned char*)src; scnt < slen && idx < dlen-1; c++, scnt++)
    {
        // According to HP manual, characters greater then 129 are treated like 
        // characters beginning at 2.
        if (*c > 129) *c -= 128;
        
        switch (*c)
        {
            case 0: // divide
                dst[idx++] = 0xC3;
                dst[idx++] = 0xB7;
                break;
            case 1: // multiply (cross x)
                dst[idx++] = 0xC3;
                dst[idx++] = 0x97;
                break;                
            case 2: // square root
                dst[idx++] = 0xE2;
                dst[idx++] = 0x88;
                dst[idx++] = 0x9A;
                break;                
            case 3: // Integral symbol
                dst[idx++] = 0xE2;
                dst[idx++] = 0x88;
                dst[idx++] = 0xAB;
                break;                
            case 4: // Delete symbol (greyed box)
                dst[idx++] = 0xE2;
                dst[idx++] = 0x90;
                dst[idx++] = 0xA5;
                break;                
            case 5: // Summation
                dst[idx++] = 0xE2;
                dst[idx++] = 0x88;
                dst[idx++] = 0x91;
                break;                
            case 6: // right pointer (program running symbol)
                dst[idx++] = 0xE2;
                dst[idx++] = 0x96;
                dst[idx++] = 0xBA;
                break;                
            case 7: // product
                dst[idx++] = 0xE2;
                dst[idx++] = 0x88;
                dst[idx++] = 0x8F;
                break;                
            case 9: // less than equal to
                dst[idx++] = 0xE2;
                dst[idx++] = 0x89;
                dst[idx++] = 0xA4;
                break;                
            case 10: // line feed
                dst[idx++] = 0xE2;
                dst[idx++] = 0x90;
                dst[idx++] = 0x8A;
                break;                
            case 11: // greater than equal to
                dst[idx++] = 0xE2;
                dst[idx++] = 0x89;
                dst[idx++] = 0xA5;
                break;                
            case 12: // not equal
                dst[idx++] = 0xE2;
                dst[idx++] = 0x89;
                dst[idx++] = 0xA0;
                break;                
            case 13: // return
                dst[idx++] = 0xE2;
                dst[idx++] = 0x86;
                dst[idx++] = 0xB5;
                break;                
            case 14: // down arrow
                dst[idx++] = 0xE2;
                dst[idx++] = 0x86;
                dst[idx++] = 0x93;
                break;                
            case 15: // right arrow
                dst[idx++] = 0xE2;
                dst[idx++] = 0x86;
                dst[idx++] = 0x92;
                break;                
            case 16: // left arrow
                dst[idx++] = 0xE2;
                dst[idx++] = 0x86;
                dst[idx++] = 0x90;
                break;                
            case 17: // micro
                dst[idx++] = 0xC2;
                dst[idx++] = 0xB5;
                break;
            case 18: // Pound Currency
                dst[idx++] = 0xC2;
                dst[idx++] = 0xA3;
                break;                
            case 19: // left arrow
                dst[idx++] = 0xE2;
                dst[idx++] = 0x86;
                dst[idx++] = 0x90;
                break;                
            case 20: // A with hat
                dst[idx++] = 0xC3;
                dst[idx++] = 0x85;
                break;                
            case 21: // N with squiggle
                dst[idx++] = 0xC3;
                dst[idx++] = 0x91;
                break;                
            case 22: // A omlaut
                dst[idx++] = 0xC3;
                dst[idx++] = 0x84;
                break;                
            case 23: // Angle
                dst[idx++] = 0xE2;
                dst[idx++] = 0x88;
                dst[idx++] = 0xA1;
                break;                
            case 24: // The exponent character
                dst[idx++] = 'e'; 
                break;
            case 25: // funky symbol... (not sure what this is)
                dst[idx++] = 0xC3;
                dst[idx++] = 0x86;
                break;                
            case 26: // The continuation char, indicates number too long for buffer
                dst[idx++] = '+'; 
                break;
            case 27: // E/C symbol, but this is actually E/M
                dst[idx++] = 0xE2;
                dst[idx++] = 0x90;
                dst[idx++] = 0x99;
                break;
            case 28: // O omlaut
                dst[idx++] = 0xC3;
                dst[idx++] = 0x96;
                break;
            case 29: // U omlaut
                dst[idx++] = 0xC3;
                dst[idx++] = 0x9C;
                break;
            case 30: // Delete symbol (candidate for replacement)
                dst[idx++] = 0xE2;
                dst[idx++] = 0x90;
                dst[idx++] = 0xA5;
                break;                
            case 31: // Bullet
                dst[idx++] = 0xE2;
                dst[idx++] = 0x88;
                dst[idx++] = 0x99;
//                dst[idx++] = 0x80;
//                dst[idx++] = 0xA2;
                break;                
            case 94: // up arrow
                dst[idx++] = 0xE2;
                dst[idx++] = 0x86;
                dst[idx++] = 0x91;
                break;
            case 127: // Append character
                dst[idx++] = 0xE2;
                dst[idx++] = 0x94;
                dst[idx++] = 0xA3;
                break;
            case 128: // Actually a left shifted colon.. 
                dst[idx++] = ':';
                break;
            case 129: // Actuall a three progned shape, cant find it though (candidate replace)
                dst[idx++] = 'Y';
                break;
            default:
                dst[idx++] = *c;
                break;
        }
    }
    dst[idx] = 0; // null terminate
}



/**
 * Draw a bitmap image in data to a CGContext. data points to a one bit per pixel data buffer
 * which is blitted to the context.  We us this to blit Free42's display bit image to 
 * BlitterView and for blitting print data to PrintView.h.
 */
void drawBlitterDataToContext(CGContextRef ctx,   // Context to blit to 
		 const char* data,   // data buffer to read from, size is in bytes is height*byte_width
		 int xoffset,        // horz offset for drawing to the context
	     int yoffset,        // vert offset for drawing to the context
		 int height,         // pixel height of data in the data buffer.
		 int byte_width,     // number of bytes per row
		 float xscale,       // horz scale factor when blitting to context							  
		 float yscale,       // vert scale factor when blitting to context
         int hlclip,         // horz clip, left
		 int hrclip,         // horz clip, right
         int inv)            // If we should draw inverse
{
	assert(data);
	// We draw free42's display to the context, then we scale it
	// to fit
	CGContextSaveGState(ctx);
	CGContextTranslateCTM(ctx, xoffset, yoffset);
	CGContextScaleCTM(ctx, xscale, yscale);
	for(int h=0; h < height; h++)
	{
        int xpos = 0;
		for(int w=0; w < byte_width; w++)
		{
			char byte = data[h*byte_width + w];
			if (byte)  // Quick test to see if we even need to display anything in the byte
			{
  			for (int bcnt = 0; bcnt < 8; bcnt++)
 			{				
				int isset = byte&1;
				if ((isset^inv) && xpos > hlclip && xpos < hrclip)
				{
					int ypos = h;
					// Strange that CG provides no way to set a single
					// pixel, so we draw a rect one pixel in size.
					CGContextFillRect(ctx, CGRectMake(xpos,ypos, 1, 1));
				}
				byte >>= 1;
				xpos += 1;
			}
			}
			else
			{
				xpos += 8;
			}
		}
	}	
	
	// Restore the back to the old context so we no longer scale
    CGContextRestoreGState(ctx);	
}

