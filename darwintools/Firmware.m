// Thanks to @absidue#9322 and Zebra Team for the Objective-C rewrite of firmware.sh

#import "Firmware.h"

@implementation Firmware {
    NSString *_adminDirectory;
    NSMutableString *_status;
    DeviceInfo *_deviceInfo;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self->_status = [[NSMutableString alloc] init];
        self->_deviceInfo = [DeviceInfo sharedDevice];
        self->_adminDirectory = [self->_deviceInfo getDPKGAdminDirectory];
    }
    return self;
}

- (void)exitWithError:(NSError *)error andMessage:(NSString *)message {
    NSLog(@"%@", message);
    if (error) {
        NSLog(@"Error: %@", error);
    }
    exit(1);
}

- (void)loadInstalledPackages {

    // regex

    NSString *virtualFirmwarePattern = @"^Package: (firmware|gsc[.].+|cy[+].+)\n$";

    NSError *error;
    NSRegularExpression *virtualFirmwareRegex = [NSRegularExpression regularExpressionWithPattern:virtualFirmwarePattern options:0 error:&error];

    if (!virtualFirmwareRegex) {
        [self exitWithError:error andMessage:[NSString stringWithFormat:@"Error parsing regex: '%@'", virtualFirmwarePattern]];
    }

    // control variables

    BOOL virtualFirmwarePackage = NO;
    BOOL previousWasBlank = YES;

    // file reading

    const char *statusFilePath = [[self->_adminDirectory stringByAppendingString:@"/status"] UTF8String];
    FILE *statusFile;
    char *cLine = NULL;
    size_t len = 0;
    ssize_t read;

    DEBUGLOG("Check status file path: %s", statusFilePath);
    statusFile = fopen(statusFilePath, "r");
    if (statusFile == NULL) {
        [self exitWithError:nil andMessage:[NSString stringWithFormat:@"Error opening statusfile for reading at: %s", statusFilePath]];
    }

    while ((read = getline(&cLine, &len, statusFile)) != -1) {
        if (strcmp("\n", cLine) == 0) {
            previousWasBlank = YES;

            if (virtualFirmwarePackage) {
                DEBUGLOG("Virtual firmware package present.");
                virtualFirmwarePackage = NO;
            } else {
                DEBUGLOG("Appending newline to status file.");
                [self->_status appendString:[NSString stringWithCString:cLine encoding:NSUTF8StringEncoding]];
            }

            continue;
        }

        if (virtualFirmwarePackage) {
            continue;
        }

        NSString *line = [NSString stringWithCString:cLine encoding:NSUTF8StringEncoding];

        if (previousWasBlank) {
            previousWasBlank = NO;

            if (line.length == [virtualFirmwareRegex rangeOfFirstMatchInString:line options:0 range:NSMakeRange(0, line.length)].length) {
                virtualFirmwarePackage = YES;
                continue;
            }
        }

        DEBUGLOG("Appending newline to status file.");
        [self->_status appendString:line];
    }
}

- (void)generatePackageListFile:(NSString *)package {
    static NSString *packageList;
    static NSString *pathFormat;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        packageList = @"/.\n";
        pathFormat = @"%@/info/%@.list";
    });

    NSString *packageListFile = [NSString stringWithFormat:pathFormat, self->_adminDirectory, package];

    NSError *error;
    if (![packageList writeToFile:packageListFile atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        [self exitWithError:error andMessage:[NSString stringWithFormat:@"Error writing package list to %@", packageListFile]];
    }
}

- (void)generatePackage:(NSString *)package forVersion:(NSString *)version withDescription:(NSString *)description {
    static NSString *packageTemplate;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        packageTemplate = [NSString stringWithFormat:
                           @"Package: %%@\n"
                           "Essential: yes\n"
                           "Status: install ok installed\n"
                           "Priority: required\n"
                           "Section: System\n"
                           "Installed-Size: 0\n"
                           "Architecture: %@\n"
                           "Version: %%@\n"
                           "Description: %%@\n"
                           "Maintainer: %@\n"
                           "Tag: role::cydia\n"
                           "\n",
                           [self->_deviceInfo getDebianArchitecture], MAINTAINER];
    });

    [self generatePackageListFile:package];

    [self->_status appendFormat:packageTemplate, package, version, description];
}

