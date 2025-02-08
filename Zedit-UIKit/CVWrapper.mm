//
//  CVWrapper.mm
//  Zedit-UIKit
//
//  Created by VR on 02/01/25.
//

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

#import "CVWrapper.h"
#import "CVFuntions.hpp"
#import <AVFoundation/AVFoundation.h>

@implementation ProcessingError
@synthesize hasError;
@synthesize message;
@end

@implementation SceneRange
@synthesize start;
@synthesize end;
@end

@implementation CV

+ (NSString *)debugPath:(NSString *)path {
    NSLog(@"Raw path: %@", path);
    NSString *trimmed = [path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *encoded = [trimmed stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    NSLog(@"Encoded path: %@", encoded);
    return encoded;
}
+ (BOOL)validateVideo:(NSString *)path error:(NSString **)errorMessage {
    // Use original path directly
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:path]) {
        *errorMessage = @"File does not exist";
        return NO;
    }
    
    NSURL *url = [NSURL fileURLWithPath:path];
    AVAsset *asset = [AVAsset assetWithURL:url];
    if (![asset isPlayable]) {
        *errorMessage = @"File is not a valid video";
        return NO;
    }
    
    return YES;
}

+ (ProcessingError *)detectSceneChanges:(NSString *)videoPath scenes:(NSMutableArray<SceneRange *> *)scenes minDuration:(double)minDuration {
    ProcessingError *error = [[ProcessingError alloc] init];
    NSString *errorMessage = nil;
    
    // Use path directly without encoding
    if (![self validateVideo:videoPath error:&errorMessage]) {
        error.hasError = YES;
        error.message = errorMessage;
        return error;
    }
    
    std::string cppPath([videoPath UTF8String]);
    std::vector<CVFuncs::SceneRange> cppScenes;
    
    auto cppError = CVFuncs::detect_scene_changes(cppPath, cppScenes, minDuration);
    error.hasError = cppError.hasError;
    error.message = @(cppError.message.c_str());
    
    if (!error.hasError) {
        for (const auto& scene : cppScenes) {
            SceneRange *range = [[SceneRange alloc] init];
            range.start = scene.start;
            range.end = scene.end;
            [scenes addObject:range];
            NSLog(@"Added scene: start=%d, end=%d", (int)scene.start, (int)scene.end);
        }
    }
    
    return error;
}

@end
