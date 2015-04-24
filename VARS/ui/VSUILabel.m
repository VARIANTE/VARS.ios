/**
 *  VARSobjc
 *  (c) VARIANTE <http://variante.io>
 *
 *  This software is released under the MIT License:
 *  http://www.opensource.org/licenses/mit-license.php
 */

#import "vsmem.h"
#import "VSUILabel.h"

/**
 *  Default UUID.
 */
static const int DEFAULT_UUID = -1;

#pragma mark - INTERFACE

/*
 *  @inheritdoc
 */
@interface VSUILabel()
{
@private
    VSUIViewUpdate *_updateDelegate;
}

#pragma mark - INTERFACE METHODS
#pragma mark - Event Handling

/**
 *  @private
 *
 *  Handler invoked when the menu should be revealed.
 *
 *  @param gestureRecognizer
 */
- (void)_onRevealMenu:(UIGestureRecognizer *)gestureRecognizer;

/**
 *  @private
 *
 *  Handler invoked when the menu should be hidden.
 *
 *  @param gestureRecognizer
 */
- (void)_onHideMenu:(UIGestureRecognizer *)gestureRecognizer;

@end

#pragma mark - IMPLEMENTATION

/*
 *  @inheritdoc
 */
@implementation VSUILabel

#pragma mark - PROTOCOL PROPERTIES
#pragma mark - Drawing

/*
 *  @inheritdoc VSUIViewUpdateDelegate
 */
- (VSUIViewUpdate *)updateDelegate
{
    if (_updateDelegate != nil) return _updateDelegate;

    _updateDelegate = [[VSUIViewUpdate alloc] init];
    [_updateDelegate setDelegate:self];

    return _updateDelegate;
}

/*
 *  @inheritdoc VSUIViewUpdateDelegate
 */
- (UIInterfaceOrientation)interfaceOrientation
{
    return [self.updateDelegate interfaceOrientation];
}

/*
 *  @inheritdoc VSUIViewUpdateDelegate
 */
- (void)setInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [self.updateDelegate setInterfaceOrientation:interfaceOrientation];
}

#pragma mark - PROPERTIES
#pragma mark - Identifier

/*
 *  @inheritdoc
 */
@synthesize UUID = _uUID;

#pragma mark - Data

/*
 *  @inheritdoc UILabel
 */
- (void)setText:(NSString *)text
{
    [super setText:text];
    [self.updateDelegate setDirty:VSUIDirtyTypeData];
}

#pragma mark - Behaviors

/*
 *  @inheritdoc
 */
@synthesize menuEnabled = _menuEnabled;

/*
 *  @inheritdoc
 */
- (void)setMenuEnabled:(BOOL)menuEnabled
{
    _menuEnabled = menuEnabled;

    [self setUserInteractionEnabled:YES];
}

/*
 *  @inheritdoc
 */
@synthesize shouldRedirectTouchesToNextResponder = _shouldRedirectTouchesToNextResponder;

/*
 *  @inheritdoc
 */
@synthesize menuGesturesEnabled = _menuGesturesEnabled;

#pragma mark - Styles

/*
 *  @inheritdoc
 */
@synthesize textEdgeInsets = _textEdgeInsets;

#pragma mark - PROTOCOL METHODS
#pragma mark - Updating

/*
 *  @inheritdoc VSUIViewUpdateDelegate
 */
- (void)setNeedsUpdate
{
    [self setNeedsDisplay];
}

/*
 *  @inheritdoc VSUIViewUpdateDelegate
 */
- (void)update
{
    [self.updateDelegate viewDidUpdate];
}

/*
 *  @inheritdoc VSUIViewUpdateDelegate
 */
- (BOOL)isDirty:(VSUIDirtyType)dirtyType
{
    return [self.updateDelegate isDirty:dirtyType];
}

#pragma mark - INSTANCE METHODS
#pragma mark - Lifecycle

/*
 *  @inheritdoc UIView
 */
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        [self setUUID:DEFAULT_UUID];
        [self didInit];
    }

    return self;
}

/*
 *  @inheritdoc
 */
- (id)initWithFrame:(CGRect)frame UUID:(int)UUID
{
    self = [super initWithFrame:frame];

    if (self)
    {
        [self setUUID:UUID];
        [self didInit];
    }

    return self;
}

/*
 *  @inheritdoc
 */
