//
//  ViewController.m
//  audioReverse
//
//  Created by sx on 18/03/15.
//  Copyright (c) 2015 sx. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL *audioUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sample" ofType:@"m4a"]];
    AVURLAsset  *audioAsset = [[AVURLAsset alloc]initWithURL:audioUrl options:nil];
    
    [self reverse:audioAsset];
    
    NSLog(@"Output: %@", NSTemporaryDirectory());
}

- (void)reverse:(AVAsset *)asset
{
    AVAssetReader* reader = [[AVAssetReader alloc] initWithAsset:asset error:nil];
    
    AVAssetTrack* audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
    
    NSMutableDictionary* audioReadSettings = [NSMutableDictionary dictionary];
    [audioReadSettings setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM]
                         forKey:AVFormatIDKey];
    
    AVAssetReaderTrackOutput* readerOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTrack outputSettings:audioReadSettings];
    [reader addOutput:readerOutput];
    [reader startReading];
 
    NSDictionary *outputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                    [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                                    [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
                                    [NSNumber numberWithInt:128000], AVEncoderBitRateKey,
                                    [NSData data], AVChannelLayoutKey,
                                    nil];

    AVAssetWriterInput *writerInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio
                                                                     outputSettings:outputSettings];

    NSString *exportPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"out.m4a"];
    
    NSURL *exportURL = [NSURL fileURLWithPath:exportPath];
    NSError *writerError = nil;
    AVAssetWriter *writer = [[AVAssetWriter alloc] initWithURL:exportURL
                                                      fileType:AVFileTypeAppleM4A
                                                         error:&writerError];
    [writerInput setExpectsMediaDataInRealTime:NO];
    writer.shouldOptimizeForNetworkUse = NO;
    [writer addInput:writerInput];
    [writer startWriting];
    [writer startSessionAtSourceTime:kCMTimeZero];
    

    CMSampleBufferRef sample;// = [readerOutput copyNextSampleBuffer];
    NSMutableArray *samples = [[NSMutableArray alloc] init];
    int i = 0;
    while (sample != NULL) {
        sample = [readerOutput copyNextSampleBuffer];
        
        if (sample == NULL)
            continue;

        //size_t sampleSize =  CMSampleBufferGetSampleSize(sample, 0);
        //NSLog(@"%zu", sampleSize);
    
        [samples addObject:(__bridge id)(sample)];
 
        CFRelease(sample);
    }

    NSArray* reversedSamples = [[samples reverseObjectEnumerator] allObjects];

    for (id reversedSample in reversedSamples) {
        if (writerInput.readyForMoreMediaData)  {
            [writerInput appendSampleBuffer:(__bridge CMSampleBufferRef)(reversedSample)];
            //size_t sampleSize =  CMSampleBufferGetSampleSize((__bridge CMSampleBufferRef)(reversedSample), 0);
            //NSLog(@"** %zu", sampleSize);
        }
        else {
            [NSThread sleepForTimeInterval:0.05];
        }
    }
    
    [writerInput markAsFinished];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(queue, ^{
        [writer finishWriting];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
