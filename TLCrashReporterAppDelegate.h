//
//  TLCrashReporterDelegate.h
//  TLCrashReporter
//
//  Created by Jon Hjelle on 12/1/08.
//  Copyright 2008 Calf Trail Software, LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TLCrashReporterAppDelegate : NSObject {
    IBOutlet NSTextView* descriptionView;
    IBOutlet NSTextView* crashLogView;
    IBOutlet NSWindow* crashReporterWindow;
@private
    NSString* crashLog;
}

- (IBAction)sendCrashReport:(id)sender;

@end
