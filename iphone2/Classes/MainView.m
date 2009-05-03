/*****************************************************************************
 * Free42 -- an HP-42S calculator simulator
 * Copyright (C) 2004-2009  Thomas Okken
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License, version 2,
 * as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see http://www.gnu.org/licenses/.
 *****************************************************************************/

#import <UIKit/UIKit.h>
#import <sys/stat.h>
#import <sys/sysctl.h>
#import <pthread.h>

#import <AudioToolbox/AudioServices.h>

#import "MainView.h"
#import "MyRect.h"
#import "free42.h"
#import "core_main.h"
#import "core_display.h"
#import "shell.h"
#import "shell_iphone.h"
#import "shell_skin_iphone.h"

// For "audio enable" flag
#import "core_globals.h"


///////////////////////////////////////////////////////////////////////////////
/////                         Ye olde C stuphphe                          /////
///////////////////////////////////////////////////////////////////////////////

static int level = 0;

class Tracer {
private:
	const char *name;
public:
	Tracer(const char *name) {
		this->name = name;
		for (int i = 0; i < level; i++)
			fprintf(stderr, " ");
		fprintf(stderr, "ENTERING %s\n", name);
		level++;
	}
	~Tracer() {
		level--;
		for (int i = 0; i < level; i++)
			fprintf(stderr, " ");
		fprintf(stderr, "EXITING %s\n", name);
	}
};

#if 0
#define TRACE(x) Tracer T(x)
#else
#define TRACE(x)
#endif
		
static void quit2();
static void shell_keydown();
static void shell_keyup();

static int skin_width, skin_height;

static int read_shell_state(int *version);
static void init_shell_state(int version);
static int write_shell_state();

state_type state;
static FILE* statefile;

static int quit_flag = 0;
static int enqueued;
static int keep_running = 0;
static int we_want_cpu = 0;
static bool is_running = false;
static pthread_mutex_t is_running_mutex = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t is_running_cond = PTHREAD_COND_INITIALIZER;

static int ckey = 0;
static int skey;
static unsigned char *macro;
static int mouse_key;

static bool timeout_active = false;
static int timeout_which;
static bool timeout3_active = false;
static bool repeater_active = false;

static int ann_updown = 0;
static int ann_shift = 0;
static int ann_print = 0;
static int ann_run = 0;
//static int ann_battery = 0;
static int ann_g = 0;
static int ann_rad = 0;

///////////////////////////////////////////////////////////////////////////////
/////                    Ende ophphe ye olde C stuphphe                   /////
///////////////////////////////////////////////////////////////////////////////


static MainView *mainView = nil;

@implementation MainView


- (id) initWithFrame:(CGRect)frame {
	TRACE("initWithFrame");
    if (self = [super initWithFrame:frame]) {
        // Note: this does not get called when instantiated from a nib file,
		// so don't bother doing anything here!
    }
    return self;
}

- (void) setNeedsDisplayInRectSafely2:(id) myrect {
	TRACE("setNeedsDisplayInRectSafely2");
	CGRect r = [myrect rect];
	[self setNeedsDisplayInRect:r];
}

- (void) setNeedsDisplayInRectSafely:(CGRect) rect {
	TRACE("setNeedsDisplayInRectSafely");
	if ([NSThread isMainThread])
		[self setNeedsDisplayInRect:rect];
	else
		[self performSelectorOnMainThread:@selector(setNeedsDisplayInRectSafely2:) withObject:[MyRect rectWithCGRect:rect] waitUntilDone:NO];
}

- (void) showMainMenu {
	UIActionSheet *menu =
	[[UIActionSheet alloc] initWithTitle:@"Main Menu"
								delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
					   otherButtonTitles:@"Show Print-Out", @"Program Import & Export", @"Preferences", @"Select Skin", @"About Free42", nil, nil];
	
	[menu showInView:self];
	[menu release];
}

