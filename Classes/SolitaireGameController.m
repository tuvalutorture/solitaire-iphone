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

static SolitaireCard *sliceCardFromDrawPile(SolitaireDrawPile *pile) {
	SolitaireCard *theCard = (SolitaireCard*)CFArrayGetValueAtIndex(pile->pile, pile->index - 1);
	CFArrayRemoveValueAtIndex(pile->pile, pile->index - 1);
	pile->index -= 1; pile->displayed -= 1;
	if (pile->index == 0) pile->displayed = 0;
	else if (pile->displayed == 0) {
		pile->isPullingFromBelow = YES;
		pile->displayed = 1;
		((SolitaireCard*)CFArrayGetValueAtIndex(pile->pile, pile->index - 1))->flipped = NO;
	}
	return theCard;
}

@implementation SolitaireMove
- (BOOL)moveToFoundation {
	SolitaireCard *sourceCard = (SolitaireCard*)CFArrayGetValueAtIndex(source.selected, source.index);
	SolitaireCard *receiverCard = CFArrayGetCount(receiver.selected) > 0 ? (SolitaireCard*)CFArrayGetValueAtIndex(receiver.selected, receiver.index) : NULL;
	if (getSuit(sourceCard) != getSuit(receiverCard) && getSuit(receiverCard) != SolitaireNoSuit) return NO;
	if (getValue(sourceCard) != getValue(receiverCard) + 1 && getValue(receiverCard) != SolitaireNoValue) return NO;
	if (getValue(receiverCard) == SolitaireNoValue && getValue(sourceCard) != SolitaireAce) return NO;
	CFRange range = CFRangeMake(source.index, CFArrayGetCount(source.selected) - source.index);
	switch (source.selection) {
		case SolitaireStackDrawPileDrawn: CFArrayAppendValue(receiver.selected, sourceCard); break;
		case SolitaireStackTable: 
			CFArrayAppendArray(receiver.selected, source.selected, range);
			CFArrayReplaceValues(source.selected, range, NULL, 0);
			if (CFArrayGetCount(source.selected) > 0 && ((SolitaireCard*)CFArrayGetValueAtIndex(source.selected, CFArrayGetCount(source.selected) - 1))->flipped == YES) {
				((SolitaireCard*)CFArrayGetValueAtIndex(source.selected, CFArrayGetCount(source.selected) - 1))->flipped = NO;
				didRevealParent = YES;
			}
			break;
		case SolitaireStackFoundation: 
			CFArrayRemoveValueAtIndex(source.selected, source.index); 
			CFArrayAppendValue(receiver.selected, sourceCard);
			break;
		default: break;
	}
	pointsAwarded = source.selection != SolitaireStackFoundation ? 15 : 0;
	return YES;
}

