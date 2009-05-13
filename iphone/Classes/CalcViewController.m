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
#import "CalcViewController.h"
#import "core_main.h"
#import "Settings.h"
#import "PrintViewController.h"
#import "NavViewController.h"
#import "core_globals.h"
#import "TonePlayer.h"

const float SLOW_KEY_REPEAT_RATE = 0.2;  // Slow key repeat rate in seconds
const float FAST_KEY_REPEAT_RATE = 0.1;  // Fast key repeat rate in seconds

// Reference to this instance of the view.  We need this as a sort of hack to 
// reference it from the shell_delay C method.
CalcViewController *viewCtrl; 

int enqueued = FALSE;
int callKeydownAgain = FALSE;
bool timer3active = FALSE;  // Keep track if the timer3 event is currently pending



/*
 * The CalcViewController manages the key pad portion of the calculator
 */
@implementation CalcViewController

@synthesize screen;
@synthesize b01;
@synthesize b02;
@synthesize b03;
@synthesize b04;
@synthesize b05;
@synthesize b06;
@synthesize b07;
@synthesize b08;
@synthesize b09;
@synthesize b10;
@synthesize b11;
@synthesize b12;
@synthesize b13;
@synthesize b14;
@synthesize b15;
@synthesize b16;
@synthesize b17;
@synthesize b18;
@synthesize b19;
@synthesize b20;
@synthesize b21;
@synthesize b22;
@synthesize b23;
@synthesize b24;
@synthesize b25;
@synthesize b26;
@synthesize b27;
@synthesize b28;
@synthesize b29;
@synthesize b30;
@synthesize b31;
@synthesize b32;
@synthesize b33;
@synthesize b34;
@synthesize b35;
@synthesize b36;
@synthesize b37;
@synthesize blitterView;
@synthesize bgImageView;
@synthesize navViewController;
@synthesize bgBlankButtons;
@synthesize bgImage;
@synthesize menuView;

/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */

/*
 This handler gets called whenever the run loop is about to sleep.  We us it to try
 and do a better job at executing free42 programs, and handling key events.
 */

void mySleepHandler (CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
	if (callKeydownAgain)
	{
		[viewCtrl performSelectorOnMainThread:@selector(keepRunning) withObject:NULL waitUntilDone:NO];
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[blitterView setNavViewController:navViewController];
	[blitterView setShiftButton:b28];
	viewCtrl = self;	// Initialize our hack reference.

    // Install the mySleepHandler run loop observer
    NSRunLoop* myRunLoop = [NSRunLoop currentRunLoop];
    // Create a run loop observer and attach it to the run loop.
    CFRunLoopObserverContext  context = {0, self, NULL, NULL, NULL};
    CFRunLoopObserverRef    observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
					kCFRunLoopBeforeWaiting, YES, 0, &mySleepHandler, &context);
	CFRunLoopRef    cfLoop = [myRunLoop getCFRunLoop];
	CFRunLoopAddObserver(cfLoop, observer, kCFRunLoopDefaultMode);

	bgBlankButtons  = [UIImage imageNamed:@"Default-BlankTop.png"];
	bgImage = [bgImageView image];
	menuActive = core_menu();
	if (menuActive && menuKeys)
	{
	  [[self bgImageView] setImage:bgBlankButtons];
	}
	else
	{
		[menuView setAlpha:0.0];
	}
	
	//tonePlayer = [[TonePlayer alloc] init];
}
 
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}


const char *displayBuff;
const char *menuBuff;

void shell_blitter(const char *bits, int bytesperline, int x, int y,
				   int width, int height)
{	
	// We don't take advantage of the additional clipping information, but
	// I don't think this is an issue given the iPhone's hardware display support.
	// displayBuff = bits + 136 - 68;
	displayBuff = bits;
	menuBuff = bits + 272 + 17*2;
	[blitterView setNeedsDisplay];
	
	if (!viewCtrl) return;
	if (core_menu() && menuKeys)
	{
		[[viewCtrl menuView] setAlpha:1.0];
		[[viewCtrl menuView] setNeedsDisplay];
	}
	else
	{  
		[[viewCtrl menuView] setAlpha:0.0];
	} 
}


// ************************************ KEY HANDLING ******************************************

