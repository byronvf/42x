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

#include <stdlib.h>

#include "core_globals.h"
#include "core_variables.h"
#include "core_tables.h"
#include "core_display.h"
#include "undo.h"

snapshot* snapshot_head = NULL;
int snapshot_count = 0;
int undo_pos = 0;

snapshot* setstack(int snappos)
{
	// Free the current dynamic stack
	stack_item *si = bigstack_head;
	while(si)
	{
		stack_item *tmp = si->next;
		free_vartype(si->var);
		free_stack_item(si);
		si = tmp;
	}
	bigstack_head = NULL;
	stacksize = 3;
	
	// Find our snapshot based on the current undo position
	snapshot *snap = snapshot_head;
	int tmpcnt = snappos;
	while (tmpcnt-- > 0)
	{
		snap = snap->next;
		// snap should never be null here because caller should insure 
		// that snappos is always less then or equal to the number of snapshots
		assert(snap); 
	}		
	si = snap->stack_item_head;
	
	// Initialize the fixed registers

	free_vartype(reg_x);
	reg_x = dup_vartype(si->var);
	si = si->next;
	free_vartype(reg_y);
	reg_y = dup_vartype(si->var);
	si = si->next;
	free_vartype(reg_z);
	reg_z = dup_vartype(si->var);
	si = si->next;
	
	if (si)
	{
		free_vartype(reg_t);
		reg_t = dup_vartype(si->var);
		si = si->next;
		stacksize++;
	}
	else if (!flags.f.f32)
	{
		free_vartype(reg_t);
		reg_t = new_real(0);
		stacksize = 4;
	}

	// Build dynamic stack
	
	stack_item *prev = NULL;
	while (si)
	{		
		stack_item *tmp = new_stack_item(dup_vartype(si->var));
		if (prev)
		{
			prev->next = tmp;
		}
		else
		{
			bigstack_head = tmp;
		}
		prev = tmp;
		si = si->next;
		stacksize++;
	}
	
	return snap;
}

void undo_message(snapshot* snap, const char* name, int undcnt)
{
	char numstr[22];
	snprintf(numstr, 22, "%s %d: %s", name, undcnt, snap->describe);
	clear_row(0);
	draw_string(0, 0, numstr, strlen(numstr));
	flags.f.message = 1;
}

void free_snapshot(snapshot *snap)
{
	stack_item* si = snap->stack_item_head;
	while (si)
	{
		stack_item *tmp = si->next;
		free_vartype(si->var);
		free_stack_item(si);
		si = tmp;
	}
	free(snap);
}

void remove_first_snapshot()
{
	snapshot *tmp = snapshot_head->next;
	free_snapshot(snapshot_head);
	snapshot_head = tmp;
	snapshot_count--; assert(snapshot_count >= 0);
}

void record_undo(const char* desc)
{
	// Drop all the redo's that we will not use now since
	// we are recording an undo
	while(undo_pos > 0)
	{
		remove_first_snapshot();
		undo_pos--;
	}
	
	snapshot_count++;
	
	if (snapshot_count > MAX_UNDOS)
	{
		// Too many undos, so remove one
		snapshot *snap = snapshot_head;
		snapshot *prev = snap;
		
		// This fails if we ever have less then one snapshot, so don't do that
		while(snap->next)
		{
			prev = snap;
			snap = snap->next;
		}
		
		free_snapshot(snap);
		prev->next = NULL;
		snapshot_count--;
	}
		
	snapshot* snap = (snapshot*)malloc(sizeof(snapshot));
	snap->next = snapshot_head;
	snap->stack_item_head = NULL;		
	snapshot_head = snap;
		
	stack_item *si = bigstack_head;
	stack_item *currsi = NULL;
	while(si)
	{
		if (currsi)
		{
			currsi->next = new_stack_item(dup_vartype(si->var));
			currsi = currsi->next;
		}
		else
		{
			snap->stack_item_head = new_stack_item(dup_vartype(si->var));
			currsi = snap->stack_item_head;
		}
		si = si->next;
	}
	
	if (stacksize > 3)
	{
		currsi = new_stack_item(dup_vartype(reg_t));
		currsi->next = snap->stack_item_head;
		snap->stack_item_head = currsi;
	}
		
	currsi = new_stack_item(dup_vartype(reg_z));
	currsi->next = snap->stack_item_head;
	snap->stack_item_head = currsi;
		
	currsi = new_stack_item(dup_vartype(reg_y));
	currsi->next = snap->stack_item_head;
	snap->stack_item_head = currsi;
		
	currsi = new_stack_item(dup_vartype(reg_x));
	currsi->next = snap->stack_item_head;
	snap->stack_item_head = currsi;
		
	strncpy(snap->describe, desc, DESC_SIZE);
}

