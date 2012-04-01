
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
//static unit_type unit_table[NUM_UNIT_TYPES];

// values we use for temperature conversions
static vartype *temp_273_15; // 273.15
static vartype *temp_5_9;    // 5/9
static vartype *temp_9_5;    // 9/5
static vartype *temp_32;     // 32

static unit length_units[] =
{
	{"m",       "1.0", NULL},
	{"km",      "1e3", NULL},
	{"cm",      "1e-2", NULL},
	{"ft",      "3.048e-1", NULL},
	{"in",      "2.54e-2", NULL},
	{"mile",    "1.609344e3", NULL},
	{"lyear",   "9.46073e15", NULL},
	{"ua",      "1.495979e11", NULL},
	{"fathm",   "1.828804", NULL},
	{"Angst",   "1.0e-10", NULL},
	{"mm",      "1e-3", NULL},
	{"micrn",   "1e-6", NULL},
	{"yard",    "9.144e-1", NULL},
	{"parsc",   "3.085678e16", NULL},
};

static unit area_units[] = 
{
	{"m^2",     "1.0", NULL},
	{"ft^2",    "9.290304e-2", NULL},
	{"in^2",	"6.4516-4", NULL},
	{"mil^2",   "2.589988e6", NULL},
	{"acre",    "4.046873e3", NULL},
	{"Hectr",   "1e4", NULL},
	{"yrd^2",   "8.361274e-1", NULL},
	{"cm^2",    "1e-4", NULL},
};

static unit volume_units[] =
{
	{"liter",  "1.0", NULL},
	{"ft^3",   "2.831685e1", NULL},
	{"USgal",  "3.785412", NULL},
	{"UKgal",  "4.54609", NULL},
	{"mL",     "1e-3", NULL},
	{"USfoz",  "2.957353e-2", NULL},
	{"UKfoz",  "2.841306e-2", NULL},
	{"pint",   "4.731765e-1", NULL},
	{"quart",  "9.463529e-1", NULL},
	{"cord",   "3.624556e3", NULL},
	{"cup",    "2.365882e-1", NULL},
	{"tabsp",  "1.478676e-2", NULL},
	{"teasp",  "4.928922e-3", NULL},
	{"cc",     "1e-3", NULL},
};

static unit speed_units[] =
{
	{"m/sec",  "1.0", NULL},
	{"km/h",   "2.777778e-1", NULL},
	{"mil/h",  "4.4704e-1", NULL},
	{"ft/s",   "3.048e-1", NULL},
	{"mil/s",  "1.609344e3", NULL},
	{"knot",   "5.144444e-1", NULL},
};

static unit mass_units[] =
{
	{"kg",     "1.0", NULL},
	{"pound",  "4.5359237e-1", NULL},
	{"g",      "1e-3", NULL},
	{"ounce",  "2.834952e-2", NULL},
	{"TRYoz",  "3.110348e-2", NULL},
	{"carat",  "2e-4", NULL},
	{"UKton",  "1.016047e3", NULL},
	{"USton",  "9.071847e2", NULL},
	{"grain",  "6.479891e-5", NULL},
	{"slug",   "1.459390e1", NULL},
};

static unit force_units[] =
{
	{"N",      "1.0", NULL},
	{"lbf",    "4.4482216152605", NULL},
};

static unit energy_units[] =
{
	{"Joule",  "1.0", NULL},
	{"cal",    "4.1868", NULL},
	{"kcal",   "4.1868e3", NULL},
	{"Btu",    "1.05505585262e3", NULL},
	{"eV",     "1.602177e-19", NULL},
	{"kWh",    "3.6e6", NULL},
	{"ftLbf",  "1.355818", NULL},
	{"erg",    "1e-7", NULL},
};

static unit power_units[] =
{
	{"watt",   "1.0", NULL},
	{"hp",     "7.456999e2", NULL},
	{"bhp",    "9.80950e3", NULL},
	{"erg/s",  "1.0e-7", NULL},
	{"Btu/m",  "1.7584264e1", NULL},
	{"ftb/s",  "2.259697e-2", NULL},
	{"ftb/m",  "2.259697E-2", NULL},
	{"ftb/h",  "3.766161e-4", NULL},
};

static unit pressure_units[] =
{
	{"Pa",     "1.0", NULL},
	{"atm",    "1.01325e5", NULL},
	{"kPa",    "1e3", NULL},
	{"psi",    "6.894757e3", NULL},
	{"bar",    "1e5", NULL},
	{"mbar",   "1e2", NULL},
	{"mmHg",   "1.333224e2", NULL},
	{"cmH2O",  "9.80665e1", NULL},
	{"inHg",   "3.386389e3", NULL},
};

