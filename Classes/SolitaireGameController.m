//
//  SolitaireGameController.m
//  Solitaire
//
//  Created by Xander Gomez on 7/24/26.
//  Copyright 2026 __MyCompanyName__. All rights reserved.
//

#import "SolitaireGameController.h"
#import "SolitaireViewController.h"
#import <stdlib.h>
#import <time.h>

static void unlinkCardFromDrawPile(SolitaireSelection* selectedPile) {
	SolitaireCard *theCard = selectedPile->selectedCard;
	if (selectedPile->selection != SolitaireStackDrawPileDrawn) return;
	SolitaireDrawPile *thePile = (SolitaireDrawPile*)selectedPile->selectionReference;
	SolitaireCard *parent = theCard->parent;
	if (parent != NULL) parent->child = theCard->child;
	if (theCard->child != NULL) theCard->child->parent = parent;
	theCard->child = NULL;
	theCard->parent = NULL;
	if (theCard == thePile->third) thePile->third = NULL;
	else if (theCard == thePile->second) thePile->second = NULL;
	else if (theCard == thePile->first) {
		thePile->first = parent;
		if (thePile->first != NULL) thePile->first->flipped = NO;
	}
}

static BOOL unlinkCardFromTableStack(SolitaireSelection* selectedStack) { // returns if you flipped the parent over
	SolitaireCard *theCard = selectedStack->selectedCard;
	SolitaireTableStack *theStack = (SolitaireTableStack*)selectedStack->selectionReference;
	SolitaireCard *theNewTop = theCard->parent;
	BOOL didFlip = NO;
	if (theNewTop != NULL) {
		if (theNewTop->flipped) {
			theNewTop->flipped = NO;
			didFlip = YES;
		}
		theNewTop->child = NULL;
	}
	theStack->bottomCard = theNewTop;
	if (theCard == theStack->topCard) theStack->topCard = NULL;
	theCard->parent = NULL;
	return didFlip;
}

static void unlinkCardFromFoundation(SolitaireSelection* selectedFoundation) {
	if (selectedFoundation->selection != SolitaireStackFoundation) return;
	SolitaireFoundation *theFoundation = ((SolitaireFoundation*)selectedFoundation->selectionReference);
	SolitaireCard *theCard = *theFoundation;
	theCard->child = NULL;
	if (theCard->parent != NULL) theCard->parent->child = NULL;
	*theFoundation = theCard->parent;
	theCard->parent = NULL;
}

static void relinkCardToDrawPile(SolitaireSelection* selectedPile) {
	SolitaireCard *theCard = selectedPile->selectedCard;
	SolitaireDrawPile *thePile = (SolitaireDrawPile*)selectedPile->selectionReference;
	if (thePile->first == NULL) { 
		thePile->first = theCard; 
		theCard->parent = NULL;
		
	} else if (thePile->second == NULL) {
		thePile->second = theCard;
		theCard->parent = thePile->first;		
	} else if (thePile->third == NULL) {
		thePile->third = theCard;
		theCard->parent = thePile->second;
	}
	theCard->child = thePile->pile;
}

static int countOfCardsBeforeFirstInPile(SolitaireDrawPile* pile) { // sentinel -1ooooooookoip000qwwwwwwwwwwwwwwwwtyyyyyyyyygho	
	int count = 0;
	SolitaireCard *theCard = pile->first;
	if (theCard == NULL) return -1;
	while ((theCard = theCard->parent) != NULL) count += 1;
	return count;
}

@implementation SolitaireMove
- (BOOL)moveToFoundation {
	if (getSuit(source.selectedCard) != getSuit(receiver.selectedCard) && getSuit(receiver.selectedCard) != SolitaireNoSuit) return NO;
	if (getValue(source.selectedCard) != getValue(receiver.selectedCard) + 1 && getValue(receiver.selectedCard) != SolitaireNoValue) return NO;
	if (getValue(receiver.selectedCard) == SolitaireNoValue && getValue(source.selectedCard) != SolitaireAce) return NO;
	SolitaireFoundation *destination = (SolitaireFoundation*)receiver.selectionReference;
	switch (source.selection) {
		case SolitaireStackDrawPileDrawn: unlinkCardFromDrawPile(&source); break;
		case SolitaireStackTable: didRevealParent = unlinkCardFromTableStack(&source); break;
		case SolitaireStackFoundation: unlinkCardFromFoundation(&source); break; // ace-moving edge case even though it'd otherwise be impossible
		default: break;
	}
	source.selectedCard->parent = *destination; // its technically double indirection (SolitaireFoundation* == SolitaireCard**) so we gotta do this
	if (*destination != NULL) (*destination)->child = source.selectedCard;
	*destination = source.selectedCard;
	pointsAwarded = source.selection != SolitaireStackFoundation ? 15 : 0;
	return YES;
}

