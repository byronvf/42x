//
//  main.m
//  Free42
//
//  Created by Jerrod Hofferth on 7/30/08.
//  Copyright Texas A&M Department of Aerospace Engineering 2008. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "core_main.h"

int main(int argc, char *argv[]) {
	
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	int retVal = UIApplicationMain(argc, argv, nil, nil);
	[pool release];
	return retVal;
}