static unit temperature_units[] =
{
	{"C",      "1.0", NULL},
	{"F",      "1.8", NULL},
	{"K",      "1.0", NULL},
};

static unit time_units[] =
{
	{"msec",    "1.0", NULL},
	{"sec",     "1e3", NULL},
	{"min",     "6e4", NULL},
	{"hour",    "3.6e6", NULL},
	{"day",     "8.64e7", NULL},
	{"year",    "3.1536e10", NULL},
	{"s.sid",   "9.972696e2", NULL},	
	{"m.sid",   "5.983617e4", NULL},	
	{"d.sid",   "8.616409e7", NULL},	
	{"y.sid",   "3.155815e10", NULL},	
	{"shake",   "1e-5", NULL},
	{"\x11sec", "1e-3", NULL},
};


static unit_type unit_table[] =
{
	{"LNGTH", sizeof(length_units)/sizeof(unit), length_units},
	{"AREA", sizeof(area_units)/sizeof(unit), area_units},
	{"VOL", sizeof(volume_units)/sizeof(unit), volume_units},
	{"SPEED", sizeof(speed_units)/sizeof(unit), speed_units},
	{"MASS", sizeof(mass_units)/sizeof(unit), mass_units},
	{"FORCE", sizeof(force_units)/sizeof(unit), force_units},
	{"ENRGY", sizeof(energy_units)/sizeof(unit), energy_units},
	{"POWER", sizeof(power_units)/sizeof(unit), power_units},
	{"PRESS", sizeof(pressure_units)/sizeof(unit), pressure_units},
	{"TEMP", sizeof(temperature_units)/sizeof(unit), temperature_units},
	{"TIME", sizeof(time_units)/sizeof(unit), time_units},
};

const int NUM_UNIT_TYPES = sizeof(unit_table)/sizeof(unit_type);

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

void lazyInitUnit(unit* u)
{
	if (u->scale == NULL)
	{
		u->scale = new_real(0);
		if (!parse_phloat(u->scaleStr, strlen(u->scaleStr), 
						  &((vartype_real*)u->scale)->x))
		{
			// A string could not be converted to a BCD number, which means
			// we screwed up the string... Too late to handle it, we are screwed
			assert(FALSE);
			exit(1);
		}
	}
}

// Initializes units at program startup reading unit info from the units.txt text file.
int init_units()
{
    
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

    assert(NUM_UNIT_TYPES >= 6);  
    for (int i = 0; i < 6; i++)
    {
        menu_item_spec *mi = &menus[MENU_CONVERT1].child[i];
        int strsz = MIN(sizeof(menus[MENU_CONVERT1].child[0].title),
                        strlen(unit_table[i].label));
        strncpy(mi->title, unit_table[i].label, strsz);
        mi->title_length = strsz;
    }

    assert(NUM_UNIT_TYPES <= 12);
    for (int i = 0; i < NUM_UNIT_TYPES-6; i++)
    {
        menu_item_spec *mi = &menus[MENU_CONVERT2].child[i];
        int strsz = MIN(sizeof(menus[MENU_CONVERT2].child[0].title),
                        strlen(unit_table[i+6].label));        
        strncpy(mi->title, unit_table[i+6].label, strsz);
        mi->title_length = strsz;
    } 
	
	
#ifdef DEBUG
	// Scale strings are lazily converted to phloat values as we perform the specific
	// conversion.  In debug we make sure all conversion can be made, so we don't 
	// have any surprises at runtime.  We then revert the units table back to the way it was.
	for (int i=0; i<NUM_UNIT_TYPES; i++)
	{
		for (int j=0; j<unit_table[i].num_units; j++)
		{
			// fails fast with exit(1) if scaleStr cannot be converted to a phloat
			lazyInitUnit(&unit_table[i].units[j]);
		}			
	}

	for (int i=0; i<NUM_UNIT_TYPES; i++)
	{
		for (int j=0; j<unit_table[i].num_units; j++)
		{
			free_vartype(unit_table[i].units[j].scale);	
			unit_table[i].units[j].scale = NULL;
		}			
	}
#endif    
	
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
    int uf = (param >> 5)&0x1F;  // unit from
    int ut = (param >> 10)&0x1F; // unit to
    
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
	lazyInitUnit(ufrom);
    unit *uto = getUnitByCode(type, ut);
	lazyInitUnit(uto);
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