- (BOOL)moveToTableStack {
	SolitaireCard *sourceCard = (SolitaireCard*)CFArrayGetValueAtIndex(source.selected, source.index);
	SolitaireCard *receiverCard = CFArrayGetCount(receiver.selected) > 0 ? (SolitaireCard*)CFArrayGetValueAtIndex(receiver.selected, receiver.index) : NULL;
	// if first is diamond and second heart then first shifted right by 2 should get heart (1000 -> 0010), and vice versa (checks other side too)
	if (
		getSuit(sourceCard) == getSuit(receiverCard) ||
		getSuit(sourceCard) >> 2 == getSuit(receiverCard) || 
		getSuit(receiverCard) >> 2 == getSuit(sourceCard) // soooooo much cleaner than checking all combos
	) return NO;
	if (getValue(sourceCard) != getValue(receiverCard) - 1) return NO;
	if (receiverCard != (SolitaireCard*)CFArrayGetValueAtIndex(receiver.selected, CFArrayGetCount(receiver.selected) - 1)) return NO;
	CFRange range = CFRangeMake(source.index, CFArrayGetCount(source.selected) - source.index);
	switch (source.selection) {
		case SolitaireStackDrawPileDrawn: CFArrayAppendValue(receiver.selected, sourceCard); break;
		case SolitaireStackTable: 
			CFArrayAppendArray(receiver.selected, source.selected, range);
			CFArrayReplaceValues(source.selected, range, NULL, 0);
			if (CFArrayGetCount(source.selected) > 0 && ((SolitaireCard*)CFArrayGetValueAtIndex(source.selected, CFArrayGetCount(source.selected) - 1))->flipped == YES) {
				((SolitaireCard*)CFArrayGetValueAtIndex(source.selected, CFArrayGetCount(source.selected) - 1))->flipped = NO;
				didRevealParent = YES;
			}
			break;
		case SolitaireStackFoundation: 
			CFArrayRemoveValueAtIndex(source.selected, source.index); 
			CFArrayAppendValue(receiver.selected, sourceCard);
			break;
		default: break;
	}
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
@end

@implementation SolitaireDrawPileMove
+ (id)hitDrawPile:(BOOL)penalised {
	SolitaireDrawPileMove *newMove = [SolitaireDrawPileMove new];
	if (penalised) newMove->penalty = -20;
	return [newMove autorelease];
}
@end


@implementation SolitaireGameController
@synthesize viewController = _viewController;
@synthesize foundations = _foundations;
@synthesize tableStacks = _tableStacks;
- (SolitaireDrawPile*)drawPile { return &_drawPile; }

- (id)init {
	self = [super init];
	loadCardAssets();
	for (int i = 0; i < 52; i++) deck[i] = newSolitaireCard((i % 13) | (SolitaireSpade << (i / 13)));	
	deloadCardAssets();
	_foundations = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
	for (int i = 0; i < 4; i++) {
		CFMutableArrayRef theFoundation = CFArrayCreateMutable(NULL, 0, NULL);
		CFArrayAppendValue(_foundations, theFoundation);
		CFRelease(theFoundation);
	}
	_tableStacks = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
	for (int i = 0; i < 7; i++) {
		CFMutableArrayRef theStack = CFArrayCreateMutable(NULL, 0, NULL);
		CFArrayAppendValue(_tableStacks, theStack);
		CFRelease(theStack);
	}
	_drawPile.pile = CFArrayCreateMutable(NULL, 0, NULL);
	moves = [NSMutableArray new];
	timeElapsed = -1;
	return self;
}

- (id)initWithViewController:(SolitaireViewController*)controller {
	self = [self init];
	_viewController = controller;
	return self;
}

- (void)shuffle { // good ol' O(N) fisher-yates
	srand(time(NULL));
	for (int i = 1; i < 52; i++) {
		int ii = rand() % i;
		SolitaireCard one = deck[i], two = deck[ii];
		deck[i] = two; deck[ii] = one;
	}
}

- (void)newGame:(id)sender {	
	int index = 0;
	[self shuffle];
	if (gameTimer != nil) [gameTimer invalidate];
	gameTimer = nil;
	playerScore = 0;
	timeElapsed = 0;
	[moves removeAllObjects];
	for (int i = 0; i < 52; i++) resetAttributes(&deck[i]);
	for (int i = 0; i < 7; i++) {
		CFMutableArrayRef theStack = (CFMutableArrayRef)CFArrayGetValueAtIndex(_tableStacks, i);
		CFArrayRemoveAllValues(theStack);
		for (int ii = 0; ii <= i; ii++) {
			SolitaireCard *newCard = &deck[index++];
			newCard->flipped = YES;
			CFArrayAppendValue(theStack, newCard);
		}
		((SolitaireCard*)CFArrayGetValueAtIndex(theStack, CFArrayGetCount(theStack) - 1))->flipped = NO;
		
		[[_viewController gameView] drawTableStack:i];
	}
	CFArrayRemoveAllValues(_drawPile.pile);
	_drawPile.passes = 0;
	_drawPile.index = 0;
	_drawPile.displayed = 0;
	for (; index < 52; index++) { 
		SolitaireCard *theCard = &deck[index];
		theCard->flipped = YES;
		CFArrayAppendValue(_drawPile.pile, theCard);
	}
	for (int i = 0; i < 4; i++)  {
		CFArrayRemoveAllValues((CFMutableArrayRef)CFArrayGetValueAtIndex(_foundations, i));
		[[_viewController gameView] drawFoundation:i];
	}
	memset(&currentSelection, 0, sizeof(SolitaireSelection));
	[[_viewController gameView] drawDrawPile];
	[[_viewController gameView] showScore:0];
	[[_viewController gameView] showTime:0];
}


- (void)hitDrawPile {
	if (timeElapsed == -1) return; 
	if (gameTimer == nil) gameTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tickTime:) userInfo:nil repeats:YES];
	SolitaireDrawPile snapshot = _drawPile;
	SolitaireCard *currentCard = NULL;
	BOOL shouldPenalise = NO, didPass = NO;
	[self clearSelection:&currentSelection];
	
	_drawPile.isPullingFromBelow = NO;
	
	for (int i = 1; i <= _drawPile.displayed; i++) {
		currentCard = (SolitaireCard*)CFArrayGetValueAtIndex(_drawPile.pile, _drawPile.index - i);
		currentCard->flipped = YES;
		currentCard->selected = NO;
	}
	
	NSInteger count = CFArrayGetCount(_drawPile.pile);
	_drawPile.displayed = 0;
	
	if (_drawPile.index == count) {
		if (++_drawPile.passes > 3) shouldPenalise = YES;
		_drawPile.index = 0;
		didPass = YES;
	}
	
	for (int i = 0; i < 3 && _drawPile.index != count && !didPass; i++) {
		currentCard = (SolitaireCard*)CFArrayGetValueAtIndex(_drawPile.pile, _drawPile.index++);
		currentCard->flipped = NO;
		_drawPile.displayed += 1;
	}
	
	SolitaireDrawPileMove *move = [SolitaireDrawPileMove hitDrawPile:shouldPenalise];
	[moves addObject:move];
	playerScore += move->penalty;
	if (playerScore < 0) playerScore = 0;
	move->snapshot = snapshot;
	[[_viewController gameView] showScore:playerScore];
	[[_viewController gameView] drawDrawPile];
}