- (id)initWithUUID:(int)UUID
{
    self = [self initWithFrame:CGRectZero UUID:UUID];

    return self;
}

/*
 *  @inheritdoc NSObject
 */
- (void)dealloc
{
    [self willDealloc];

#if !__has_feature(objc_arc)
    [super dealloc];
#endif
}

/*
 *  @inheritdoc
 */
- (void)didInit
{
    [self setTextEdgeInsets:UIEdgeInsetsZero];
    [self setShouldRedirectTouchesToNextResponder:NO];
    [self setMenuGesturesEnabled:YES];

    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_onRevealMenu:)];
    [self addGestureRecognizer:longPressGestureRecognizer];
    vs_dealloc(longPressGestureRecognizer);

    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_onHideMenu:)];
    [singleTapGestureRecognizer setNumberOfTapsRequired:1];
    [self addGestureRecognizer:singleTapGestureRecognizer];
    vs_dealloc(singleTapGestureRecognizer);

    [self.updateDelegate viewDidInit];
}

/*
 *  @inheritdoc
 */
- (void)willDealloc
{
    vs_dealloc(_updateDelegate);
}

#pragma mark - Layout

/*
 *  @inheritdoc
 */
- (void)layoutSubviews
{
    [super layoutSubviews];

    [self.updateDelegate setDirty:VSUIDirtyTypeLayout];
}

#pragma mark - Drawing

/*
 *  @inheritdoc UIView
 */
- (void)drawRect:(CGRect)rect
{
    [self update];

    [super drawRect:rect];
}

/*
 *  @inheritdoc UILabel
 */
- (void)drawTextInRect:(CGRect)rect
{
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.textEdgeInsets)];
}

#pragma mark - Behaviors

/*
 *  @inheritdoc UIResponder
 */
- (BOOL)canBecomeFirstResponder
{
    return self.menuEnabled;
}

/*
 *  @inheritdoc UIResponder
 */
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (self.menuEnabled)
    {
        return (action == @selector(copy:) || action == @selector(paste:));
    }
    else
    {
        return NO;
    }
}

/*
 *  @inheritdoc
 */
- (void)copy:(id)sender
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setString:self.text];
}

/*
 *  @inheritdoc
 */
- (void)paste:(id)sender
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [self setText:pasteboard.string];
}

/*
 *  @inheritdoc
 */
- (void)revealMenu
{
    if (!self.menuEnabled) return;

    [self becomeFirstResponder];

    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setTargetRect:self.frame inView:self.superview];
    [menu setMenuVisible:YES animated:YES];
}

/*
 *  @inheritdoc
 */
- (void)hideMenu
{
    if (!self.menuEnabled) return;

    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setMenuVisible:NO animated:YES];

    [self resignFirstResponder];
}

#pragma mark - Event Handling

/*
 *  @inheritdoc UIResponder
 */
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.shouldRedirectTouchesToNextResponder)
    {
        [self.nextResponder touchesBegan:touches withEvent:event];
    }
    else
    {
        [super touchesBegan:touches withEvent:event];
    }
}

/*
 *  @inheritdoc UIResponder
 */
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.shouldRedirectTouchesToNextResponder)
    {
        [self.nextResponder touchesMoved:touches withEvent:event];
    }
    else
    {
        [super touchesMoved:touches withEvent:event];
    }
}

/*
 *  @inheritdoc UIResponder
 */
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.shouldRedirectTouchesToNextResponder)
    {
        [self.nextResponder touchesEnded:touches withEvent:event];
    }
    else
    {
        [super touchesEnded:touches withEvent:event];
    }
}

/*
 *  @inheritdoc UIResponder
 */
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.menuGesturesEnabled) return;

    if (self.shouldRedirectTouchesToNextResponder)
    {
        [self.nextResponder touchesCancelled:touches withEvent:event];
    }
    else
    {
        [super touchesCancelled:touches withEvent:event];
    }
}

/*
 *  @inheritdoc
 */
- (void)_onRevealMenu:(UIGestureRecognizer *)gestureRecognizer
{
    if (!self.menuGesturesEnabled) return;

    if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
    {
        [self revealMenu];
    }
}

/*
 *  @inheritdoc
 */
- (void)_onHideMenu:(UIGestureRecognizer *)gestureRecognizer
{
    [self hideMenu];
}

@end