- (void)generatePackage:(NSString *)package forVersion:(NSString *)version withDescription:(NSString *)description andName:(NSString *)name {
    static NSString *packageTemplate;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        packageTemplate = [NSString stringWithFormat:
                           @"Package: %%@\n"
                           "Essential: yes\n"
                           "Status: install ok installed\n"
                           "Priority: required\n"
                           "Section: System\n"
                           "Installed-Size: 0\n"
                           "Architecture: %@\n"
                           "Version: %%@\n"
                           "Description: %%@\n"
                           "Maintainer: %@\n"
                           "Tag: role::cydia\n"
                           "Name: %%@\n"
                           "\n",
                           [self->_deviceInfo getDebianArchitecture], MAINTAINER];
    });

    [self generatePackageListFile:package];

    [self->_status appendFormat:packageTemplate, package, version, description, name];
}

- (void)generateCapabilityPackages {
    NSDictionary *capabilites = [self->_deviceInfo getCapabilities];

    // generate packages for device capabilites
    NSString *ipad = @"ipad";
    NSString *gsc = @"gsc.";
    NSString *standardDescription = @"virtual GraphicsServices dependency";

    for (NSString *name in capabilites) {
        NSString *packageVersion = [capabilites valueForKey:name];

        if ([ipad isEqualToString:name]) {
            [self generatePackage:@"gsc.ipad" forVersion:packageVersion withDescription:@"this device has a very large screen" andName:@"iPad"];
            [self generatePackage:@"gsc.wildcat" forVersion:packageVersion withDescription:@"this device has a very large screen" andName:@"iPad"];
        } else {
            [self generatePackage:[gsc stringByAppendingString:name] forVersion:packageVersion withDescription:standardDescription];
        }
    }
}

- (void)writePackagesToStatusFile {
    NSError *error;
    NSString *statusFile = [self->_adminDirectory stringByAppendingString:@"/status"];

    if (![self->_status writeToFile:statusFile atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        [self exitWithError:error andMessage:@"Error writing to status file"];
    }
}

- (void)setupUserSymbolicLink {

    // -------------
    // TODO: implement cp -afT in objective-c
    // -------------

    NSError *error;

    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSString *userPath = @"/User";
    NSString *varMobileDirectory = @"/var/mobile";

    NSDictionary *userAttributes = [fileManager attributesOfItemAtPath:userPath error:nil];


    // copy files from /User to /var/mobile

    if (userAttributes && ![userAttributes.fileType isEqualToString:NSFileTypeSymbolicLink] && [userAttributes.fileType isEqualToString:NSFileTypeDirectory]) {
        pid_t pid;
        extern char **environ;
        
        char *argv[] = {
            "/usr/bin/env",
            "cp",
            "-afT",
            (char *)[userPath UTF8String],
            (char *)[varMobileDirectory UTF8String],
            NULL
        };

        posix_spawn(&pid, argv[0], NULL, NULL, argv, environ);
        waitpid(pid, NULL, 0);
    }


    // delete item at user path if it exists

    if (userAttributes) {
        if (![fileManager removeItemAtPath:userPath error:&error]) {
            [self exitWithError:error andMessage:[NSString stringWithFormat:@"Error deleting %@", userPath]];
        }
    }

    // symlink user path to mobile user directory

    if (![fileManager createSymbolicLinkAtPath:userPath withDestinationPath:varMobileDirectory error:&error]) {
        [self exitWithError:error andMessage:[NSString stringWithFormat:@"Error creating symbolic link at %@ to %@", userPath, varMobileDirectory]];
    }
}

@end
