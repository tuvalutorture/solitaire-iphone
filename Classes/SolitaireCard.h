//
//  SolitaireCard.h
//  Solitaire
//
//  Created by Xander Gomez on 7/24/26.
//  Copyright 2026 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define SolitaireSuitMask 0xF0
#define SolitaireValueMask 0x0F
typedef char SolitaireCardValue; 
typedef struct SolitaireCard SolitaireCard;

typedef enum {
	SolitaireAce,
	SolitaireTwo,
	SolitaireThree,
	SolitaireFour,
	SolitaireFive,
	SolitaireSix,
	SolitaireSeven,
	SolitaireEight,
	SolitaireNine,
	SolitaireTen,
	SolitaireJack,
	SolitaireQueen,
	SolitaireKing,
	SolitaireNoValue
} SolitaireValue;

typedef enum {
	SolitaireNoSuit,
	SolitaireSpade = 16,
	SolitaireHeart = 32,
	SolitaireClub = 64,
	SolitaireDiamond = 128,
} SolitaireSuit;

struct SolitaireCard { // does not need to be an objc object ffs. anyways we typedef'd this above so we don't need to re-typedef
	CGImageRef faceImage;
	CGImageRef backImage;
	CGImageRef inverted;
	BOOL flipped;
	BOOL selected;
	SolitaireCardValue value; // saves memory (up to 2 bytes per card, not a lot but 52 cards across 128mb and that do add up) and looks kewler to do bitwise shit
	CGFloat height; // takes extra bytes but is worth holding for speed
	CGFloat width;
};

CGImageRef loadPNG(CFStringRef);

CGImageRef compositeCard(SolitaireCardValue);
CGImageRef compositeStack(CFArrayRef);

void loadCardAssets(void);
void deloadCardAssets(void);

SolitaireCard newSolitaireCard(SolitaireCardValue); // it's best practice to call loadCardAssets / deloadCardAssets if you're doing this in a loop, but if you are loading once we do it for ya
void releaseSolitaireCard(SolitaireCard*); // doesnt actually free a heap instance, just releases the images that are held by the card struct

static inline SolitaireValue getValue(SolitaireCard* card) {
	if (card == NULL) return SolitaireNoValue;
	return card->value & SolitaireValueMask;
}
static inline SolitaireSuit getSuit(SolitaireCard* card) {
	if (card == NULL) return SolitaireNoSuit;
	return card->value & SolitaireSuitMask;
}
static inline CGImageRef getImage(SolitaireCard* card) {
	return card->flipped ? card->backImage : (card->selected ? card->inverted : card->faceImage);
}
static inline void resetAttributes(SolitaireCard* card) { // resets all OPTIONAL attributes to 0, while retaining any important data like size / images / value
	card->flipped = NO;
	card->selected = NO;
}