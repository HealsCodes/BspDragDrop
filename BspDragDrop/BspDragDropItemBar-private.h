/*
 *  BspDragDropItemBar-private.h
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

@class BspDragDropItemBar;
@class BspDragDropItemView;
@class BspDragDropBackgroundView;

@protocol BspDragDropItemBarDelegate

@optional
- (BOOL)itemBar:(BspDragDropItemBar*)theItemBar shouldPickUpItem:(BspDragDropItemView*)theItem;
- (void)itemBar:(BspDragDropItemBar*)theItemBar didPickUpItem:(BspDragDropItemView*)theItem;
- (void)itemBar:(BspDragDropItemBar*)theItemBar willStoreItem:(BspDragDropItemView*)theItem;
- (void)itemBar:(BspDragDropItemBar*)theItemBar didStoreItem:(BspDragDropItemView*)theItem;

@end

@interface BspDragDropItemBar : UIScrollView<UIGestureRecognizerDelegate> {
@private
    NSMutableArray *_items;
    UIGestureRecognizer *_longPress;
    
    BspDragDropBackgroundView *_backgroundView;
    BspDragDropItemView *_lastItemRemoved;
    BOOL _dragLock;
    
    BOOL _fillGaps;
    BOOL _haveGaps;
    BOOL _remindSortOrder;
    int _gapIndex;
    
    id<BspDragDropItemBarDelegate,UIScrollViewDelegate> _theDelegate;
}
@property (readonly) NSArray* items;
@property (nonatomic, assign) BOOL fillGaps;
@property (nonatomic, assign) BOOL remindSortOrder;
@property (nonatomic, assign) IBOutlet id<BspDragDropItemBarDelegate,UIScrollViewDelegate> delegate;
@property (nonatomic, retain) IBOutlet BspDragDropBackgroundView* backgroundView;

- (void)setItems:(NSArray*)items animated:(BOOL)animated;
- (void)removeItems:(BOOL)animated;

/* semi-private methods used by other BspDragDrop*-Members */
- (void)beginDragLock;
- (void)endDragLock;
- (void)performFillGaps;
- (void)resetItemOrigins:(BOOL)animated;
- (void)replaceItem:(BspDragDropItemView*)theItem animated:(BOOL)animated;
@end
