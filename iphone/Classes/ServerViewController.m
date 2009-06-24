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
#include <stdarg.h>
#include <netdb.h>

#include "shell.h"
#include "core_main.h"

/* simpleserver logger */
void errprintf(const char *fmt, ...) {
	/* TODO: write to the screen? */
    va_list ap;
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
}

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
    fcntl(ssock,F_SETFL,O_NONBLOCK);
	
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

extern void handle_client(int);

- (int) handleRequest
{
    int csock;
    struct sockaddr_in ca;
    int err;
	
	unsigned int n = sizeof(ca);
	csock = accept(ssock, (struct sockaddr *) &ca, &n);
	
	// csock inherits NONBLOCK from the server socket. the simple web
	// server requires the socket to block, so we clear the non-block flag here.
	int flags = fcntl(csock, F_GETFL);
	fcntl(csock, F_SETFL, flags & ~O_NONBLOCK);
	
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
	close(csock);
	// Check sooner since there are probably additional requests.
	[self performSelector:@selector(handleRequest) withObject:NULL afterDelay:0.1];	
	return 0;
}


- (NSString*) getHost
{
	NSString* addr = NULL;
	struct ifaddrs *list = NULL;
	if(getifaddrs(&list) < 0)
	{
		perror("getifaddrs");
		return nil;
	}
	
	struct ifaddrs *cur;	
	for(cur = list; cur != NULL; cur = cur->ifa_next)
	{
		if(cur->ifa_addr->sa_family != AF_INET) continue;
		
		struct sockaddr_in *addrStruct = (struct sockaddr_in *)cur->ifa_addr;
		NSString *name = [NSString stringWithCString:cur->ifa_name];
		// only the wireless interface begins with "en"
		if ([name hasPrefix:@"en"])
		{	
			struct hostent *h = gethostbyaddr(&addrStruct->sin_addr, 
											  sizeof(addrStruct->sin_addr), AF_INET);
			// Test if we can use a DNS host name, otherwise use the IP
			if (h != NULL)
			    addr = [NSString stringWithCString:h->h_name];

			// If the dns name is longer then 20 characters, like an auto assign
			// dns name, then we use the ip since it will probably be simpler to type
			if (addr == NULL || [addr length] > 20)
				addr = [NSString stringWithCString:inet_ntoa(addrStruct->sin_addr)];
			
			break;
		}
	}
	
	freeifaddrs(list); 	
	return addr;
}


#define PORT_START 8000
#define NUM_TRIES 3

- (void)startServer
{	
	int port = PORT_START-1;
	NSString* host = [self getHost];
	NSString* msg = @"You are not connected to a wireless network";	
	if (host)
	{
		int status;
		do
		{
		   // The user may pop right back into this view after using it 
		   // Which means that the port may still be in use,  so we try
		   // a few port numbers, then give up.
  		   status = [self init: ++port];
		}
		while(status == EADDRINUSE && port < PORT_START + NUM_TRIES - 1);			
		if (status)
		{
			// Something went wrong initializing...
		    msg = [NSString stringWithFormat:@"Error - %s (%i)", strerror(status), status];
		}
		else
		{
			
		    msg = [NSString stringWithFormat:@"http://%@:%i", host, port];
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
