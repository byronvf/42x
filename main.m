//
//  main.m
//  Free42
//
//  Created by Jerrod Hofferth on 7/30/08.
//  Copyright Texas A&M Department of Aerospace Engineering 2008. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <unistd.h>

int main(int argc, char *argv[]) {
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	// This is so that the remainder of the Free42 code can assume that the current
	// directory is the home directory; this will be the top-level directory that
	// users can navigate with the built-in HTTP server.
	// TODO: Is UTF-8 the right encoding to use here? Does it matter?
	char *homedir = (char *) malloc(1024);
	[NSHomeDirectory() getCString:homedir maxLength:1024 encoding:NSUTF8StringEncoding];
	strcat(homedir, "/Documents");
	//NSLog([NSString stringWithCString:homedir encoding:NSUTF8StringEncoding]);
	chdir(homedir);
	free(homedir);
	
	int retVal = UIApplicationMain(argc, argv, nil, nil);
	[pool release];
	return retVal;
}