- (void) showImportExportMenu {
	UIActionSheet *menu =
	[[UIActionSheet alloc] initWithTitle:@"Import & Export Menu"
								delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
					   otherButtonTitles:@"HTTP Server", @"Import Programs", @"Export Programs", @"Back", nil, nil, nil];
	
	[menu showInView:self];
	[menu release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if ([[actionSheet title] isEqualToString:@"Main Menu"]) {
		switch (buttonIndex) {
			case 0:
				// Show Print-Out
				[shell_iphone showPrintOut];
				break;
			case 1:
				// Program Import & Export
				[self showImportExportMenu];
				break;
			case 2:
				// Preferences
				[shell_iphone showPreferences];
				break;
			case 3:
				// Select Skin
				[shell_iphone showSelectSkin];
				break;
			case 4:
				// About Free42
				[shell_iphone showAbout];
				break;
			case 5:
				// Cancel
				break;
		}
	} else {
		switch (buttonIndex) {
			case 0:
				// HTTP Server
				[shell_iphone showHttpServer];
				break;
			case 1:
				// Import Programs
				[shell_iphone playSound:10];
				break;
			case 2:
				// Export Programs
				[shell_iphone playSound:10];
				break;
			case 3:
				// Back
				[self showMainMenu];
				break;
			case 4:
				// Cancel
				break;
		}
	}
}

- (void) drawRect:(CGRect)rect {
	TRACE("drawRect");
	if (mainView == nil)
		[self initialize];
	skin_repaint(&rect);
}

- (void) dealloc {
	TRACE("dealloc");
	NSLog(@"Shutting down!");
    [super dealloc];
}

- (void) touchesBegan3 {
	TRACE("touchesBegan3");
	// TODO -- a separate Keyboard Clicks setting in Preferences would be better;
	// figuring out how to read Settings -> General -> Sounds -> Keyboard Clicks
	// would be better still!
	if (flags.f.audio_enable)
		AudioServicesPlaySystemSound(1105);
	macro = skin_find_macro(ckey);
	shell_keydown();
	mouse_key = 1;
}

- (void) touchesBegan2 {
	TRACE("touchesBegan2");
	we_want_cpu = 1;
	pthread_mutex_lock(&is_running_mutex);
	while (is_running)
		pthread_cond_wait(&is_running_cond, &is_running_mutex);
	pthread_mutex_unlock(&is_running_mutex);
	we_want_cpu = 0;
	[self performSelectorOnMainThread:@selector(touchesBegan3) withObject:NULL waitUntilDone:NO];
}

- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event {
	TRACE("touchesBegan");
	[super touchesBegan:touches withEvent:event];
	UITouch *touch = (UITouch *) [touches anyObject];
	CGPoint p = [touch locationInView:self];
	int x = (int) p.x;
	int y = (int) p.y;
	if (skin_in_menu_area(x, y)) {
		[self showMainMenu];
	} else if (ckey == 0) {
		skin_find_key(x, y, ann_shift != 0, &skey, &ckey);
		if (ckey != 0) {
			if (is_running)
				[self performSelectorInBackground:@selector(touchesBegan2) withObject:NULL];
			else
				[self touchesBegan3];
		}
	}
}

- (void) touchesEnded3 {
	TRACE("touchesEnded3");
	shell_keyup();
}

- (void) touchesEnded2 {
	TRACE("touchesEnded2");
	we_want_cpu = 1;
	pthread_mutex_lock(&is_running_mutex);
	while (is_running)
		pthread_cond_wait(&is_running_cond, &is_running_mutex);
	pthread_mutex_unlock(&is_running_mutex);
	we_want_cpu = 0;
	[self performSelectorOnMainThread:@selector(touchesEnded3) withObject:NULL waitUntilDone:NO];
}

- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event {
	TRACE("touchesEnded");
	[super touchesEnded:touches withEvent:event];
	if (ckey != 0 && mouse_key) {
		if (is_running)
			[self performSelectorInBackground:@selector(touchesEnded2) withObject:NULL];
		else
			[self touchesEnded3];
	}
}

- (void) touchesCancelled: (NSSet *) touches withEvent: (UIEvent *) event {
	TRACE("touchesCancelled");
	[super touchesCancelled:touches withEvent:event];
	if (ckey != 0 && mouse_key) {
		if (is_running)
			[self performSelectorInBackground:@selector(touchesEnded2) withObject:NULL];
		else
			[self touchesEnded3];
	}
}

+ (void) repaint {
	TRACE("repaint");
	[mainView setNeedsDisplay];
}

+ (void) quit {
	TRACE("quit");
	quit2();
}

- (void) startRunner {
	TRACE("startRunner");
	[self performSelectorInBackground:@selector(runner) withObject:NULL];
}

- (void) initialize {
	TRACE("initialize");
	mainView = self;
	statefile = fopen("config/state", "r");
	int init_mode, version;
	if (statefile != NULL) {
		if (read_shell_state(&version)) {
			init_mode = 1;
		} else {
			init_shell_state(-1);
			init_mode = 2;
		}
	} else {
		init_shell_state(-1);
		init_mode = 0;
	}

	long w, h;
	skin_load(&w, &h);
	skin_width = w;
	skin_height = h;
	
	core_init(init_mode, version);
	if (statefile != NULL) {
		fclose(statefile);
		statefile = NULL;
	}
	keep_running = core_powercycle();
	if (keep_running)
		[self startRunner];
}

- (void) runner {
	TRACE("runner");
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int dummy1, dummy2;
	is_running = true;
	keep_running = core_keydown(0, &dummy1, &dummy2);
	pthread_mutex_lock(&is_running_mutex);
	is_running = false;
	pthread_cond_signal(&is_running_cond);
	pthread_mutex_unlock(&is_running_mutex);
	if (quit_flag)
		[self performSelectorOnMainThread:@selector(quit) withObject:NULL waitUntilDone:NO];
	else if (keep_running && !we_want_cpu)
		[self performSelectorOnMainThread:@selector(startRunner) withObject:NULL waitUntilDone:NO];
	[pool release];
}

- (void) setTimeout:(int) which {
	TRACE("setTimeout");
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout_callback) object:NULL];
	timeout_which = which;
	timeout_active = true;
	[self performSelector:@selector(timeout_callback) withObject:NULL afterDelay:(which == 1 ? 0.25 : 1.75)];
}

