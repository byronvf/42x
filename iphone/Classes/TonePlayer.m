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

#import "TonePlayer.h"

#import <math.h>


// Data structures, constancts and callback function
// In fact, everything that lives outside of the class

static const int kNumberBuffers = 1;


// Define the playback audio queue callback function
static void toneBufferCallback( void* userData, AudioQueueRef queue, AudioQueueBufferRef buffer)
{
	TonePlayer* self = (TonePlayer*)userData;
	AudioQueueFreeBuffer(queue, buffer);
	
	self.tonesPlayed += 1;
	if( self.tonesRequested == self.tonesPlayed)
	{
		self.tonesPlayed = self.tonesRequested = 0;
		AudioQueueStop(queue, NO);
	}
}

@implementation TonePlayer

@synthesize frequency;
@synthesize initialPhase;
@synthesize sampleRate;
@synthesize sampleCount;
@synthesize maxSampleCount;
@synthesize dataFormat;
@synthesize queue;
@synthesize dataBuffer;

@synthesize tonesRequested;
@synthesize tonesPlayed;

@synthesize omega;
@synthesize b1;
@synthesize y0;
@synthesize y1;
@synthesize y2;
@synthesize done;

@synthesize volumeMultiplier;
@synthesize soundTones;

-(id)init
{
	self = [super init];
	
	initialPhase = 0.0;
	sampleRate = 4100;		// Samples/second
	done = YES;
	
	pi = atan(1.0) * 4.0;	// Determine Pi as accurately as we need to
	
	// Set up the stream data
	dataFormat.mSampleRate = 4100.0;	// # sample frames per second
	dataFormat.mFormatID = kAudioFormatLinearPCM;
	dataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
	dataFormat.mBytesPerPacket = 2;		// 2 bytes per sample
	dataFormat.mFramesPerPacket = 1;	// Single channel
	dataFormat.mBytesPerFrame = 2;		// bytesPerFrame / FramesPerPacket
	dataFormat.mChannelsPerFrame = 1;	// Mono
	dataFormat.mBitsPerChannel = 16;	// 16 bit values
	
	// The following three lines make sure that the tones mix with the current
	// iPod music, and phone sound, and don't interrup it.
	AudioSessionInitialize (NULL,NULL,NULL,NULL);
	UInt32 sessionCategory = kAudioSessionCategory_AmbientSound;	
	AudioSessionSetProperty (kAudioSessionProperty_AudioCategory,
						 sizeof (sessionCategory),
					     &sessionCategory);

	// Start the audio process going
	AudioQueueNewOutput( &dataFormat, &toneBufferCallback, self,
						 CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0,
						 &queue);

	return self;
}

-(void)soundTone:(CGFloat)toneFrequency forDuration: (CGFloat)toneDuration
{
	if( !soundTones)
	{ return; }		// Sound is turned off
	
	self.tonesRequested += 1;
	
	self.frequency = toneFrequency;
	self.maxSampleCount = self.sampleRate * toneDuration;		// Samples/Second * seconds = total number of samples
	self.sampleCount = 0;
	
	// Calculate the various constants needed
	self.omega = self.frequency * 2.0 * pi /self. sampleRate;
	self.b1 = 2.0 * cos(self.omega);
	self.y1 = sin(self.initialPhase - self.omega);
	self.y2 = sin(self.initialPhase - 2.0 * self.omega);
	
	// Create the audio buffers
	AudioQueueAllocateBuffer( self.queue, self.maxSampleCount * 2, &dataBuffer);	// 2 bytes/sample
	
	// Generate the data for this packet
	for( self.sampleCount = 0; self.sampleCount < self.maxSampleCount; self.sampleCount += 1)
	{
		self.y0 = self.b1 * self.y1 - self.y2;
		((SInt16*)dataBuffer->mAudioData)[self.sampleCount] = self.y0 * volumeMultiplier;
		self.y2 = self.y1;
		self.y1 = self.y0;
	}
	
	// Return the buffer data
	self.dataBuffer->mAudioDataByteSize = self.sampleCount * 2;		// Number of bytes added to the buffer
	
	AudioQueueEnqueueBuffer( self.queue, self.dataBuffer, 0, NULL);
	
	// Start the playing process
	AudioQueueStart(self.queue, NULL);	// Start playing immediately
	
	// Playing the tone continues asynchronously
}


-(void)setSound:(BOOL)on withVolume:(CGFloat)volume
{
	self.soundTones = on;
	self.volumeMultiplier = volume;
}


@end
