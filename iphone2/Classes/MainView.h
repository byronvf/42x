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

#define SHELL_VERSION 1
#define FILENAMELEN 1024

typedef struct state_type {
	int printerToTxtFile;
	int printerToGifFile;
	char printerTxtFileName[FILENAMELEN];
	char printerGifFileName[FILENAMELEN];
	int printerGifMaxLength;
	char skinName[FILENAMELEN];
	int popupKeyboard;
};

extern state_type state;


@interface MainView : UIView <UIActionSheetDelegate> {
	//
}

- (void) initialize;
- (void) actionSheet:(UIActionSheet *) actionSheet clickedButtonAtIndex:(NSInteger) buttonIndex;
- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event;
- (void) setNeedsDisplayInRectSafely:(CGRect) rect;
+ (void) repaint;
+ (void) quit;
- (void) setTimeout:(int) which;
- (void) cancelTimeout3;
- (void) setRepeater:(int) delay;
- (void) cancelRepeater;

@end
