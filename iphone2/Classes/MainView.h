/*****************************************************************************
 * Free42 -- an HP-42S calculator simulator
 * Copyright (C) 2004-2009  Thomas Okken
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License, version 2,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see http://www.gnu.org/licenses/.
 *****************************************************************************/

#import <UIKit/UIKit.h>


@interface MainView : UIView {
	//
}

- (void) initialize;
- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event;
- (void) setNeedsDisplayInRectSafely:(CGRect) rect;
+ (void) quit;
- (void) setTimeout:(int) which;
- (void) cancelTimeout3;
- (void) setRepeater:(int) delay;
- (void) cancelRepeater;

@end
