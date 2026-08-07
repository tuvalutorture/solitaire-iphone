//
//  SolitaireCard.m
//  Solitaire
//
//  Created by Xander Gomez on 7/24/26.
//  Copyright 2026 __MyCompanyName__. All rights reserved.
//

#import "SolitaireCard.h"
#import <CoreFoundation/CoreFoundation.h>
#import <stdlib.h>

// stupid statics
static BOOL assetsAreLoaded = NO;
static CGImageRef numberImages[13];
static CGImageRef suitImages[4];
static CGImageRef suitSmallImages[4];
static CGImageRef baseImage;
static CGImageRef backImage;
static CGColorSpaceRef colourSpace;

// tipsy, topsy, turvy, gimme yer money or i give ye scurvy. this aint even used to compensate for uikit ngl we just do it to draw the upside down halves of cards without making upside down ver
static inline void flipContextY(CGContextRef context, CGFloat contextHeight) { 
	CGContextTranslateCTM(context, 0.0f, contextHeight);
	CGContextScaleCTM(context, 1.0f, -1.0f);	
}

// removed flipContextX in favour of manual X changes in the switch cause flipping the X system via affine transforms every time is less optimised than just floating point subtraction lmao

CGImageRef loadPNG(CFStringRef fileName) {
	CFURLRef path = CFBundleCopyResourceURL(CFBundleGetMainBundle(), fileName, CFSTR("png"), NULL);
	CGDataProviderRef dataProvider = CGDataProviderCreateWithURL(path);
	CFRelease(path);
	CGImageRef theImage = CGImageCreateWithPNGDataProvider(dataProvider, NULL, YES, kCGRenderingIntentDefault);
	CGDataProviderRelease(dataProvider);
	return theImage;
}

void loadCardAssets(void) { // a helper function to avoid having to allocate things on the heap constantly and microwaving the poor samsung cpu
	CFStringRef cardNames[13] = { CFSTR("a"), CFSTR("2"), CFSTR("3"), CFSTR("4"), CFSTR("5"), CFSTR("6"), CFSTR("7"), CFSTR("8"), CFSTR("9"), CFSTR("10"), CFSTR("j"), CFSTR("q"), CFSTR("k") };
	CFStringRef suitNames[4] = { CFSTR("spade"), CFSTR("heart"), CFSTR("club"), CFSTR("diamond") };
	CFStringRef suitSmallNames[4] = { CFSTR("spade_small"), CFSTR("heart_small"), CFSTR("club_small"), CFSTR("diamond_small") };
	
	colourSpace = CGColorSpaceCreateDeviceRGB();
	baseImage = loadPNG(CFSTR("card_blank"));
	backImage = loadPNG(CFSTR("card_back"));
	
	for (int i = 0; i < 13; i++) {
		numberImages[i] = loadPNG((CFStringRef)cardNames[i]);
	}
	
	for (int i = 0; i < 4; i++) {
		suitImages[i] = loadPNG((CFStringRef)suitNames[i]);
		suitSmallImages[i] = loadPNG((CFStringRef)suitSmallNames[i]);
	}
	
	assetsAreLoaded = YES;
}

void deloadCardAssets(void) {
	CGImageRelease(baseImage);
	CGImageRelease(backImage);
	CGColorSpaceRelease(colourSpace);
	for (int i = 0; i < 13; i++) {
		CGImageRelease(numberImages[i]);
	}
		
	for (int i = 0; i < 4; i++) {
		CGImageRelease(suitImages[i]);
		CGImageRelease(suitSmallImages[i]);
	}
	assetsAreLoaded = NO;
}

CGImageRef createImageWithInvertedColour(CGImageRef source) {
	CGFloat height = CGImageGetHeight(source), width = CGImageGetWidth(source);
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, 0, space, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	CGRect theRect = CGRectMake(0.0f, 0.0f, width, height);
	CGContextClipToMask(context, theRect, source);
	CGFloat colourComponents[4] = { 1.0f, 1.0f, 1.0f, 1.0f };
	CGColorRef whiteColour = CGColorCreate(space, colourComponents);
	CGColorSpaceRelease(space);
	CGContextSetFillColorWithColor(context, whiteColour);
	CGContextFillRect(context, theRect);
	CGColorRelease(whiteColour);
	CGContextSetBlendMode(context, kCGBlendModeDifference);
	CGContextDrawImage(context, theRect, source);
	CGImageRef final = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	return final;
}