- (BOOL)moveToTableStack {
	// if first is diamond and second heart then first shifted right by 2 should get heart (1000 -> 0010), and vice versa (checks other side too)
	if (
		getSuit(source.selectedCard) == getSuit(receiver.selectedCard) ||
		getSuit(source.selectedCard) >> 2 == getSuit(receiver.selectedCard) || 
		getSuit(receiver.selectedCard) >> 2 == getSuit(source.selectedCard) // soooooo much cleaner than checking all combos
	) return NO;
	if (getValue(source.selectedCard) != getValue(receiver.selectedCard) - 1) return NO;
	SolitaireTableStack *destination = ((SolitaireTableStack*)receiver.selectionReference);
	if (receiver.selectedCard != destination->bottomCard) return NO;
	switch (source.selection) {
		case SolitaireStackDrawPileDrawn: unlinkCardFromDrawPile(&source); break;
		case SolitaireStackTable: didRevealParent = unlinkCardFromTableStack(&source); break;
		case SolitaireStackFoundation: unlinkCardFromFoundation(&source); break;
		default: break;
	}
	source.selectedCard->parent = destination->bottomCard;
	if (destination->bottomCard != NULL) destination->bottomCard->child = source.selectedCard;
	SolitaireCard *bottom = source.selectedCard;
	while (bottom != NULL) {
		destination->bottomCard = bottom;
		bottom = bottom->child;
	}
	if (destination->topCard == NULL) destination->topCard = source.selectedCard;
	pointsAwarded = (source.selection == SolitaireStackFoundation) ? -15 : ((source.selection == SolitaireStackDrawPileDrawn || didRevealParent) ? 5 : 0);
	return YES;
}

+ (id)makeMoveFrom:(SolitaireSelection)firstSelection to:(SolitaireSelection)secondSelection {
	BOOL result;
	if (firstSelection.selection == SolitaireStackNone || secondSelection.selection == SolitaireStackNone) return nil;
	SolitaireMove *newMove = [[SolitaireMove new] autorelease];
	newMove->source = firstSelection;
	newMove->receiver = secondSelection;
	switch (secondSelection.selection) {
		case SolitaireStackTable: result = [newMove moveToTableStack]; break;
		case SolitaireStackFoundation: result = [newMove moveToFoundation]; break;
		default: result = NO; break;
	}
	return result ? newMove : nil;
}

+ (id)hitDrawPile:(BOOL)penalised {
	SolitaireMove *newMove = [SolitaireMove new];
	newMove->source.selection = SolitaireStackDrawPile;
	if (penalised) newMove->pointsAwarded = -20;
	return [newMove autorelease];
}
@end

@implementation SolitaireGameController
@synthesize viewController = _viewController;
- (SolitaireTableStack*)tableStacks { return _tableStacks; }
- (SolitaireFoundation*)foundations { return _foundations; }
- (SolitaireDrawPile*)drawPile { return &_drawPile; }

- (id)initWithViewController:(SolitaireViewController*)controller {
	self = [self init];
	_viewController = controller;
	
	loadCardAssets();
	for (int i = 0; i < 52; i++) deck[i] = newSolitaireCard((i % 13) | (SolitaireSpade << (i / 13)));	
	deloadCardAssets();
			
	return self;
}

- (void)shuffle {
	srand(time(NULL));
	for (int i = 0; i < 52; i++) {
		int ii = 0;
		if (i > 0) ii = rand() % i;
		SolitaireCard one = deck[i], two = deck[ii];
		deck[i] = two; deck[ii] = one;
	}
}

