// Copyright Base2 Corporation 2009
//
// This file is part of 42s.
//
// 42s is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// 42s is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with 42s.  If not, see <http://www.gnu.org/licenses/>.

#import <time.h>
#import <sys/time.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#import <AudioToolbox/AudioServices.h>
#import "shell.h"
#import "Settings.h"
#import "core_main.h"

double shell_random_seed()
{
	struct timeval tv;
    gettimeofday(&tv, NULL);
    return ((tv.tv_sec * 1000000L + tv.tv_usec) & 0xffffffffL) / 4294967296.0;	
}


/**
 * We could tell if the system reports a low battery, and show the
 * Free42 low bat aunnuciator.. but I think the standard iPhone indicator
 * is enough.
 */
int shell_low_battery()
{
	return 0;
}

uint4 shell_milliseconds()
{
	struct timeval tv;
    gettimeofday(&tv, NULL);
    return (uint4) (tv.tv_sec * 1000L + tv.tv_usec / 1000);
}	


void shell_delay(int duration)
{   
    struct timespec ts;
    ts.tv_sec = duration / 1000;
    ts.tv_nsec = (duration % 1000) * 1000000;
    nanosleep(&ts, NULL);
}


uint4 shell_get_mem()
{
	int mib[2];
	uint4 memsize;
	size_t len;

	// Retrieve the available system memory
	
	mib[0] = CTL_HW;
	mib[1] = HW_USERMEM;
	len = sizeof(memsize);
	sysctl(mib, 2, &memsize, &len, NULL, 0);
		
	return memsize;
}


#ifndef BCD_MATH
shell_bcd_table_struct *shell_get_bcd_table() SHELL1_SECT {return NULL;}
shell_bcd_table_struct *shell_put_bcd_table(shell_bcd_table_struct *bcdtab,
											uint4 size) SHELL1_SECT {return bcdtab;}
void shell_release_bcd_table(shell_bcd_table_struct *bcdtab) SHELL1_SECT {free(bcdtab);}
#endif 