- (void)select:(SolitaireSelection)selection {
	if (selection.selected == NULL) return;
	setCurrentSelection:
	if (currentSelection.selection == SolitaireStackNone && selection.selection != SolitaireStackNone && selection.index != -1) {
		SolitaireCard *selectedCard = (SolitaireCard*)CFArrayGetValueAtIndex(selection.selected, selection.index);
		if (selection.selection == SolitaireStackDrawPileDrawn && currentSelection.selected == _drawPile.pile) {
			if (_drawPile.displayed > 2 && selectedCard != (SolitaireCard*)CFArrayGetValueAtIndex(_drawPile.pile, _drawPile.index - 1)) return;
			if (_drawPile.displayed == 2 && selectedCard != (SolitaireCard*)CFArrayGetValueAtIndex(_drawPile.pile, _drawPile.index - 2)) return;
		}
		currentSelection = selection;
		selectedCard->selected = YES;
		if (selection.selection == SolitaireStackDrawPileDrawn && currentSelection.selected == _drawPile.pile) [[_viewController gameView] drawDrawPile];
		else {
			if (currentSelection.selection == SolitaireStackTable) [[_viewController gameView] drawTableStack:[self indexOfTableStack:currentSelection.selected]];
			else [[_viewController gameView] drawFoundation:[self indexOfFoundation:currentSelection.selected]];
		}
		return;
	} 
	else if (currentSelection.selection == SolitaireStackNone) return;
	
	SolitaireCard *currentSelectedCard = (SolitaireCard*)CFArrayGetValueAtIndex(currentSelection.selected, currentSelection.index);
	if (selection.selection == SolitaireStackDrawPileDrawn && currentSelection.selection != SolitaireStackDrawPileDrawn) {
		[self clearSelection:&currentSelection];
		goto setCurrentSelection;
	}
	
	SolitaireMove* theMove = [SolitaireMove makeMoveFrom:currentSelection to:selection];
	currentSelectedCard->selected = NO;
	void *selectionReference = currentSelection.selected;
	SolitaireStackType oldSelection = currentSelection.selection;
	memset(&currentSelection, 0, sizeof(SolitaireSelection));
	currentSelection.index = -1;
	if (theMove == nil) goto drawTheStacks;
	if (oldSelection == SolitaireStackDrawPileDrawn) sliceCardFromDrawPile(&_drawPile);
	playerScore += theMove->pointsAwarded;
	if (playerScore < 0) playerScore = 0;
	[[_viewController gameView] showScore:playerScore];
	[moves addObject:theMove];
	if (gameTimer == nil) gameTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tickTime:) userInfo:nil repeats:YES];
	
	drawTheStacks:
	switch (oldSelection) {
		case SolitaireStackTable: [[_viewController gameView] drawTableStack:[self indexOfTableStack:selectionReference]]; break;
		case SolitaireStackFoundation: [[_viewController gameView] drawFoundation:[self indexOfFoundation:selectionReference]]; break;
		case SolitaireStackDrawPileDrawn: [[_viewController gameView] drawDrawPile]; break;
		default: break;
	}
	switch (selection.selection) {
		case SolitaireStackTable: [[_viewController gameView] drawTableStack:[self indexOfTableStack:selection.selected]]; break;
		case SolitaireStackFoundation: [[_viewController gameView] drawFoundation:[self indexOfFoundation:selection.selected]]; break;
		default: break;
	}
	
	for (int i = 0; i < 4; i++) {
		CFMutableArrayRef theFoundation = (CFMutableArrayRef)CFArrayGetValueAtIndex(_foundations, i);
		if (CFArrayGetCount(theFoundation) < 1) return;
		if (getValue((SolitaireCard*)CFArrayGetValueAtIndex(theFoundation, CFArrayGetCount(theFoundation) - 1)) != SolitaireKing) return;
	}
	
	if (timeElapsed > 30) playerScore += 700000 / timeElapsed;
	UIAlertView *theView = [[[UIAlertView alloc] initWithTitle:@"You Win!" message:[NSString stringWithFormat:@"Score: %d\nTime: %d seconds", playerScore, timeElapsed] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] autorelease];
	[theView show];

	memset(&currentSelection, 0, sizeof(SolitaireSelection));
	
	[gameTimer invalidate];
	gameTimer = nil;
		
	timeElapsed = -1;
	
	for (int i = 0; i < 4; i++) {
		CFArrayRemoveAllValues((CFMutableArrayRef)CFArrayGetValueAtIndex(_foundations, i));
		[[_viewController gameView] drawFoundation:i];
	}
	for (int i = 0; i < 7; i++) { 
		CFArrayRemoveAllValues((CFMutableArrayRef)CFArrayGetValueAtIndex(_tableStacks, i));
		[[_viewController gameView] drawTableStack:i];
	}
	
	[[_viewController gameView] drawDrawPile];
	[[_viewController gameView] showTime:-1];
	[[_viewController gameView] showScore:-1];
}