- (void)newGame:(id)sender {	
	int index = 0;
	[self shuffle];
	if (gameTimer != nil) [gameTimer invalidate];
	playerScore = 0;
	timeElapsed = 0;
	memset(&currentSelection, 0, sizeof(SolitaireSelection));
	for (int i = 0; i < 52; i++) resetAttributes(&deck[i]);
	memset(_tableStacks, 0, sizeof(SolitaireTableStack) * 7);
	for (int i = 0; i < 7; i++) {
		for (int ii = 0; ii <= i; ii++) {
			SolitaireCard *newCard = &deck[index++];
			newCard->flipped = YES;
			newCard->parent = _tableStacks[i].bottomCard;
			if (_tableStacks[i].topCard == NULL) _tableStacks[i].topCard = newCard;
			if (newCard->parent != NULL) newCard->parent->child = newCard;
			_tableStacks[i].bottomCard = newCard;
		}
		_tableStacks[i].bottomCard->flipped = NO;
		[[_viewController gameView] drawTableStack:i];
	}
	memset(&_drawPile, 0, sizeof(SolitaireDrawPile));
	SolitaireCard *topCard = &deck[index++];
	topCard->flipped = YES;
	_drawPile.pile = topCard;
	for (; index < 52; index++) { 
		_drawPile.pile->child = &deck[index];
		deck[index].parent = _drawPile.pile;
		deck[index].flipped = YES;
		_drawPile.pile = &deck[index];
	}
	_drawPile.pile = topCard;
	memset(_foundations, 0, sizeof(SolitaireFoundation) * 4);
	for (int i = 0; i < 4; i++) [[_viewController gameView] drawFoundation:i];
	memset(&currentSelection, 0, sizeof(SolitaireSelection));
	[[_viewController gameView] drawDrawPile];
	[[_viewController gameView] showScore:0];
	[[_viewController gameView] showTime:0];
	gameTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tickTime:) userInfo:nil repeats:YES];
}


- (void)hitDrawPile {
	if (gameTimer == nil) return;
	SolitaireCard *currentCard = NULL;
	BOOL shouldPenalise = NO, didPass = NO;
	[self clearSelection:&currentSelection];
	
	if (_drawPile.first != NULL) {
		currentCard = _drawPile.first;
		_drawPile.first->flipped = YES;
		_drawPile.first->selected = NO;
		_drawPile.first = NULL;
	}
	
	if (_drawPile.second != NULL) {
		currentCard = _drawPile.second;
		_drawPile.second->flipped = YES;
		_drawPile.second->selected = NO;
		_drawPile.second = NULL;
	}
	
	if (_drawPile.third != NULL) {
		currentCard = _drawPile.third;
		_drawPile.third->flipped = YES;
		_drawPile.third->selected = NO;
		_drawPile.third = NULL;
	}
	
	if (_drawPile.pile == NULL) {
		if (++_drawPile.passes > 3) shouldPenalise = YES;
		while (currentCard != NULL) {
			_drawPile.pile = currentCard;
			currentCard = currentCard->parent;
		}
		didPass = YES;
		goto drawThePile;
	}
	
	currentCard = _drawPile.pile;
	_drawPile.first = currentCard;
	currentCard->flipped = NO;
	
	currentCard = _drawPile.pile->child;
	_drawPile.pile = currentCard;
	if (_drawPile.pile == NULL) goto drawThePile;
	_drawPile.second = currentCard;
	currentCard->flipped = NO;
	
	currentCard = _drawPile.pile->child;
	_drawPile.pile = currentCard;
	if (_drawPile.pile == NULL) goto drawThePile;
	_drawPile.third = currentCard;
	currentCard->flipped = NO;
	
	_drawPile.pile = _drawPile.pile->child;
	
	drawThePile: 
		playerScore += ((SolitaireMove*)[SolitaireMove hitDrawPile:shouldPenalise])->pointsAwarded;
		[[_viewController gameView] showScore:playerScore];
		[[_viewController gameView] drawDrawPile];
}

