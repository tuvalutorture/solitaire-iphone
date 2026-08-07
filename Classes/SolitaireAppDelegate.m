//
//  SolitaireAppDelegate.m
//  Solitaire
//
//  Created by Xander Gomez on 7/24/26.
//  Copyright __MyCompanyName__ 2026. All rights reserved.
//

#import "SolitaireAppDelegate.h"
#import "SolitaireViewController.h"

@implementation SolitaireAppDelegate

@synthesize window;
@synthesize viewController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {    
    
    // Override point for customization after app launch    
    [window addSubview:viewController.view];
    [window makeKeyAndVisible];
}


- (void)dealloc {
    [viewController release];
    [window release];
    [super dealloc];
}


@end
