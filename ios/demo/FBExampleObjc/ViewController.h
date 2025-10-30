//
//  ViewController.h
//  FBExampleObjc
//
//  Created by admin on 2025/7/28.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import "BeautyPanelViewController.h"
#import "CameraManager.h"

@interface ViewController : UIViewController <CameraManagerDelegate, BeautyPanelDelegate>

@end
