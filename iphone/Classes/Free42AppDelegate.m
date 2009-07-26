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

FILE* printFile = NULL;  // shared in PrintViewController.m

// Set to true after we call init_core basically so we can use it
// in assert calls to verify Free42 has been initialized.
BOOL free42init = FALSE;

// Base name of 42s state file name, this will be prepended by the home directory
static NSString* stateBaseName = @"/Documents/42s.state";

// File discriptor for the statefile
static FILE *statefile;

// If we are loading from the old style state method NSUserDefaults
BOOL oldStyleStateExists;

// Persist format version, bumped when there are changes so we can convert
static const int PERSIST_VERSION = 2;

// Persist version stored
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
	int length = [data length];
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
	if (statefile == NULL)
	return false;
    else {
		int4 n = fwrite(buf, 1, nbytes, statefile);
		if (n != nbytes) {
			fclose(statefile);
			NSString *statepath = [NSHomeDirectory() stringByAppendingString:stateBaseName];	
			remove([statepath UTF8String]);
			statefile = NULL;
			return false;
		} else
			return true;
    }
}

int stateReadUpTo = 0;
int readCnt = 0;
int4 shell_read_saved_state(void *buf, int4 bufsize)
{

	if (oldStyleStateExists)
	{
		if (bufsize == 816)
		{
			// We do this to convert the file state format from the old version
			// to the new version that stores 5 lines of display.
			read_state(STATE_KEY, &stateReadUpTo, buf, 272);
			memset((char*)buf+272, 0, 544);
			readCnt += 816;
			return 816;
		}

		int n = read_state(STATE_KEY, &stateReadUpTo, buf, bufsize);
		readCnt += n;
		return n;
	}
	

    if (statefile == NULL)
		return -1;
    else 
	{
		int4 n = fread(buf, 1, bufsize, statefile);
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
@synthesize viewController;
@synthesize navViewController;

NSString* CONFIG_KEY_CLICK_ON = @"keyClickOn";
NSString* CONFIG_BEEP_ON = @"beepOn";
NSString* CONFIG_KEYBOARD = @"keyboardOn";
NSString* CONFIG_AUTO_PRINT_ON = @"autoPrintOn";
NSString* CONFIG_PRINT_BUF = @"printBuf";
NSString* CONFIG_MENU_KEYS_BUF = @"menuKeys";
NSString* CONFIG_DISP_ROWS = @"dispRows";
NSString* CONFIG_PERSIST_VERSION = @"persistVersion";
NSString* CONFIG_PRLCD = @"prlcd";

- (void)loadSettings
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

	persistVersion = [defaults integerForKey:CONFIG_PERSIST_VERSION];
	
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
		dispRows = [defaults integerForKey:CONFIG_DISP_ROWS];
	else
		dispRows = 2;
		
	if ([defaults objectForKey:CONFIG_PRINT_BUF])
    {
		NSData *data = [defaults dataForKey:CONFIG_PRINT_BUF];
		NSMutableData *pbuf = [[NSMutableData alloc] init];
		[pbuf setData:data];
		[[navViewController printViewController] setPrintBuff:pbuf];
	}		
}

- (void)saveSettings
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:PERSIST_VERSION forKey:CONFIG_PERSIST_VERSION];
	[defaults setBool:[[Settings instance] beepSoundOn] forKey:CONFIG_BEEP_ON];
	[defaults setBool:[[Settings instance] clickSoundOn] forKey:CONFIG_KEY_CLICK_ON];
	[defaults setBool:[[Settings instance] keyboardOn] forKey:CONFIG_KEYBOARD];
	[defaults setBool:[[Settings instance] printedPRLCD] forKey:CONFIG_PRLCD];
	[defaults setInteger:dispRows forKey:CONFIG_DISP_ROWS];
	[defaults setBool:menuKeys forKey:CONFIG_MENU_KEYS_BUF];

	NSMutableData *pbuf = [[navViewController printViewController] printBuff];
	[defaults setObject:pbuf forKey:@"printBuf"];
}


- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	return YES;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {	

	[self loadSettings];
	
	NSString *statepath = [NSHomeDirectory() stringByAppendingString:stateBaseName];	
	statefile = fopen([statepath UTF8String], "r");
	
	oldStyleStateExists = getStateData(STATE_KEY) != NULL;
	
	[self loadSettings];
	
	if (!oldStyleStateExists && statefile == NULL)
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
	    else
			core_init(1, FREE42_VERSION);
	}
	free42init = TRUE;
	
	if (statefile) fclose(statefile);

    //[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];

	// Override point for customization after app launch
	[navViewController setNavigationBarHidden:TRUE animated:FALSE];
	[navViewController setDelegate:navViewController];
    [window addSubview: [navViewController view]];
	[window makeKeyAndVisible];
			
	const char *sound_names[] = { "tone0", "tone1", "tone2", "tone3", "tone4", "tone5", "tone6", "tone7", "tone8", "tone9", "squeak" };
	for (int i = 0; i < 11; i++) {
		NSString *name = [NSString stringWithCString:sound_names[i]];
		NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"wav"];
		OSStatus status = AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:path], &[Settings instance]->soundIDs[i]);
		if (status)
			NSLog(@"error loading sound:  %d", name);
	}
		
	NSString* fileStr = [NSHomeDirectory() stringByAppendingString:PRINT_FILE_NAME];	
	printFile = fopen([fileStr UTF8String], "a");	
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	if (oldStyleStateExists)
	{
     	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];		
		// Remove the state key so we don't use this method anymore.
		[defaults removeObjectForKey:STATE_KEY];		
	}
	
	NSString *statepath = [NSHomeDirectory() stringByAppendingString:stateBaseName];	
    statefile = fopen([statepath UTF8String], "w");	
    core_quit();
	if (statefile) fclose(statefile);	
	[self saveSettings];
	
	if (printFile) fclose(printFile);	
}

- (void)dealloc {
    [viewController release];
	[window release];
	[super dealloc];
}


@end
