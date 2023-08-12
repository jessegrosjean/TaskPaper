//
//  getFileDescriptorPath.m
//  Birch
//
//  Created by Jesse Grosjean on 9/6/16.
//
//

#import "getFileDescriptorPath.h"

NSString* __nullable  getFileDescriptorPath(int fd) {
    char filePath[PATH_MAX];
    if (fcntl(fd, F_GETPATH, filePath) != -1)
    {
        return [NSString stringWithCString:filePath encoding:NSUTF8StringEncoding];
    }
    return nil;
}