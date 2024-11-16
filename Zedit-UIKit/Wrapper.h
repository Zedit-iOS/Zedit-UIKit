//
//  Wrapper.h
//  Zedit-UIKit
//
//  Created by VR on 16/11/24.
//

#ifndef Wrapper_h
#define Wrapper_h

#import <Foundation/Foundation.h>

@interface SceneRange : NSObject
@property(nonatomic) double start;
@property(nonatomic) double end;
@end

@interface CV : NSObject
+ (NSString *)version;
+ (NSArray<SceneRange *> *)detectSceneChanges:(NSString *)videoPath;
@end

#endif