- (void)select:(SolitaireSelection)selection {
	if (selection.selectionReference == NULL) return;
	setCurrentSelection:
	if (currentSelection.selection == SolitaireStackNone && selection.selection != SolitaireStackNone && selection.selectedCard != NULL) {
		if (selection.selection == SolitaireStackDrawPileDrawn) {
			if (_drawPile.third != NULL && selection.selectedCard != _drawPile.third) return;
			if (_drawPile.third == NULL && _drawPile.second != NULL && selection.selectedCard != _drawPile.second) return;
		}
		currentSelection = selection;
		selection.selectedCard->selected = YES;
		if ((SolitaireDrawPile*)currentSelection.selectionReference == &_drawPile) [[_viewController gameView] drawDrawPile];
		else {
			if (currentSelection.selection == SolitaireStackTable) [[_viewController gameView] drawTableStack:[self indexOfTableStack:currentSelection.selectionReference]];
			else [[_viewController gameView] drawFoundation:[self indexOfFoundation:currentSelection.selectionReference]];
		}
		return;
	} 
	else if (currentSelection.selection == SolitaireStackNone) return;
	
	if (selection.selection == SolitaireStackDrawPileDrawn && currentSelection.selection != SolitaireStackDrawPileDrawn) {
		currentSelection.selectedCard->selected = NO;
		switch (currentSelection.selection) {
			case SolitaireStackTable: [[_viewController gameView] drawTableStack:[self indexOfTableStack:currentSelection.selectionReference]]; break;
			case SolitaireStackFoundation: [[_viewController gameView] drawFoundation:[self indexOfFoundation:currentSelection.selectionReference]]; break;
			default: break;
		}
		memset(&currentSelection, 0, sizeof(SolitaireSelection));
		goto setCurrentSelection;
	}
	
	SolitaireMove* theMove = [SolitaireMove makeMoveFrom:currentSelection to:selection];
	currentSelection.selectedCard->selected = NO;
	void *selectionReference = currentSelection.selectionReference;
	SolitaireStackType oldSelection = currentSelection.selection;
	memset(&currentSelection, 0, sizeof(SolitaireSelection));
	currentSelection.selection = SolitaireStackNone;
	if (theMove == nil) goto drawTheStacks;
	playerScore += theMove->pointsAwarded;
	[[_viewController gameView] showScore:playerScore];
	
	drawTheStacks:
	switch (oldSelection) {
		case SolitaireStackTable: [[_viewController gameView] drawTableStack:[self indexOfTableStack:selectionReference]]; break;
		case SolitaireStackFoundation: [[_viewController gameView] drawFoundation:[self indexOfFoundation:selectionReference]]; break;
		case SolitaireStackDrawPileDrawn: [[_viewController gameView] drawDrawPile]; break;
		default: break;
	}
	switch (selection.selection) {
		case SolitaireStackTable: [[_viewController gameView] drawTableStack:[self indexOfTableStack:selection.selectionReference]]; break;
		case SolitaireStackFoundation: [[_viewController gameView] drawFoundation:[self indexOfFoundation:selection.selectionReference]]; break;
		default: break;
	}
	
	for (int i = 0; i < 4; i++) {
		if (getValue(_foundations[i]) != SolitaireKing) return;
	}
	
	if (timeElapsed > 30) playerScore += 700000 / timeElapsed;
	UIAlertView *theView = [[[UIAlertView alloc] initWithTitle:@"You Win!" message:[NSString stringWithFormat:@"Score: %d\nTime: %d", playerScore, timeElapsed] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
	[theView show];
	
	memset(_foundations, 0, sizeof(SolitaireFoundation) * 4);
	memset(_tableStacks, 0, sizeof(SolitaireTableStack) * 7);
	memset(&_drawPile, 0, sizeof(SolitaireDrawPile));
	memset(&currentSelection, 0, sizeof(SolitaireSelection));
	
	[gameTimer invalidate];
	gameTimer = nil;
	
	for (int i = 0; i < 4; i++) [[_viewController gameView] drawFoundation:i];
	for (int i = 0; i < 7; i++) [[_viewController gameView] drawTableStack:i];
	[[_viewController gameView] drawDrawPile];
	[[_viewController gameView] showTime:-1];
	[[_viewController gameView] showScore:-1];
}


- (void)clearSelection:(SolitaireSelection*)selection {
	if (selection->selectedCard != NULL) selection->selectedCard->selected = NO;
	switch (selection->selection) {
		case SolitaireStackTable: [[_viewController gameView] drawTableStack:[self indexOfTableStack:selection->selectionReference]]; break;
		case SolitaireStackFoundation: [[_viewController gameView] drawFoundation:[self indexOfFoundation:selection->selectionReference]]; break;
		case SolitaireStackDrawPileDrawn: [[_viewController gameView] drawDrawPile]; break;
		default: break;
	}
	memset(selection, 0, sizeof(SolitaireSelection));
	return;
}

- (void)tickTime:(NSTimer*)timer {
	timeElapsed += 1;
	if (timeElapsed % 10 == 0 && timeElapsed != 0) playerScore -= 2;
	[[_viewController gameView] showTime:timeElapsed];
	[[_viewController gameView] showScore:playerScore];
}

- (NSInteger)indexOfTableStack:(SolitaireTableStack*)theStack {
	for (int i = 0; i < 7; i++) {
		if (theStack == &_tableStacks[i]) return i;
	}
	return -1;
}
- (NSInteger)indexOfFoundation:(SolitaireFoundation*)theFoundation {
	for (int i = 0; i < 4; i++) {
		if (theFoundation == &_foundations[i]) return i;
	}
	return -1;
}

- (void)dealloc {
	// worry abt this later
	[super dealloc];
}
@end
