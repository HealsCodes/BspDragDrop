/*
 *  BspDragDropItemBar.m
 *
 *
 * Copyright (c) 2011 René Köcher <info@bitspin.org>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modifica-
 * tion, are permitted provided that the following conditions are met:
 * 
 *   1.  Redistributions of source code must retain the above copyright notice,
 *       this list of conditions and the following disclaimer.
 * 
 *   2.  Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ''AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MER-
 * CHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPE-
 * CIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTH-
 * ERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * Created by René Köcher on 2001-04-17
 */

#import "BspDragDropItemBar-private.h"

#import "BspDragDropItemView-private.h"
#import "BspDragDropBackgroundView-private.h"

#import "QuartzCore/CALayer.h"


#import <UIKit/UIGestureRecognizerSubclass.h>

#define DND_TINT_VIEW_ID 0x446e4401  //"DnD01"

@interface BspDragDropLongPressGestureRecognizer : UILongPressGestureRecognizer {
@private
    BOOL _passThrough; 
}
@property (nonatomic, assign) BOOL passThrough;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
@end

@implementation BspDragDropLongPressGestureRecognizer
@synthesize passThrough=_passThrough;

- (id)initWithTarget:(id)target action:(SEL)action
{
    self = [super initWithTarget:target action:action];
    if (self)
    {
        _passThrough = NO;
    }
    return self;
}

- (void)reset
{
    _passThrough = NO;
    [super reset];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.state == UIGestureRecognizerStateChanged && _passThrough)
    {
        [self.view touchesBegan:touches withEvent:event];
    }
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.state == UIGestureRecognizerStateChanged && _passThrough)
    {
        [self.view touchesMoved:touches withEvent:event];
    }
    [super touchesMoved: touches withEvent:event];    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.state == UIGestureRecognizerStateChanged && _passThrough)
    {
        [self.view touchesEnded:touches withEvent:event];
    }
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.state == UIGestureRecognizerStateChanged && _passThrough)
    {
        [self.view touchesCancelled:touches withEvent:event];
    }
    [super touchesCancelled:touches withEvent:event];
}

@end
/* ---------------------------------------------------------------------------*/

@implementation BspDragDropItemBar

@synthesize items=_items;
@synthesize delegate=_theDelegate;
@synthesize backgroundView=_backgroundView;
@synthesize fillGaps=_fillGaps;
@synthesize remindSortOrder=_remindSortOrder;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        BspDragDropLongPressGestureRecognizer *longPress;
        longPress = [[BspDragDropLongPressGestureRecognizer alloc] initWithTarget:self 
                                                                           action:@selector(handlePickUpGesture:)];
        longPress.minimumPressDuration = 0.3;
        longPress.cancelsTouchesInView = NO;
     
        _longPress = longPress;
        [self addGestureRecognizer:_longPress];
        [_longPress release];
        
        _items = nil;
        _fillGaps = NO;
        _remindSortOrder = NO;
        
        
        self.scrollsToTop = NO;
        self.showsHorizontalScrollIndicator = YES;
        self.showsVerticalScrollIndicator = NO;
    }
    return self;
}

