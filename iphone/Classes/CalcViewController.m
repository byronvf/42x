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
#import "core_display.h"
#import "Settings.h"
#import "PrintViewController.h"
#import "NavViewController.h"
#import "core_globals.h"

const float SLOW_KEY_REPEAT_RATE = 0.2;  // Slow key repeat rate in seconds
const float FAST_KEY_REPEAT_RATE = 0.1;  // Fast key repeat rate in seconds

// Reference to this instance of the view.  We need this as a sort of hack to 
// reference it from the shell_delay C method.
CalcViewController *viewCtrl; 

int enqueued = FALSE;
int callKeydownAgain = FALSE;
bool timer3active = FALSE;  // Keep track if the timer3 event is currently pending

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

void shell_blitter(const char *bits, int bytesperline, int x, int y,
				   int width, int height)
{		
	// Indicate that the blitter view needs to update the given region,
	// The *3 is due to the fact that the blitter is 3 times the size of the buffer pixel.
	// The 18 is the base offset into the display, pass the flags row
	if (flags.f.prgm_mode)
		[blitterView setNeedsDisplay];
	else
		// +3 for fudge so that when switching between 5 to 4 row mode, we clean
		// up dirtly bits just below the 4th row
		[blitterView setNeedsDisplayInRect:CGRectMake(0, 18 + y*3, 320, height*3 + 3)];
	
	// If a program is running, force Free42 to pop out of core_keydown and
	// service display, see shell_wants_cpu()
	cpuCount = 0;
	
	// If the viewCtrl is not initialized yet, don't try and use it
	if (!viewCtrl) return;
	
	viewCtrl.displayBuff = bits;
	
	if (core_menu() && menuKeys)
	{
		// The menu keys are in the third row of the display (> 16), so 
		// don't bother updateing unless this area of the display has changed.
		if (height + y > 16)
		{
			[[viewCtrl menuView] setAlpha:1.0];
			[[viewCtrl blankButtonsView] setAlpha:1.0];
			[[viewCtrl menuView] setNeedsDisplay];
		}
	}
	else
	{  
		[[viewCtrl menuView] setAlpha:0.0];
		[[viewCtrl blankButtonsView] setAlpha:0.0];
	} 
}

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
@synthesize blankButtonsView;
@synthesize displayBuff;
@synthesize menuView;


/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */

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
	if (core_menu() && menuKeys)
	{
		[blankButtonsView setAlpha:1.0];
	}
	else
	{
		[blankButtonsView setAlpha:0.0];
		[menuView setAlpha:0.0];
	}
	
	blitterView.calcViewController = self;
	menuView.calcViewController = self;
	
	// to initialize displayBuff;
	redisplay();
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)handlePopupKeyboard
{
	if ([[Settings instance] keyboardOn])
	{		
		if( !alphaMenuActive && core_alpha_menu())
		{
			alphaMenuActive = YES;
            set_menu(MENULEVEL_ALPHA, 1);
			redisplay();
			[textEntryField becomeFirstResponder];
			textEntryField.text = @"";
		}
		else if( alphaMenuActive && !core_alpha_menu())
		{
			alphaMenuActive = NO;
			[textEntryField resignFirstResponder];
		}	
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
		[blitterView annuncNeedsDisplay];
		
		if ([[Settings instance] autoPrintOn])
			[navViewController switchToPrintView];
	}
	
	// Test if we need to pop up the keyboard here, this can happen if
	// a program is being run that activates the keyboard which otherwise
	// the normal key handling would not detect.
	[self handlePopupKeyboard];
}


/*
 * Handle the user pressing a keypad button
 */
- (void)buttonDown:(UIButton*)sender
{
	bool old_prgm_mode = flags.f.prgm_mode;
	
	// If a hightlight is active for cut and past, turn it off
	// Woud be nice to get a notification when cut/paste menu goes
	// away, but couldn't get it to work, so this kludge.
	blitterView.highlight = FALSE;
	
	// Play click sound
	if ([[Settings instance] clickSoundOn])
		//AudioServicesPlaySystemSound(1105);
		AudioServicesPlaySystemSound ([Settings instance]->clickSoundId);
	
	int keynum = (int)[sender tag];
	if (core_menu() && dispRows > 2 && keynum < 13) keynum -= 6;
	
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
	
	if (flags.f.prgm_mode && !old_prgm_mode && dispRows > 2)
	{
		dispRows = 5;
		redisplay();
	}
	else if (!flags.f.prgm_mode && old_prgm_mode && dispRows > 2)
	{
		dispRows = 4;
	}	
	
	[self handlePopupKeyboard];	
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
	
	if(newString.length != 0)
	{
		// We are inserting a character
		unichar newChar = [newString characterAtIndex:0];
		if( ' ' <= newChar && newChar <= '~')
		{
			// Adding an alpha character
			core_keydown(newChar + 1024, &enqueued, &repeat);
			if( !enqueued) core_keyup();
		}
		else if( '\n' == newChar)
		{
			// End the edit
			core_keydown(KEY_ENTER, &enqueued, &repeat);
			if( !enqueued) core_keyup();
		}
	}
	else
	{
		// We are deleting a character
		core_keydown(KEY_BSP, &enqueued, &repeat);
		if( !enqueued) core_keyup();
	}
	
	if (!core_alpha_menu())
	{
		[textEntryField resignFirstResponder];
		alphaMenuActive = NO;
	}
		
	return YES;
}

- (void) twoLineDisp
{	
	// If we are entering something then change the line
	// with the display.  Free42 uses this  to track the current row
	// for entry.
	if (flags.f.prgm_mode)
		cmdline_row = 1;
	else
		cmdline_row -= 2;
	
	b01.enabled = TRUE;
	b02.enabled = TRUE;
	b03.enabled = TRUE;
	b04.enabled = TRUE;
	b05.enabled = TRUE;
	b06.enabled = TRUE;

	CGPoint cent = blankButtonsView.center;
	cent.y = 108;
	blankButtonsView.center = cent;

	cent = menuView.center;
	cent.y = 102;
	menuView.center = cent;
	
	[blitterView twoLineDisp];
}

- (void) fourLineDisp
{
	// If we are entering something then change the line
	// with the display.  Free42 uses this  to track the current row
	// for entry.
	if (!flags.f.prgm_mode)
		cmdline_row += 2;
	
	b01.enabled = FALSE;
	b02.enabled = FALSE;
	b03.enabled = FALSE;
	b04.enabled = FALSE;
	b05.enabled = FALSE;
	b06.enabled = FALSE;
		
	
	CGPoint cent;
	
	cent = menuView.center;
	cent.y = 155;
	menuView.center = cent;

	cent = blankButtonsView.center;
	cent.y = 161;
	blankButtonsView.center = cent;
	
	[b07.superview bringSubviewToFront:b07];
	[b08.superview bringSubviewToFront:b08];
	[b09.superview bringSubviewToFront:b09];
	[b10.superview bringSubviewToFront:b10];
	[b11.superview bringSubviewToFront:b11];
	[b12.superview bringSubviewToFront:b12];
	
	[blitterView fourLineDisp];	
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
	if (dispRows > 2) [self fourLineDisp];	
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
	[super dealloc];
}

@end
