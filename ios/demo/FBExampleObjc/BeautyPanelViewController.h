//
//  BeautyPanelViewController.h
//  FBExampleObjc
//
//  Created by admin on 2025/9/8.
//

#import <Facebetter/FBBeautyEffectEngine.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BeautyPanelDelegate <NSObject>
- (void)beautyPanelDidChangeParam:(FBBeautyType)beautyType
                            param:(NSInteger)paramType
                            value:(float)value;
@end

@interface BeautyPanelViewController : UIViewController

@property(nonatomic, assign) id<BeautyPanelDelegate> delegate;

- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
