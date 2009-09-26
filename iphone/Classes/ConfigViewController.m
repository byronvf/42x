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

#import "ConfigViewController.h"
#import "Settings.h"
#import "NavViewController.h"
#import "CalcViewController.h"
#import "core_main.h"
#import "core_display.h"

@implementation ConfigViewController

@synthesize clickSoundSwitch;
@synthesize lastXSwitch;
@synthesize beepSoundSwitch;
@synthesize keyboardSwitch;
@synthesize bigStackSwitch;
@synthesize menuKeysSwitch;
@synthesize gotoServerButton;
@synthesize largeLCD;

@synthesize navViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		// Initialization code
	}
	return self;
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

- (void)viewWillAppear:(BOOL)animated
{
	[clickSoundSwitch setOn:[[Settings instance] clickSoundOn]];	
	[beepSoundSwitch setOn:[[Settings instance] beepSoundOn]];	
	[keyboardSwitch setOn:[[Settings instance] keyboardOn]];	
	[lastXSwitch setOn:[[Settings instance] showLastX]];	
	[bigStackSwitch setOn:mode_bigstack];
	[menuKeysSwitch setOn:menuKeys];
	[largeLCD setOn:[[Settings instance] largeLCD]];
}

- (void)buttonUp:(UISwitch*)sender
{
	if (sender == clickSoundSwitch)
	{
		[[Settings instance] setClickSoundOn:[sender isOn]];
	}
	else if (sender == beepSoundSwitch)
	{
		[[Settings instance] setBeepSoundOn:[sender isOn]];
	}	
	else if (sender == keyboardSwitch)
	{
		[[Settings instance] setKeyboardOn:[sender isOn]];
	}	
	else if (sender == bigStackSwitch)
	{
		mode_bigstack = [sender isOn];
	}
	else if (sender == menuKeysSwitch)
	{
		menuKeys = [sender isOn];
		core_repaint_display();
	}
	else if (sender == lastXSwitch)
	{
		[[Settings instance] setShowLastX:[sender isOn]];
		[[navViewController calcViewController] testUpdateLastX:TRUE];
	}
	else if (sender == largeLCD)
	{
		[[Settings instance] setLargeLCD:[sender isOn]];
		[[navViewController calcViewController] resetLCD];
	}
}

#if DEV_REL
  #define MOD @" dev"
#elif BETA_REL
  #define MOD @" beta"
#else
  #define MOD @""
#endif

- (void)buttonDown:(UIButton*)sender
{
	if (sender == gotoServerButton)
	{
		[navViewController switchToServerView];
	}
	else
	{
		// Read Free42 version from VERSION file.
		NSString *path = [[NSBundle mainBundle] pathForResource:@"VERSION" ofType:nil];
		NSString *free42ver = [NSString stringWithContentsOfFile:path];
		free42ver = [free42ver stringByTrimmingCharactersInSet: [NSCharacterSet controlCharacterSet]];
		free42ver = [free42ver stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
		NSString *ver = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
		
		NSString *title = [NSString stringWithFormat:@"42s Version %@%@\nFree42 Version %@", ver, MOD, free42ver];
		
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title
		message:@"Licensed under GPL" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];	
		[alert addButtonWithTitle:@"Web Site"];
		[alert show];		
	}
}


- (void)alertView: (UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == 1)
	{
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString: @"http://free42iphone.appspot.com/"]];
	}
}


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