- (void)clearSelection:(SolitaireSelection*)selection {
	switch (selection->selection) {
		case SolitaireStackTable: [[_viewController gameView] drawTableStack:[self indexOfTableStack:selection->selected]]; break;
		case SolitaireStackFoundation: [[_viewController gameView] drawFoundation:[self indexOfFoundation:selection->selected]]; break;
		case SolitaireStackDrawPileDrawn: [[_viewController gameView] drawDrawPile]; break;
		default: break;
	}
	memset(selection, 0, sizeof(SolitaireSelection));
	selection->index = -1;
	return;
}

- (void)undo:(id)sender {
	if ([moves count] < 1) return;
	id move = [moves lastObject];
	SolitaireDrawPileMove *hit = [move isMemberOfClass:[SolitaireDrawPileMove class]] ? move : nil;
	SolitaireMove *theMove = [move isMemberOfClass:[SolitaireMove class]] ? move : nil;
	if (hit != nil) {
		for (int i = 0; i < _drawPile.displayed; i++) ((SolitaireCard*)CFArrayGetValueAtIndex(_drawPile.pile, _drawPile.index - _drawPile.displayed + i))->flipped = YES;
		_drawPile = hit->snapshot;
		for (int i = 0; i < _drawPile.displayed; i++) ((SolitaireCard*)CFArrayGetValueAtIndex(_drawPile.pile, _drawPile.index - _drawPile.displayed + i))->flipped = NO;
		[[_viewController gameView] drawDrawPile];
	} else if (theMove->source.selection != SolitaireStackDrawPileDrawn) {
		if (theMove->source.selection == SolitaireStackTable && CFArrayGetCount(theMove->source.selected) > 0) 
			((SolitaireCard*)CFArrayGetValueAtIndex(theMove->source.selected, CFArrayGetCount(theMove->source.selected) - 1))->flipped = theMove->didRevealParent;
		CFRange range = CFRangeMake(theMove->receiver.index + 1, CFArrayGetCount(theMove->receiver.selected) - theMove->receiver.index - 1);
		CFArrayAppendArray(theMove->source.selected, theMove->receiver.selected, range);   
		CFArrayReplaceValues(theMove->receiver.selected, range, NULL, 0);
		switch (theMove->source.selection) {
			case SolitaireStackTable: [[_viewController gameView] drawTableStack:[self indexOfTableStack:theMove->source.selected]]; break;
			case SolitaireStackFoundation: [[_viewController gameView] drawFoundation:[self indexOfFoundation:theMove->source.selected]]; break;
			default: break;
		}
		switch (theMove->receiver.selection) {
			case SolitaireStackTable: [[_viewController gameView] drawTableStack:[self indexOfTableStack:theMove->receiver.selected]]; break;
			case SolitaireStackFoundation: [[_viewController gameView] drawFoundation:[self indexOfFoundation:theMove->receiver.selected]]; break;
			default: break;
		}
	} else {
		int index = CFArrayGetCount(theMove->receiver.selected) - 1;
		SolitaireCard *theCard = (SolitaireCard*)CFArrayGetValueAtIndex(theMove->receiver.selected, index);
		CFArrayRemoveValueAtIndex(theMove->receiver.selected, index);
		CFArrayInsertValueAtIndex(_drawPile.pile, _drawPile.index++, theCard);
		if (!_drawPile.isPullingFromBelow) _drawPile.displayed += 1;
		switch (theMove->receiver.selection) {
			case SolitaireStackTable: [[_viewController gameView] drawTableStack:[self indexOfTableStack:theMove->receiver.selected]]; break;
			case SolitaireStackFoundation: [[_viewController gameView] drawFoundation:[self indexOfFoundation:theMove->receiver.selected]]; break;
			default: break;
		}
		[[_viewController gameView] drawDrawPile];
	}
	
	playerScore -= theMove != nil ? theMove->pointsAwarded : (hit != nil ? hit->penalty : 0);
	if (playerScore < 0) playerScore = 0;
	[[_viewController gameView] showScore:playerScore];
	[moves removeLastObject];
}

- (void)tickTime:(NSTimer*)timer {
	timeElapsed += 1;
	if (timeElapsed % 10 == 0 && timeElapsed != 0) playerScore -= 2;
	if (playerScore < 0) playerScore = 0;
	[[_viewController gameView] showTime:timeElapsed];
	[[_viewController gameView] showScore:playerScore];
}

- (NSInteger)indexOfTableStack:(CFMutableArrayRef)theStack {
	for (int i = 0; i < 7; i++) {
		if (CFArrayGetValueAtIndex(_tableStacks, i) == theStack) return i;
	}
	return -1;
}
- (NSInteger)indexOfFoundation:(CFMutableArrayRef)theFoundation {
	for (int i = 0; i < CFArrayGetCount(_foundations); i++) {
		if (CFArrayGetValueAtIndex(_foundations, i) == theFoundation) return i;
	}
	return -1;
}

- (void)dealloc {
	// worry abt this later
	[super dealloc];
}
@end
