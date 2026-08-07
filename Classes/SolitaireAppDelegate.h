//
//  SolitaireAppDelegate.h
//  Solitaire
//
//  Created by Xander Gomez on 7/24/26.
//  Copyright __MyCompanyName__ 2026. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SolitaireViewController;

@interface SolitaireAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    SolitaireViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet SolitaireViewController *viewController;

@end

