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

int main(int argc, char *argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	// This is so that the remainder of the Free42 code can assume that the current
	// directory is the home directory; this will be the top-level directory that
	// users can navigate with the built-in HTTP server.
	// TODO: Is UTF-8 the right encoding to use here? Does it matter?
	char *homedir = (char *) malloc(1024);
	[NSHomeDirectory() getCString:homedir maxLength:1024 encoding:NSUTF8StringEncoding];
	strcat(homedir, "/Documents");
	NSLog(@"home = %s", homedir);
	chdir(homedir);
	free(homedir);

    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
}
