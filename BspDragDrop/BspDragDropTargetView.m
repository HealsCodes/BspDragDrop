/*
 *  BspDragDropTargetView.m
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

#import "BspDragDropTargetView-private.h"

#import "BspDragDropItemBar-private.h"
#import "BspDragDropBackgroundView-private.h"

@implementation BspDragDropTargetView

@synthesize items=_items;
@synthesize delegate=_delegate;
@synthesize itemBar=_itemBar;
@synthesize backgroundView=_backgroundView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // Initialization code
        _items = [[NSMutableArray alloc] initWithCapacity:10];
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
/*
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(ctx, [UIColor redColor].CGColor);
    
    CGContextBeginPath(ctx);
    for (UIView *item in _items)
    {
        CGRect locInSelf = [self convertRect:item.frame toView:self];
        
        CGContextMoveToPoint(ctx, 0, locInSelf.origin.y);
        CGContextAddLineToPoint(ctx, self.bounds.size.width, locInSelf.origin.y);
        
        CGContextMoveToPoint(ctx, locInSelf.origin.x, 0);
        CGContextAddLineToPoint(ctx, locInSelf.origin.x, self.bounds.size.height);
    }
    CGContextStrokePath(ctx);
}
*/

- (void)dealloc
{
    [self setDelegate:nil];
    [self setBackgroundView:nil];
    [self setItemBar:nil];
    if (_items)
    {
        [_items release];
    }
    _items = nil;
    
    [super dealloc];
}

- (void)awakeFromNib
{
    if (!_items)
    {
        _items = [[NSMutableArray alloc] initWithCapacity:10];
    }
}
- (void)resetItems:(BOOL)animated
{
    NSAssert(_itemBar != nil, @"Invalid itemBar!");
    NSAssert(_backgroundView != nil, @"Invalid backgroundView!");
    
    for (BspDragDropItemView *item in _items)
    {
        [_backgroundView removeItem:item];
        [_itemBar replaceItem:item animated:animated];
    }
    
    [_itemBar resetItemOrigins:animated];
    [_items removeAllObjects];
}

- (BOOL)acceptDroppedItem:(BspDragDropItemView *)theItem atPosition:(CGPoint)thePoint
{
    if ([_items containsObject:theItem])
    {
        [self setNeedsDisplay];
        return YES;
    }
    
    if (_delegate && [(NSObject*)_delegate respondsToSelector:@selector(dropTarget:shouldAcceptDroppedItem:atPosition:)])
    {
        if (![_delegate dropTarget:self shouldAcceptDroppedItem:theItem atPosition:thePoint])
        {
            return NO;
        }
    }
    
    //NSLog(@"DDTarget: acceptDroppedItem: %@", theItem);
    [_items addObject:theItem];
    [self setNeedsDisplay];
    
    if (_delegate && [(NSObject*)_delegate respondsToSelector:@selector(dropTarget:didAcceptDroppedItem:atPosition:)])
    {
        [_delegate dropTarget:self didAcceptDroppedItem:theItem atPosition:thePoint];
    }
    return YES;
}

- (void)removeItem:(BspDragDropItemView *)theItem
{
    [self setNeedsDisplay];
    if ([_items containsObject:theItem])
    {
        //NSLog(@"DDTarget: removeItem: %@", theItem);
        [_items removeObject:theItem];
    }
}

- (void)pickUpNotification:(BspDragDropItemView *)theItem
{
    if (![_items containsObject:theItem])
    {
        return;
    }
    
    if (_delegate && [(NSObject*)_delegate respondsToSelector:@selector(dropTarget:didPickUpItem:)])
    {
        [_delegate dropTarget:self didPickUpItem:theItem];
    }
}
@end
