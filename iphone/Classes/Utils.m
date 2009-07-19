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

void drawFastBlitDataToContext(CGContextRef ctx,   // Context to blit to 
							  const char* data,   // data buffer to read from, size is in bytes is height*byte_width
							  int xoffset,        // horz offset for drawing to the context
							  int yoffset,        // vert offset for drawing to the context
							  int height,         // pixel height of data in the data buffer.
							  int byte_width,     // number of bytes per row
                              int offset)
{
	assert(data);
	// We draw free42's display to the context, then we scale it
	// to fit
	UInt32* ui = (UInt32*)CGBitmapContextGetData(ctx);
	int ty = 0;
	for(int h=0; h < height; h++)
	{
        int tx = xoffset;
		//Commented out the pale blue stripes
		//They get out of sync with the printed text when PRLCD
		//is used -- text lines are 9 pixels high, PRLCD output
		//is 16 pixels high...
		//int altclr = (offset++ + 1) % 18;
		for(int w=0; w < byte_width; w++)
		{
			char byte = data[h*byte_width + w];
			for (int bcnt = 0; bcnt < 8; bcnt++)
			{				
				int isset = byte&1;
				int tm = ty*320;
				if (isset)
				{
					// Strange that CG provides no way to set a single
					// pixel, so we draw a rect one pixel in size.
//					CGContextFillRect(ctx, CGRectMake(xpos,ypos, 1, 1));
					*(ui + tm + tx) = 0;
					*(ui + tm + tx + 1) = 0;
					*(ui + tm + 320 + tx) = 0;
					*(ui + tm + 320 + tx + 1) = 0;
				}
				//else if (altclr > 8)
				//{
				//	*(ui + tm + tx) = 0xD0D0D0;
				//	*(ui + tm + tx + 1) = 0xD0D0D0;
				//	*(ui + tm + 320 + tx) = 0xD0D0D0;
				//	*(ui + tm + 320 + tx + 1) = 0xD0D0D0;					
				//}
				
				byte >>= 1;
				tx += 2;
			}
		}
		
		ty += 2;
	}	
}
