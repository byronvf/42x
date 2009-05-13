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

#import <UIKit/UIKit.h>

void drawBlitterDataToContext(CGContextRef ctx, const char* data, int xoffset, 
			int yoffset, int height, int byte_width, float xscale, float yscale, int hl, int hr, int inv);


void drawFastBlitDataToContext(CGContextRef ctx,   // Context to blit to 
							   const char* data,   // data buffer to read from, size is in bytes is height*byte_width
							   int xoffset,        // horz offset for drawing to the context
							   int yoffset,        // vert offset for drawing to the context
							   int height,         // pixel height of data in the data buffer.
							   int byte_width,     // number of bytes per row
                               int offset);