- (void) cancelTimeout {
	TRACE("cancelTimeout");
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout_callback) object:NULL];
	timeout_active = false;
}

- (void) timeout_callback {
	TRACE("timeout_callback");
	timeout_active = false;
	if (ckey != 0) {
		if (timeout_which == 1) {
			core_keytimeout1();
			[self setTimeout:2];
		} else if (timeout_which == 2) {
			core_keytimeout2();
		}
	}
}

- (void) setTimeout3: (int) delay {
	TRACE("setTimeout3");
	[self cancelTimeout3];
	[self performSelector:@selector(timeout3_callback) withObject:NULL afterDelay:(delay / 1000.0)];
	timeout3_active = true;
}

- (void) cancelTimeout3 {
	TRACE("cancelTimeout3");
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout3_callback) object:NULL];
	timeout3_active = false;
}
	
- (void) timeout3_callback {
	TRACE("timeout3_callback");
	timeout3_active = false;
	keep_running = core_timeout3(1);
	if (keep_running)
		[self startRunner];
}

- (void) setRepeater: (int) delay {
	TRACE("setRepeater");
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(repeater_callback) object:NULL];
	[self performSelector:@selector(repeater_callback) withObject:NULL afterDelay:(delay / 1000.0)];
	repeater_active = true;
}

- (void) cancelRepeater {
	TRACE("cancelRepeater");
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(repeater_callback) object:NULL];
	repeater_active = false;
}

