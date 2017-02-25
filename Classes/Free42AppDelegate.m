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

#import <AudioToolbox/AudioServices.h>
#import "Free42AppDelegate.h"
#import "core_main.h"
#import "core_display.h"
#import "free42.h"
#import "Settings.h"
#import "PrintViewController.h"
#import "core_variables.h"

// Set to true after we call init_core basically so we can use it
// in assert calls to verify Free42 has been initialized.
BOOL free42init = FALSE;

// Set this to true when we are in sleep mode
BOOL isSleeping = FALSE;

// Base name of 42s state file name, this will be prepended by the home directory
static NSString* stateBaseName = @"/Documents/42s.state";

// File discriptor for the statefile
static FILE *statefile = NULL;

// Persist format version, bumped when there are changes so we can convert
static const int PERSIST_VERSION = 7;

// Versions ---- PERSIST_VERION - 42s release version - FREE42_VERSION

// 2 - 2.2    - 12
// 3 - 2.2.1  - 12
// 4 - 2.3    - 13
// 5 - 2.3.1  - 13
// 5 - 2.3.2  - 13
// 6 - 2.3.3  - 16
// 7 - 3.0    - 17   Undo stuff

// Versions before PERSIST_VERSION was added uses FREE42_VERSION 11

static int persistVersion = 0;

int cpuCount = 0;
/*
 * The problem is that I'm not aware of a way we can test if an event is pending,
 * mainly a key press, which would mean we need to pop out of core_keydown and 
 * proccess it in the case it may be EXIT or R/S.  So, as a little hack we simply
 * return true (which means we should pop out of core_keydown) every so many 
 * calls to this method.
 */
int shell_wants_cpu()
{
	if (cpuCount > 0)
	{
		cpuCount--;
		return 0;
	}
	
	cpuCount = 500;
	return 1;
}


//************************ Generic read and write ****************************

NSData* getStateData(NSString* key)
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];	
	NSData *data = [defaults dataForKey:key];
	return data;
}

int4 read_state(NSString* key, int *readUpTo, void *buf, int4 bufsize)
{
	NSData *data = getStateData(key);
	if (!data)
	{
		// No file previously saved
		return -1;
	}
	
	const char *sbuf = (char*)[data bytes];
	int length = (int)[data length];
	int cnt = MIN(length - *readUpTo, bufsize);	
	memcpy(buf, sbuf+*readUpTo, cnt);
	*readUpTo += cnt;
	return cnt;	
}

// -------------------------  Saving State -------------------------------

NSString* STATE_KEY = @"free42state";
bool stateFirstWrite = TRUE;
bool shell_write_saved_state(const void *buf, int4 nbytes)
{
	if (!statefile)
	{
		NSString *statepath = [NSHomeDirectory() stringByAppendingString:stateBaseName];	
		statefile = fopen([statepath UTF8String], "w");	
		if (statefile == NULL) return false;
	}		
		
	int n = (int)fwrite(buf, 1, nbytes, statefile);
	if (n != nbytes) {
		fclose(statefile);
		NSString *statepath = [NSHomeDirectory() stringByAppendingString:stateBaseName];	
		remove([statepath UTF8String]);
		statefile = NULL;
		return false;
	}
		
	return true;
}

int stateReadUpTo = 0;
int readCnt = 0;
int4 shell_read_saved_state(void *buf, int4 bufsize)
{	
    if (persistVersion < 3 && bufsize == 1360)
	{
		int4 n = (int)fread(buf, 1, 816, statefile);
		if (n != 816 && ferror(statefile)) 
		{
			fclose(statefile);
			statefile = NULL;
			return -1;
		} 
        memset((char*)buf+816, 0, 544);
		readCnt += 1360;
		return 1360;
	}
	
    if (statefile == NULL)
		return -1;
    else 
	{
		int4 n = (int)fread(buf, 1, bufsize, statefile);
		if (n != bufsize && ferror(statefile)) 
		{
			fclose(statefile);
			statefile = NULL;
			return -1;
		} 
		else
		{
			readCnt += n;
			return n;
		}
    }	
	
}
	
// ************************* read write programs **********************************

const NSString* PRGM_STATE = @"free42prgm";
bool prgmFirstWrite = TRUE;
// TODO: Implemented in simpleserver.c, at least for now.
// Something will have to be changed in order to support *both*
// direct export by doing a GET /memory/<num> from the HTTP
// server, *and* the old-fashioned interface of saving to a local
// file.
//int shell_write(const char *buf, int4 nbytes)
//{
//	return write_state(PRGM_STATE, &prgmFirstWrite, buf, nbytes);
//}
//
//int prgmReadUpTo = 0;
//int4 shell_read(char *buf, int4 buflen)
//{
//	return read_state(PRGM_STATE, &prgmReadUpTo, buf, buflen);
//}


@implementation Free42AppDelegate

