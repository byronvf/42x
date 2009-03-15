//
//  ServerViewController.m
//  Free42
//
//  Created by Byron Foster on 3/13/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ServerViewController.h"

#include <dirent.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <net/if.h>
#include <ifaddrs.h>

#include "shell.h"
#include "core_main.h"

@implementation ServerViewController

@synthesize addressLabel;

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

int ssock;

- (int)init: (int)port
{
    int backlog = 32;
    struct sockaddr_in sa;
	int err;
	
    ssock = socket(AF_INET, SOCK_STREAM, 0);
    if (ssock == -1) {
		return errno;
    }

	// Make accepts on socket non-blocking
    fcntl(ssock,F_SETFL,FNDELAY);
	
    sa.sin_family = AF_INET;
    sa.sin_port = htons(port);
    sa.sin_addr.s_addr = INADDR_ANY;
    err = bind(ssock, (struct sockaddr *) &sa, sizeof(sa));
    if (err != 0) {
		return errno;
    }
	
    err = listen(ssock, backlog);
    if (err != 0) {
		err = errno;
    }
	
	return 0;
}

int shell_write(const char *buf, int4 buflen)
{
	return 0;
}


int4 shell_read(char *buf, int4 buflen)
{
	return 0;
}

extern void handle_client(int);

- (int) handleRequest
{
    int csock;
    struct sockaddr_in ca;
    int err;
	
	unsigned int n = sizeof(ca);
	csock = accept(ssock, (struct sockaddr *) &ca, &n);
	if (csock == -1) {
		// If we fall out because of non blocking, and no sockets waiting
		err = errno;
		if (err != EWOULDBLOCK)
		{
    		fprintf(stderr, "Could not accept connection from client: %s (%d)\n", strerror(err), err);
		}
		[self performSelector:@selector(handleRequest) withObject:NULL afterDelay:0.5];
		return 1;
	}
	
	handle_client(csock);
	// Check sooner since there are probably additional requests.
	[self performSelector:@selector(handleRequest) withObject:NULL afterDelay:0.1];	
	return 0;
}


- (NSString*) getIpAddress
{
	struct ifaddrs *list;
	if(getifaddrs(&list) < 0)
	{
		perror("getifaddrs");
		return nil;
	}
	
	NSMutableArray *array = [NSMutableArray array];
	struct ifaddrs *cur;	
	for(cur = list; cur != NULL; cur = cur->ifa_next)
	{
		if(cur->ifa_addr->sa_family != AF_INET)
			continue;
		
		struct sockaddr_in *addrStruct = (struct sockaddr_in *)cur->ifa_addr;
		NSString *name = [NSString stringWithUTF8String:cur->ifa_name];
		NSString *addr = [NSString stringWithUTF8String:inet_ntoa(addrStruct->sin_addr)];
		[array addObject:
		 [NSDictionary dictionaryWithObjectsAndKeys:
		  name, @"name",
		  addr, @"address",
		  [NSString stringWithFormat:@"%@ - %@", name, addr], @"formattedName",
		  nil]];
	}
	
	freeifaddrs(list);	
	NSString *wlanAddress =  [[array objectAtIndex:1] valueForKey:@"address"];
	return wlanAddress;
}


- (void)startServer
{
	int port = 9089;
	NSString* ipAddr = [self getIpAddress];
	NSString* msg = @"You are not connected to a wireless network";	
	if (ipAddr)
	{
		int status;
		do
		{
		   // The user may pop right back into this view after using it 
		   // Which means that the port may still be in use,  so we try
		   // a few port numbers, then give up.
  		   status = [self init: ++port];
		}
		while(status == EADDRINUSE && port < 9095);			
		if (status)
		{
			// Something went wrong initializing...
		    msg = [NSString stringWithFormat:@"Error - %s (%i)", strerror(status), status];
		}
		else
		{
		    msg = [NSString stringWithFormat:@"http://%@/%i", ipAddr, port];
		   [self handleRequest];
		}
    }
	[addressLabel setText:msg];		
}


- (void)stopServer
{
	[[self class] cancelPreviousPerformRequestsWithTarget: self];	
	close(ssock);
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc {
    [super dealloc];
}


@end