- (void) repeater_callback {
	TRACE("repeater_callback");
	int repeat = core_repeat();
	if (repeat != 0)
		[self setRepeater:(repeat == 1 ? 200 : 100)];
	else
		[self setTimeout:1];
}

// The following is some wrapper code, to allow functions called by core_keydown()
// while it is running in the background, to run in the main thread.

static union {
	struct {
		int delay;
	} shell_request_timeout3_args;
	struct {
		const char *text;
		int length;
		const char *bits;
		int bytesperline;
		int x, y, width, height;
	} shell_print_args;
} helper_args;

static pthread_mutex_t shell_helper_mutex = PTHREAD_MUTEX_INITIALIZER;

- (void) shell_request_timeout3_helper {
	TRACE("shell_request_timeout3_helper");
	[mainView setTimeout3:helper_args.shell_request_timeout3_args.delay];
	pthread_mutex_unlock(&shell_helper_mutex);
}

- (void) shell_print_helper {
	TRACE("shell_print_helper");
	// TODO
	pthread_mutex_unlock(&shell_helper_mutex);
}

@end

///////////////////////////////////////////////////////////////////////////////
/////                   Here beginneth thy olde C code                    /////
///////////////////////////////////////////////////////////////////////////////

static int read_shell_state(int *ver) {
	TRACE("read_shell_state");
    int magic;
    int version;
    int state_size;
    int state_version;
	
    if (shell_read_saved_state(&magic, sizeof(int)) != sizeof(int))
		return 0;
    if (magic != FREE42_MAGIC)
		return 0;
	
    if (shell_read_saved_state(&version, sizeof(int)) != sizeof(int))
		return 0;
    if (version == 0) {
		/* State file version 0 does not contain shell state,
		 * only core state, so we just hard-init the shell.
		 */
		init_shell_state(-1);
		*ver = version;
		return 1;
    } else if (version > FREE42_VERSION)
		/* Unknown state file version */
		return 0;
	
    if (shell_read_saved_state(&state_size, sizeof(int)) != sizeof(int))
		return 0;
    if (shell_read_saved_state(&state_version, sizeof(int)) != sizeof(int))
		return 0;
    if (state_version < 0 || state_version > SHELL_VERSION)
		/* Unknown shell state version */
		return 0;
    if (shell_read_saved_state(&state, state_size) != state_size)
		return 0;
	
    init_shell_state(state_version);
    *ver = version;
    return 1;
}

static void init_shell_state(int version) {
	TRACE("init_shell_state");
    switch (version) {
        case -1:
            state.printerToTxtFile = 0;
            state.printerToGifFile = 0;
            state.printerTxtFileName[0] = 0;
            state.printerGifFileName[0] = 0;
            state.printerGifMaxLength = 256;
            state.skinName[0] = 0;
            /* fall through */
        case 0:
			state.popupKeyboard = 0;
			/* fall through */
		case 1:
            /* current version (SHELL_VERSION = 1),
             * so nothing to do here since everything
             * was initialized from the state file.
             */
            ;
    }
}

static void quit2() {
	TRACE("quit2");
	mkdir("config", 0755);
    statefile = fopen("config/state", "w");
    if (statefile != NULL)
        write_shell_state();
    core_quit();
    if (statefile != NULL)
        fclose(statefile);
	exit(0);
}

