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

#import "NavViewController.h"
#import "PrintViewController.h"
#import "ServerViewController.h"

static NavViewController *navCtrl = NULL;

void shell_powerdown()
{
	[navCtrl switchToView:[navCtrl configViewController]];
	[[navCtrl configViewController] setNavViewController:navCtrl];
}	

@implementation NavViewController

@synthesize configViewController;
@synthesize printViewController;
@synthesize serverViewController;
@synthesize calcViewController;


/**
 *  We are not using a NIB for this class, so this is never called
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {		
		// Initialization code
	}
	return self;
}


/// Set to true when we are currently displaying the server view
BOOL showingServerView;

- (void)awakeFromNib
{
	navCtrl = self;	
	showingServerView = FALSE;
}

/*
 * Switch the view controlled by viewCtrl
 */
- (void)switchToView:(UIViewController*) viewCtrl
{
	[self setNavigationBarHidden:FALSE animated:FALSE];
	[self pushViewController:viewCtrl animated:TRUE];
}


- (void)switchToPrintView
{
	[self switchToView:(UIViewController*)printViewController];
	[printViewController display];
	
}

- (void)switchToServerView
{	
	[self switchToView:(UIViewController *)serverViewController];	
}

/*
 * Intercept switching between views so we can test for the server view, and insert logic
 */
	
- (void)navigationController:(UINavigationController *)navigationController 
	   willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	// There will be one view controller on the stack if returning to the calc view
	if ([[self viewControllers] count] == 1)
	{
  	    // When we come back to the calc view, rehide the navigation bar
	    [self setNavigationBarHidden:TRUE animated:TRUE];
	}
		
	if (showingServerView)
	{
		// We don't want the server running in the background while not on the server
		// view, so if we are switching away from the server view, stop the web server.
		[serverViewController stopServer];
		showingServerView = FALSE;
	}		
	
	if (viewController == (UIViewController*)serverViewController)
	{
		// We are switching to the server view, so start up the web server. We do it 
		// now so that the results of starting the server can be displayed on 
		// the view before we switch in, for example server URL, or an error message.
		showingServerView = TRUE;
		[serverViewController startServer];
	}
}

/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */

/*
 If you need to do additional setup after loading the view, override viewDidLoad.
- (void)viewDidLoad {
}
 */


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

- (void)dealloc {
	[super dealloc];
}


@end
