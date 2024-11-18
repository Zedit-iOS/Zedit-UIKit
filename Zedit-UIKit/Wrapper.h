//
//  Wrapper.h
//  Zedit-UIKit
//
//  Created by VR on 16/11/24.
//

#ifndef Wrapper_h
#define Wrapper_h

#import <Foundation/Foundation.h>

@interface ProcessingError : NSObject
@property(nonatomic, assign) BOOL hasError;
@property(nonatomic, copy) NSString *message;
@end

@interface SceneRange : NSObject
@property(nonatomic, assign) double start;
@property(nonatomic, assign) double end;
@end

@interface CV : NSObject
+ (ProcessingError *)detectSceneChanges:(NSString *)videoPath scenes:(NSMutableArray<SceneRange *> *)scenes minDuration:(double)minDuration;
+ (NSString *)debugPath:(NSString *)path;
+ (BOOL)validateVideo:(NSString *)path error:(NSString **)errorMessage;
@end

#endif /* Wrapper_h */