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

#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>


@interface TonePlayer : NSObject {
	CGFloat frequency;			// In Hertz
	CGFloat initialPhase;		// 0 to 2Pi radians
	CGFloat volumeMultiplier;
	BOOL soundTones;
	long sampleRate;			// Number of samples per second
	long sampleCount;			// Sample number ( 0 = first sample)
	long maxSampleCount;		// Total number of samples to produce
	
	// Internal values needed form one call to the next
	CGFloat omega;				// 2*Pi * frequency / sampleRate
	CGFloat b1;					// 2.0 * cos(omega)
	CGFloat y0;					// Last calculated value
	CGFloat y1;					// intermediate calculation value
	CGFloat y2;					// intermediate calculation value
	BOOL done;
	
	AudioStreamBasicDescription dataFormat;
	AudioQueueRef queue;
	AudioQueueBufferRef dataBuffer;
	
	int tonesRequested;
	int tonesPlayed;
	
	CGFloat pi;					// The famous constant
}
-(void)soundTone:(CGFloat)toneFrequency forDuration: (CGFloat)toneDuration;
-(void)setSound:(BOOL)on withVolume:(CGFloat)volume;

@property (readwrite) CGFloat frequency;
@property (readwrite) CGFloat initialPhase;
@property (readwrite) long sampleRate;
@property (readwrite) long sampleCount;
@property (readwrite) long maxSampleCount;

@property (readwrite) AudioStreamBasicDescription dataFormat;
@property (readwrite) AudioQueueRef queue;
@property (readwrite) AudioQueueBufferRef dataBuffer;

@property (readwrite) int tonesRequested;
@property (readwrite) int tonesPlayed;

@property (readwrite) CGFloat omega;
@property (readwrite) CGFloat b1;
@property (readwrite) CGFloat y0;
@property (readwrite) CGFloat y1;
@property (readwrite) CGFloat y2;
@property (readwrite) BOOL done;

@property (readwrite) CGFloat volumeMultiplier;
@property (readwrite) BOOL soundTones;


@end

