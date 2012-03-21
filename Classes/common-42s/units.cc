
/*
 This module provides the functionality for converting between units such as
 km to miles. We break it down to two concepts of type and unit, where the type is 
 something such as temperature or pressure, and a unit is a specific unit within
 those types.  The basic data structure that contains these values is unit_table which
 is an array of types with lists of units for each type.  Much of the code in 
 this module is dedicated to working with a 16 bit conversion word. with the following
 bit pattern:
 
 bits 0-4: type code
 bits 5-9: code of unit being converted from
 bits 10-14: code of unit being converted to
 
 This is also the value that is stored in programs for the conversion command.
*/

#include <stdio.h>
#include <string.h>
#include "units.h"
#include "core_variables.h"
#include "core_main.h"
#include "core_helpers.h"
#include "core_sto_rcl.h"

// Keeps track of the current unit page we are on, note that we don't persist
// which means that after a program restart the page will begin on 0.
int unit_menu_page = 0;

// Table of all the unit types and associated list of units
static unit_type unit_table[NUM_UNIT_TYPES];

// values we use for temperature conversions
static vartype *temp_273_15; // 273.15
static vartype *temp_5_9;    // 5/9
static vartype *temp_9_5;    // 9/5
static vartype *temp_32;     // 32

// Provide some simple parsing for reading the units text file including 
// some niceities like ignoring blank lines and comment lines
int skipline(const char* line)
{
    // Simple comment character
    if (line[0] == ';') return TRUE;
    
    for (int i=0; line[i] != 0; line++)
    {
        if (line[i] != ' ' && line[i] != '\t' && line[i] != '\n')
            return FALSE;
    }
    return TRUE;
}

// Sort of a hack for now, HP char set does not contain the '^' character
// so we replace it with the hp up arrow char... grrr
void conv_karat(char *str)
{
    for (char *c = str; *c != 0; c++)
    {
        if (*c == '^') *c = 0x5E;
    }
}


// The following four methods are used to retrieve Type and unit information
// either by type or unit codes, or by index (such as in the case of menu order).
// Note that currently both the unit and type codes are simply the index val +1.
// This may and probably will change if we need to change the unit order.

unit *getUnitByOrder(int typeIndex, int unitIndex)
{
    typeIndex &= 0x1F;
    unitIndex &= 0x1F;
    if (typeIndex >= NUM_UNIT_TYPES ||
	unitIndex >= unit_table[typeIndex].num_units) return NULL;
    return &unit_table[typeIndex].units[unitIndex];
}

unit *getUnitByCode(int typeCode, int unitCode)
{
    typeCode &= 0x1F;
    unitCode &= 0x1F;
    return getUnitByOrder(typeCode-1, unitCode-1);
}

unit_type *getTypeByOrder(int typeIndex)
{
    typeIndex &= 0x1F;
    if (typeIndex >= NUM_UNIT_TYPES) return NULL;
    return &unit_table[typeIndex];
}

unit_type *getTypeByCode(int typeCode)
{
    typeCode &= 0x1F;
    return getTypeByOrder(typeCode-1);
}

// Initializes units at program startup reading unit info from the units.txt text file.
int init_units()
{
    FILE *f;
    char line[100];
    
    // Read unit conversion files from text file
    
    // The call to NSHomeDirectory doesn't belong here, but I don't want to change
    // shell.cc at this point with a callback method to get the path to units.txt.
    const char* unitsfile =
      [[NSHomeDirectory() stringByAppendingString:@"/42s.app/units.txt"] UTF8String];
    if (!(f = fopen(unitsfile, "r"))) return 1;
    int tnum = 0;
    while (tnum < NUM_UNIT_TYPES)
    {
        fgets(line, 100, f);
        if (skipline(line)) continue;  // A comment character... skip
        
        unit_type *utype = &unit_table[tnum];
        memset(utype->label, 0, UNIT_LABEL_SIZE);
        // %9s = UNIT_LABEL_SIZE-1
        int res = sscanf(line, "%9s %d", utype->label, &utype->num_units);
        if (res != 2) return 1;
        utype->units = (unit*)malloc(sizeof(unit)*utype->num_units);
        int ucnt = 0;
        while (ucnt < utype->num_units)
        {
            fgets(line, 100, f);
            if (skipline(line)) continue;
            unit *u = &utype->units[ucnt];            
            char scale_str[50], offset_str[50];
            int res2 = 
                sscanf(line, "%9s %50s %s50s", u->label, scale_str, offset_str);
            if (res2 < 2 || res2 > 3) return 1;
            u->scale = new_real(0);
            if (!parse_phloat(scale_str, strlen(scale_str), &((vartype_real*)u->scale)->x))
                return 1;
            conv_karat(u->label);
            ucnt++;
        }
        tnum++;
    }
    // -------  Initialze values for temperature conversions -----------
    
    phloat tf;
    parse_phloat("273.15", 6, &tf);
    temp_273_15 = new_real(tf);
    tf = 9;
    tf = tf / 5;
    temp_9_5 = new_real(tf);
    tf = 1 / tf;
    temp_5_9 = new_real(tf);
    tf = 32;
    temp_32 = new_real(tf);
    
    //  -------   Initialize menus ----------------

    assert(NUM_UNIT_TYPES == 10);  // loops below fail if this is not true
    for (int i = 0; i < 6; i++)
    {
        menu_item_spec *mi = &menus[MENU_CONVERT1].child[i];
        int strsz = MIN(sizeof(menus[MENU_CONVERT1].child[0].title),
                        strlen(unit_table[i].label));
        strncpy(mi->title, unit_table[i].label, strsz);
        mi->title_length = strsz;
    }

    for (int i = 0; i < 4; i++)
    {
        menu_item_spec *mi = &menus[MENU_CONVERT4].child[i];
        int strsz = MIN(sizeof(menus[MENU_CONVERT4].child[0].title),
                        strlen(unit_table[i+6].label));        
        strncpy(mi->title, unit_table[i+6].label, strsz);
        mi->title_length = strsz;
    }
    
    
    return 0;
}

