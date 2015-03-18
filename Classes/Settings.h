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
#import <AudioToolbox/AudioServices.h>
#include "core_globals.h"


@interface Settings : NSObject {
	
	
	bool clickSoundOn;
	bool beepSoundOn;
	bool keyboardOn;
	bool showLastX;
	bool autoPrint;
	bool dropFirstClick;
	bool showFlags;
	
	// Indicates if we have used the PRLCD command which prints the LCD
	// to the display.  If so, then we must turn off the striping in the
	// print view becuase it will no longer align.
	bool printedPRLCD;
	
	@public
	
	SystemSoundID soundIDs[11];
}

@property bool showLastX;
@property bool clickSoundOn;
@property bool beepSoundOn;
@property bool keyboardOn;
@property bool printedPRLCD;
@property bool autoPrint;
@property bool dropFirstClick;
@property bool showFlags;
+ (Settings*)instance;

@end