static void shell_keydown() {
	TRACE("shell_keydown");
    int repeat;
    if (skey == -1)
		skey = skin_find_skey(ckey);
	skin_set_pressed_key(skey, mainView);
    if (timeout3_active && (macro != NULL || ckey != 28 /* KEY_SHIFT */)) {
		[mainView cancelTimeout3];
		core_timeout3(0);
    }
	
	// We temporarily set we_want_cpu to 'true', to force the calls
	// to core_keydown() in this function to return quickly. This is
	// necessary since this function runs on the main thread, and we
	// can't peek ahead in the event queue while core_keydown() is
	// hogging the CPU on the main thread. (The lack of something like
	// EventAvail is an annoying omission of the iPhone API.)
		
    if (macro != NULL) {
		if (*macro == 0) {
			squeak();
			return;
		}
		bool one_key_macro = macro[1] == 0 || (macro[2] == 0 && macro[0] == 28);
		if (!one_key_macro) {
			skin_display_set_enabled(false);
		}
		while (*macro != 0) {
			we_want_cpu = 1;
			keep_running = core_keydown(*macro++, &enqueued, &repeat);
			we_want_cpu = 0;
			if (*macro != 0 && !enqueued)
				core_keyup();
		}
		if (!one_key_macro) {
			skin_display_set_enabled(true);
			skin_repaint_display(mainView);
			/*
			skin_repaint_annunciator(1, ann_updown);
			skin_repaint_annunciator(2, ann_shift);
			skin_repaint_annunciator(3, ann_print);
			skin_repaint_annunciator(4, ann_run);
			skin_repaint_annunciator(5, ann_battery);
			skin_repaint_annunciator(6, ann_g);
			skin_repaint_annunciator(7, ann_rad);
			*/
			repeat = 0;
		}
    } else {
		we_want_cpu = 1;
		keep_running = core_keydown(ckey, &enqueued, &repeat);
		we_want_cpu = 0;
	}
	
    if (quit_flag)
		quit2();
    else if (keep_running)
		[mainView startRunner];
    else {
		[mainView cancelTimeout];
		[mainView cancelRepeater];
		if (repeat != 0)
			[mainView setRepeater:(repeat == 1 ? 1000 : 500)];
		else if (!enqueued)
			[mainView setTimeout:1];
    }
}

static void shell_keyup() {
	TRACE("shell_keyup");
	skin_set_pressed_key(-1, mainView);
    ckey = 0;
    skey = -1;
	[mainView cancelTimeout];
	[mainView cancelRepeater];
    if (!enqueued) {
		keep_running = core_keyup();
		if (quit_flag)
			quit2();
		else if (keep_running)
			[mainView startRunner];
    } else if (keep_running) {
		[mainView startRunner];
	}
}

static int write_shell_state() {
	TRACE("write_shell_state");
    int magic = FREE42_MAGIC;
    int version = FREE42_VERSION;
    int state_size = sizeof(state);
    int state_version = SHELL_VERSION;
	
    if (!shell_write_saved_state(&magic, sizeof(int)))
        return 0;
    if (!shell_write_saved_state(&version, sizeof(int)))
        return 0;
    if (!shell_write_saved_state(&state_size, sizeof(int)))
        return 0;
    if (!shell_write_saved_state(&state_version, sizeof(int)))
        return 0;
    if (!shell_write_saved_state(&state, sizeof(state)))
        return 0;
	
    return 1;
}

void shell_blitter(const char *bits, int bytesperline, int x, int y, int width, int height) {
	TRACE("shell_blitter");
	skin_display_blitter(bits, bytesperline, x, y, width, height, mainView);
}

void shell_beeper(int frequency, int duration) {
	TRACE("shell_beeper");
	const int cutoff_freqs[] = { 164, 220, 243, 275, 293, 324, 366, 418, 438, 550 };
	for (int i = 0; i < 10; i++) {
		if (frequency <= cutoff_freqs[i]) {
			[shell_iphone playSound:i];
			shell_delay(250);
			return;
		}
	}
	[shell_iphone playSound:10];
	shell_delay(125);
}

void shell_annunciators(int updn, int shf, int prt, int run, int g, int rad) {
	TRACE("shell_annunciators");
	if (updn != -1 && ann_updown != updn) {
		ann_updown = updn;
		skin_update_annunciator(1, ann_updown, mainView);
	}
	if (shf != -1 && ann_shift != shf) {
		ann_shift = shf;
		skin_update_annunciator(2, ann_shift, mainView);
	}
	if (prt != -1 && ann_print != prt) {
		ann_print = prt;
		skin_update_annunciator(3, ann_print, mainView);
	}
	if (run != -1 && ann_run != run) {
		ann_run = run;
		skin_update_annunciator(4, ann_run, mainView);
	}
	if (g != -1 && ann_g != g) {
		ann_g = g;
		skin_update_annunciator(6, ann_g, mainView);
	}
	if (rad != -1 && ann_rad != rad) {
		ann_rad = rad;
		skin_update_annunciator(7, ann_rad, mainView);
	}
}