- (void)cancelKeyTimer
{
	// Cancel in previous key timer
	[[self class] cancelPreviousPerformRequestsWithTarget: self];	
}

/*
 * We use the keepRunning runMore method pairs to handle the situation of running a 
 * a free42 program. keepRunning calls runMore by using a zero time selector which 
 * allows us to process events before we call core_keydown again.  This is important
 * so that we can handle the user pressing the R/S key again, which will call 
 * buttonDown, and stop the program.
 */
-(void)keepRunning
{
	int repeat;
	// We are not processing a key event, so pass 0,
	callKeydownAgain = core_keydown(0, &enqueued, &repeat);
	
	if (!callKeydownAgain && printingStarted)
	{
		// We set printingStarted to true in the shell_print method to indicate 
		// that printing has begun.  For each line out output Free42 returns from
		// core_keydown, but returns true if ther are more lines. If we get
		// to this point it means that there are no more lines to print, so
		// our print buffer is full and now display the print view.
		printingStarted = FALSE;
		
		// We use the printingStarted flag to turn on the and off the print aunnunciator
		// since it is off now, we want to redisplay.
		[blitterView setNeedsDisplay];
		
		if ([[Settings instance] autoPrintOn])
			[navViewController switchToPrintView];
	}
}


/*
 * Handle the user pressing a keypad button
 */
- (void)buttonDown:(UIButton*)sender
{
	// Play click sound
	if ([[Settings instance] clickSoundOn])
		AudioServicesPlaySystemSound ([Settings instance]->clickSoundId);
	
	int keynum = (int)[sender tag];
	if (keynum != 28)
		[self cancelKeyTimer];
	
	int repeat;
	callKeydownAgain = core_keydown(keynum, &enqueued, &repeat);
	if (repeat)
	{
		if (repeat == 1)  // Slow Repeat
		{
			[self performSelector:@selector(keyRepeatTimer) withObject:NULL 
					   afterDelay:1.0];  // 1s initial delay for slow repeat
		}
		else // repeat = 2  Fast Repeat
		{
			[self performSelector:@selector(keyRepeatTimer) withObject:NULL 
					   afterDelay:0.5];  // 500ms initial delay for fast repeat
		}
	}
	else if (!enqueued && !timer3active)
	{
		// if the key is held down for 0.25 seconds, then flash the 
		// key function.
		[self performSelector:@selector(keyTimerEvent1) withObject:NULL afterDelay:0.25];
	}
		
	// Tests if in enqueMode and if so, call core_keydown again
	//[self keepRunning];
}


- (void)buttonUp:(UIButton*)sender
{
	if (!enqueued && !timer3active)
	{
		// If the timer 3 event is active, we don't want to stop the timer on 
		// a key up event
		[self cancelKeyTimer];
	}
	
	// This logic is specified in the shell API
	if (!enqueued)
	{
		callKeydownAgain = core_keyup();
	}
		
	if ([[Settings instance] keyboardOn])
	{
		if (!menuActive && core_menu())
		{
			menuActive = YES;
			[[self bgImageView] setImage:bgBlankButtons];
		}
		else if (menuActive && !core_menu())
		{	menuActive = NO;
			[[self bgImageView] setImage:bgImage];
		}
		
		
		if( !alphaMenuActive && core_alpha_menu())
		{
			alphaMenuActive = YES;
			[textEntryField becomeFirstResponder];
		}
		else if( alphaMenuActive && !core_alpha_menu())
		{
			alphaMenuActive = NO;
			[textEntryField resignFirstResponder];
		}	
	}
	
	timer3active = FALSE;
	[self keepRunning];	
}

// *******************************  Timer and key repeat handling *************************

- (void)keyRepeatTimer
{
	[self cancelKeyTimer];
	int val = core_repeat();
	if (val == 1)
		[self performSelector:@selector(keyRepeatTimer) 
				   withObject:NULL afterDelay:SLOW_KEY_REPEAT_RATE];
	else if (val == 2)
		[self performSelector:@selector(keyRepeatTimer) 
				   withObject:NULL afterDelay:FAST_KEY_REPEAT_RATE];
	else  //val == 0 means to stop repeating.
		[self performSelector:@selector(keyTimerEvent1) withObject:NULL afterDelay:0.25];
		
}

/*
 * Displays action when key is held down
 */
