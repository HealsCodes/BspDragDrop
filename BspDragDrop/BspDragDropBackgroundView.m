/*
 *  BspDragDropBackgroundView.m
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

#import "BspDragDropBackgroundView-private.h"

#import "BspDragDropTargetView-private.h"
#import "BspDragDropItemBar-private.h"
#import "BspDragDropItemView-private.h"

@implementation BspDragDropBackgroundView
@synthesize delegate=_delegate;
@synthesize itemBar=_itemBar;
@synthesize targetView=_targetView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        // Initialization code
        _trackedItems = [[NSMutableArray alloc] initWithCapacity:2];
        _itemBar = nil;
        _targetView = nil;
        _activeItem = nil;
    }
    return self;
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
    [self setItemBar:nil];
    [self setTargetView:nil];
    if (_trackedItems)
    {
        [_trackedItems release];
    }
    
    _trackedItems = nil;
    [super dealloc];
}

- (void)awakeFromNib
{
    _activeItem = nil;
    if (!_trackedItems)
    {
        _trackedItems = [[NSMutableArray alloc] initWithCapacity:2];
    }
}

#pragma mark semi-private API
- (BOOL)acceptDraggedItem:(BspDragDropItemView*)item
{
    if ([_trackedItems containsObject:item])
    {
        return NO;
    }
    
    if (_delegate && [(NSObject*)_delegate respondsToSelector:@selector(backgroundView:shouldTrackItem:)])
    {
        if (![_delegate backgroundView:self shouldTrackItem:item])
        {
            return NO;
        }
    }
    
    //NSLog(@"DDBackground: adopt item %@", item);
    [_trackedItems addObject:item];
    _activeItem = item;
    item.userInteractionEnabled = YES;
    
    if (_delegate && [(NSObject*)_delegate respondsToSelector:@selector(backgroundView:startedTrackingItem:)])
    {
        [_delegate backgroundView:self startedTrackingItem:item];
    }
    return YES;
}

- (void)removeItem:(BspDragDropItemView*)item
{
    if ([_trackedItems containsObject:item])
    {
        [_trackedItems removeObject:item];
    }
}

#pragma mark UIView touch-Event handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[touches allObjects] objectAtIndex:0];
    UIView *item = touch.view;
    
    if (touch.view == nil)
    {
        item = [self hitTest:[touch locationInView:self] withEvent:event];
    }
    if (![_trackedItems containsObject:item])
    {
        //        NSLog(@"DDBackground: not a tracked item: %@", item);
        _activeItem = nil;
        return;
    }
    
    _activeItem = (BspDragDropItemView*)item;
    if (_itemBar)
    {
        [_itemBar beginDragLock];
    }
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[touches allObjects] objectAtIndex:0];
/*    UIView *item = touch.view;
    
    if (touch.view == nil)
    {
        item = [self hitTest:[touch locationInView:self] withEvent:event];
    }
    if (![_trackedItems containsObject:item])
    {
        //        NSLog(@"DDBackground: not a tracked item: %@", item);
        return;
    }
 
    item.center = [touch locationInView:self];
*/
    if (!_activeItem)
    {
        return;
    }
    _activeItem.center = [touch locationInView:self];
    if (_targetView)
    {
        [_targetView pickUpNotification:(BspDragDropItemView*)_activeItem];
        [_targetView removeItem:(BspDragDropItemView*)_activeItem];
    }
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSAssert(_itemBar != nil, @"Invalid itemBar!");
    NSAssert(_targetView != nil, @"Invalid targetView!");
    
    UITouch *touch = [[touches allObjects] objectAtIndex:0];
    
    BspDragDropItemView *item = nil;
    
    CGPoint dropLocation;
    BOOL dropIsValid = YES;
    
    if (touch.view == nil)
    {
        // default case if the touches get passed by the itemBar.. (too bad)
        // we need to hitTest a few views to check if there is an item here..
        for (UIView *tmpItem in self.subviews)
        {
            // cons: slower than hitTest'ing, pro's: works for non-interactive views
            if ([tmpItem pointInside:[touch locationInView:tmpItem] withEvent:event])
            {
                if ([tmpItem isKindOfClass:[BspDragDropItemView class]])
                {
                    item = (BspDragDropItemView*)tmpItem;
                    break;
                }
            }
        }

        if (item == nil)
        {
            //NSLog(@"DDBackground: Not in targetView (null-determination)");
            dropIsValid = NO;
        }
    }
    else
    {
        if (![touch.view isKindOfClass:[BspDragDropItemView class]])
        {
            //in a valid d&d drag event view *must* be the dragged item
            //NSLog(@"DDBackground: Not in targetView (no-d&d-drag)");
            dropIsValid = NO;
        }
        else
        {
            item = (BspDragDropItemView*)touch.view;
        }
    }
    
    if (dropIsValid && ![_targetView pointInside:[touch locationInView:_targetView]
                                       withEvent:event])
    {
        //NSLog(@"DDBackground: Not in targetView (no-pointInside)");
        dropIsValid = NO;
    }
    else
    {
        if (item)
        {
            //calculate the top-left corner instead of the center point
            CGPoint topLeft = item.frame.origin;
            if (topLeft.x < _targetView.frame.origin.x
                || topLeft.y < _targetView.frame.origin.y)
            {
                //NSLog(@"DDBackground: Not in targetView (top-left-outside)
                dropIsValid = NO;
            }
            else
            {
                dropLocation = CGPointMake(topLeft.x - _targetView.frame.origin.x, 
                                           topLeft.y - _targetView.frame.origin.y);
            }
        }
        else
        {
            dropLocation = [touch locationInView:_targetView];
        }
    }
    
    if (item)
    {
        if (dropIsValid)
        {
            if ([_targetView acceptDroppedItem:item atPosition:dropLocation])
            {
                [_itemBar performFillGaps];
                if ([(NSObject*)_delegate respondsToSelector:@selector(backgroundView:didStopTrackingItem:)])
                {
                    [_delegate backgroundView:self didStopTrackingItem:item];
                }            
            }
            else
            {
                /* the primary re-placement needs to be done *after* 
                 * UIKit realizes what that the item changed superviews */
                [self performSelector:@selector(finalizeReplacement:) withObject:item afterDelay:0.0];
            }
        }
        else
        {   
            if ([_targetView.items containsObject:item])
            {
                [_targetView removeItem:item];
            }
            
            /* the primary re-placement needs to be done *after* 
             * UIKit realizes what that the item changed superviews */
            [self performSelector:@selector(finalizeReplacement:) withObject:item afterDelay:0.0];
        }
    }
    _activeItem = nil;
    if (_itemBar)
    {
        [_itemBar endDragLock];
    }
    [super touchesEnded:touches withEvent:event];
}

- (void)finalizeReplacement:(BspDragDropItemView*)item
{
    NSAssert(_itemBar != nil, @"Invalid itemBar!");
    
    [_itemBar replaceItem:item animated:YES];
    [_trackedItems removeObject:item];
    if ([(NSObject*)_delegate respondsToSelector:@selector(backgroundView:didStopTrackingItem:)])
    {
        [_delegate backgroundView:self didStopTrackingItem:item];
    }
}
@end
