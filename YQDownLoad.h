//
//  YQDownLoad.h
//  文件断点续传下载
//
//  Created by Cuiyongqin on 16/4/27.
//  Copyright © 2016年 Cuiyongqin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface YQDownLoad : NSObject
+ (instancetype)sharedDownLoad;
- (void)downLoadFileWithFilePath:(NSString *)filePath andURLString:(NSString *)urlString;
@end
