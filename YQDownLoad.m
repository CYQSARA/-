//
//  YQDownLoad.m
//  文件断点续传下载
//
//  Created by Cuiyongqin on 16/4/27.
//  Copyright © 2016年 Cuiyongqin. All rights reserved.
//

#import "YQDownLoad.h"

@interface YQDownLoad ()<NSURLConnectionDataDelegate>

@property(nonatomic,copy)NSString  *filePath;
@property(nonatomic,assign)long long localFileLength;
@property(nonatomic,assign)long long serverFileLength;
@property(nonatomic,strong)NSOutputStream  *stream;


@end
@implementation YQDownLoad
static id _instance;
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

+ (instancetype)sharedDownLoad {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc]init];
    });
    return _instance;
}

- (id)copyWithZone :(NSZone *)zone {
    return _instance;
}

- (void)downLoadFileWithFilePath:(NSString *)filePath andURLString:(NSString *)urlString {
    self.filePath = filePath;
    //获取本地文件大小
    [self getLocalFileLengthWithFilePath:filePath andURLString:urlString];
    
    //获取服务器文件大小
    [self getServerFileLengthWithURLString:urlString];
    
    //文件下载
    if (self.localFileLength>self.serverFileLength) {
        //删除文件，重新下载
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
        [self downLoadFileWithURLString:urlString];
        
    }else if (self.localFileLength==self.serverFileLength){
        //下载完毕，直接展示
        //测试
        //  NSLog(@"下载完毕");
        
    }else if (self.localFileLength!=0){
        //断点续传
        [self downLoadFileWithLastFileLength:self.localFileLength andWithURLString:urlString];
    }

}

- (void)downLoadFileWithLastFileLength:(long long)lastFileLength andWithURLString:(NSString *)urlString {
    
    //  NSLog(@"断点续传");
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
     
        NSURL *url = [NSURL URLWithString:urlString];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        
        NSString *range  = [NSString stringWithFormat:@"bytes=%zd-",lastFileLength];
        
        [request setValue:range forHTTPHeaderField:@"Range"];
        
        NSURLConnection *con = [[NSURLConnection alloc]initWithRequest:request delegate:self];
        
        [con setDelegateQueue:[[NSOperationQueue alloc]init]];
        
        [con start];
        
        [[NSRunLoop currentRunLoop] run];
    });
    
}

//获取本地文件大小
- (void)getLocalFileLengthWithFilePath:(NSString *)filePath andURLString:(NSString *)urlString{
    
    // NSLog(@"获取本地文件大小");
    
    BOOL is_exisits = [[NSFileManager defaultManager] fileExistsAtPath:filePath];
    
    //MARK:- 判断本地文件是否存在，如果存在，获取本地文件大小
    if (is_exisits) {
        
        NSDictionary *dict = [[NSFileManager defaultManager] attributesOfItemAtPath:self.filePath error:NULL];
        
        self.localFileLength = [dict[NSFileSize] longLongValue];
        
    }else {
        //如果本地文件不存在，则大小为0，并下载
        self.localFileLength = 0;
        [self downLoadFileWithURLString:urlString];
    }
    
}

//获取服务器文件大小
- (void)getServerFileLengthWithURLString:(NSString *)urlString {
    
    // NSLog(@"获取服务器文件大小");
    
 
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"HEAD";
    
    NSURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:NULL];
    self.serverFileLength = response.expectedContentLength;
}

- (void)downLoadFileWithURLString:(NSString *)urlString {
    
    //  NSLog(@"文件下载");
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
    
        NSURL *url = [NSURL URLWithString:urlString];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSURLConnection *con = [[NSURLConnection alloc]initWithRequest:request delegate:self];
        [con setDelegateQueue:[[NSOperationQueue alloc]init]];
        
        [con start];
        
        [[NSRunLoop currentRunLoop] run];
        
    });
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    self.stream = [[NSOutputStream alloc]initToFileAtPath:self.filePath append:YES];
    
    [self.stream open];
    
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    static long long length =0;
    
    length += data.length;
    
    [self.stream write:data.bytes maxLength:data.length];
    
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self.stream close];
}


@end


























