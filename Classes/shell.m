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
#import <CoreLocation/CoreLocation.h>
#import "shell.h"
#import "Settings.h"
#import "core_main.h"

double shell_random_seed()
{
	struct timeval tv;
    gettimeofday(&tv, NULL);
    return ((tv.tv_sec * 1000000L + tv.tv_usec) & 0xffffffffL) / 4294967296.0;	
}

//////////////////////////////////////////////////////////////////////
/////   Accelerometer, Location Services, and Compass support    /////
///// Be sure to keep this in sync between both iPhone versions! /////
//////////////////////////////////////////////////////////////////////

static double accel_x = 0, accel_y = 0, accel_z = 0;
static double loc_lat = 0, loc_lon = 0, loc_lat_lon_acc = 0, loc_elev = 0, loc_elev_acc = 0;
static double hdg_mag = 0, hdg_true = 0, hdg_acc = 0, hdg_x = 0, hdg_y = 0, hdg_z = 0;

@interface HardwareDelegate : NSObject <UIAccelerometerDelegate, CLLocationManagerDelegate> {}
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration;
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading;
- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager;
@end

@implementation HardwareDelegate

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	accel_x = acceleration.x;
	accel_y = acceleration.y;
	accel_z = acceleration.z;
	NSLog(@"Acceleration received: %g %g %g", accel_x, accel_y, accel_z);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	loc_lat = newLocation.coordinate.latitude;
	loc_lon = newLocation.coordinate.longitude;
	loc_lat_lon_acc = newLocation.horizontalAccuracy;
	loc_elev = newLocation.altitude;
	loc_elev_acc = newLocation.verticalAccuracy;
	NSLog(@"Location received: %g %g", loc_lat, loc_lon);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"Location error received: %@", [error localizedDescription]);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading {
	hdg_mag = newHeading.magneticHeading;
	hdg_true = newHeading.trueHeading;
	hdg_acc = newHeading.headingAccuracy;
	hdg_x = newHeading.x;
	hdg_y = newHeading.y;
	hdg_z = newHeading.z;
	NSLog(@"Heading received: %g", hdg_mag);
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
	return NO;
}

@end

static HardwareDelegate *hwDel = [HardwareDelegate alloc];
static CLLocationManager *locMgr = NULL;

int shell_get_acceleration(double *x, double *y, double *z) {
	static bool accelerometer_active = false;
	if (!accelerometer_active) {
		UIAccelerometer *am = [UIAccelerometer sharedAccelerometer];
		am.updateInterval = 1;
		am.delegate = hwDel;
		accelerometer_active = true;
	}
	*x = accel_x;
	*y = accel_y;
	*z = accel_z;
	return 1;
}

int shell_get_location(double *lat, double *lon, double *lat_lon_acc, double *elev, double *elev_acc) {
	static bool location_active = false;
	if (locMgr == NULL) {
		locMgr = [[CLLocationManager alloc] init];
		locMgr.delegate = hwDel;
	}
	if (!location_active) {
		locMgr.distanceFilter = kCLDistanceFilterNone;
		locMgr.desiredAccuracy = kCLLocationAccuracyBest;
		[locMgr startUpdatingLocation];
		location_active = true;
	}
	*lat = loc_lat;
	*lon = loc_lon;
	*lat_lon_acc = loc_lat_lon_acc;
	*elev = loc_elev;
	*elev_acc = loc_elev_acc;
	return 1;
}

int shell_get_heading(double *mag_heading, double *true_heading, double *acc, double *x, double *y, double *z) {
	static bool heading_active = false;
	if (locMgr == NULL) {
		locMgr = [[CLLocationManager alloc] init];
		locMgr.delegate = hwDel;
	}
	if (!CLLocationManager.headingAvailable)
		return 0;
	if (!heading_active) {
		locMgr.headingFilter = kCLHeadingFilterNone;
		[locMgr startUpdatingHeading];
		heading_active = true;
	}
	*mag_heading = hdg_mag;
	*true_heading = hdg_true;
	*acc = hdg_acc;
	*x = hdg_x;
	*y = hdg_y;
	*z = hdg_z;
	return 1;
}

//////////////////////////////////////////////////////////////////////
/////          Here endeth ye iPhone hardware support.           /////
//////////////////////////////////////////////////////////////////////

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

void shell_get_time_date(uint4 *time, uint4 *date, int *weekday) {
	struct timeval tv;
	gettimeofday(&tv, NULL);
	struct tm tms;
	localtime_r(&tv.tv_sec, &tms);
	if (time != NULL)
		*time = ((tms.tm_hour * 100 + tms.tm_min) * 100 + tms.tm_sec) * 100 + tv.tv_usec / 10000;
	if (date != NULL)
		*date = ((tms.tm_year + 1900) * 100 + tms.tm_mon + 1) * 100 + tms.tm_mday;
	if (weekday != NULL)
		*weekday = tms.tm_wday;
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
