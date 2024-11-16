//
//  Wrapper.mm
//  Zedit-UIKit
//
//  Created by VR on 16/11/24.
//

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

#import "Wrapper.h"
#import "CVFunctions.hpp"

@implementation SceneRange
@end

@implementation CV
+ (NSString *)version {
    return [NSString stringWithUTF8String:CVFuncs::getVersion().c_str()];
}

+ (NSArray<SceneRange *> *)detectSceneChanges:(NSString *)videoPath {
    std::vector<CVFuncs::SceneRange> scenes;
    CVFuncs::detect_scene_changes(videoPath.UTF8String, scenes);
    
    NSMutableArray<SceneRange *> *result = [NSMutableArray array];
    for (const auto& scene : scenes) {
        SceneRange *range = [[SceneRange alloc] init];
        range.start = scene.start;
        range.end = scene.end;
        [result addObject:range];
    }
    
    return result;
}
@end
