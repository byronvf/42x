/*****************************************************************************
 * Free42 -- an HP-42S calculator simulator
 * Copyright (C) 2004-2010  Thomas Okken
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

#ifndef SHELL_MAIN_H
#define SHELL_MAIN_H 1

#define FILENAMELEN 256

extern Display *display;
extern Screen *screen;
extern int screennumber;
extern Window rootwindow;
extern Visual *visual;
extern Colormap colormap;
extern int depth; 
extern GC gc;
extern unsigned long black, white; 

extern Widget calc_widget;
extern Window calc_canvas;
extern int allow_paint;


#define SHELL_VERSION 4

typedef struct state_type {
    int extras;
    int printerToTxtFile;
    int printerToGifFile;
    char printerTxtFileName[FILENAMELEN];
    char printerGifFileName[FILENAMELEN];
    int printerGifMaxLength;
    char mainWindowKnown, printWindowKnown, printWindowMapped;
    int mainWindowX, mainWindowY;
    int printWindowX, printWindowY, printWindowHeight;
    char skinName[FILENAMELEN];
    int singleInstance;
};

extern state_type state;

extern char free42dirname[FILENAMELEN];


#define KEYMAP_MAX_MACRO_LENGTH 31
typedef struct {
    bool ctrl;
    bool alt;
    bool shift;
    bool cshift;
    KeySym keysym;
    unsigned char macro[KEYMAP_MAX_MACRO_LENGTH];
} keymap_entry;

keymap_entry *parse_keymap_entry(char *line, int lineno);

void allow_mainwindow_resize();
void disallow_mainwindow_resize();

#endif