CGImageRef compositeCard(SolitaireCardValue card) { // pure, cg glory. make sure to load in your components first before running 
	SolitaireValue value = card & SolitaireValueMask; 
	char suit;
	switch ((card & SolitaireSuitMask)) {
		case SolitaireSpade: suit = 0; break;
		case SolitaireHeart: suit = 1; break;
		case SolitaireClub: suit = 2; break;
		case SolitaireDiamond: suit = 3; break;
		default: break;
	}
	CGImageRef suitImage = suitImages[suit], numberImage = numberImages[value];
	CGFloat cardWidth = CGImageGetWidth(baseImage), cardHeight = CGImageGetHeight(baseImage);
	
	CGContextRef cardContext = CGBitmapContextCreate(NULL, cardWidth, cardHeight, 8, 0, colourSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	
	CGContextDrawImage(cardContext, CGRectMake(0.0f, 0.0f, cardWidth, cardHeight), baseImage);
	
	CGFloat numberWidth = CGImageGetWidth(numberImage), numberHeight = CGImageGetHeight(numberImage);
	CGFloat suitImageSmallWidth = CGImageGetWidth(suitSmallImages[suit]), suitImageSmallHeight = CGImageGetHeight(suitSmallImages[suit]);
	CGFloat identifierWidth = ((numberWidth > suitImageSmallWidth) ? numberWidth : suitImageSmallWidth), identifierHeight = suitImageSmallHeight + numberHeight + 1;
	
	CGRect identifierFrame = CGRectMake(0.0f, 0.0f, identifierWidth, identifierHeight);
	CGContextRef identifierContext = CGBitmapContextCreate(NULL, identifierWidth, identifierHeight, 8, 0, colourSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	
	CGContextDrawImage(identifierContext, CGRectMake(0.0f, 0.0f, suitImageSmallWidth, suitImageSmallHeight), suitSmallImages[suit]);
	CGContextDrawImage(identifierContext, CGRectMake(0.0f, suitImageSmallHeight + 1, numberWidth, numberHeight), numberImage);
	
	CGImageRef recolourMask = CGBitmapContextCreateImage(identifierContext);	
	CGContextClipToMask(identifierContext, identifierFrame, recolourMask);
	CGFloat colourComponents[4] = { (CGFloat)((card & SolitaireSuitMask) == SolitaireHeart || (card & SolitaireSuitMask) == SolitaireDiamond), 0.0f, 0.0f, 1.0f };
	CGColorRef newColour = CGColorCreate(colourSpace, colourComponents);
	CGContextSetFillColorWithColor(identifierContext, newColour);
	CGContextFillRect(identifierContext, identifierFrame);
	CGColorRelease(newColour);
	CGImageRelease(recolourMask);
	
	CGImageRef identifierImage = CGBitmapContextCreateImage(identifierContext);
	if (value > SolitaireTen) numberImage = CGImageCreateWithImageInRect(identifierImage, CGRectMake(0.0f, 0.0f, numberWidth, numberHeight));
	CGContextRelease(identifierContext);
		
	identifierFrame.origin = CGPointMake(4.0f, cardHeight - identifierHeight - 4.0f);
	
	CGContextDrawImage(cardContext, identifierFrame, identifierImage);
	flipContextY(cardContext, cardHeight);
	CGContextTranslateCTM(cardContext, cardWidth, 0.0f);
	CGContextScaleCTM(cardContext, -1.0f, 1.0f);	
	CGContextDrawImage(cardContext, identifierFrame, identifierImage);
	CGImageRelease(identifierImage);
	CGContextTranslateCTM(cardContext, cardWidth, 0.0f);
	CGContextScaleCTM(cardContext, -1.0f, 1.0f);	
	flipContextY(cardContext, cardHeight);
		
	CGFloat contentWidth = cardWidth - (12.0f * 2);
	CGFloat contentHeight = cardHeight - (12.0f * 2);
	CGRect contentFrame = CGRectMake(12.0f, 12.0f, contentWidth, contentHeight);
	CGContextRef theContext = CGBitmapContextCreate(NULL, contentWidth, contentHeight, 8, 0, colourSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
		
	CGFloat suitHeight = CGImageGetHeight(suitImage);
	CGFloat suitWidth = CGImageGetWidth(suitImage);
	CGRect currentFrame = CGRectMake(0.0f, 0.0f, suitWidth, suitHeight);
	switch (value) {
		case SolitaireJack:
		case SolitaireQueen:
		case SolitaireKing:
			contentFrame.size.height -= 16.0f;
			contentFrame.size.width -= 8.0f;
			contentFrame.origin.x += 4.0f;
			contentFrame.origin.y += 8.0f;
			CGContextDrawImage(theContext, CGRectMake(0.0f, 0.0f, contentWidth, contentHeight), numberImage);
			CGImageRelease(numberImage);
			break;
			
		case SolitaireThree:
		case SolitaireTwo: 
			currentFrame = CGRectMake((contentWidth / 2) - (suitWidth / 2), contentHeight - suitHeight, suitWidth, suitHeight);
			CGContextDrawImage(theContext, currentFrame, suitImage);
			flipContextY(theContext, contentHeight);
			CGContextDrawImage(theContext, currentFrame, suitImage);
			flipContextY(theContext, contentHeight); 
			if (value != SolitaireThree) break;
			else goto makeCentrePoint;
			
		case SolitaireSeven:
			CGContextDrawImage(theContext, CGRectMake((contentWidth / 2) - (suitWidth / 2), (contentHeight / 2) + (suitHeight / 2), suitWidth, suitHeight), suitImage);
		case SolitaireSix:
			currentFrame = CGRectMake(0.0f, (contentHeight / 2) - (suitHeight / 2), suitWidth, suitHeight);
			CGContextDrawImage(theContext, currentFrame, suitImage);
			currentFrame.origin.x = contentWidth - suitWidth;
			CGContextDrawImage(theContext, currentFrame, suitImage);
			goto makeFour;
			
		case SolitaireTen:
			currentFrame = CGRectMake((contentWidth / 2) - (suitWidth / 2), contentHeight - (suitHeight * 1.5), suitWidth, suitHeight);
			CGContextDrawImage(theContext, currentFrame, suitImage);
			flipContextY(theContext, contentHeight);
			CGContextDrawImage(theContext, currentFrame, suitImage);
			flipContextY(theContext, contentHeight);
		case SolitaireNine:
		case SolitaireEight:
			currentFrame = CGRectMake(0.0f, contentHeight - ((suitHeight * 2) + 1), suitWidth, suitHeight);
			CGContextDrawImage(theContext, currentFrame, suitImage);
			currentFrame.origin.x = contentWidth - suitWidth;
			CGContextDrawImage(theContext, currentFrame, suitImage);
			flipContextY(theContext, contentHeight);
			CGContextDrawImage(theContext, currentFrame, suitImage);
			currentFrame.origin.x = 0.0f;
			CGContextDrawImage(theContext, currentFrame, suitImage);
			flipContextY(theContext, contentHeight);			
		case SolitaireFive:
		case SolitaireFour:
		makeFour:
			currentFrame = CGRectMake(0.0f, contentHeight - suitHeight, suitWidth, suitHeight);
			CGContextDrawImage(theContext, currentFrame, suitImage);
			currentFrame.origin.x = contentWidth - suitWidth;
			CGContextDrawImage(theContext, currentFrame, suitImage);
			flipContextY(theContext, contentHeight);
			CGContextDrawImage(theContext, currentFrame, suitImage);
			currentFrame.origin.x = 0.0f;
			CGContextDrawImage(theContext, currentFrame, suitImage);
			flipContextY(theContext, contentHeight);
			if (value != SolitaireFive && value != SolitaireNine) break;  
		case SolitaireAce:
		makeCentrePoint:
			CGContextDrawImage(theContext, CGRectMake((contentWidth / 2) - (suitWidth / 2), (contentHeight / 2) - (suitHeight / 2), suitWidth, suitHeight), suitImage);
			break;
		default: break;
	}
	
	CGImageRef contentImage = CGBitmapContextCreateImage(theContext);
	CGContextRelease(theContext);
	CGContextDrawImage(cardContext, contentFrame, contentImage);
	CGImageRelease(contentImage);
	CGImageRef cardImage = CGBitmapContextCreateImage(cardContext);
	CGContextRelease(cardContext);
	
	return cardImage;
}

CGImageRef compositeStack(SolitaireCard *firstCard) {
	int cardCount = 1, flipped = 0;
	SolitaireCard *currentCard = firstCard;
	while ((currentCard = currentCard->child) != NULL) { 
		cardCount++;
		flipped += currentCard->flipped;
	}
	currentCard = firstCard;
	
	CGFloat height = (cardCount - 1 - flipped) * (15.0f - (cardCount / 2) - (cardCount >= 13)) + firstCard->height + ((11.0f - (cardCount / 2) - (cardCount >= 13)) * flipped);
	CGColorSpaceRef compositorColourSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef compositorContext = CGBitmapContextCreate(NULL, firstCard->width, height, 8, 0, compositorColourSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	CGColorSpaceRelease(compositorColourSpace);
	
	CGRect imageRect = CGRectMake(0.0f, height - firstCard->height, firstCard->width, firstCard->height);
	while (currentCard != NULL) {
		CGContextDrawImage(compositorContext, imageRect, getImage(currentCard));
		imageRect.origin.y -= (currentCard->flipped ? 11.0f : 15.0f) - (cardCount / 2) - (cardCount >= 13);
		currentCard = currentCard->child;
	}
	CGImageRef compositedStack = CGBitmapContextCreateImage(compositorContext);
	CGContextRelease(compositorContext);
	return compositedStack;
}

SolitaireCard newSolitaireCard(SolitaireCardValue card) {
	SolitaireCard newCard;
	memset(&newCard, 0, sizeof(SolitaireCard));
	BOOL assetsAreLoadedAtCreate = assetsAreLoaded;
	if (!assetsAreLoadedAtCreate) loadCardAssets();
	newCard.faceImage = compositeCard(card);
	newCard.backImage = backImage;
	newCard.inverted = createImageWithInvertedColour(newCard.faceImage);
	CGImageRetain(backImage);
	newCard.value = card;
	newCard.height = CGImageGetHeight(newCard.faceImage);
	newCard.width = CGImageGetWidth(newCard.faceImage);
	if (!assetsAreLoadedAtCreate) deloadCardAssets();
	return newCard;
}

void releaseSolitaireCard(SolitaireCard* card) {
	CGImageRelease(card->faceImage);
	CGImageRelease(card->backImage);
	CGImageRelease(card->inverted);
}
