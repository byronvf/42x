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

#define DESC_SIZE 22
#define MAX_UNDOS 20

struct snapshot_struct
{
    stack_item* stack_item_head;
    struct snapshot_struct* next;
    char describe[DESC_SIZE];
};

typedef struct snapshot_struct snapshot;

extern snapshot* snapshot_head;
extern int snapshot_count;

int docmd_undo(arg_struct *arg);
int docmd_redo(arg_struct *arg);
void record_undo_pending_cmd();
void record_undo(const char*);

#endif
