//
//  SolitaireViewController.m
//  Solitaire
//
//  Created by Xander Gomez on 7/24/26.
//  Copyright __MyCompanyName__ 2026. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SolitaireViewController.h"
#import "SolitaireGameController.h"

@class SolitaireViewController;

@implementation SolitaireGameView
@synthesize context = _context;
- (id)initWithGameController:(SolitaireGameController*)theController {
	self = [self init];
	blankImage = loadPNG(CFSTR("slot_blank"));
	_foundations = [theController foundations];
	_tableStacks = [theController tableStacks];
	_drawPile = [theController drawPile];
	controller = theController;
	[self setUserInteractionEnabled:YES];
	timeView = [UITextField new];
	[timeView setBorderStyle:UITextBorderStyleRoundedRect];
	[timeView setUserInteractionEnabled:NO];
	[timeView setTextAlignment:UITextAlignmentLeft];
	[timeView setFont:[UIFont systemFontOfSize:12.0f]];
	[timeView setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
	[self addSubview:timeView];
	[timeView release];
	gameButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[gameButton addTarget:theController action:@selector(newGame:) forControlEvents:UIControlEventTouchUpInside];
	[gameButton setTitle:@"New Game" forState:UIControlStateNormal];
	[self addSubview:gameButton];
	scoreView = [UITextField new];
	[scoreView setBorderStyle:UITextBorderStyleRoundedRect];
	[scoreView setUserInteractionEnabled:NO];
	[scoreView setTextAlignment:UITextAlignmentRight];
	[scoreView setFont:[UIFont systemFontOfSize:12.0f]];
	[scoreView setContentVerticalAlignment:UIControlContentVerticalAlignmentCenter];
	[self addSubview:scoreView];
	[scoreView release];
	[self showTime:-1];
	[self showScore:-1];
	return self;
}

- (void)render {
	CGImageRef rendered = CGBitmapContextCreateImage(_context);
	[self setImage:[UIImage imageWithCGImage:rendered]];
	CGImageRelease(rendered);
}

- (void)resize:(CGSize)newSize {
	CGRect newFrame = [self frame];
	newFrame.size = newSize; // my math means it shooooould never exceed the bounds and clip into the buttons, key word should
	[self setFrame:newFrame];
	if (_context != NULL) CGContextRelease(_context);
	CGFloat cardHeight = CGImageGetHeight(blankImage), cardWidth = CGImageGetWidth(blankImage);
	CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
	_context = CGBitmapContextCreate(NULL, newSize.width, newSize.height, 8, 0, colourSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	CGColorSpaceRelease(colourSpace);
	drawPileFrame = CGRectMake(SolitaireViewPadding, newSize.height - SolitaireViewPadding - cardHeight, cardWidth, cardHeight);
	CGRect drawPileCardFame = drawPileFrame;
	drawPileCardFame.origin.x += SolitaireViewPadding * 2 + drawPileFrame.size.width;
	for (int i = 0; i < 3; i++) {
		drawPileCardFrames[i] = drawPileCardFame;
		drawPileCardFame.origin.x += SolitaireViewPadding;
	}
	[self drawDrawPile];
	CGRect foundationFrame = CGRectMake(newSize.width - cardWidth - SolitaireViewPadding, drawPileFrame.origin.y, cardWidth, cardHeight);
	for (int i = 3; i >= 0; i--) {
		foundationFrames[i] = foundationFrame;
		[self drawFoundation:i];
		foundationFrame.origin.x -= SolitaireViewPadding + foundationFrame.size.width;
	}
	CGRect tableStackFrame = CGRectMake(SolitaireViewPadding * 2, drawPileFrame.origin.y - SolitaireViewPadding - cardHeight, cardWidth, cardHeight);
	CGFloat tableStackSpace = (newSize.width - (SolitaireViewPadding * 4) - (cardWidth * 7)) / 6.0f;
	for (int i = 0; i < 7; i++) {
		tableStackFrames[i] = tableStackFrame;
		[self drawTableStack:i];
		tableStackFrame.origin.x += tableStackSpace + cardWidth;
	}
	[self render];
	CGRect elementRect = CGRectMake(SolitaireViewPadding, newSize.height - SolitaireBottomHeight - 2, (newSize.width - (SolitaireViewPadding * 5)) / 4, SolitaireBottomHeight);
	[timeView setFrame:elementRect];
	elementRect.origin.x += SolitaireViewPadding + elementRect.size.width;
	CGFloat gameSize = SolitaireViewPadding + elementRect.size.width * 2;
	[gameButton setFrame:CGRectMake(elementRect.origin.x, elementRect.origin.y, gameSize, elementRect.size.height)];
	elementRect.origin.x += gameSize + SolitaireViewPadding;
	[scoreView setFrame:elementRect];
}

- (void)drawTableStack:(NSInteger)targetTableStack {
	if (targetTableStack >= 7 || targetTableStack < 0) return;
	SolitaireTableStack tableStack = _tableStacks[targetTableStack];
	CGRect frame = tableStackFrames[targetTableStack];
	CGContextClearRect(_context, frame);
	if (tableStack.topCard == NULL) {
		CGFloat newY = frame.origin.y + (tableStackFrames[targetTableStack].size.height - CGImageGetHeight(blankImage));
		tableStackFrames[targetTableStack] = CGRectMake(frame.origin.x, newY, CGImageGetWidth(blankImage), CGImageGetHeight(blankImage)); 
		CGContextDrawImage(_context, tableStackFrames[targetTableStack], blankImage);
		return;
	}
	CGImageRef renderedStack = compositeStack(tableStack.topCard);
	CGFloat height = CGImageGetHeight(renderedStack);
	frame.origin.y = [self frame].size.height - (SolitaireViewPadding * 2) - height - CGImageGetHeight(blankImage);
	frame.size.height = height;
	tableStackFrames[targetTableStack] = frame;
	CGContextDrawImage(_context, frame, renderedStack);
	CGImageRelease(renderedStack);
	[self render];
}
- (void)drawFoundation:(NSInteger)targetFoundation {
	if (targetFoundation >= 4 || targetFoundation < 0) return;
	SolitaireFoundation theFoundation = _foundations[targetFoundation];
	CGRect theFrame = foundationFrames[targetFoundation];
	CGContextClearRect(_context, theFrame);
	if (theFoundation == NULL) CGContextDrawImage(_context, theFrame, blankImage);
	else CGContextDrawImage(_context, theFrame, getImage((SolitaireCard*)theFoundation));
	[self render];
}
- (void)drawDrawPile {
	CGContextClearRect(_context, drawPileFrame);
	CGContextDrawImage(_context, drawPileFrame, _drawPile->pile == NULL ? blankImage : getImage(_drawPile->pile));
	for (int i = 0; i < 3; i++) CGContextClearRect(_context, drawPileCardFrames[i]);
	if (_drawPile->first) CGContextDrawImage(_context, drawPileCardFrames[0], getImage(_drawPile->first)); 
	if (_drawPile->second != NULL) CGContextDrawImage(_context, drawPileCardFrames[1], getImage(_drawPile->second));
	if (_drawPile->third != NULL) CGContextDrawImage(_context, drawPileCardFrames[2], getImage(_drawPile->third));
	[self render];
}

- (SolitaireTableStack*)stackForPoint:(CGPoint)point {	
	for (int i = 0; i < 7; i++) {
		if (CGRectContainsPoint(tableStackFrames[i], point)) return &_tableStacks[i];
	}
	return NULL;
}
- (SolitaireFoundation*)foundationForPoint:(CGPoint)point {
	for (int i = 0; i < 4; i++) {
		if (CGRectContainsPoint(foundationFrames[i], point)) return &_foundations[i];
	}
	return NULL;
}
- (SolitaireDrawPile*)drawPileForPoint:(CGPoint)point {
	return CGRectContainsPoint(drawPileFrame, point) ? _drawPile : NULL;
}

- (SolitaireCard*)tableStackCard:(CGPoint)point {
	SolitaireTableStack *stack = [self stackForPoint:point];
	if (stack == NULL || stack->topCard == NULL || stack->bottomCard == NULL) return NULL;
	int count = 0;
	SolitaireCard *cardCounter = stack->topCard;
	while (cardCounter != NULL) {
		cardCounter = cardCounter->child;
		count += 1;
	}
	CGFloat distance = 15.0f - (count / 2) - (count >= 13);
	CGRect baseFrame;
	for (int i = 0; i < 7; i++) {
		if (CGRectContainsPoint((baseFrame = tableStackFrames[i]), point)) break;
	}
	baseFrame.size.width = stack->bottomCard->width;
	baseFrame.size.height = stack->bottomCard->height;
	if (CGRectContainsPoint(baseFrame, point)) return stack->bottomCard;
	SolitaireCard *currentCard = stack->bottomCard->parent;
	CGRect currentFrame = baseFrame;
	currentFrame.size.height = distance;
	currentFrame.origin.y += baseFrame.size.height;
	for (int i = 1; i < count && currentCard != NULL; i++) {
		if (CGRectContainsPoint(currentFrame, point) && !currentCard->flipped) return currentCard;
		currentCard = currentCard->parent;
		currentFrame.origin.y += distance;
		if (currentFrame.origin.y > point.y) break;
	}
	return NULL;
}
- (SolitaireCard*)drawPileCard:(CGPoint)point {
	CGRect hitTest = drawPileCardFrames[0];
	hitTest.size.width = (drawPileCardFrames[2].origin.x + drawPileCardFrames[2].size.width) - drawPileCardFrames[0].origin.x;
	if (!CGRectContainsPoint(hitTest, point)) return NULL;
	CGFloat x = point.x;
	CGFloat low = drawPileCardFrames[0].origin.x;
	CGFloat high = _drawPile->second != NULL ? low + SolitaireViewPadding : low + drawPileCardFrames[0].size.width;
	if (x >= low && x <= high) return _drawPile->first;
	low = high;
	high += _drawPile->third != NULL ? SolitaireViewPadding : drawPileCardFrames[1].size.width;
	if (x >= low && x <= high) return _drawPile->second;
	low = high;
	high += drawPileCardFrames[2].size.width;
	if (x >= low && x <= high) return _drawPile->third;
	return NULL;
}

- (CGPoint)convertToCGPointFromUIKitPoint:(CGPoint)UIKitPoint {
	CGPoint newPoint = UIKitPoint;
	newPoint.y = [self frame].size.height - UIKitPoint.y;
	return newPoint;
}

- (void)clicked:(CGPoint)atPoint {
	SolitaireSelection selection;
	memset(&selection, 0, sizeof(SolitaireSelection));
	selection.selection = SolitaireStackNone;
	SolitaireDrawPile *pile;
	if ((pile = [self drawPileForPoint:atPoint]) != NULL) {
		[controller hitDrawPile];
		goto sendSelection;
	}
	SolitaireCard *drawnCard;
	if ((drawnCard = [self drawPileCard:atPoint]) != NULL) {
		selection.selection = SolitaireStackDrawPileDrawn;
		selection.selectedCard = drawnCard;
		selection.selectionReference = _drawPile;
		goto sendSelection;
	}
	SolitaireTableStack *stack;
	if ((stack = [self stackForPoint:atPoint]) != NULL) {
		SolitaireCard* theCard = [self tableStackCard:atPoint];
		selection.selection = SolitaireStackTable;
		selection.selectedCard = theCard;
		selection.selectionReference = stack;
		goto sendSelection;
	}
	SolitaireFoundation *theFoundation;
	if ((theFoundation = [self foundationForPoint:atPoint]) != NULL) {
		selection.selection = SolitaireStackFoundation;
		selection.selectedCard = *theFoundation;
		selection.selectionReference = theFoundation;
		goto sendSelection;
	}
	
	sendSelection: [controller select:selection]; // saves lines, doesn't horribly murder control flow, valid-ish i'd say
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
	[self clicked:[self convertToCGPointFromUIKitPoint:[[touches anyObject] locationInView:self]]];
}

- (void)showTime:(int)seconds {
	if (seconds == -1) { 
		[timeView setText:@"Time:"];
		return;
	}
	int minutes = seconds / 60;
	seconds -= minutes * 60;
	int hours = minutes / 60;
	minutes -= hours * 60;
	if (hours > 0) {
		[timeView setText:[NSString stringWithFormat:@"Time: %d:%02d:02d", hours, minutes, seconds]];
	} else {
		[timeView setText:[NSString stringWithFormat:@"Time: %01d:%02d", minutes, seconds]];
	}
}
- (void)showScore:(NSInteger)score {
	if (score == -1) {
		[scoreView setText:@"Score:"];
		return;
	}
	[scoreView setText:[NSString stringWithFormat:@"Score: %d", score]];
}

- (void)dealloc {	
	CGContextRelease(_context);
	CGImageRelease(blankImage);
	[super dealloc];
}
@end


@implementation SolitaireViewController
@synthesize gameView = _gameView;

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


- (void)viewDidLoad { 
    [super viewDidLoad];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
	[[self view] setBackgroundColor:[UIColor colorWithRed:0.04f green:0.6f blue:0.15f alpha:1.0f]];	
	
	gameController = [[SolitaireGameController alloc] initWithViewController:self];
}

- (void)viewDidAppear:(BOOL)animated { // the reason we use height and width backwards here is because the device has not yet oriented to be sideways hence we need to grab the opposing ways yk
	[super viewDidAppear:animated];
	CGRect frame = CGRectMake(0.0f, 0.0f, [[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width - 20);
	NSLog(@"%f %f", frame.size.height, frame.size.width);
	
	_gameView = [[SolitaireGameView alloc] initWithGameController:gameController];
	
	[[self view] addSubview:_gameView];
	[_gameView setFrame:frame];
	[_gameView resize:frame.size];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)dealloc {
	[gameController release];
	[_gameView release];
    [super dealloc];
}

@end
