//
//  BeautyPanelViewController.h
//  FBExampleObjc
//
//  Created by admin on 2025/7/19.
//

#import <Cocoa/Cocoa.h>
#import <Facebetter/FBBeautyParams.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BeautyPanelDelegate <NSObject>
- (void)beautyPanelDidChangeParam:(FBBeautyType)beautyType
                            param:(NSInteger)paramType
                            value:(float)value;
@end

@interface BeautyPanelViewController : NSViewController

@property(nonatomic, assign) id<BeautyPanelDelegate> delegate;

- (instancetype)init;
- (void)togglePanelVisibility;
- (void)showPanel;
- (void)hidePanel;
- (void)updateHideTipVisibility;

@end

NS_ASSUME_NONNULL_END
