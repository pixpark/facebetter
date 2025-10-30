//
//  ViewController.m
//  FBExampleObjc
//
//  Created by admin on 2025/7/28.
//

#import "ViewController.h"
#import "GLRGBARenderView.h"
#import <Facebetter/FBBeautyEffectEngine.h>

// ViewController 负责：
// 1) 初始化并管理相机采集
// 2) 通过 BeautyEngine 处理帧，取得 RGBA 数据
// 3) 使用自定义 OpenGL 视图进行渲染
@interface ViewController ()
@property(nonatomic, strong) FBBeautyEffectEngine *beautyEffectEngine;
@property(nonatomic, strong) CameraManager *cameraManager;

// UI
@property(nonatomic, strong) GLRGBARenderView *previewView;
@property(nonatomic, strong) BeautyPanelViewController *beautyPanelViewController;


@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setupUI];
  [self setupBeautyEngine];
  [self setupCameraManager];
}

- (void)setupUI {
  // 预览视图：使用 OpenGL 渲染 RGBA 数据
  self.previewView = [[GLRGBARenderView alloc] initWithFrame:self.view.bounds];
  self.previewView.backgroundColor = [UIColor blackColor];
  self.previewView.translatesAutoresizingMaskIntoConstraints = NO;
  [self.view addSubview:self.previewView];
  
  // 美颜调节面板
  self.beautyPanelViewController = [[BeautyPanelViewController alloc] init];
  self.beautyPanelViewController.delegate = self;
  [self addChildViewController:self.beautyPanelViewController];
  [self.view addSubview:self.beautyPanelViewController.view];
  [self.beautyPanelViewController didMoveToParentViewController:self];
  
  // 约束
  [NSLayoutConstraint activateConstraints:@[
    // 预览视图占满整个屏幕
    [self.previewView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.previewView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.previewView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.previewView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    
    // 美颜面板填充父视图（其本身内部处理点击区域和布局）
    [self.beautyPanelViewController.view.topAnchor constraintEqualToAnchor:self.view.topAnchor],
    [self.beautyPanelViewController.view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
    [self.beautyPanelViewController.view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    [self.beautyPanelViewController.view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
  ]];
}

- (void)setupBeautyEngine {
  /* ===================== Facebetter Beauty Engine Usage =====================
   * 1) 配置日志（可选）
   * 2) 使用 AppId/AppKey 创建引擎实例
   * 3) 启用需要的美颜类型（Basic/Reshape/Makeup/...）
   * 4) 后续通过 setXXXParam 接口实时调参（见 beautyPanelDidChangeParam）
   * 5) 不使用 setRenderView，处理结果通过 toRGBA 提取后自行渲染
   * ======================================================================= */
  // 1) 配置日志（可选）
  FBLogConfig* logConfig = [[FBLogConfig alloc] init];
  logConfig.consoleEnabled = YES;
  logConfig.fileEnabled = NO;
  logConfig.level = FBLogLevel_Info;
  logConfig.fileName = @"ios_beauty_engine.log";
  [FBBeautyEffectEngine setLogConfig:logConfig];
 
  // 2) 创建引擎实例（需替换为你的 AppId/AppKey）
  FBEngineConfig *engineConfig = [[FBEngineConfig alloc] init];
  engineConfig.appId = @"";
  engineConfig.appKey = @"";
 
  self.beautyEffectEngine = [FBBeautyEffectEngine createEngineWithConfig:engineConfig];
  
  // 3) 启用美颜类型（实际生效需配合具体参数值）
  [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Basic enabled:TRUE];
  [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Reshape enabled:TRUE];
  [self.beautyEffectEngine setBeautyTypeEnabled:FBBeautyType_Makeup enabled:TRUE];
}

- (void)setupCameraManager {
  // 相机权限检查
  AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
  if (status == AVAuthorizationStatusNotDetermined) {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
      dispatch_async(dispatch_get_main_queue(), ^{
        if (granted) {
          [self initializeCamera];
        } else {
          [self showCameraPermissionAlert];
        }
      });
    }];
  } else if (status == AVAuthorizationStatusAuthorized) {
    [self initializeCamera];
  } else {
    [self showCameraPermissionAlert];
  }
}

- (void)initializeCamera {
  // 初始化相机管理器并开始采集
  self.cameraManager = [[CameraManager alloc] initWithSessionPreset:AVCaptureSessionPreset1280x720 cameraDevice:nil];
  self.cameraManager.delegate = self;
  
  [self.cameraManager startCapture];
}

- (void)showCameraPermissionAlert {
  UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"相机权限"
                                                                 message:@"请在设置中允许应用访问相机"
                                                          preferredStyle:UIAlertControllerStyleAlert];
  UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:@"去设置"
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]
                                       options:@{}
                             completionHandler:nil];
  }];
  UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消"
                                                         style:UIAlertActionStyleCancel
                                                       handler:nil];
  [alert addAction:settingsAction];
  [alert addAction:cancelAction];
  [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - CameraManagerDelegate

- (void)cameraManager:(id)cameraManager didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
  // 将相机帧包装为 FBImageFrame，再交给 BeautyEngine 处理
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
        // iOS 常见相机格式之一（BGRA）
        input_image = [FBImageFrame createWithBGRA:data width:width height:height stride:stride];
        break;
      case kCVPixelFormatType_32RGBA:
        // RGBA 格式
        input_image = [FBImageFrame createWithRGBA:data width:width height:height stride:stride];
        break;
      case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:  // NV12
      case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange: {
        // NV12：从 Y/UV 平面构造输入
        const uint8_t *y_plane = (const uint8_t *)CVPixelBufferGetBaseAddressOfPlane(buffer, 0);
        size_t y_stride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0);

        // UV 平面
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

    // 通过引擎处理帧（视频模式）
    FBImageFrame *output_frame = [self.beautyEffectEngine processImage:input_image processMode:FBProcessModeVideo];
    
    // 提取 RGBA 并渲染到 OpenGL 视图
    if (output_frame) {
      FBImageBuffer *rgba_buffer = [output_frame toRGBA];
      if (rgba_buffer) {
        [self.previewView renderBuffer:rgba_buffer];
      }
    }
   
    CVPixelBufferUnlockBaseAddress(buffer, kCVPixelBufferLock_ReadOnly);
}
 
- (void)dealloc {
  // 停止相机采集
  [self.cameraManager stopCapture];
}

#pragma mark - BeautyPanelDelegate

- (void)beautyPanelDidChangeParam:(FBBeautyType)beautyType param:(NSInteger)paramType value:(float)value {
  // 应用美颜参数到引擎
  switch (beautyType) {
    case FBBeautyType_Basic:
      [self.beautyEffectEngine setBasicParam:(FBBasicParam)paramType floatValue:value];
      break;
    case FBBeautyType_Reshape:
      [self.beautyEffectEngine setReshapeParam:(FBReshapeParam)paramType floatValue:value];
      break;
    case FBBeautyType_Makeup:
      [self.beautyEffectEngine setMakeupParam:(FBMakeupParam)paramType floatValue:value];
      break;
    case FBBeautyType_Segmentation:
      // 对于分割参数，这里需要根据具体需求处理
      break;
    default:
      break;
  }
}

@end