int docmd_undo(arg_struct *arg)
{
	assert(undo_pos <= snapshot_count);
	if (undo_pos+1 >= snapshot_count)
		return ERR_NONE;
	
	if (undo_pos == 0)
	{
		record_undo("STACK");
	}
		
	undo_pos++;
	
	snapshot* snap = setstack(undo_pos);	
	undo_message(snap, "UNDO", undo_pos);	
	
	return ERR_NONE;
}

int docmd_redo(arg_struct *arg)
{
	assert(undo_pos >= 0);
	if (undo_pos == 0)
		return ERR_NONE;
	
	undo_pos--;
	
	snapshot* snap = setstack(undo_pos);
	undo_message(snap->next, "REDO", undo_pos+1);
	
	if (undo_pos == 0)
	{
		remove_first_snapshot();
	}
	
	return ERR_NONE;
}

void record_undo_cmd(int cmd) 
{
	record_undo(cmdlist(cmd)->name);	
}

void record_undo_pending_cmd()
{	
	switch (pending_command)
	{
		case CMD_CLX:
		case CMD_SWAP:
		case CMD_CHS:
		case CMD_DIV:
		case CMD_MUL:
		case CMD_SUB:
		case CMD_ADD:
		case CMD_LASTX:
		case CMD_SIN:
		case CMD_COS:
		case CMD_TAN:
		case CMD_ASIN:
		case CMD_ACOS:
		case CMD_ATAN:
		case CMD_LOG:
		case CMD_10_POW_X:
		case CMD_LN:
		case CMD_E_POW_X:
		case CMD_SQRT:
		case CMD_SQUARE:
		case CMD_INV:
		case CMD_Y_POW_X:
		case CMD_PERCENT:
		case CMD_PI:
		case CMD_COMPLEX:
		case CMD_STO:
		case CMD_STO_DIV:
		case CMD_STO_MUL:
		case CMD_STO_SUB:
		case CMD_STO_ADD:
		case CMD_RCL:
		case CMD_RCL_DIV:
		case CMD_RCL_MUL:
		case CMD_RCL_SUB:
		case CMD_RCL_ADD:
		case CMD_ARCL:
		case CMD_CLST:
		case CMD_DEL:
		case CMD_CLALLa:
		case CMD_TO_DEG:
		case CMD_TO_RAD:
		case CMD_TO_HR:
		case CMD_TO_HMS:
		case CMD_TO_REC:
		case CMD_TO_POL:
		case CMD_IP:
		case CMD_FP:
		case CMD_RND:
		case CMD_ABS:
		case CMD_SIGN:
		case CMD_MOD:
		case CMD_COMB:
		case CMD_PERM:
		case CMD_FACT:
		case CMD_GAMMA:
		case CMD_RAN:
		case CMD_SIGMAADD:
		case CMD_SIGMASUB:
		case CMD_NEWMAT:
		case CMD_ACOSH:
		case CMD_ALENG:
		case CMD_AND:
		case CMD_ASINH:
		case CMD_ATANH:
		case CMD_BASEADD:
		case CMD_BASESUB:
		case CMD_BASEMUL:
		case CMD_BASEDIV:
		case CMD_BASECHS:
		case CMD_CORR:
		case CMD_COSH:
		case CMD_CROSS:
		case CMD_DELR:
		case CMD_DROP:
			
		record_undo_cmd(pending_command);
		break;
			
		case CMD_ENTER:
		
		record_undo("NEW NUMBER");
		break;
			
		case CMD_XEQ:
		
		char tmpstr[20];
		if (pending_command_arg.type == ARGTYPE_STR)
		{
			int length = MIN(pending_command_arg.length, 19);
			strncpy(tmpstr, pending_command_arg.val.text, length);
			tmpstr[length] = 0;
			record_undo(tmpstr);
		}
		else if (pending_command_arg.type == ARGTYPE_LBLINDEX)
		{
			int index = pending_command_arg.val.num;
			int length = MIN(labels[index].length, 19);
			strncpy(tmpstr, labels[index].name, length);
			tmpstr[length] = 0;
			record_undo(tmpstr);
		}
		break;
	}
		
}



