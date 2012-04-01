//
//  units.h
//  42s
//
//  Created by Byron Foster on 2/8/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#ifndef _2s_units_h
#define _2s_units_h

#include "core_globals.h"

typedef struct unit_struct
{
    const char* label;
	const char* scaleStr;
    vartype* scale;
} unit;

typedef struct unit_type_struct
{
    const char* label;
    int num_units;
    unit *units; // Array of units
	//unit units[];	
} unit_type;

extern const int NUM_UNIT_TYPES;

extern int init_units();
extern int docmd_convert(arg_struct *arg);

//pulled from core_main.cc, we define it here so we don't have to modify
// core_main.h
extern bool parse_phloat(const char *p, int len, phloat *res);

extern unit *getUnitByOrder(int typeIndex, int unitIndex);
extern unit *getUnitByCode(int typeCode, int unitCode);
extern unit_type *getTypeByOrder(int typeCode);
extern unit_type *getTypeByCode(int typeCode);
int write_unit_string_to_buf(char* buf, int bufsz, int start, int convert);

extern int unit_menu_page;

#endif
