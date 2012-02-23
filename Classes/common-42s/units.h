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

const int UNIT_LABEL_SIZE = 10;
typedef struct unit_struct
{
    int num;
    char label[UNIT_LABEL_SIZE];
    vartype* scale;
} unit;

const int UNIT_TYPE_LABEL_SIZE = 10;
typedef struct unit_type_struct
{
    char label[UNIT_TYPE_LABEL_SIZE];
    int num_units;
    unit *units; // Array of units
} unit_type;

const int NUM_UNIT_TYPES = 10;

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
