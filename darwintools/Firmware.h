// Thanks to @absidue#9322 and Zebra Team for the Objective-C rewrite of firmware.sh

#import <Foundation/Foundation.h>
#import "DeviceInfo.h"

#import <stdlib.h>
#import <stdio.h>

#import <spawn.h>

#ifndef MAINTAINER
#define MAINTAINER @"Steve Jobs <steve@apple.com>"
#endif

@interface Firmware : NSObject

- (void)exitWithError:(NSError *)error andMessage:(NSString *)message;
- (void)loadInstalledPackages;
- (void)generatePackage:(NSString *)package forVersion:(NSString *)version withDescription:(NSString *)description;
- (void)generatePackage:(NSString *)package forVersion:(NSString *)version withDescription:(NSString *)description andName:(NSString *)name;
- (void)generateCapabilityPackages;
- (void)writePackagesToStatusFile;
- (void)setupUserSymbolicLink;

@end