- (void)awakeFromNib
{    
    BOOL needRecognizer = YES;
    for (UIGestureRecognizer *recog in self.gestureRecognizers)
    {
        if ([recog class] == [UILongPressGestureRecognizer class])
        {
            needRecognizer = NO;
            _longPress = recog;
            break;
        }
    }
    
    if (needRecognizer)
    {
        BspDragDropLongPressGestureRecognizer *longPress;
        longPress = [[BspDragDropLongPressGestureRecognizer alloc] initWithTarget:self 
                                                                           action:@selector(handlePickUpGesture:)];
        longPress.minimumPressDuration = 0.3;
        longPress.cancelsTouchesInView = NO;
        
        _longPress = longPress;
        [self addGestureRecognizer:_longPress];
        [_longPress release];
    }
    _items = nil;
    _fillGaps = NO;
    _remindSortOrder = NO;
    
    self.scrollsToTop = NO;
    self.showsHorizontalScrollIndicator = YES;
    self.showsVerticalScrollIndicator = NO;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc
{
    [self setDelegate:nil];
    [self setBackgroundView:nil];
    if (_items)
    {
        [_items release];
    }
    _items = nil;
    
    [super dealloc];
}

- (void)setDelegate:(id<BspDragDropItemBarDelegate,UIScrollViewDelegate>)delegate
{
    _theDelegate = delegate;
    [super setDelegate:(id<UIScrollViewDelegate>)delegate];
}

#pragma mark public API
- (void)setItems:(NSArray *)items animated:(BOOL)animated
{
    [self removeItems:animated];
    
    float totalWidth = 0.0;
    const float spacing = 5.0;
    
    _items = [items retain];
    
    if (!items || [items count] == 0)
    {
        return;
    }
    
    // calculate the total width needed to contain all items
    for (UIView *item in _items)
    {
        totalWidth += spacing + item.bounds.size.width;
    }
    totalWidth += spacing;
    
    self.contentSize = CGSizeMake(totalWidth, self.frame.size.height - 5.0);
    
    if (animated)
    {
        float offsetX = spacing;
        float delay = 0.0;
        
        for (UIView *item in _items)
        {
            // final center point
            CGPoint center = CGPointMake((offsetX + item.frame.size.width) / 2.0,
                                         (spacing + item.frame.size.height) / 2.0);
            
            // tiny frame for thumnails
            CGRect tinyFrame = CGRectMake(center.x - 5.0, center.y - 5.0, 5.0, 5.0);
            
            item.frame = CGRectMake(offsetX, spacing, item.frame.size.width, item.frame.size.height);
            item.userInteractionEnabled = YES;
            [self addSubview:item];
         
            
            // if the item is not visible we don't animate it
            if (item.frame.origin.x >= self.bounds.size.width)
            {
                if ([item isKindOfClass:[BspDragDropItemView class]])
                {
                    CGPoint center = CGPointMake(item.frame.origin.x + item.frame.size.width / 2.0,
                                                 item.frame.origin.y + item.frame.size.height / 2.0);
                    [(BspDragDropItemView*)item set_itemBarCenter:center];
                    [(BspDragDropItemView*)item set_itemBarInitialCenter:center];
                }
                offsetX += item.frame.size.width + spacing;
                delay += 0.07;
                continue;
            }
            // render the item into a scalable image view
            UIGraphicsBeginImageContext(item.bounds.size);
            
            [item.layer renderInContext:UIGraphicsGetCurrentContext()];
            item.alpha = 0.0; // hide until we're ready to display it
            
            UIImage *thumbImage = UIGraphicsGetImageFromCurrentImageContext();
            
            UIGraphicsEndImageContext();
            
            // create a thumbnail using this image und scale it down to tinyFrame
            UIImageView *thumbNail = [[UIImageView alloc] initWithImage:thumbImage];
            thumbNail.alpha = 0.0;
            thumbNail.frame = tinyFrame;
            
            [self addSubview:thumbNail];
            [thumbNail release];
                        
            [UIView animateWithDuration:1.0
                                  delay:delay
                                options:UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 // animate the thumbnail growing it to the final size
                                 thumbNail.alpha = 1.0;
                                 thumbNail.frame = item.frame;
                             }
                             completion:^(BOOL unused){
                                 // now remove it and show the real view
                                 [thumbNail removeFromSuperview];
                                 item.alpha = 1.0;
                                 if ([item isKindOfClass:[BspDragDropItemView class]])
                                 {
                                     CGPoint center = CGPointMake(item.frame.origin.x + item.frame.size.width / 2.0,
                                                                  item.frame.origin.y + item.frame.size.height / 2.0);
                                     [(BspDragDropItemView*)item set_itemBarCenter:center];
                                     [(BspDragDropItemView*)item set_itemBarInitialCenter:center];
                                 }
                             }
             ];
            offsetX += item.frame.size.width + spacing;
            delay += 0.07;
        }
             
    }
    else
    {
        float offsetX = spacing;
        for (UIView *item in _items)
        {
            [self addSubview:item];
            
            item.frame = CGRectMake(offsetX, spacing, item.frame.size.width, item.frame.size.height);
            offsetX += item.frame.size.width + spacing;
            
            if ([item isKindOfClass:[BspDragDropItemView class]])
            {
                CGPoint center = CGPointMake(item.frame.origin.x + item.frame.size.width / 2.0,
                                             item.frame.origin.y + item.frame.size.height / 2.0);
                [(BspDragDropItemView*)item set_itemBarCenter:center];
                [(BspDragDropItemView*)item set_itemBarInitialCenter:center];
            }
        }
    }
}

