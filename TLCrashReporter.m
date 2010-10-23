/*
 *  TLCrashReporter.m
 *  TLCrashReporter
 *
 *  Created by Nathan Vander Wilt on 1/8/09, orig. Jon Hjelle on 12/8/08.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

#include "TLCrashReporter.h"

// NOTE: this class helps us find the framework bundle containing the helper app
@interface TLCrashReporter_DummyClass : NSObject {}
@end
@implementation TLCrashReporter_DummyClass
@end


static char* TLCrashReporter_Executable = NULL;
static char* TLCrashReporter_Arguments[] = { NULL, NULL, NULL };
static char* TLCrashReporter_Environment[] = { NULL };

static void TLCrashReporter_SignalGrabber(int signum) {
    if (TLCrashReporter_Executable && TLCrashReporter_Arguments[1]) {
		pid_t pid = fork();
		if (!pid) {
			// child process: detach from parent and become crash reporter
			(void)setsid();
			execve(TLCrashReporter_Executable, TLCrashReporter_Arguments, TLCrashReporter_Environment);
			_exit(0);
		}
	}
    signal(signum, NULL);
    raise(signum);
}

void TLCrashReporterRegisterSignals() {
    @try {
        NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
		NSBundle* frameworkBundle = [NSBundle bundleForClass:[TLCrashReporter_DummyClass class]];
        NSString* crashReporterAppPath = [frameworkBundle pathForResource:@"CrashReporter" ofType:@"app"];
        NSString* executablePath = [[NSBundle bundleWithPath:crashReporterAppPath] executablePath];
		NSCAssert(executablePath, @"CrashReporter executable could not be found.");
		TLCrashReporter_Executable = strdup([executablePath UTF8String]);
		TLCrashReporter_Arguments[0] = TLCrashReporter_Executable;
		
		NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey];
		NSCAssert(appName, @"Application name could not be found.");
		TLCrashReporter_Arguments[1] = strdup([appName UTF8String]);
		
        [pool drain];
    }
	@catch (id exception) {
		NSLog(@"Failed to register crash reporter (%@).", exception);
		return;
	}
    
    signal(SIGQUIT, TLCrashReporter_SignalGrabber);
    signal(SIGILL, TLCrashReporter_SignalGrabber);
    signal(SIGTRAP, TLCrashReporter_SignalGrabber);
    signal(SIGABRT, TLCrashReporter_SignalGrabber);
    signal(SIGEMT, TLCrashReporter_SignalGrabber);
    signal(SIGFPE, TLCrashReporter_SignalGrabber);
    signal(SIGBUS, TLCrashReporter_SignalGrabber);
    signal(SIGSEGV, TLCrashReporter_SignalGrabber);
    signal(SIGSYS, TLCrashReporter_SignalGrabber);
}
