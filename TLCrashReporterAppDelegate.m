//
//  TLCrashReporterDelegate.m
//  TLCrashReporter
//
//  Created by Jon Hjelle on 12/1/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import "TLCrashReporterAppDelegate.h"


static NSString* const TLCrashReporterPostURL = @"http://example.com/cgi-bin/script";
static NSString* const TLCrashReporterProtocolVersion = @"1";


@interface TLCrashReporterAppDelegate ()
@property (nonatomic, copy) NSString* crashLog;
@end


@implementation TLCrashReporterAppDelegate

@synthesize crashLog;

- (void)setCrashLog:(NSString*)newCrashLog {
    [crashLog autorelease];
    crashLog = [newCrashLog copy];
    [crashLogView setString:newCrashLog];
}

- (NSString*)mostRecentCrashLogForApplication:(NSString*)appName {
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    if (![paths count]) return nil;
    NSString* libraryDirPath = [paths objectAtIndex:0];
    NSString* crashLogsDirPath = [libraryDirPath stringByAppendingString:@"/Logs/CrashReporter"];
    NSArray* allLogs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:crashLogsDirPath error:NULL];
    if (!allLogs) return nil;
    
    NSUInteger appNameIndex = [appName length];
    NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch | NSNumericSearch |
                                               NSWidthInsensitiveSearch | NSForcedOrderingSearch;
    NSString* newestLogfile = nil;
    for (NSString* logfile in allLogs) {
        if ([logfile length] < appNameIndex) continue;
        if ([[logfile substringToIndex:appNameIndex] isEqualToString:appName]) {
            if (!newestLogfile ||
                [newestLogfile compare:logfile options:comparisonOptions] == NSOrderedAscending)
            {
                newestLogfile = logfile;
            }
        }
    }
    if (!newestLogfile) return nil;
    
    // TODO: check that the crash log is not too old, otherwise wait longer or just fail.
    
    NSString* pathToCrashLog = [crashLogsDirPath stringByAppendingPathComponent:newestLogfile];
    NSStringEncoding encoding = 0;
    NSString* crashLogContents = [NSString stringWithContentsOfFile:pathToCrashLog
                                                       usedEncoding:&encoding
                                                              error:NULL];
    (void)encoding;
    
    return crashLogContents;
}

- (NSString*)urlEncodeString:(NSString*)string {
    NSString* result = (NSString*)CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                          (CFStringRef)string,
                                                                          NULL, CFSTR("?=&+"),
                                                                          kCFStringEncodingUTF8);
    return [result autorelease];
}

- (IBAction)sendCrashReport:(id)sender {
	// hide app (it has no dock icon) so user does not retry send multiple times
    [[NSApplication sharedApplication] hide:sender];
    
    /* The following and urlEncodeString were found from:
     http://deusty.blogspot.com/2006/11/sending-http-get-and-post-from-cocoa.html */
    
    NSString* description = [descriptionView string];
    NSString* log = [self crashLog];
    
    NSString* post = [NSString stringWithFormat:@"version=%@&description=%@&log=%@",
                          [self urlEncodeString:TLCrashReporterProtocolVersion],
                          [self urlEncodeString:description],
                          [self urlEncodeString:log]];
    NSData* postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    
    NSString* postLength = [NSString stringWithFormat:@"%lu", (long unsigned)[postData length]];
    // TODO: Add version number
    NSMutableURLRequest* urlRequest = [[[NSMutableURLRequest alloc] init] autorelease];
    [urlRequest setURL:[NSURL URLWithString:TLCrashReporterPostURL]];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setHTTPBody:postData];
    
    NSURLConnection* connection = [NSURLConnection connectionWithRequest:urlRequest delegate:self];
    CFRetain(connection);
}

- (NSString*)applicationName {
    NSArray* arguments = [[NSProcessInfo processInfo] arguments];
    if ([arguments count] < 2) return nil;
    // TODO: make this work with many more arguments in various orders
    return [arguments objectAtIndex:1];
}


#pragma mark NSApplication Delegate methods

- (void)applicationWillFinishLaunching:(NSNotification*)aNotification {
    (void)aNotification;
    NSString* application = [self applicationName];
    if (!application) {
        [[NSApplication sharedApplication] terminate:self];
    }
    NSString* titleBar = [application stringByAppendingString:@" Crash Reporter"];
    [crashReporterWindow setTitle:titleBar];
    NSString* log = [self mostRecentCrashLogForApplication:application];
    if (!log) {
        log = @"Couldn't find crash log.";
    }
    [self setCrashLog:log];
	[descriptionView selectAll:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)theApplication {
    return YES;
}


#pragma mark NSURLConnection Delegate methods

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
	NSLog(@"%@\n", error);
    CFRelease(connection);
    [[NSApplication sharedApplication] terminate:self];
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection {
    CFRelease(connection);
    [[NSApplication sharedApplication] terminate:self];
}

@end