- (void)keyTimerEvent1
{
	[self cancelKeyTimer];
	core_keytimeout1();
	[self performSelector:@selector(keyTimerEvent2) withObject:NULL afterDelay:2.0];
}

/*
 * When key is held down for this time, the action for the key is canceled.
 */
- (void)keyTimerEvent2
{
	[self cancelKeyTimer];
	core_keytimeout2();
}	

// ********************************** timeout3 events ***************************************


- (void)beginTimerEvent3: (int)delay
{
	[self cancelKeyTimer];
	float fdelay = delay / 1000.0;
	[self performSelector:@selector(keyTimerEvent3) withObject:NULL afterDelay:fdelay];	
}

/*
 * Callback method from free42
 */
void shell_request_timeout3(int delay)
{
	[viewCtrl beginTimerEvent3:delay];
	timer3active = TRUE;
}

- (void)keyTimerEvent3
{
	[self cancelKeyTimer];
	timer3active = FALSE;
	callKeydownAgain = core_timeout3(1);
	if (callKeydownAgain)
		// PSE just ended
		[self keepRunning];
}


// ************************************  Popup Keyboard *************************************


-(BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)targetRange 
                                       replacementString:(NSString*)newString
{
	int repeat;
	
	if( 0 == targetRange.length)
	{
		// We are inserting a character
		unichar newChar = [newString characterAtIndex:0];
		if( ' ' <= newChar && newChar <= '~')
		{
			// Adding an alpha character
			core_keydown(newChar + 1024, &enqueued, &repeat);
			if( !enqueued)
			{ core_keyup(); }
		}
		else if( '\n' == newChar)
		{
			// End the edit
			core_keydown(KEY_ENTER, &enqueued, &repeat);
			if( !enqueued)
			{ core_keyup(); }
		}
	}
	else
	{
		// We are deleting a character
		core_keydown(KEY_BSP, &enqueued, &repeat);
		if( !enqueued)
		{ core_keyup(); }
	}
	
	if (!core_alpha_menu())
	{
		[textEntryField resignFirstResponder];
		[[self bgImageView] setImage:bgImage];
		menuActive = FALSE;
		alphaMenuActive = NO;
	}
		
	return YES;
}

/**
 * This is a crude implementation which just plays a wave beep sound.
 * Needs to be further.
 */
void shell_beeper(int frequency, int duration)
{
	if ([[Settings instance] beepSoundOn])
	  AudioServicesPlaySystemSound ([Settings instance]->beepSoundId);

	//[viewCtrl->tonePlayer setSound:TRUE withVolume:32000.0];
	//[viewCtrl->tonePlayer soundTone:frequency forDuration:duration/1000.0];
	
}


/**
 * This is a big hack for when UINavigationController navigates back to this view.
 * Without this the bounds on the view gets messed up, so you can't push the 
 * bottom row of buttons.  this method corrects that when it is called when
 * the view switches back to the calc view.
 */
- (void)viewDidAppear:(BOOL)animated
{
	CGRect rect = [[UIScreen mainScreen] bounds];
	[[self view] setFrame:rect];
	[[self view] setBounds:rect];
}

- (void)dealloc {
	[screen dealloc];
	[b01 dealloc];
	[b02 dealloc];
	[b03 dealloc];
	[b04 dealloc];
	[b05 dealloc];
	[b06 dealloc];
	[b07 dealloc];
	[b08 dealloc];
	[b09 dealloc];
	[b10 dealloc];
	[b11 dealloc];
	[b12 dealloc];
	[b13 dealloc];
	[b14 dealloc];
	[b15 dealloc];
	[b16 dealloc];
	[b17 dealloc];
	[b18 dealloc];
	[b19 dealloc];
	[b20 dealloc];
	[b21 dealloc];
	[b22 dealloc];
	[b23 dealloc];
	[b24 dealloc];
	[b25 dealloc];
	[b26 dealloc];
	[b27 dealloc];
	[b28 dealloc];
	[b29 dealloc];
	[b30 dealloc];
	[b31 dealloc];
	[b32 dealloc];
	[b33 dealloc];
	[b34 dealloc];
	[b35 dealloc];
	[b36 dealloc];
	[b37 dealloc];
	[blitterView dealloc];
	[tonePlayer dealloc];

	[super dealloc];
}

@end
