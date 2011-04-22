/*****************************************************************************
 * Free42 -- an HP-42S calculator simulator
 * Copyright (C) 2004-2011  Thomas Okken
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

#ifndef CORE_COMMANDS7_H
#define CORE_COMMANDS7_H 1

#include "free42.h"
#include "core_globals.h"

#if defined(ANDROID) || defined(IPHONE)
int docmd_accel(arg_struct *arg) COMMANDS7_SECT;
int docmd_locat(arg_struct *arg) COMMANDS7_SECT;
int docmd_heading(arg_struct *arg) COMMANDS7_SECT;
#endif

int docmd_adate(arg_struct *arg) COMMANDS7_SECT;
int docmd_atime(arg_struct *arg) COMMANDS7_SECT;
int docmd_atime24(arg_struct *arg) COMMANDS7_SECT;
int docmd_clk12(arg_struct *arg) COMMANDS7_SECT;
int docmd_clk24(arg_struct *arg) COMMANDS7_SECT;
int docmd_date(arg_struct *arg) COMMANDS7_SECT;
int docmd_date_plus(arg_struct *arg) COMMANDS7_SECT;
int docmd_ddays(arg_struct *arg) COMMANDS7_SECT;
int docmd_dmy(arg_struct *arg) COMMANDS7_SECT;
int docmd_dow(arg_struct *arg) COMMANDS7_SECT;
int docmd_mdy(arg_struct *arg) COMMANDS7_SECT;
int docmd_time(arg_struct *arg) COMMANDS7_SECT;

#endif