- (void)removeItems:(BOOL)animated
{
    if (animated)
    {
        for (UIView *item in _items)
        {
            [UIView animateWithDuration:1.0
                             animations:^{
                                 item.alpha = 0.0;
                             }
                             
                             completion:^(BOOL unused){
                                 [item removeFromSuperview];
                             }];
        }
        [_items removeAllObjects];        
    }
    else
    {
        for (UIView *item in _items)
        {
            [item removeFromSuperview];
        }
        [_items removeAllObjects];
    }
}

#pragma mark semi-public API
- (void)beginDragLock
{
    if (_dragLock)
    {
        return;
    }
 
    @synchronized(self) {
        _dragLock = YES;
    }
    
    UIView *tintView = [[UIView alloc] initWithFrame:self.bounds];
    
    _dragLock = YES;
    
    tintView.backgroundColor = [UIColor blackColor];
    tintView.alpha = 0.0;
    tintView.tag = DND_TINT_VIEW_ID;
    tintView.userInteractionEnabled = NO;
    
    [self addSubview:tintView];
    [tintView release];
    
    [UIView animateWithDuration:0.5 animations:^{
        self.scrollEnabled = NO;
        tintView.alpha = 0.5;
    }];
}

- (void)endDragLock
{
    if (!_dragLock)
    {
        return;
    }
    
    @synchronized(self) {
        _dragLock = NO;
        ((BspDragDropLongPressGestureRecognizer*)_longPress).passThrough = NO;
      
        UIView *tintView = [self viewWithTag:DND_TINT_VIEW_ID];
        if (tintView)
        {
            [UIView animateWithDuration:0.5
                             animations:^{
                                 self.scrollEnabled = YES;
                                 tintView.alpha = 0.0;
                             }
                             completion:^(BOOL unused){
                                 [tintView removeFromSuperview];
                             }
            ];
        }
    }

}

#pragma mark private methods
- (void)handlePickUpGesture:(UIGestureRecognizer*)recognizer
{
    UIView *item = nil;
 
    NSAssert(_backgroundView != nil, @"Invalid backgroundView!");
    
    if (_dragLock)
    {
        // prevent multi-pickups
        return;
    }
    
    item = [self hitTest:[recognizer locationInView:self] withEvent:nil];
    if (item && ![item isKindOfClass:[BspDragDropItemView class]])
    {
        item = nil;
    }
    
    if (item == nil)
    {
        // slow hit testing.. :(
        for (UIView *tmpItem in _items)
        {
            // cons: slower than hitTest'ing, pro's: works for non-interactive views
            if ([tmpItem pointInside:[recognizer locationInView:tmpItem] withEvent:nil])
            {
                item = tmpItem;
            }
        }
    }
    
    if (item == nil || ![_items containsObject:item])
    {
        return;
    }
    
    if (_theDelegate != nil && [(NSObject*)_theDelegate respondsToSelector:@selector(itemBar:shouldPickUpItem:)])
    {
        if (![_theDelegate itemBar:self shouldPickUpItem:(BspDragDropItemView*)item])
        {
            return;
        }
    }
  
    ((BspDragDropLongPressGestureRecognizer*)_longPress).passThrough = YES;
    
    CGPoint locInItem = [recognizer locationInView:item];
    CGPoint locInSuper = [recognizer locationInView:self.superview];
        
    if ([_backgroundView acceptDraggedItem:(BspDragDropItemView*)item])
    {
        [item retain];
        [item removeFromSuperview];
        [_backgroundView addSubview:item];
        [item release];
    
        item.frame = CGRectMake(locInSuper.x - locInItem.x, locInSuper.y - locInItem.y,
                                item.frame.size.width, item.frame.size.height);
        
        if (_fillGaps)
        {
            //compress items / fill gaps
            //item will take the place of the right-most item,
            //all others move left
            _haveGaps = NO;
            _gapIndex = 0;
            
            for (_gapIndex = 0; _gapIndex < [_items count]; ++_gapIndex)
            {
                if ([[_items objectAtIndex:_gapIndex] isEqual:item])
                {
                    if (_gapIndex < [_items count] - 1)
                    {
                        //items to the right
                        _haveGaps = YES;
                        break;
                    }
                    else
                    {
                        break;
                    }
                }
            }
            
            if (_haveGaps)
            {
                _lastItemRemoved = (BspDragDropItemView*)item;
            }
        }

        [UIView animateWithDuration:0.2 animations:^{ item.center = locInSuper; }];
        [_items removeObject:item];
        [self beginDragLock];
    }
    
    if (_theDelegate && [(NSObject*)_theDelegate respondsToSelector:@selector(itemBar:didPickUpItem:)])
    {
        [_theDelegate itemBar:self didPickUpItem:(BspDragDropItemView*)item];
    }
}

