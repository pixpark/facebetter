//
//  ViewController.m
//  FBExampleObjc
//
//  Created by admin on 2025/7/19.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Facebetter/FBBeautyEffectEngine.h>
#import "CameraManager.h"
#import "BeautyPanelViewController.h"
#import "GLRGBARenderView.h"
 
@interface ViewController () <CameraManagerDelegate, BeautyPanelDelegate>
@property(nonatomic, strong) FBBeautyEffectEngine *beautyEffectEngine;
@property(nonatomic, strong) CameraManager *cameraManager;
@property(nonatomic, strong) BeautyPanelViewController *beautyPanelViewController;
@property(nonatomic, strong) GLRGBARenderView *previewView;
@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // 日志
  FBLogConfig* logConfig = [[FBLogConfig alloc] init];
  logConfig.consoleEnabled = YES;
  logConfig.fileEnabled = NO;
  logConfig.level = FBLogLevel_Info;
  logConfig.fileName = @"facebetter_sdk.log";
  [FBBeautyEffectEngine setLogConfig:logConfig];
 
  // engine
  FBEngineConfig *engineConfig = [[FBEngineConfig alloc] init];
 
  // replace with your appid and appkey
  engineConfig.appId = @"";
  engineConfig.appKey = @"";
 
  self.beautyEffectEngine = [FBBeautyEffectEngine createEngineWithConfig:engineConfig];

  [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Basic enabled:TRUE];
  [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Reshape enabled:TRUE];
  [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Makeup enabled:TRUE];

  // 使用自定义 OpenGL 视图渲染 RGBA
  self.previewView = [[GLRGBARenderView alloc] initWithFrame:self.view.bounds];
  self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.previewView setMirrored:YES];
  [self.view addSubview:self.previewView];
  [NSLayoutConstraint activateConstraints:@[
    [self.previewView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.previewView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.previewView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.previewView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
  ]];
 
  // 初始化相机管理器
  self.cameraManager = [[CameraManager alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720
                                                       cameraDevice:nil];
  self.cameraManager.delegate = self;
  [self.cameraManager startCapture];
 
  // 初始化美颜调节面板
  self.beautyPanelViewController = [[BeautyPanelViewController alloc] init];
  self.beautyPanelViewController.delegate = self;
  [self addChildViewController:self.beautyPanelViewController];
  [self.view addSubview:self.beautyPanelViewController.view];
  
  // 设置美颜面板视图的约束，让它填充整个父视图
  [NSLayoutConstraint activateConstraints:@[
    [self.beautyPanelViewController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.beautyPanelViewController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.beautyPanelViewController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.beautyPanelViewController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
  ]];
  
  // 设置键盘快捷键来切换面板显示/隐藏 (Cmd+B)
  NSEvent *localEvent = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent *(NSEvent *event) {
    if (event.modifierFlags & NSEventModifierFlagCommand && event.keyCode == 11) { // Cmd+B
      [self.beautyPanelViewController togglePanelVisibility];
      return nil; // 阻止事件继续传播
    }
    return event;
  }];
}

#pragma mark - CameraManagerDelegate

- (void)cameraManager:(id)cameraManager didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  // 获取图像缓冲区
  CVImageBufferRef buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  if (!buffer) {
    return;
  }
  
  CVPixelBufferLockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
  int width = (int32_t)CVPixelBufferGetWidth(buffer);
  int height = (int32_t)CVPixelBufferGetHeight(buffer);
  int stride = (int32_t)CVPixelBufferGetBytesPerRow(buffer);
  
  void *data = CVPixelBufferGetBaseAddress(buffer);
  
  FBImageFrame *input_image;
  OSType pixelFormat = CVPixelBufferGetPixelFormatType(buffer);
  switch (pixelFormat) {
    case kCVPixelFormatType_32BGRA:
      input_image = [FBImageFrame createWithBGRA:data width:width height:height stride:stride];
      break;
    case kCVPixelFormatType_32RGBA:
      input_image = [FBImageFrame createWithRGBA:data width:width height:height stride:stride];
      break;
    case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:  // NV12
    case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange: {
      // 获取Y平面数据
      const uint8_t *y_plane = (const uint8_t *)CVPixelBufferGetBaseAddressOfPlane(buffer, 0);
      size_t y_stride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0);
      
      // 获取UV平面数据
      const uint8_t *uv_plane = (const uint8_t *)CVPixelBufferGetBaseAddressOfPlane(buffer, 1);
      size_t uv_stride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 1);
      
      input_image = [FBImageFrame createWithNV12:width
                                               height:height
                                                dataY:y_plane
                                              strideY:(int32_t)y_stride
                                               dataUV:uv_plane
                                             strideUV:(int32_t)uv_stride];
      break;
    }
    default:
      break;
  }
  
  FBImageFrame *output_image = [self.beautyEffectEngine processImage:input_image processMode:FBProcessModeVideo];
  if (output_image) {
    FBImageBuffer *rgba = [output_image toRGBA];
    if (rgba) {
      [self.previewView renderBuffer:rgba];
    }
  }
  
  CVPixelBufferUnlockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
}

#pragma mark - 定时器相关方法

- (void)processImageWithTimer {
  
}
 
#pragma mark - BeautyPanelDelegate

- (void)beautyPanelDidChangeParam:(FBBeautyType)beautyType param:(NSInteger)paramType value:(float)value {
  switch (beautyType) {
    case FBBeautyType_Basic: {
      FBBasicParam basicParam = (FBBasicParam)paramType;
      [self.beautyEffectEngine setBasicParam:basicParam floatValue:value];
      break;
    }
    case FBBeautyType_Reshape: {
      FBReshapeParam reshapeParam = (FBReshapeParam)paramType;
      [self.beautyEffectEngine setReshapeParam:reshapeParam floatValue:value];
      break;
    }
    case FBBeautyType_Makeup: {
      FBMakeupParam makeupParam = (FBMakeupParam)paramType;
      [self.beautyEffectEngine setMakeupParam:makeupParam floatValue:value];
      break;
    }
    case FBBeautyType_Segmentation: {
      if(value > 0.0f) {
        [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Segmentation enabled:TRUE];
      } else {
        [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Segmentation enabled:FALSE];
      }
      break;
    }
  }
  
  NSLog(@"Beauty param changed - Type: %ld, Param: %ld, Value: %.2f", (long)beautyType, (long)paramType, value);
}
 
- (void)setRepresentedObject:(id)representedObject {
  [super setRepresentedObject:representedObject];
  // Update the view, if already loaded.
}

- (void)dealloc {
  // 停止相机采集
  [self.cameraManager stopCapture];
}

@end