int shell_wants_cpu() {
	TRACE("shell_wants_cpu");
	return we_want_cpu;
}

void shell_delay(int duration) {
	TRACE("shell_delay");
    struct timespec ts;
    ts.tv_sec = duration / 1000;
    ts.tv_nsec = (duration % 1000) * 1000000;
    nanosleep(&ts, NULL);
}

void shell_request_timeout3(int delay) {
	TRACE("shell_request_timeout3");
	pthread_mutex_lock(&shell_helper_mutex);
	helper_args.shell_request_timeout3_args.delay = delay;
	[mainView performSelectorOnMainThread:@selector(shell_request_timeout3_helper) withObject:NULL waitUntilDone:NO];
}

int shell_read_saved_state(void *buf, int bufsize) {
	TRACE("shell_read_saved_state");
    if (statefile == NULL)
		return -1;
    else {
		int n = fread(buf, 1, bufsize, statefile);
		if (n != bufsize && ferror(statefile)) {
			fclose(statefile);
			statefile = NULL;
			return -1;
		} else
			return n;
    }
}

bool shell_write_saved_state(const void *buf, int nbytes) {
	TRACE("shell_write_saved_state");
    if (statefile == NULL)
		return false;
    else {
		int n = fwrite(buf, 1, nbytes, statefile);
		if (n != nbytes) {
			fclose(statefile);
			remove("config/state");
			statefile = NULL;
			return false;
		} else
			return true;
    }
}

unsigned int shell_get_mem() {
	TRACE("shell_get_mem");
	int mib[2];
	unsigned int memsize;
	size_t len;
	
	// Retrieve the available system memory
	
	mib[0] = CTL_HW;
	mib[1] = HW_USERMEM;
	len = sizeof(memsize);
	sysctl(mib, 2, &memsize, &len, NULL, 0);
	
	return memsize;
}

int shell_low_battery() {
	TRACE("shell_low_battery");
	// TODO
	return 0;
}

void shell_powerdown() {
	TRACE("shell_powerdown");
	quit_flag = 1;
	we_want_cpu = 1;
}

double shell_random_seed() {
	TRACE("shell_random_seed");
	struct timeval tv;
	gettimeofday(&tv, NULL);
	return ((tv.tv_sec * 1000000L + tv.tv_usec) & 0xffffffffL) / 4294967296.0;
}

unsigned int shell_milliseconds() {
	TRACE("shell_milliseconds");
	struct timeval tv;
    gettimeofday(&tv, NULL);
    return (unsigned int) (tv.tv_sec * 1000L + tv.tv_usec / 1000);
}

void shell_print(const char *text, int length,
				 const char *bits, int bytesperline,
				 int x, int y, int width, int height) {
	TRACE("shell_print");
	pthread_mutex_lock(&shell_helper_mutex);
	[mainView performSelectorOnMainThread:@selector(shell_print_helper) withObject:NULL waitUntilDone:NO];
}

/*
int shell_write(const char *buf, int buflen) {
	return 0;
}

int shell_read(char *buf, int buflen) {
	return -1;
}
*/

shell_bcd_table_struct *shell_get_bcd_table() {
	TRACE("shell_get_bcd_table");
	return NULL;
}

shell_bcd_table_struct *shell_put_bcd_table(shell_bcd_table_struct *bcdtab,
											unsigned int size) {
	TRACE("shell_put_bcd_table");
	return bcdtab;
}

void shell_release_bcd_table(shell_bcd_table_struct *bcdtab) {
	TRACE("shell_release_bcd_table");
	free(bcdtab);
}
