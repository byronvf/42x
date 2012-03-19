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

#ifndef UNDO_H
#define UNDO_H 1

#define DESC_SIZE 24
#define MAX_UNDOS 31

struct snapshot_struct
{
    struct stack_item_struct* stack_item_head;
    struct snapshot_struct* next;
    char describe[DESC_SIZE];
};

typedef struct snapshot_struct snapshot;

extern snapshot* snapshot_head;
extern int snapshot_count;
extern int undo_pos;
extern int roll_count;
extern bool roll_pending;

int docmd_undo(arg_struct *arg);
int docmd_redo(arg_struct *arg);
void record_undo_cmd(int cmd, arg_struct *arg);
void record_undo(const char*);
void record_undo_cleanup(int error);

vartype* get_most_recent_x();
void modify_most_recent_snapshot_message(char *buf, int length);
void remove_first_snapshot();
#endif