#define UNIT_TYPE_TEMP 10
#define UNIT_C 1
#define UNIT_F 2
#define UNIT_K 3


static int comp_err;
static vartype *comp_res;
static void completion(int error, vartype *res) {
    comp_err = error;
    comp_res = res;
}


int docmd_convert(arg_struct *arg)
{
    if (reg_x->type == TYPE_STRING) return ERR_ALPHA_DATA_IS_INVALID;

    int param = arg->val.num;
    int type = param&0x1F;
    int uf = (param >> 5)&0x1F;
    int ut = (param >> 10)&0x1F;
    
    if (type == UNIT_TYPE_TEMP) 
    {
	// Lots of work for the eseteric case of temp conversions, we skip
	// allot of error handing here, but I'm lazy, and what could wrong...
	
	vartype *res = NULL;
	if (uf == UNIT_C) 
	{
	    if (ut == UNIT_K)
	    {
		generic_add(reg_x, temp_273_15, &res);				
	    }
	    else // UNIT_F
	    {
		generic_mul(reg_x, temp_9_5, completion);
		generic_add(comp_res, temp_32, &res);
		free_vartype(comp_res);
	    }
	}
	else if (uf == UNIT_F)
	{
	    if (ut == UNIT_C)
	    {
		generic_sub(temp_32, reg_x, &res);
		generic_mul(res, temp_5_9, completion);
		free_vartype(res);
		res = comp_res;
	    }
	    else // UNIT_K
	    {
		generic_sub(temp_32, reg_x, &res);
		generic_mul(res, temp_5_9, completion);
		free_vartype(res);
		generic_add(comp_res, temp_273_15, &res);
		free_vartype(comp_res);
	    }
	}
	else // UNIT_K
	{
	    if (ut == UNIT_C)
	    {
		generic_sub(temp_273_15, reg_x, &res);
	    }
	    else // UNIT_F
	    {
		generic_sub(temp_273_15, reg_x, &res);
		generic_mul(res, temp_9_5, completion);
		free_vartype(res);
		generic_add(comp_res, temp_32, &res);
		free_vartype(comp_res);
	    }
	}
	
	free_vartype(reg_x);
	reg_x = res;
	return ERR_NONE;
    }
    
    unit *ufrom = getUnitByCode(type, uf);
    unit *uto = getUnitByCode(type, ut);
    phloat *from = &((vartype_real*)ufrom->scale)->x;
    phloat *to = &((vartype_real*)uto->scale)->x;        
    vartype *scale = new_real(*from / *to);
        
    generic_mul(reg_x, scale, completion);
    free_vartype(scale);
    if (comp_err != ERR_NONE) return comp_err;
    free_vartype(reg_x);
    reg_x = comp_res;
    
    return ERR_NONE;
}

// Create a string representing the unit conversion passed in convert
int write_unit_string_to_buf(char* buf, int bufsz, int start, int convert)
{
    int bufptr = start;
    if (convert&0x3E0)
    {
	unit *u = getUnitByCode(convert, convert >> 5);
	string2buf(buf, bufsz, &bufptr, u->label, strlen(u->label));
	string2buf(buf, bufsz, &bufptr, " \x0F ", 3);
	if (convert&0x7C00)
	{
	    u = getUnitByCode(convert, convert >> 10);
	    string2buf(buf, bufsz, &bufptr, u->label, strlen(u->label));
	}
    }
    return bufptr;
}