- (void)resetItemOrigins:(BOOL)animated
{
    [_items sortUsingComparator:^(id obj1, id obj2) {
            if ([(NSObject*)obj1 isKindOfClass:[BspDragDropItemView class]]
                && [(NSObject*)obj1 isKindOfClass:[BspDragDropItemView class]])
            {
                BspDragDropItemView *item1 = (BspDragDropItemView*)obj1;
                BspDragDropItemView *item2 = (BspDragDropItemView*)obj2;
                
                if (item1._itemBarInitialCenter.x <= item2._itemBarInitialCenter.x)
                {
                    return (NSComparisonResult)NSOrderedAscending;
                }
                return (NSComparisonResult)NSOrderedDescending;
            }
        
        return (NSComparisonResult)NSOrderedSame;
    }];

    if (_remindSortOrder)
    {
        for (BspDragDropItemView *item in _items)
        {
            item._itemBarCenter = item._itemBarInitialCenter;
            
            if (animated)
            {
                [UIView animateWithDuration:0.2 
                                 animations:^{ 
                                     item.center = item._itemBarInitialCenter; 
                                 }
                                 completion:^(BOOL unused){
                                         [self scrollRectToVisible:CGRectMake(0, 0, 10, 10) 
                                                          animated:YES];
                                 }];
            }
            else
            {
                item.center = item._itemBarInitialCenter;
            }
        }
    }
}

- (void)replaceItem:(BspDragDropItemView *)theItem animated:(BOOL)animated
{
    NSAssert(_backgroundView != nil, @"Invalid backgroundView!");

    if (_theDelegate && [(NSObject*)_theDelegate respondsToSelector:@selector(itemBar:willStoreItem:)])
    {
        [_theDelegate itemBar:self willStoreItem:theItem];
    }
    
    
    if (![_items containsObject:theItem])
    {
        //NSLog(@"DDItemBar: re-addItem: %@", theItem);
        [_items addObject:theItem];
        [_items sortUsingComparator:^(id obj1, id obj2) {
            if ([(NSObject*)obj1 isKindOfClass:[BspDragDropItemView class]]
                && [(NSObject*)obj1 isKindOfClass:[BspDragDropItemView class]])
            {
                BspDragDropItemView *item1 = (BspDragDropItemView*)obj1;
                BspDragDropItemView *item2 = (BspDragDropItemView*)obj2;
                
                if (item1._itemBarCenter.x <= item2._itemBarCenter.x)
                {
                    return (NSComparisonResult)NSOrderedAscending;
                }
                return (NSComparisonResult)NSOrderedDescending;
            }
            
            return (NSComparisonResult)NSOrderedSame;
        }];
    }
    
    CGRect viewRect = CGRectMake(theItem._itemBarCenter.x - theItem.bounds.size.width / 2.0, 
                                 theItem._itemBarCenter.y - theItem.bounds.size.height / 2.0,
                                 theItem.bounds.size.width, 
                                 theItem.bounds.size.height);
    
    void (^doReAddItem)(BOOL unused) = ^(BOOL unused) {
        [theItem removeFromSuperview];
        
        if (_dragLock)
        {
            //FIXME: viewWithTag *could* return nil - but it shouldn't at this point
            [self insertSubview:theItem belowSubview:[self viewWithTag:DND_TINT_VIEW_ID]];
        }
        else
        {
            [self addSubview:theItem];
        }
        theItem.center = theItem._itemBarCenter;
        theItem.userInteractionEnabled = YES;
        
        if (_theDelegate && [(NSObject*)_theDelegate respondsToSelector:@selector(itemBar:didStoreItem:)])
        {
            [_theDelegate itemBar:self didStoreItem:theItem];
        }
    };
    
    if (animated)
    {
        [self scrollRectToVisible:viewRect animated:YES];
    
        [UIView animateWithDuration:0.2
                         animations:^{
                             theItem.center = [_backgroundView convertPoint:theItem._itemBarCenter fromView:self];
                         } 
                         completion:doReAddItem];
    }
    else
    {
        [self scrollRectToVisible:viewRect animated:NO];
        doReAddItem(YES);
    }
}

