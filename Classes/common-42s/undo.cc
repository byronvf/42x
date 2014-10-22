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
#include "core_helpers.h"
#include "undo.h"
#include "units.h"

// Pointer to the list of snapshots that we use to keep version of the stack
snapshot* snapshot_head = NULL;

// Number of snapshots, or undos that are currently in the list pointed to by
// snapshot_head
int snapshot_count = 0;

// keeps track of the current snapshot number currently displayed.  1 being
// the most recent undo
int undo_pos = 0;

// We track the number of roll operations so we can collect them into a single
// undo.  roll_count is decremented for rolling down, and increment for up.
int roll_count = 0;

// Indicates that the stack has been disturbed by rolling operations, we use 
// this to determine if we should create undo snapshots in given cases.
bool roll_pending = FALSE;

// Tracks if we have created a new snapshot, used by method undo_record_cleanup
// so that we can unwind, or remove a snapshot if a command creates an error
bool new_snapshot = FALSE;

/* Restore the stack to the given snapshot number, we begin counting
   with zero so that the first snapshot in the list is 0. */
snapshot* setstack(int snappos)
{
	// We can't restore from a position larger then the number of snapshots
	assert(snappos < snapshot_count);
	
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

void draw_lcd_message(const char* msg)
{
	clear_row(0);
	int len = (int)strlen(msg);
		
	draw_string(0, 0, msg, len);

	// hack to handle the devide symbol, there should be 
	// no other reason a '/' charater should be in the undo string
	for (int i=0; i<len; i++)
		if (msg[i] == '\022') 
			draw_string(i, 0, "\000", 1);
	
	if (len >= 23) 
		draw_string(21, 0, "\032", 1); // the "..." character
	flags.f.message = 1;
}

void undo_message(snapshot* snap, const char* name, int undcnt)
{
	char str[DESC_SIZE];
	memset(str, ' ', DESC_SIZE);
	snprintf(str, DESC_SIZE, "%s %d\200%s", name, undcnt, snap->describe);
	draw_lcd_message(str);
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
	assert(snapshot_head);
	snapshot *tmp = snapshot_head->next;
	free_snapshot(snapshot_head);
	snapshot_head = tmp;
	snapshot_count--; 
    	assert(snapshot_count >= 0);
}

void record_undo(const char* desc)
{
	new_snapshot = TRUE;
	
	if (roll_pending)
	{
		char dir_char = '\016';
		if (roll_count > 0) dir_char = '^';
		
		roll_pending = FALSE;
		if (undo_pos == 0)
		{			
			if (roll_count % stacksize == 0)
			{
				assert(snapshot_head);
				remove_first_snapshot();		
			}
			else 
			{
				snprintf(snapshot_head->describe, 
						 DESC_SIZE, "ROLL %c * %d",dir_char, abs(roll_count));
				snapshot_head->describe[DESC_SIZE-1] = NULL;
			}
		}
		else if (roll_count % stacksize != 0)
		{
			snprintf(snapshot_head->describe, 
					 DESC_SIZE, "ROLL %c * %d",dir_char, abs(roll_count));
			snapshot_head->describe[DESC_SIZE-1] = NULL;
			record_undo(snapshot_head->describe);
		}

		roll_count = 0;
	}	
	
	// If the undo_pos is more than zero, then we have one extra 
	// snapshot on the list which was the current stack before
	// the undos, so we force the removal of that snapshot here.
	if (undo_pos > 0) undo_pos++;
	
	// Drop all the redo's that we will not use now since
	// we are recording an undo. 
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
	snap->describe[DESC_SIZE-1] = NULL;
}

int docmd_undo(arg_struct *arg)
{
	if (!(undo_pos == 0 and snapshot_count == 1) && 
		undo_pos >= snapshot_count-1)
	{	
		draw_lcd_message("No More UNDOs");
		return ERR_NONE;
	}
	
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
	{
		draw_lcd_message("No More REDOs");
		return ERR_NONE;
	}
	
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

void record_undo_cmd(int cmd, arg_struct *arg)
{
	new_snapshot = FALSE;
	
	char str[DESC_SIZE];
	switch (cmd)
	{
		case CMD_DIV:
			record_undo("\022");
			break;
			
		case CMD_CLX:
		case CMD_SWAP:
		case CMD_CHS:
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
		case CMD_ATOX:	
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

		case CMD_ACCEL:
		case CMD_LOCAT:
		case CMD_HEADING:
		

		case CMD_DATE:
		case CMD_DATE_PLUS:
		case CMD_DDAYS:
		case CMD_DOW:
		case CMD_TIME:			


		case CMD_DET:
		case CMD_DIM:
		case CMD_DOT:
		case CMD_EDIT:
		case CMD_EDITN:
		case CMD_E_POW_X_1:
		case CMD_FCSTX:
		case CMD_FCSTY:
		case CMD_FNRM:
		case CMD_GETM:
		case CMD_HMSADD:
		case CMD_HMSSUB:
		case CMD_INSR:
		case CMD_INVRT:
		case CMD_LN_1_X:
		case CMD_MEAN:
		case CMD_NOT:
		case CMD_OLD:
		case CMD_OR:
		case CMD_POSA:
		case CMD_PUTM:
		case CMD_RCLEL:
		case CMD_RCLIJ:
		case CMD_RNRM:
		case CMD_ROTXY:
		case CMD_RSUM:
		case CMD_SWAP_R:
		case CMD_SDEV:
		case CMD_SINH:
		case CMD_SLOPE:
		case CMD_STOEL:
		case CMD_STOIJ:
		case CMD_SUM:
		case CMD_TANH:
		case CMD_TRANS:
		case CMD_UVEC:
		case CMD_WMEAN:
		case CMD_X_SWAP:
		case CMD_XOR:
		case CMD_YINT:
		case CMD_TO_DEC:
		case CMD_TO_OCT:
		case CMD_PERCENT_CH:
		case CMD_MAX:
		case CMD_MIN:
			
		case CMD_VMSOLVE:
		case CMD_INTEG:
						
			record_undo_cmd(cmd);
		break;
			
		case CMD_ENTER:
		
			record_undo("ENTER");
		break;
			
		case CMD_XEQ:
		
			if (arg->type == ARGTYPE_STR)
			{
				snprintf(str, DESC_SIZE, "XEQ \"%.*s\"", arg->length, arg->val.text);
				record_undo(str);
			}
			else if (arg->type == ARGTYPE_LBLINDEX)
			{
				snprintf(str, DESC_SIZE, "XEQ \"%.*s\"", labels[arg->val.num].length, 
						 labels[arg->val.num].name);
				record_undo(str);
			}
			else
				record_undo("XEQ");

			// Even if XEQ may create an error, we don't want to 
			// pop a snapshot off the undo list in record_undo_cleanup
			// since running a program may still disturb the stack
			new_snapshot = FALSE;
			break;
			
			case CMD_RDN:		
				roll_count -= 2;
				// fall through, roll_count will only decrement by 1
			case CMD_RUP:
				roll_count++;
				roll_count %= stacksize;

			if (!roll_pending)
			{
				if (undo_pos == 0)
				{
					record_undo_cmd(cmd);
				}
				roll_pending = TRUE;
			}
		break;
			
		case CMD_NUMBER:
			// We only get here if we are stepping through a program
			record_undo("NUMBER");			
		break;
		
		case CMD_STO:
		case CMD_STO_DIV:
		case CMD_STO_MUL:
		case CMD_STO_SUB:
		case CMD_STO_ADD:
			
			if (arg->type == ARGTYPE_STK)
			{
				char str[DESC_SIZE];
				snprintf(str, DESC_SIZE, "%s ST %c",cmdlist(cmd)->name, 
					 arg->val.stk);	
				record_undo(str);
			}
			
			break;		
			
		case CMD_RCL:
		case CMD_RCL_DIV:
		case CMD_RCL_MUL:
		case CMD_RCL_SUB:
		case CMD_RCL_ADD:

			switch (arg->type)
			{
				case ARGTYPE_STR:
					if (cmd == CMD_RCL_DIV)
						snprintf(str, DESC_SIZE, "RCL\022 \"%.*s\"", arg->length, arg->val.text);
					else
						snprintf(str, DESC_SIZE, "%s \"%.*s\"", cmdlist(cmd)->name,
								 arg->length, arg->val.text);
					break;
					
				case ARGTYPE_NUM:
					snprintf(str, DESC_SIZE, "%s '%d'",cmdlist(cmd)->name,	
							 arg->val.num);
					break;
				case ARGTYPE_STK:
					snprintf(str, DESC_SIZE, "%s ST %c",cmdlist(cmd)->name, 
							 arg->val.stk);
					break;
					
				default:
					snprintf(str, DESC_SIZE, "%s",cmdlist(cmd)->name);
					break;	
			}

			if (cmd == CMD_RCL_DIV) memcpy(str, "RCL\022", 4);
			record_undo(str);	
			
		break;	
			
				
		case CMD_RUN:
			record_undo("R/S");
		break;		
			
		case CMD_SST:
			
		break;
		
	    	case CMD_CONVERT:
		
			char buf[30];
			int sz = write_unit_string_to_buf(buf, 29, 0, arg->val.num);
			buf[sz] = NULL;  // null terminate
			record_undo(buf);
		break;			
	}
		
}
/* We use this method to bump an undo off the stack in the case a 
   command creates an error, such as divide by zero.

   Hmm, on further study, some functions return errors, but
   still modify the stack, and display no error.. in these cases
   we still would want to perserve the stack before the operation.
   It's beyond these changes at this point to do a case by case,
   so we only do it for divide for now... */
void record_undo_cleanup(int error)
{
	if (new_snapshot && error)
	{
		if (pending_command == CMD_DIV)
			remove_first_snapshot();
	}
	new_snapshot = FALSE;	
}

vartype* get_most_recent_x()
{
    if (snapshot_count == 0) return NULL;
    snapshot *snap = snapshot_head;
    return snap->stack_item_head->var;
}

void modify_most_recent_snapshot_message(char *buf, int length)
{
    if (snapshot_count == 0) return;
    snapshot *snap = snapshot_head;
    int ptr;
    string2buf(snap->describe, DESC_SIZE-1, &ptr, buf, length);
    snap->describe[DESC_SIZE-1]  = NULL;
}

