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
#import "core_main.h"

@implementation ConfigViewController

@synthesize clickSoundSwitch;
@synthesize beepSoundSwitch;
@synthesize keyboardSwitch;
@synthesize autoPrintSwitch;
@synthesize menuKeysSwitch;
@synthesize gotoServerButton;

@synthesize navViewController;

int menuKeys;

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
	[autoPrintSwitch setOn:[[Settings instance] autoPrintOn]];
	[menuKeysSwitch setOn:menuKeys];
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
	else if (sender == autoPrintSwitch)
	{
		[[Settings instance] setAutoPrintOn:[sender isOn]];
	}
	else if (sender == menuKeysSwitch)
	{
		menuKeys = [sender isOn];
		core_repaint_display();
	}
}

- (void)buttonDown:(UIButton*)sender
{
	if (sender == gotoServerButton)
	{
		[navViewController switchToServerView];
	}
	else
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
