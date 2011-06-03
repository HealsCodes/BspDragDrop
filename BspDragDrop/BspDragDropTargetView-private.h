/*
 *  BspDragDropTargetView-private.h
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

#import <UIKit/UIKit.h>

@class BspDragDropItemView;
@class BspDragDropItemBar;
@class BspDragDropBackgroundView;
@class BspDragDropTargetView;

@protocol BspDragDropTargetViewDelegate

@optional
- (BOOL)dropTarget:(BspDragDropTargetView*)theTarget shouldAcceptDroppedItem:(BspDragDropItemView*)theItem atPosition:(CGPoint)thePosition;
- (void)dropTarget:(BspDragDropTargetView*)theTarget didAcceptDroppedItem:(BspDragDropItemView*)theItem atPosition:(CGPoint)thePosition;
- (void)dropTarget:(BspDragDropTargetView*)theTarget didPickUpItem:(BspDragDropItemView*)theItem;
@end

@interface BspDragDropTargetView : UIView {
@private
    NSMutableArray *_items;
    
    BspDragDropItemBar *_itemBar;
    BspDragDropBackgroundView *_backgroundView;
    
    id<BspDragDropTargetViewDelegate> _delegate;
}

@property (readonly) NSArray* items;
@property (nonatomic,assign) IBOutlet id<BspDragDropTargetViewDelegate> delegate;
@property (nonatomic,retain) IBOutlet BspDragDropItemBar* itemBar;
@property (nonatomic,retain) IBOutlet BspDragDropBackgroundView* backgroundView;


- (void)resetItems:(BOOL)animated;

/* semi-private methods used by other BspDragDrop*-Members */
- (BOOL)acceptDroppedItem:(BspDragDropItemView*)theItem atPosition:(CGPoint)thePoint;
- (void)removeItem:(BspDragDropItemView*)theItem;
- (void)pickUpNotification:(BspDragDropItemView *)theItem;
@end