- (void)performFillGaps
{
    if (_fillGaps && _haveGaps && _lastItemRemoved)
    {
        CGPoint tmpLoc = ((BspDragDropItemView*)[_items lastObject])._itemBarCenter;
        //move all items right of this one to their left neigbor
        
        [UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                                
                            for (int i = _gapIndex; i < [_items count]; ++i)
                            {
                                BspDragDropItemView *actItem, *lastItem;
                                actItem = (BspDragDropItemView*)[_items objectAtIndex:i];
                                
                                if (i == _gapIndex)
                                {
                                    actItem.center = _lastItemRemoved._itemBarCenter;
                                }
                                else
                                {
                                    lastItem = (BspDragDropItemView*)[_items objectAtIndex:i-1];                                    
                                    actItem.center = lastItem._itemBarCenter;
                                }
                            }
                        }
                        completion:^(BOOL unused){
                            //fixup _itemBarCenter
                            for (int i = _gapIndex; i < [_items count]; ++i)
                            {
                                BspDragDropItemView *actItem;
                                
                                actItem = (BspDragDropItemView*)[_items objectAtIndex:i];
                                actItem._itemBarCenter = actItem.center;
                            }
                        }];
/*
        //fixup _itemBarCenter
        for (int i = _gapIndex; i < [_items count]; ++i)
        {
            BspDragDropItemView *actItem;
            
            actItem = (BspDragDropItemView*)[_items objectAtIndex:i];
            actItem._itemBarCenter = actItem.center;
        }
 */
        //push the floating item to the back
        [_items sortUsingComparator:^(id obj1, id obj2) {
            if ([(NSObject*)obj1 isKindOfClass:[BspDragDropItemView class]]
                && [(NSObject*)obj1 isKindOfClass:[BspDragDropItemView class]])
            {
                BspDragDropItemView *item1 = (BspDragDropItemView*)obj1;
                BspDragDropItemView *item2 = (BspDragDropItemView*)obj2;
                
                if (item1._itemBarCenter.x <= item2._itemBarCenter.x)
                {
                    return (NSComparisonResult)NSOrderedAscending;
                }
                return (NSComparisonResult)NSOrderedDescending;
            }
            
            return (NSComparisonResult)NSOrderedSame;
        }];
        _lastItemRemoved._itemBarCenter = tmpLoc;
    }
    
    _haveGaps = NO;
    _lastItemRemoved = nil;
}

#pragma mark touch handling
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{    
    if (_dragLock)
    {
        [self.superview touchesBegan:touches withEvent:event];
        return;
    }
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_dragLock)
    {
        [self.superview touchesMoved:touches withEvent:event];
        return;
    }
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_dragLock)
    {
        [self.superview touchesEnded:touches withEvent:event];
        
        // end transparent drags if they are enabled
        ((BspDragDropLongPressGestureRecognizer*)_longPress).passThrough = NO;
        return;
    }
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_dragLock)
    {
        [self.superview touchesCancelled:touches withEvent:event];
        return;
    }
    [super touchesCancelled:touches withEvent:event];
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return (_dragLock == NO);
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return (_dragLock == NO);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}
@end
