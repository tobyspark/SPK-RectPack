//
//  SPK_RectPackPlugIn.m
//  SPK-RectPack
//
//  Created by Toby Harris on 10/11/2013.
//  Copyright (c) 2013 *spark live. All rights reserved.
//

// It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering
#import <OpenGL/CGLMacro.h>

#import "SPK_RectPackPlugIn.h"
#import "MaxRectsBinPack.h"

#define	kQCPlugIn_Name				@"SPK-RectPack"
#define	kQCPlugIn_Description		@"SPK-RectPack description"

@implementation SPK_RectPackPlugIn

// Here you need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation
//@dynamic inputFoo, outputBar;

+ (NSDictionary *)attributes
{
	// Return a dictionary of attributes describing the plug-in (QCPlugInAttributeNameKey, QCPlugInAttributeDescriptionKey...).
    return @{QCPlugInAttributeNameKey:kQCPlugIn_Name, QCPlugInAttributeDescriptionKey:kQCPlugIn_Description};
}

+ (NSDictionary *)attributesForPropertyPortWithKey:(NSString *)key
{
	// Specify the optional attributes for property based ports (QCPortAttributeNameKey, QCPortAttributeDefaultValueKey...).

    if ([key isEqual:@"inputWidth"])            return @{ QCPortAttributeNameKey : @"Pixel Width" };
    if ([key isEqual:@"inputHeight"])           return @{ QCPortAttributeNameKey : @"Pixel Height" };
    if ([key isEqual:@"inputRects"])            return @{ QCPortAttributeNameKey : @"Rects Structure" };
    if ([key isEqual:@"inputPackHeuristic"])    return @{ QCPortAttributeNameKey : @"Packing Fit",
                                                          QCPortAttributeMaximumValueKey : @4,
                                                          QCPortAttributeMenuItemsKey : @[@"Best short side fit", @"Best long side fit", @"Best area fit", @"Bottom left rule", @"Contact point rule"]};
    if ([key isEqual:@"inputPackCanRotate"])    return @{ QCPortAttributeNameKey : @"Packing Rotate" };
    if ([key isEqual:@"outputRects"])           return @{ QCPortAttributeNameKey : @"Rects Structure" };
    
	return nil;
}

+ (QCPlugInExecutionMode)executionMode
{
	// Return the execution mode of the plug-in: kQCPlugInExecutionModeProvider, kQCPlugInExecutionModeProcessor, or kQCPlugInExecutionModeConsumer.
	return kQCPlugInExecutionModeProcessor;
}

+ (QCPlugInTimeMode)timeMode
{
	// Return the time dependency mode of the plug-in: kQCPlugInTimeModeNone, kQCPlugInTimeModeIdle or kQCPlugInTimeModeTimeBase.
	return kQCPlugInTimeModeNone;
}

- (id)init
{
	self = [super init];
	if (self) {
		// Allocate any permanent resource required by the plug-in.
	}
	
	return self;
}


@end

@implementation SPK_RectPackPlugIn (Execution)

- (BOOL)startExecution:(id <QCPlugInContext>)context
{
	// Called by Quartz Composer when rendering of the composition starts: perform any required setup for the plug-in.
	// Return NO in case of fatal failure (this will prevent rendering of the composition to start).
	
	return YES;
}

- (void)enableExecution:(id <QCPlugInContext>)context
{
	// Called by Quartz Composer when the plug-in instance starts being used by Quartz Composer.
}

- (BOOL)execute:(id <QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary *)arguments
{
	/*
	Called by Quartz Composer whenever the plug-in instance needs to execute.
	Only read from the plug-in inputs and produce a result (by writing to the plug-in outputs or rendering to the destination OpenGL context) within that method and nowhere else.
	Return NO in case of failure during the execution (this will prevent rendering of the current frame to complete).
	
	The OpenGL context for rendering can be accessed and defined for CGL macros using:
	CGLContextObj cgl_ctx = [context CGLContextObj];
	*/
	
    int width = [[self valueForInputKey:@"inputWidth"] intValue];
    int height = [[self valueForInputKey:@"inputHeight"] intValue];

    NSMutableDictionary* rectStruct = [[self valueForInputKey:@"inputRects"] mutableCopy];

    rbp::MaxRectsBinPack::FreeRectChoiceHeuristic fit = rbp::MaxRectsBinPack::RectBestShortSideFit;
    switch ([[self valueForInputKey:@"inputPackHeuristic"] intValue]) {
        case 0: fit = rbp::MaxRectsBinPack::RectBestShortSideFit; break;
        case 1: fit = rbp::MaxRectsBinPack::RectBestLongSideFit; break;
        case 2: fit = rbp::MaxRectsBinPack::RectBestAreaFit; break;
        case 3: fit = rbp::MaxRectsBinPack::RectBottomLeftRule; break;
        case 4: fit = rbp::MaxRectsBinPack::RectContactPointRule; break;
    }
    
    bool canRotate = [[self valueForInputKey:@"inputPackCanRotate"] boolValue];
    
    rbp::MaxRectsBinPack pack(width, height, canRotate);
    
    NSArray* keys = [rectStruct allKeys];
    for (NSString* key in keys)
    {
        NSMutableDictionary* rectDict = [[rectStruct objectForKey:key] mutableCopy];
        
        rbp::Rect rectOut = pack.Insert([rectDict[@"width"] intValue], [rectDict[@"height"] intValue], rbp::MaxRectsBinPack::RectBestShortSideFit);
        
        rectDict[@"x"] = @(rectOut.x);
        rectDict[@"y"] = @(rectOut.y);
        
        BOOL rotated = [[rectDict objectForKey:@"width"] intValue] != rectOut.width;
        
        if (rotated)
        {
            rectDict[@"width"] = @(rectOut.width);
            rectDict[@"height"] = @(rectOut.height);
            rectDict[@"rotated"] = @YES;
        }
        
        [rectStruct setObject:rectDict forKey:key];
    }
    
    [self setValue:rectStruct forOutputKey:@"outputRects"];
    
	return YES;
}

- (void)disableExecution:(id <QCPlugInContext>)context
{
	// Called by Quartz Composer when the plug-in instance stops being used by Quartz Composer.
}

- (void)stopExecution:(id <QCPlugInContext>)context
{
	// Called by Quartz Composer when rendering of the composition stops: perform any required cleanup for the plug-in.
}

@end
