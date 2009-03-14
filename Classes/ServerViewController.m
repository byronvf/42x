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
char ipaddress[256];

- (int)init
{
    int port = 9090;
    int backlog = 32;
    struct sockaddr_in sa;
    int err;
	
    ssock = socket(AF_INET, SOCK_STREAM, 0);
    if (ssock == -1) {
		err = errno;
		fprintf(stderr, "Could not create socket: %s (%d)\n", strerror(err), err);
		return 1;
    }

	// Make accepts on socket non-blocking
    fcntl(ssock,F_SETFL,FNDELAY);
	
    sa.sin_family = AF_INET;
    sa.sin_port = htons(port);
    sa.sin_addr.s_addr = INADDR_ANY;
    err = bind(ssock, (struct sockaddr *) &sa, sizeof(sa));
    if (err != 0) {
		err = errno;
		fprintf(stderr, "Could not bind socket to port %d: %s (%d)\n", port, strerror(err), err);
		return 1;
    }
	
    err = listen(ssock, backlog);
    if (err != 0) {
		err = errno;
		fprintf(stderr, "Could not listen (backlog = %d): %s (%d)\n", backlog, strerror(err), err);
		return 1;
    }
	
	inet_ntop(AF_INET, &sa.sin_addr, ipaddress, sizeof(ipaddress));

	return 0;
}


extern void handle_client(int);

- (int)handleRequest
{
    int csock;
    struct sockaddr_in ca;
    int err;
	

    //ca.sin_family = AF_INET;
    //ca.sin_port = htons(9090);	
    //ca.sin_addr.s_addr = INADDR_ANY;	
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
	//inet_ntop(AF_INET, &ca.sin_addr, cname, sizeof(cname));
	/*fprintf(stderr, "Accepted connection from %s\n", cname);*/
	
	handle_client(csock);
	
	// Check sooner since there are probably additional requests.
	[self performSelector:@selector(handleRequest) withObject:NULL afterDelay:0.1];	
	return 0;
}

- (void)startServer
{
	[self init];
	char textbuf[256];
	sprintf(textbuf, "http://%s/9090", ipaddress);
	
	NSString* addr = [[NSString alloc] initWithBytes:textbuf length:strlen(textbuf)
											encoding:NSISOLatin1StringEncoding];
	[addressLabel setText:addr];
	[addr release];
	[self performSelector:@selector(handleRequest) withObject:NULL afterDelay:0.5];
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
