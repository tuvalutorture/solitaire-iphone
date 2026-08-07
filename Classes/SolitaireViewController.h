//
//  SolitaireViewController.h
//  Solitaire
//
//  Created by Xander Gomez on 7/24/26.
//  Copyright __MyCompanyName__ 2026. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SolitaireCard.h"
#import "SolitaireGameController.h"
#define SolitaireViewPadding 10.0f
#define SolitaireBottomHeight 31.0f // the size of the UITextField with rounded bezel style in UIKit

@class SolitaireGameController;

@interface SolitaireGameView : UIImageView {
	SolitaireTableStack *_tableStacks;
	SolitaireFoundation *_foundations;
	SolitaireDrawPile *_drawPile;
	
	CGRect foundationFrames[4];
	CGRect tableStackFrames[7];
	CGRect drawPileFrame;
	CGRect drawPileCardFrames[3];
	
	CGContextRef _context;
	
	CGImageRef blankImage;
	
	SolitaireGameController *controller;
	
	UITextField *timeView;
	UIButton *gameButton; // end/new game
	UITextField *scoreView;
	CGRect bottomFrame;
}

@property (nonatomic, readonly) CGContextRef context;

- (void)resize:(CGSize)newSize;

- (void)drawTableStack:(NSInteger)targetTableStack;
- (void)drawFoundation:(NSInteger)targetFoundation;
- (void)drawDrawPile;

- (void)render;

- (void)showTime:(int)seconds;
- (void)showScore:(NSInteger)score;

- (SolitaireTableStack*)stackForPoint:(CGPoint)point; // returns NULL if no overlap
- (SolitaireFoundation*)foundationForPoint:(CGPoint)point;
- (SolitaireDrawPile*)drawPileForPoint:(CGPoint)point;

- (CGPoint)convertToCGPointFromUIKitPoint:(CGPoint)UIKitPoint;

- (void)clicked:(CGPoint)atPoint;
@end


@interface SolitaireViewController : UIViewController {
	SolitaireGameController *gameController;
	SolitaireGameView *_gameView;
}

@property (nonatomic, readonly) SolitaireGameView *gameView;
@end

