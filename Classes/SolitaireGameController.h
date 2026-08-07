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
@class SolitaireFoundationButton;

typedef SolitaireCard *SolitaireFoundation; // typedef'd since you only ever need the top card at once (which can hold prior cards as parents), or NULL if no card is present

typedef enum {
	SolitaireStackNone,
	SolitaireStackFoundation,
	SolitaireStackTable,
	SolitaireStackDrawPile, // used primarily for hitting
	SolitaireStackDrawPileDrawn
} SolitaireStackType;

/* why so many structs / unions? because like, all of these dont need to be heap allocated classes my guy XD */
typedef struct { 
	SolitaireCard *topCard; // works since the top card is a linked list
	SolitaireCard *bottomCard;
} SolitaireTableStack;

typedef struct { // coulda done a SolitaireCard *visible[3] but eh, quicker this way and same space anyway
	SolitaireCard *pile; // take advantage of the fact they're linked lists to save memory
	SolitaireCard *first; // the card that also pulls from the rest of the drawn cards
	SolitaireCard *second; // middle card in the drawn 3
	SolitaireCard *third; // top-most card in draw 3
	NSInteger passes;
} SolitaireDrawPile;

typedef struct {
	SolitaireStackType selection;
	SolitaireCard *selectedCard;
	void *selectionReference;
} SolitaireSelection;

typedef union { // UNIONISE, MY CHILDREN, UNIONISE! RISE, AND FIGHT AGAINST YOUR CORPORATE OPPRESSORS
	SolitaireFoundation *foundation;
	SolitaireTableStack *tableStack;
	SolitaireDrawPile *drawPile;
} SolitaireMoveStack;

@interface SolitaireMove : NSObject { // class so that it may be stored within an NSArray
	@public // we really don't need to encapsulate here
		SolitaireSelection source;
		SolitaireSelection receiver; // necessary for restoring ceeertain things like foundations, also good for quickly redrawing the affected
		BOOL didRevealParent;
		NSInteger pointsAwarded;
}

+ (id)makeMoveFrom:(SolitaireSelection)firstSelection to:(SolitaireSelection)secondSelection;
+ (id)hitDrawPile:(BOOL)penalised;
@end

/* debatably even this could be a struct with standard C methods instead if it weren't for buttons needing a target + selector, though at that point why would we even be using objc yk */
/* though even then it is entirely possible to register selectors at runtime and same with classes... but that's just straight overkill and unnecessary XD */
@interface SolitaireGameController : NSObject {
	SolitaireCard deck[52]; // it's always 52 cards no matter what XD
	SolitaireViewController *_viewController;
	
	SolitaireDrawPile _drawPile; 
	
	SolitaireTableStack _tableStacks[7];
	SolitaireFoundation _foundations[4];
	
	SolitaireSelection currentSelection;
		
	NSInteger playerScore;
	NSInteger timeElapsed;
	
	NSTimer *gameTimer;
}

@property (nonatomic, readonly) SolitaireViewController *viewController;
@property (nonatomic, readonly) SolitaireTableStack *tableStacks;
@property (nonatomic, readonly) SolitaireFoundation *foundations;
@property (nonatomic, readonly) SolitaireDrawPile *drawPile;

- (id)initWithViewController:(SolitaireViewController*)controller;

- (void)tickTime:(NSTimer*)timer;

- (void)newGame:(id)sender;
- (void)hitDrawPile;

- (void)select:(SolitaireSelection)selection;

- (void)clearSelection:(SolitaireSelection*)selection;

- (NSInteger)indexOfTableStack:(SolitaireTableStack*)theStack; // is it wasteful? yes. do i give two shits? no. i just want to stop the damn code duplication man. returns -1 on fail
- (NSInteger)indexOfFoundation:(SolitaireFoundation*)theFoundation;
@end
