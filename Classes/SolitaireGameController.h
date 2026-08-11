//
//  SolitaireGameController.h
//  Solitaire
//
//  Created by Xander Gomez on 7/24/26.
//  Copyright 2026 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SolitaireCard.h"

@class SolitaireMove;
@class SolitaireViewController;
@class SolitaireGameController;

typedef enum {
	SolitaireStackNone,
	SolitaireStackFoundation,
	SolitaireStackTable,
	SolitaireStackDrawPile, // used primarily for hitting
	SolitaireStackDrawPileDrawn
} SolitaireStackType;

typedef struct {
	CFMutableArrayRef pile; 
	NSInteger passes;
	NSInteger index;
	NSInteger displayed; // 0, 1, 2, or 3
	BOOL isPullingFromBelow;
} SolitaireDrawPile;

typedef struct {
	SolitaireStackType selection;
	NSInteger index;
	CFMutableArrayRef selected;
} SolitaireSelection;

@interface SolitaireMove : NSObject { // class so that it may be stored within an NSArray
	@public // we really don't need to encapsulate here
		SolitaireSelection source;
		SolitaireSelection receiver; // necessary for restoring ceeertain things like foundations, also good for quickly redrawing the affected
		BOOL didRevealParent;
		NSInteger pointsAwarded;
}

+ (id)makeMoveFrom:(SolitaireSelection)firstSelection to:(SolitaireSelection)secondSelection;
@end

@interface SolitaireDrawPileMove : NSObject { 
	@public
		SolitaireDrawPile snapshot; // snapshotting might be the most technically bankrupt thing i've yet done but it's prolly less costly than a normal move and is guaranteed safe
		NSInteger penalty;
}

+ (id)hitDrawPile:(BOOL)penalised;
@end


/* debatably even this could be a struct with standard C methods instead if it weren't for buttons needing a target + selector, though at that point why would we even be using objc yk */
/* though even then it is entirely possible to register selectors at runtime and same with classes... but that's just straight overkill and unnecessary XD */
@interface SolitaireGameController : NSObject {
	SolitaireCard deck[52]; // it's always 52 cards no matter what XD
	SolitaireViewController *_viewController;
	
	SolitaireDrawPile _drawPile; 
	
	CFMutableArrayRef _tableStacks;
	CFMutableArrayRef _foundations;
	
	SolitaireSelection currentSelection;
		
	NSInteger playerScore;
	NSInteger timeElapsed;
	
	NSTimer *gameTimer;
	
	NSMutableArray *moves;
}

@property (nonatomic, readonly) SolitaireViewController *viewController;
@property (nonatomic, readonly) CFMutableArrayRef tableStacks;
@property (nonatomic, readonly) CFMutableArrayRef foundations;
@property (nonatomic, readonly) SolitaireDrawPile *drawPile;

- (id)initWithViewController:(SolitaireViewController*)controller;

- (void)tickTime:(NSTimer*)timer;

- (void)undo:(id)sender;

- (void)newGame:(id)sender;
- (void)hitDrawPile;

- (void)select:(SolitaireSelection)selection;

- (void)clearSelection:(SolitaireSelection*)selection;

- (void)sendAllCardsToFoundation;

- (NSInteger)indexOfTableStack:(CFMutableArrayRef)theStack; // is it wasteful? yes. do i give two shits? no. i just want to stop the damn code duplication man. returns -1 on fail
- (NSInteger)indexOfFoundation:(CFMutableArrayRef)theFoundation;
@end
