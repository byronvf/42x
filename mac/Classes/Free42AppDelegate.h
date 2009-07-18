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

#import <Cocoa/Cocoa.h>

#define FILENAMELEN 256
#define SHELL_VERSION 0

typedef struct state_type {
    int printerToTxtFile;
    int printerToGifFile;
    char printerTxtFileName[FILENAMELEN];
    char printerGifFileName[FILENAMELEN];
    int printerGifMaxLength;
    char mainWindowKnown, printWindowKnown, printWindowMapped;
    int mainWindowX, mainWindowY;
    int printWindowX, printWindowY, printWindowHeight;
    char skinName[FILENAMELEN];
};

extern state_type state;

extern char free42dirname[FILENAMELEN];

void calc_mousedown(int x, int y);
void calc_mouseup();
void calc_keydown(NSString *characters, NSUInteger flags, unsigned short keycode);
void calc_keyup(NSString *characters, NSUInteger flags, unsigned short keycode);
void calc_keymodifierschanged(NSUInteger flags);
	
@class ProgramListDataSource;
@class CalcView;
@class PrintView;

@interface Free42AppDelegate : NSObject {
	NSWindow *mainWindow;
	CalcView *calcView;
	
	NSWindow *printWindow;
	PrintView *printView;
	
	NSWindow *preferencesWindow;
	NSButton *prefsSingularMatrix;
	NSButton *prefsMatrixOutOfRange;
	NSButton *prefsAutoRepeat;
	NSButton *prefsPrintText;
	NSTextField *prefsPrintTextFile;
	NSButton *prefsPrintTextRaw;
	NSButton *prefsPrintGIF;
	NSTextField *prefsPrintGIFFile;
	NSTextField *prefsPrintGIFMaxHeight;
	
	NSWindow *selectProgramsWindow;
	NSTableView *programListView;
	ProgramListDataSource *programListDataSource;
	
	NSWindow *aboutWindow;
	NSTextField *aboutVersion;
	NSTextField *aboutCopyright;
}

@property (nonatomic, retain) IBOutlet NSWindow *mainWindow;
@property (nonatomic, retain) IBOutlet CalcView *calcView;
@property (nonatomic, retain) IBOutlet NSWindow *printWindow;
@property (nonatomic, retain) IBOutlet PrintView *printView;
@property (nonatomic, retain) IBOutlet NSWindow *preferencesWindow;
@property (nonatomic, retain) IBOutlet NSButton *prefsSingularMatrix;
@property (nonatomic, retain) IBOutlet NSButton *prefsMatrixOutOfRange;
@property (nonatomic, retain) IBOutlet NSButton *prefsAutoRepeat;
@property (nonatomic, retain) IBOutlet NSButton *prefsPrintText;
@property (nonatomic, retain) IBOutlet NSTextField *prefsPrintTextFile;
@property (nonatomic, retain) IBOutlet NSButton *prefsPrintTextRaw;
@property (nonatomic, retain) IBOutlet NSButton *prefsPrintGIF;
@property (nonatomic, retain) IBOutlet NSTextField *prefsPrintGIFFile;
@property (nonatomic, retain) IBOutlet NSTextField *prefsPrintGIFMaxHeight;
@property (nonatomic, retain) IBOutlet NSWindow *selectProgramsWindow;
@property (nonatomic, retain) IBOutlet NSTableView *programListView;
@property (nonatomic, retain) IBOutlet ProgramListDataSource *programListDataSource;
@property (nonatomic, retain) IBOutlet NSWindow *aboutWindow;
@property (nonatomic, retain) IBOutlet NSTextField *aboutVersion;
@property (nonatomic, retain) IBOutlet NSTextField *aboutCopyright;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification;
- (void)applicationWillTerminate:(NSNotification *)aNotification;
- (void)windowWillClose:(NSNotification *)notification;

- (IBAction) showAbout:(id)sender;
- (IBAction) showPreferences:(id)sender;
- (void) getPreferences;
- (IBAction) browsePrintTextFile:(id)sender;
- (IBAction) browsePrintGIFFile:(id)sender;
- (IBAction) showPrintOut:(id)sender;
- (IBAction) clearPrintOut:(id)sender;
- (IBAction) importPrograms:(id)sender;
- (IBAction) exportPrograms:(id)sender;
- (IBAction) exportProgramsCancel:(id)sender;
- (IBAction) exportProgramsOK:(id)sender;
- (IBAction) doCopy:(id)sender;
- (IBAction) doPaste:(id)sender;
+ (const char *) getVersion;
- (IBAction) menuNeedsUpdate:(NSMenu *)menu;
- (void) selectSkin:(id)sender;

@end