@synthesize window;
@synthesize navViewController;

@synthesize calcCtrl;
@synthesize keyPadHolderView;

- (void)loadSettings
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	persistVersion = (int)[defaults integerForKey:CONFIG_PERSIST_VERSION];
	
	if ([defaults objectForKey:CONFIG_KEY_CLICK_ON])
		[[Settings instance] setClickSoundOn:[defaults boolForKey:CONFIG_KEY_CLICK_ON]];
	else
		[[Settings instance] setClickSoundOn:TRUE];

	if ([defaults objectForKey:CONFIG_BEEP_ON])
		[[Settings instance] setBeepSoundOn:[defaults boolForKey:CONFIG_BEEP_ON]];
	else
		[[Settings instance] setBeepSoundOn:TRUE];
	
	if ([defaults objectForKey:CONFIG_KEYBOARD])
		[[Settings instance] setKeyboardOn:[defaults boolForKey:CONFIG_KEYBOARD]];
	else
		[[Settings instance] setKeyboardOn:TRUE];
	
	if ([defaults objectForKey:CONFIG_MENU_KEYS_BUF])
		menuKeys = [defaults boolForKey:CONFIG_MENU_KEYS_BUF];
	else
		menuKeys = TRUE;	
	
	if ([defaults objectForKey:CONFIG_PRLCD])
		[[Settings instance] setPrintedPRLCD:[defaults boolForKey:CONFIG_PRLCD]];
	else
		[[Settings instance] setPrintedPRLCD:FALSE];
	
	if ([defaults objectForKey:CONFIG_DISP_ROWS])
		dispRows = (int)[defaults integerForKey:CONFIG_DISP_ROWS];
	else
		dispRows = 2;
	
	if ([defaults objectForKey:CONFIG_SHOW_FLAGS])
		[[Settings instance] setShowFlags:[defaults boolForKey:CONFIG_SHOW_FLAGS]];
	else
		 [[Settings instance] setShowFlags:TRUE];	
	
	if ([defaults objectForKey:CONFIG_SHOW_LASTX])
		[[Settings instance] setShowLastX:[defaults boolForKey:CONFIG_SHOW_LASTX]];
	else
		[[Settings instance] setShowLastX:FALSE];
	
	if ([defaults objectForKey:CONFIG_AUTO_PRINT_ON])
		[[Settings instance] setAutoPrint:[defaults boolForKey:CONFIG_AUTO_PRINT_ON]];
	else
	{
		// If AUTO_PRINT is not defined then if user is updating then keep current behavior
		// Otherwise if this is a new install then turn autoprint on.
		[[Settings instance] setAutoPrint:(persistVersion >= 4 || persistVersion == 0)];
	}
	
	if ([defaults objectForKey:CONFIG_DROP_FIRST_CLICK])
		[[Settings instance] setDropFirstClick:[defaults boolForKey:CONFIG_DROP_FIRST_CLICK]];
	else
		[[Settings instance] setDropFirstClick:FALSE];
}

- (void)saveSettings
{	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:PERSIST_VERSION forKey:CONFIG_PERSIST_VERSION];
	[defaults setBool:[[Settings instance] beepSoundOn] forKey:CONFIG_BEEP_ON];
	[defaults setBool:[[Settings instance] clickSoundOn] forKey:CONFIG_KEY_CLICK_ON];
	[defaults setBool:[[Settings instance] showLastX] forKey:CONFIG_SHOW_LASTX];
	[defaults setBool:[[Settings instance] keyboardOn] forKey:CONFIG_KEYBOARD];
	[defaults setBool:[[Settings instance] printedPRLCD] forKey:CONFIG_PRLCD];
	[defaults setBool:[[Settings instance] dropFirstClick] forKey:CONFIG_DROP_FIRST_CLICK];
	[defaults setBool:[[Settings instance] showFlags] forKey:CONFIG_SHOW_FLAGS];
	[defaults setBool:[[Settings instance] autoPrint] forKey:CONFIG_AUTO_PRINT_ON];
	[defaults setInteger:dispRows forKey:CONFIG_DISP_ROWS];
	[defaults setBool:menuKeys forKey:CONFIG_MENU_KEYS_BUF];	
	[defaults synchronize];  // When using the OFF command we must do this.
	
	[[navViewController printViewController] releasePrintBuffer];
}


- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	return YES;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {	

	[self loadSettings];
	
	NSString *statepath = [NSHomeDirectory() stringByAppendingString:stateBaseName];	
	statefile = fopen([statepath UTF8String], "r");
	
	if (statefile == NULL)
	{
		// We get here if this application has never been run, and there is 
		// no saved state.  In this case we call core_init with readstate 
		// of 0 so that it does not try to read the state, and generate an error.
		core_init(0, 0);
	}
	else
	{
		// If persistVersion is less then 2, then we are loading from
		// FREE42_VERSION 11, pre bigstack
		if (persistVersion < 2)
			core_init(1, 11);
	    else if (persistVersion == 2 || persistVersion == 3)
			core_init(1, 12);
		else if (persistVersion == 4 || persistVersion == 5)
			core_init(1, 13);
		else if (persistVersion == 6)
			core_init(1, 16);
		else
			core_init(1, FREE42_VERSION);
	}
    
    	callKeydownAgain = core_powercycle();
	free42init = TRUE;
	
	if (persistVersion < 4)
	{
		// If this is an early version, then move the setting for big stack to flag 32
		// rpl_enter_mode is set with what mode_bigstack used to be from the persist file
		flags.f.f32 = mode_rpl_enter;
		mode_rpl_enter = FALSE;
	}
	
	if (statefile) fclose(statefile);
	statefile = NULL;

	const char *sound_names[] = { "tone0", "tone1", "tone2", "tone3", "tone4", "tone5", "tone6", "tone7", "tone8", "tone9", "squeak" };
	for (int i = 0; i < 11; i++) {
		NSString *name = [NSString stringWithCString:sound_names[i] encoding:NSASCIIStringEncoding];
		NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"wav"];
		OSStatus status = AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:path], &[Settings instance]->soundIDs[i]);
		if (status)
			NSLog(@"error loading sound:  %@", name);
	}
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		[self initializeIpad];
	}
	else
	{
		[self initializeIphone];
	}
	
}

- (void)initializeIpad;
{
	NSLog(@"Tying views together...");
	//[window addSubview:[viewController view]];
	//[window setRootViewController:viewController];
	//[window addSubview:[viewController view]];
	UIViewController *viewCtrl = [window rootViewController];
	UIView *padView = viewCtrl.view;
	UIView *keyPad = calcCtrl.view;
	CGRect keyFrame = keyPad.frame;
//	CGRect keyBound = keyPad.bounds;
//	keyBound.size.width = 700;
//	assert(padView != window);
	keyFrame.size.width = window.bounds.size.width/2;
	keyFrame.size.height = window.bounds.size.height;
	keyPad.frame = keyFrame;
//	keyPad.bounds = keyBound;
//	[padView addSubview:keyPad];
//	[window addSubview: padView];
[keyPadHolderView addSubview:keyPad];
//	UIView *keypadView = [viewController view];
	//[keypadView setFrame:CGRectMake(0, 0, 512, 768)];
	//[keypadView setBounds:CGRectMake(0, 0, 512, 768)];
	//[padView addSubview:keypadView];

	CGRect rect = [window frame];
	NSLog(@"window frame (%f, %f, %f, %f)", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
	rect = [padView frame];
	NSLog(@"Pad view frame (%f, %f, %f, %f)", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
	rect = [keyPad frame];
	NSLog(@"KeyPad view frame (%f, %f, %f, %f)", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
	
	[window makeKeyAndVisible];
	
}

- (void)initializeIphone;
{
	// Override point for customization after app launch
	[navViewController setNavigationBarHidden:TRUE animated:FALSE];
	[navViewController setDelegate:navViewController];
    [window addSubview: [navViewController view]];
	[window setRootViewController:navViewController];
	[window makeKeyAndVisible];
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    [self saveSettings];
    
    // So, we put this here, but we never know when or if this handler will 
    // will be called iOS.  In fact, it will rarely every call this. 
    // Backgrounding 42s, then shutting it down manually in 
    // the iOS multitasking menu will not fire this method.  In otherwords
    // there is no reliable way to know when we are actually terminating.
    // we put this here to be complete, but it's just eye candy.    
    core_quit();
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	isSleeping = TRUE;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	isSleeping = FALSE;	
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
#ifndef NDEBUG	
 	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Memory Alert"
	message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];	
	[alert show];	
#endif
	clean_vartype_pools();
}


//----- Multi tasking stuff ---------

// Tells the delegate that the application is now in the background.

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[self saveSettings];
	save_state();
	if (statefile) fclose(statefile);
	statefile = NULL;	
}


// Tells the delegate that the application is about to enter the foreground.
// If we are going to show the status bar,.  The view assumes a full screen.  We then
// do a little kludge that forces the status bar to be displayed after the view
// is done drawing.  If we don't do this, then the status bar pushes the view 
// down.
//- (void)applicationWillEnterForeground:(UIApplication *)application
//{
//	UIViewController* vc = [navViewController visibleViewController];
//	if (vc == [navViewController calcViewController])	
//	{
//		[[UIApplication sharedApplication] setStatusBarHidden:TRUE];
//		if ([[Settings instance] showStatusBar])
//		{
//			[self performSelector:@selector(restoreStatusBar) withObject:NULL afterDelay:0.0];		
//		}
//	}
//	
//}

//- (void)restoreStatusBar
//{
//	[[UIApplication sharedApplication] setStatusBarHidden:FALSE];	
//}



@end
