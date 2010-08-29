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
#import "core_commands2.h"

@implementation ConfigViewController

@synthesize clickSoundSwitch;
@synthesize lastXSwitch;
@synthesize beepSoundSwitch;
@synthesize keyboardSwitch;
@synthesize bigStackSwitch;
@synthesize menuKeysSwitch;
@synthesize statusBarSwitch;
@synthesize autoPrintSwitch;
@synthesize RPLEnterSwitch;
@synthesize dropSwitch;

@synthesize gotoServerButton;
@synthesize aboutButton;

@synthesize navViewController;

- (UISwitch*)makeSwitch
{
	UISwitch* s = [[UISwitch alloc] initWithFrame:CGRectMake(0,0,0,0)];
	[s addTarget:self action:@selector(switchChange:) forControlEvents:UIControlEventValueChanged];
	return s;
}

- (void)viewDidLoad {
	clickSoundSwitch = [self makeSwitch];
	beepSoundSwitch = [self makeSwitch];
	keyboardSwitch = [self makeSwitch];
	lastXSwitch = [self makeSwitch];
	bigStackSwitch = [self makeSwitch];
	menuKeysSwitch = [self makeSwitch];
	statusBarSwitch = [self makeSwitch];
	autoPrintSwitch = [self makeSwitch];
	RPLEnterSwitch = [self makeSwitch];
	dropSwitch = [self makeSwitch];
	
	gotoServerButton = [[UIButton buttonWithType:UIButtonTypeDetailDisclosure] retain];
	[gotoServerButton addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
	
	aboutButton = [[UIButton buttonWithType:UIButtonTypeDetailDisclosure] retain];
	[aboutButton addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
}

- (void)viewDidUnload {
	[clickSoundSwitch release];
	[beepSoundSwitch release];
	[keyboardSwitch release];
	[lastXSwitch release];
	[bigStackSwitch release];
	[menuKeysSwitch release];
	[statusBarSwitch release];
	[autoPrintSwitch release];
	[gotoServerButton release];
	[aboutButton release];	
	[RPLEnterSwitch release];
	[dropSwitch release];
}


- (void)viewWillAppear:(BOOL)animated
{
	[clickSoundSwitch setOn:[[Settings instance] clickSoundOn]];	
	[beepSoundSwitch setOn:[[Settings instance] beepSoundOn]];	
	[keyboardSwitch setOn:[[Settings instance] keyboardOn]];	
	[lastXSwitch setOn:[[Settings instance] showLastX]];	
	[bigStackSwitch setOn:flags.f.f32];
	[menuKeysSwitch setOn:menuKeys];
	[statusBarSwitch setOn:[[Settings instance] showStatusBar]];
	[autoPrintSwitch setOn:[[Settings instance] autoPrint]];
	[RPLEnterSwitch setOn:mode_rpl_enter];
	[dropSwitch setOn:[[Settings instance] dropFirstClick]];
}


- (void)switchChange:(UISwitch*)sender
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
		arg_struct arg;
		arg.type =  ARGTYPE_NUM;
		arg.val.num = 32;
		int val = [sender isOn];
		if (val) 
			docmd_sf(&arg);
		else
			docmd_cf(&arg);
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
	else if (sender == statusBarSwitch)
	{
		[[Settings instance] setShowStatusBar:[sender isOn]];
		[[navViewController calcViewController] resetLCD];
	}
	else if (sender == autoPrintSwitch)
	{
		[[Settings instance] setAutoPrint:[sender isOn]];
	}
	else if (sender == RPLEnterSwitch)
	{
		mode_rpl_enter = [sender isOn];
	}
	else if (sender == dropSwitch)
	{
		[[Settings instance] setDropFirstClick:[sender isOn]];
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
		NSString *free42ver = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:nil];
		free42ver = [free42ver stringByTrimmingCharactersInSet: [NSCharacterSet controlCharacterSet]];
		free42ver = [free42ver stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
		NSString *ver = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
		
		NSString *title = [NSString stringWithFormat:@"42s Version %@%@\nFree42 %@i", ver, MOD, free42ver];
		
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


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}

  // Return the numer of items in the section, given the section number.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (section)
	{
		case 0: return 3;
		case 1: return 2;
		case 2: return 3;
		case 3: return 2;
		case 4: return 1;
		case 5: return 1;
		default: return 0;
	}
}

  // Return the group label for the given section number
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (section)
	{
		case 0: return @"Behavior";
		case 1: return @"Sound";
		case 2: return @"Display";
		case 3: return @"Interaction";
		case 4: return NULL;
		case 5: return NULL;
		default: return @"What???";
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *MyIdentifier = @"switch";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] 
				 initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
	if (indexPath.section == 0 && indexPath.row == 0)  // Behavior Section
	{
		cell.textLabel.text = @"Dynamic Stack";
		cell.accessoryView = bigStackSwitch;
	}
	else if (indexPath.section == 0 && indexPath.row == 1) 
	{
		cell.textLabel.text = @"No stack lift on ENTER";
		cell.accessoryView = RPLEnterSwitch;
	}
	else if (indexPath.section == 0 && indexPath.row == 2) 
	{
		cell.textLabel.text = @"DROP on first click";
		cell.accessoryView = dropSwitch;
	}
	else if (indexPath.section == 1 && indexPath.row == 0) // Sound Section
	{
		cell.textLabel.text = @"Key Clicks";
		cell.accessoryView = clickSoundSwitch;
	}
	else if (indexPath.section == 1 && indexPath.row == 1)
	{
		cell.textLabel.text = @"Beeps and Tones";
		cell.accessoryView = beepSoundSwitch;
	}
	else if (indexPath.section == 2 && indexPath.row == 0) // Display Section
	{
		cell.textLabel.text = @"Show Last X";
		cell.accessoryView = lastXSwitch;
	}
	else if (indexPath.section == 2 && indexPath.row == 1)
	{
		cell.textLabel.text = @"Overlay Menu on Keys";
		cell.accessoryView = menuKeysSwitch;
	}
	else if (indexPath.section == 2 && indexPath.row == 2)
	{
		cell.textLabel.text = @"Device Status Bar";
		cell.accessoryView = statusBarSwitch;
	}
	else if (indexPath.section == 3 && indexPath.row == 0)  // Interactions
	{
		cell.textLabel.text = @"Auto Show Keyboard";
		cell.accessoryView = keyboardSwitch;
	}
	else if (indexPath.section == 3 && indexPath.row == 1)
	{
		cell.textLabel.text = @"Auto Show Print View";
		cell.accessoryView = autoPrintSwitch;
	}	
	else if  (indexPath.section == 4 && indexPath.row == 0) // Import Export
	{
		cell.textLabel.text = @"Import and Export Programs";
		cell.accessoryView = gotoServerButton;
	}
	else if  (indexPath.section == 5 && indexPath.row == 0) // About
	{
		cell.textLabel.text = @"About";
		cell.accessoryView = aboutButton;
	}
	
    return cell;
}

@end
