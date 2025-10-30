//
//  BeautyPanelViewController.m
//  FBExampleObjc
//
//  Created by admin on 2025/7/19.
//

#import "BeautyPanelViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface BeautyPanelViewController ()

// 主容器视图
@property (nonatomic, strong) NSView *containerView;

// 滑动条区域
@property (nonatomic, strong) NSSlider *valueSlider;
@property (nonatomic, strong) NSTextField *valueLabel;

// 参数选择区域
@property (nonatomic, strong) NSScrollView *paramScrollView;
@property (nonatomic, strong) NSView *paramSelectionView;
@property (nonatomic, strong) NSMutableArray<NSButton *> *paramButtons;

// 滚动指示器
@property (nonatomic, strong) NSView *leftGradientView;
@property (nonatomic, strong) NSView *rightGradientView;
@property (nonatomic, strong) NSButton *leftScrollButton;
@property (nonatomic, strong) NSButton *rightScrollButton;

// 美颜类型切换区域
@property (nonatomic, strong) NSView *beautyTypeView;
@property (nonatomic, strong) NSMutableArray<NSButton *> *beautyTypeButtons;

// 当前选中的美颜类型和参数
@property (nonatomic, assign) FBBeautyType currentBeautyType;
@property (nonatomic, assign) NSInteger currentParamType;

// 美颜参数数据
@property (nonatomic, strong) NSArray<NSDictionary *> *beautyTypeData;

// 参数值存储 - 使用美颜类型和参数类型的组合作为key，数值作为value
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *paramValues;

// 面板状态
@property (nonatomic, assign) BOOL isPanelVisible;
@property (nonatomic, strong) NSLayoutConstraint *panelTrailingConstraint;
@property (nonatomic, strong) NSLayoutConstraint *panelBottomConstraint;

// 隐藏提示标签
@property (nonatomic, strong) NSTextField *hideTipLabel;

@end

@implementation BeautyPanelViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentBeautyType = FBBeautyType_Basic;
        _paramValues = [[NSMutableDictionary alloc] init];
        _isPanelVisible = YES; // 默认显示面板
        [self setupBeautyTypeData];
        [self initializeParamValues];
        // 初始化当前参数类型为第一个美颜类型的第一个参数
        [self initializeCurrentParamType];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)setupBeautyTypeData {
    self.beautyTypeData = @[
        @{
            @"title": @"美肤",
            @"type": @(FBBeautyType_Basic),
            @"params": @[
                @{@"title": @"磨皮", @"type": @(FBBasicParam_Smoothing)},
                @{@"title": @"锐化", @"type": @(FBBasicParam_Sharpening)},
                @{@"title": @"美白", @"type": @(FBBasicParam_Whitening)},
                @{@"title": @"红润", @"type": @(FBBasicParam_Rosiness)}
            ]
        },
        @{
            @"title": @"美型",
            @"type": @(FBBeautyType_Reshape),
            @"params": @[
                @{@"title": @"瘦脸", @"type": @(FBReshapeParam_FaceThin)},
                @{@"title": @"V脸", @"type": @(FBReshapeParam_FaceVShape)},
                @{@"title": @"窄脸", @"type": @(FBReshapeParam_FaceNarrow)},
                @{@"title": @"短脸", @"type": @(FBReshapeParam_FaceShort)},
                @{@"title": @"颧骨", @"type": @(FBReshapeParam_Cheekbone)},
                @{@"title": @"下颌骨", @"type": @(FBReshapeParam_Jawbone)},
                @{@"title": @"下巴", @"type": @(FBReshapeParam_Chin)},
                @{@"title": @"瘦鼻梁", @"type": @(FBReshapeParam_NoseSlim)},
                @{@"title": @"大眼", @"type": @(FBReshapeParam_EyeSize)},
                @{@"title": @"眼距", @"type": @(FBReshapeParam_EyeDistance)}
            ]
        },
        @{
            @"title": @"美妆",
            @"type": @(FBBeautyType_Makeup),
            @"params": @[
                @{@"title": @"口红", @"type": @(FBMakeupParam_Lipstick)},
                @{@"title": @"腮红", @"type": @(FBMakeupParam_Blush)}
            ]
        },
        @{
            @"title": @"背景",
            @"type": @(FBBeautyType_Segmentation),
            @"params": @[
               
            ]
        }
    ];
}

- (void)initializeParamValues {
    // 初始化所有参数的默认值为0.0（0%）
    for (NSDictionary *beautyType in self.beautyTypeData) {
        NSNumber *beautyTypeValue = beautyType[@"type"];
        NSArray *params = beautyType[@"params"];
        for (NSDictionary *param in params) {
            NSNumber *paramType = param[@"type"];
            // 使用美颜类型和参数类型的组合作为key
            NSString *key = [NSString stringWithFormat:@"%ld_%ld", (long)beautyTypeValue.integerValue, (long)paramType.integerValue];
            self.paramValues[key] = @(0.0); // 默认0%
        }
    }
}

- (void)initializeCurrentParamType {
    // 初始化当前参数类型为第一个美颜类型的第一个参数
    // 这确保了应用启动时滑块显示的是正确的参数值
    if (self.beautyTypeData.count > 0) {
        NSDictionary *firstBeautyType = self.beautyTypeData[0];
        NSArray *params = firstBeautyType[@"params"];
        if (params.count > 0) {
            NSDictionary *firstParam = params[0];
            self.currentParamType = [firstParam[@"type"] integerValue];
        }
    }
}

- (void)setupUI {
    // 设置视图背景为透明
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor clearColor].CGColor;
    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 创建主容器视图
    [self setupContainerView];
    
    // 创建滑动条区域
    [self setupSliderView];
    
    // 创建参数选择区域
    [self setupParamSelectionView];
    
    // 创建美颜类型切换区域
    [self setupBeautyTypeView];
    
    // 设置约束
    [self setupConstraints];
    
    // 创建隐藏提示标签
    [self setupHideTipLabel];
    
    // 初始化显示
    [self updateParamSelectionView];
}

- (void)setupContainerView {
    self.containerView = [[NSView alloc] init];
    self.containerView.wantsLayer = YES;
    self.containerView.layer.backgroundColor = [[NSColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:0.9] CGColor];
    self.containerView.layer.cornerRadius = 15;
    self.containerView.layer.borderWidth = 1.0;
    self.containerView.layer.borderColor = [[NSColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.5] CGColor];
    
    // 添加阴影效果
    self.containerView.layer.shadowColor = [[NSColor blackColor] CGColor];
    self.containerView.layer.shadowOffset = NSMakeSize(0, -2);
    self.containerView.layer.shadowRadius = 8;
    self.containerView.layer.shadowOpacity = 0.3;
    
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.containerView];
}

- (void)setupSliderView {
    // 创建滑动条
    self.valueSlider = [[NSSlider alloc] init];
    self.valueSlider.minValue = 0.0;
    self.valueSlider.maxValue = 1.0;
    self.valueSlider.doubleValue = 0.5;
    self.valueSlider.target = self;
    self.valueSlider.action = @selector(sliderValueChanged:);
    self.valueSlider.continuous = YES;
    
    // 设置滑动条样式
    self.valueSlider.wantsLayer = YES;
    self.valueSlider.layer.cornerRadius = 3;
    
    // 设置滑动条为白色
    self.valueSlider.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
    
    self.valueSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.valueSlider];
    
    // 创建数值标签
    self.valueLabel = [[NSTextField alloc] init];
    self.valueLabel.stringValue = @"50%";
    self.valueLabel.editable = NO;
    self.valueLabel.bordered = NO;
    self.valueLabel.backgroundColor = [NSColor clearColor];
    self.valueLabel.textColor = [NSColor whiteColor];
    self.valueLabel.font = [NSFont systemFontOfSize:12];
    self.valueLabel.alignment = NSTextAlignmentCenter;
    self.valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.valueLabel];
}

- (void)setupParamSelectionView {
    // 创建滚动视图
    self.paramScrollView = [[NSScrollView alloc] init];
    self.paramScrollView.hasHorizontalScroller = NO; // 隐藏滚动条
    self.paramScrollView.hasVerticalScroller = NO;
    self.paramScrollView.autohidesScrollers = YES;
    self.paramScrollView.wantsLayer = YES;
    self.paramScrollView.layer.backgroundColor = [NSColor clearColor].CGColor;
    self.paramScrollView.layer.cornerRadius = 8;
    self.paramScrollView.layer.masksToBounds = YES; // 裁剪边界，配合渐变效果
    self.paramScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 设置滚动视图的背景为透明
    self.paramScrollView.backgroundColor = [NSColor clearColor];
    self.paramScrollView.drawsBackground = NO;
    
    // 启用鼠标滚轮和触摸板滚动
    self.paramScrollView.allowsMagnification = NO;
    self.paramScrollView.hasHorizontalRuler = NO;
    self.paramScrollView.hasVerticalRuler = NO;
    
    // 启用水平滚动
    self.paramScrollView.horizontalScrollElasticity = NSScrollElasticityAllowed;
    self.paramScrollView.verticalScrollElasticity = NSScrollElasticityNone;
    
    [self.containerView addSubview:self.paramScrollView];
    
    // 创建内容视图
    self.paramSelectionView = [[NSView alloc] init];
    self.paramSelectionView.wantsLayer = YES;
    self.paramSelectionView.layer.backgroundColor = [NSColor clearColor].CGColor;
    self.paramSelectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.paramScrollView setDocumentView:self.paramSelectionView];
    
    self.paramButtons = [[NSMutableArray alloc] init];
    
    // 创建渐变遮罩视图
    [self setupGradientViews];
    
    // 创建滚动按钮
    [self setupScrollButtons];
    
    // 添加滚动监听
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(scrollViewDidScroll:)
                                                 name:NSViewBoundsDidChangeNotification
                                               object:self.paramScrollView.contentView];
}

- (void)setupGradientViews {
    // 创建左侧渐变遮罩
    self.leftGradientView = [[NSView alloc] init];
    self.leftGradientView.wantsLayer = YES;
    self.leftGradientView.layer.backgroundColor = [NSColor clearColor].CGColor;
    self.leftGradientView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.leftGradientView];
    
    // 创建右侧渐变遮罩
    self.rightGradientView = [[NSView alloc] init];
    self.rightGradientView.wantsLayer = YES;
    self.rightGradientView.layer.backgroundColor = [NSColor clearColor].CGColor;
    self.rightGradientView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.rightGradientView];
    
    // 设置渐变遮罩约束
    [NSLayoutConstraint activateConstraints:@[
        // 左侧渐变遮罩
        [self.leftGradientView.leadingAnchor constraintEqualToAnchor:self.paramScrollView.leadingAnchor],
        [self.leftGradientView.topAnchor constraintEqualToAnchor:self.paramScrollView.topAnchor],
        [self.leftGradientView.bottomAnchor constraintEqualToAnchor:self.paramScrollView.bottomAnchor],
        [self.leftGradientView.widthAnchor constraintEqualToConstant:20],
        
        // 右侧渐变遮罩
        [self.rightGradientView.trailingAnchor constraintEqualToAnchor:self.paramScrollView.trailingAnchor],
        [self.rightGradientView.topAnchor constraintEqualToAnchor:self.paramScrollView.topAnchor],
        [self.rightGradientView.bottomAnchor constraintEqualToAnchor:self.paramScrollView.bottomAnchor],
        [self.rightGradientView.widthAnchor constraintEqualToConstant:20]
    ]];
    
    // 初始时隐藏渐变遮罩
    self.leftGradientView.hidden = YES;
    self.rightGradientView.hidden = YES;
}

- (void)setupScrollButtons {
    // 创建左侧滚动按钮
    self.leftScrollButton = [[NSButton alloc] init];
    [self.leftScrollButton setTitle:@"◀"];
    [self.leftScrollButton setBezelStyle:NSBezelStyleRounded];
    [self.leftScrollButton setTarget:self];
    [self.leftScrollButton setAction:@selector(leftScrollButtonClicked:)];
    self.leftScrollButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 设置左侧按钮样式 - 26x26尺寸
    self.leftScrollButton.wantsLayer = YES;
    self.leftScrollButton.layer.cornerRadius = 13; // 调整为圆形
    self.leftScrollButton.layer.backgroundColor = [[NSColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.8] CGColor];
    self.leftScrollButton.layer.borderWidth = 1.0;
    self.leftScrollButton.layer.borderColor = [[NSColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.6] CGColor];
    [self.leftScrollButton setBordered:NO];
    
    // 设置文字颜色 - 适中字体
    NSMutableAttributedString *leftTitle = [[NSMutableAttributedString alloc] initWithString:@"◀"];
    [leftTitle addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, 1)];
    [leftTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:12] range:NSMakeRange(0, 1)];
    [self.leftScrollButton setAttributedTitle:leftTitle];
    
    [self.containerView addSubview:self.leftScrollButton];
    
    // 创建右侧滚动按钮
    self.rightScrollButton = [[NSButton alloc] init];
    [self.rightScrollButton setTitle:@"▶"];
    [self.rightScrollButton setBezelStyle:NSBezelStyleRounded];
    [self.rightScrollButton setTarget:self];
    [self.rightScrollButton setAction:@selector(rightScrollButtonClicked:)];
    self.rightScrollButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 设置右侧按钮样式 - 26x26尺寸
    self.rightScrollButton.wantsLayer = YES;
    self.rightScrollButton.layer.cornerRadius = 13; // 调整为圆形
    self.rightScrollButton.layer.backgroundColor = [[NSColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:0.8] CGColor];
    self.rightScrollButton.layer.borderWidth = 1.0;
    self.rightScrollButton.layer.borderColor = [[NSColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.6] CGColor];
    [self.rightScrollButton setBordered:NO];
    
    // 设置文字颜色 - 适中字体
    NSMutableAttributedString *rightTitle = [[NSMutableAttributedString alloc] initWithString:@"▶"];
    [rightTitle addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, 1)];
    [rightTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:12] range:NSMakeRange(0, 1)];
    [self.rightScrollButton setAttributedTitle:rightTitle];
    
    [self.containerView addSubview:self.rightScrollButton];
    
    // 设置滚动按钮约束 - 26x26像素
    [NSLayoutConstraint activateConstraints:@[
        // 左侧滚动按钮
        [self.leftScrollButton.leadingAnchor constraintEqualToAnchor:self.paramScrollView.leadingAnchor constant:5],
        [self.leftScrollButton.centerYAnchor constraintEqualToAnchor:self.paramScrollView.centerYAnchor],
        [self.leftScrollButton.widthAnchor constraintEqualToConstant:26],
        [self.leftScrollButton.heightAnchor constraintEqualToConstant:26],
        
        // 右侧滚动按钮
        [self.rightScrollButton.trailingAnchor constraintEqualToAnchor:self.paramScrollView.trailingAnchor constant:-5],
        [self.rightScrollButton.centerYAnchor constraintEqualToAnchor:self.paramScrollView.centerYAnchor],
        [self.rightScrollButton.widthAnchor constraintEqualToConstant:26],
        [self.rightScrollButton.heightAnchor constraintEqualToConstant:26]
    ]];
    
    // 初始时隐藏滚动按钮
    self.leftScrollButton.hidden = YES;
    self.rightScrollButton.hidden = YES;
}

- (void)setupBeautyTypeView {
    self.beautyTypeView = [[NSView alloc] init];
    self.beautyTypeView.wantsLayer = YES;
    self.beautyTypeView.layer.backgroundColor = [NSColor clearColor].CGColor;
    self.beautyTypeView.layer.cornerRadius = 8;
    self.beautyTypeView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.beautyTypeView];
    
    self.beautyTypeButtons = [[NSMutableArray alloc] init];
    
    // 创建美颜类型按钮
    for (NSInteger i = 0; i < self.beautyTypeData.count; i++) {
        NSDictionary *beautyType = self.beautyTypeData[i];
        NSString *title = beautyType[@"title"];
        
        NSButton *button = [[NSButton alloc] init];
        [button setTitle:title];
        [button setBezelStyle:NSBezelStyleRounded];
        [button setTarget:self];
        [button setAction:@selector(beautyTypeButtonClicked:)];
        [button setTag:i];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        // 设置按钮样式 - Tab样式
        button.wantsLayer = YES;
        button.layer.cornerRadius = 6;
        button.layer.backgroundColor = [NSColor clearColor].CGColor;
        [button setBordered:NO];
        
        // 设置文字颜色
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
        [attributedTitle addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0] range:NSMakeRange(0, title.length)];
        [attributedTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:12] range:NSMakeRange(0, title.length)];
        [button setAttributedTitle:attributedTitle];
        
        [self.beautyTypeView addSubview:button];
        [self.beautyTypeButtons addObject:button];
    }
    
    // 默认选中第一个
    [self selectBeautyTypeButton:0];
}

- (void)setupConstraints {
    [self.view addSubview:self.containerView];
    
    // 容器视图约束 - 固定在右下角，距离边缘15像素
    self.panelTrailingConstraint = [self.containerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-15];
    self.panelBottomConstraint = [self.containerView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor constant:-15];
    
    [NSLayoutConstraint activateConstraints:@[
        self.panelTrailingConstraint,
        self.panelBottomConstraint,
        [self.containerView.widthAnchor constraintEqualToConstant:320],
        [self.containerView.heightAnchor constraintEqualToConstant:170] // 增加10px高度
    ]];
    
    // 强制更新布局
    [self.view setNeedsLayout:YES];
    [self.view layoutSubtreeIfNeeded];
    
    // 滑动条约束 - 与数值标签在同一行
    [NSLayoutConstraint activateConstraints:@[
        [self.valueSlider.topAnchor constraintEqualToAnchor:self.containerView.topAnchor constant:15],
        [self.valueSlider.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [self.valueSlider.trailingAnchor constraintEqualToAnchor:self.valueLabel.leadingAnchor constant:-10],
        [self.valueSlider.heightAnchor constraintEqualToConstant:25]
    ]];
    
    // 数值标签约束 - 位于滑动条右侧
    [NSLayoutConstraint activateConstraints:@[
        [self.valueLabel.topAnchor constraintEqualToAnchor:self.valueSlider.topAnchor constant:4],
        [self.valueLabel.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-20],
        [self.valueLabel.widthAnchor constraintEqualToConstant:50],
        [self.valueLabel.heightAnchor constraintEqualToConstant:25]
    ]];
    
    // 参数选择区域约束
    [NSLayoutConstraint activateConstraints:@[
        [self.paramScrollView.topAnchor constraintEqualToAnchor:self.valueSlider.bottomAnchor constant:8],
        [self.paramScrollView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:15],
        [self.paramScrollView.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-15],
        [self.paramScrollView.heightAnchor constraintEqualToConstant:50] // 增加高度，确保按钮完全显示
    ]];
    
    // 美颜类型区域约束
    [NSLayoutConstraint activateConstraints:@[
        [self.beautyTypeView.topAnchor constraintEqualToAnchor:self.paramScrollView.bottomAnchor constant:5], // 减少间距
        [self.beautyTypeView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:15],
        [self.beautyTypeView.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-15],
        [self.beautyTypeView.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor constant:-10]
    ]];
    
    // 美颜类型按钮约束
    [self setupBeautyTypeButtonConstraints];
}

- (void)setupBeautyTypeButtonConstraints {
    if (self.beautyTypeButtons.count == 0) return;
    
    // 计算每个按钮的宽度，让它们平均分布
    CGFloat totalWidth = 200; // 总宽度
    CGFloat buttonWidth = totalWidth / self.beautyTypeButtons.count;
    CGFloat buttonHeight = 32;
    
    for (NSInteger i = 0; i < self.beautyTypeButtons.count; i++) {
        NSButton *button = self.beautyTypeButtons[i];
        
        [NSLayoutConstraint activateConstraints:@[
            [button.leadingAnchor constraintEqualToAnchor:self.beautyTypeView.leadingAnchor constant:i * buttonWidth],
            [button.centerYAnchor constraintEqualToAnchor:self.beautyTypeView.centerYAnchor],
            [button.widthAnchor constraintEqualToConstant:buttonWidth],
            [button.heightAnchor constraintEqualToConstant:buttonHeight]
        ]];
    }
}

- (void)updateParamSelectionView {
    // 清除现有的参数按钮
    for (NSButton *button in self.paramButtons) {
        [button removeFromSuperview];
    }
    [self.paramButtons removeAllObjects];
    
    // 获取当前美颜类型的参数
    NSDictionary *currentBeautyTypeData = nil;
    for (NSDictionary *beautyType in self.beautyTypeData) {
        if ([beautyType[@"type"] integerValue] == self.currentBeautyType) {
            currentBeautyTypeData = beautyType;
            break;
        }
    }
    
    if (!currentBeautyTypeData) return;
    
    NSArray *params = currentBeautyTypeData[@"params"];
    
    // 创建参数按钮
    for (NSInteger i = 0; i < params.count; i++) {
        NSDictionary *param = params[i];
        NSString *title = param[@"title"];
        
        NSButton *button = [[NSButton alloc] init];
        [button setTitle:title];
        [button setBezelStyle:NSBezelStyleRounded];
        [button setTarget:self];
        [button setAction:@selector(paramButtonClicked:)];
        [button setTag:i];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        // 设置按钮样式
        button.wantsLayer = YES;
        button.layer.cornerRadius = 15; // 圆形按钮
        button.layer.backgroundColor = [NSColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9].CGColor;
        button.layer.borderWidth = 1.0;
        button.layer.borderColor = [[NSColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.8] CGColor];
        [button setBordered:NO];
        
        // 设置文字颜色
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
        [attributedTitle addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, title.length)];
        [attributedTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:11] range:NSMakeRange(0, title.length)];
        [button setAttributedTitle:attributedTitle];
        
        [self.paramSelectionView addSubview:button];
        [self.paramButtons addObject:button];
    }
    
    // 设置参数按钮约束
    [self setupParamButtonConstraints];
    
    // 默认选中第一个参数
    if (self.paramButtons.count > 0) {
        [self selectParamButton:0];
        // 重要：更新当前参数类型为第一个参数，确保滑块调节的是正确的参数
        // 这解决了切换美颜类型时滑块调节值与实际参数不匹配的问题
        NSDictionary *firstParam = params[0];
        self.currentParamType = [firstParam[@"type"] integerValue];
        // 更新滑动条为第一个参数的数值
        [self updateSliderForCurrentParam];
    }
}

- (void)setupParamButtonConstraints {
    if (self.paramButtons.count == 0) return;
    
    CGFloat buttonWidth = 50;
    CGFloat buttonHeight = 32;
    CGFloat spacing = 8;
    
    // 计算总宽度
    CGFloat totalWidth = self.paramButtons.count * buttonWidth + (self.paramButtons.count - 1) * spacing;
    
    // 设置内容视图的宽度和高度
    // 使用frame设置而不是约束，确保滚动正常工作
    self.paramSelectionView.frame = NSMakeRect(0, 0, totalWidth, 50);
    
    // 添加约束确保内容视图有正确的高度
    [NSLayoutConstraint activateConstraints:@[
        [self.paramSelectionView.heightAnchor constraintEqualToConstant:50]
    ]];
    
    // 设置按钮约束，所有按钮排成一行
    for (NSInteger i = 0; i < self.paramButtons.count; i++) {
        NSButton *button = self.paramButtons[i];
        
        if (i == 0) {
            // 第一个按钮 - 垂直居中
            [NSLayoutConstraint activateConstraints:@[
                [button.leadingAnchor constraintEqualToAnchor:self.paramSelectionView.leadingAnchor],
                [button.centerYAnchor constraintEqualToAnchor:self.paramSelectionView.centerYAnchor],
                [button.widthAnchor constraintEqualToConstant:buttonWidth],
                [button.heightAnchor constraintEqualToConstant:buttonHeight]
            ]];
        } else {
            // 其他按钮
            NSButton *previousButton = self.paramButtons[i-1];
            [NSLayoutConstraint activateConstraints:@[
                [button.leadingAnchor constraintEqualToAnchor:previousButton.trailingAnchor constant:spacing],
                [button.centerYAnchor constraintEqualToAnchor:self.paramSelectionView.centerYAnchor],
                [button.widthAnchor constraintEqualToConstant:buttonWidth],
                [button.heightAnchor constraintEqualToConstant:buttonHeight]
            ]];
        }
    }
    
    // 强制更新滚动视图的内容大小
    [self.paramScrollView setNeedsDisplay:YES];
    
    // 确保滚动视图知道内容大小已改变
    [self.paramScrollView reflectScrolledClipView:self.paramScrollView.contentView];
    
    // 强制更新布局，确保按钮居中
    [self.paramSelectionView setNeedsLayout:YES];
    [self.paramSelectionView layoutSubtreeIfNeeded];
    
    // 检测是否需要显示滚动指示器
    [self updateScrollIndicators];
}

- (void)updateScrollIndicators {
    // 延迟执行，确保布局已完成
    dispatch_async(dispatch_get_main_queue(), ^{
        NSRect visibleRect = self.paramScrollView.documentVisibleRect;
        NSRect contentRect = self.paramSelectionView.frame;
        
        // 检查是否需要显示滚动指示器
        BOOL canScrollLeft = visibleRect.origin.x > 0;
        BOOL canScrollRight = visibleRect.origin.x + visibleRect.size.width < contentRect.size.width;
        
        // 更新左侧指示器
        self.leftGradientView.hidden = !canScrollLeft;
        self.leftScrollButton.hidden = !canScrollLeft;
        
        // 更新右侧指示器
        self.rightGradientView.hidden = !canScrollRight;
        self.rightScrollButton.hidden = !canScrollRight;
        
        // 创建渐变效果
        [self updateGradientEffects];
    });
}

- (void)updateGradientEffects {
    // 创建左侧渐变遮罩
    if (!self.leftGradientView.hidden) {
        CAGradientLayer *leftGradient = [CAGradientLayer layer];
        leftGradient.frame = self.leftGradientView.bounds;
        leftGradient.colors = @[
            (id)[[NSColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:0.9] CGColor],
            (id)[[NSColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:0.0] CGColor]
        ];
        leftGradient.startPoint = CGPointMake(0, 0.5);
        leftGradient.endPoint = CGPointMake(1, 0.5);
        self.leftGradientView.layer.sublayers = @[leftGradient];
    }
    
    // 创建右侧渐变遮罩
    if (!self.rightGradientView.hidden) {
        CAGradientLayer *rightGradient = [CAGradientLayer layer];
        rightGradient.frame = self.rightGradientView.bounds;
        rightGradient.colors = @[
            (id)[[NSColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:0.0] CGColor],
            (id)[[NSColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:0.9] CGColor]
        ];
        rightGradient.startPoint = CGPointMake(0, 0.5);
        rightGradient.endPoint = CGPointMake(1, 0.5);
        self.rightGradientView.layer.sublayers = @[rightGradient];
    }
}

#pragma mark - Button Actions

- (void)sliderValueChanged:(NSSlider *)slider {
    float value = slider.floatValue;
    self.valueLabel.stringValue = [NSString stringWithFormat:@"%.0f%%", value * 100];
    
    // 保存当前参数的值 - 使用美颜类型和参数类型的组合作为key
    NSString *key = [NSString stringWithFormat:@"%ld_%ld", (long)self.currentBeautyType, (long)self.currentParamType];
    self.paramValues[key] = @(value);
    
    // 通知代理
    if ([self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:param:value:)]) {
        [self.delegate beautyPanelDidChangeParam:self.currentBeautyType param:self.currentParamType value:value];
    }
}

- (void)beautyTypeButtonClicked:(NSButton *)button {
    NSInteger index = button.tag;
    [self selectBeautyTypeButton:index];
    
    // 更新当前美颜类型
    NSDictionary *beautyTypeData = self.beautyTypeData[index];
    self.currentBeautyType = [beautyTypeData[@"type"] integerValue];
    
    // 更新参数选择区域
    [self updateParamSelectionView];
    // updateParamSelectionView 内部已经调用了 updateSliderForCurrentParam，这里不需要重复调用
}

- (void)paramButtonClicked:(NSButton *)button {
    NSInteger index = button.tag;
    [self selectParamButton:index];
    
    // 更新当前参数类型
    NSDictionary *currentBeautyTypeData = nil;
    for (NSDictionary *beautyType in self.beautyTypeData) {
        if ([beautyType[@"type"] integerValue] == self.currentBeautyType) {
            currentBeautyTypeData = beautyType;
            break;
        }
    }
    
    if (currentBeautyTypeData) {
        NSArray *params = currentBeautyTypeData[@"params"];
        if (index < params.count) {
            NSDictionary *param = params[index];
            self.currentParamType = [param[@"type"] integerValue];
            
            // 恢复该参数对应的滑动条数值
            [self updateSliderForCurrentParam];
        }
    }
}

- (void)leftScrollButtonClicked:(NSButton *)button {
    NSRect visibleRect = self.paramScrollView.documentVisibleRect;
    CGFloat scrollAmount = 100; // 每次滚动的距离
    NSRect newRect = NSMakeRect(MAX(0, visibleRect.origin.x - scrollAmount), 
                               visibleRect.origin.y, 
                               visibleRect.size.width, 
                               visibleRect.size.height);
    [self.paramScrollView.contentView scrollToPoint:newRect.origin];
    [self.paramScrollView reflectScrolledClipView:self.paramScrollView.contentView];
    
    // 更新滚动指示器
    [self updateScrollIndicators];
}

- (void)rightScrollButtonClicked:(NSButton *)button {
    NSRect visibleRect = self.paramScrollView.documentVisibleRect;
    NSRect contentRect = self.paramSelectionView.frame;
    CGFloat scrollAmount = 100; // 每次滚动的距离
    CGFloat maxX = contentRect.size.width - visibleRect.size.width;
    NSRect newRect = NSMakeRect(MIN(maxX, visibleRect.origin.x + scrollAmount), 
                               visibleRect.origin.y, 
                               visibleRect.size.width, 
                               visibleRect.size.height);
    [self.paramScrollView.contentView scrollToPoint:newRect.origin];
    [self.paramScrollView reflectScrolledClipView:self.paramScrollView.contentView];
    
    // 更新滚动指示器
    [self updateScrollIndicators];
}

- (void)scrollViewDidScroll:(NSNotification *)notification {
    // 滚动时更新指示器
    [self updateScrollIndicators];
}

- (void)dealloc {
    // 移除通知监听
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Helper Methods

- (void)updateSliderForCurrentParam {
    // 获取当前参数对应的数值 - 使用美颜类型和参数类型的组合作为key
    NSString *key = [NSString stringWithFormat:@"%ld_%ld", (long)self.currentBeautyType, (long)self.currentParamType];
    NSNumber *paramValue = self.paramValues[key];
    if (paramValue) {
        float value = paramValue.floatValue;
        
        // 更新滑动条数值（不触发回调）
        self.valueSlider.doubleValue = value;
        
        // 更新数值标签
        self.valueLabel.stringValue = [NSString stringWithFormat:@"%.0f%%", value * 100];
    } else {
        // 如果没有找到对应的值，设置为默认值0
        self.valueSlider.doubleValue = 0.0;
        self.valueLabel.stringValue = @"0%";
    }
}

- (void)selectBeautyTypeButton:(NSInteger)index {
    for (NSInteger i = 0; i < self.beautyTypeButtons.count; i++) {
        NSButton *button = self.beautyTypeButtons[i];
        NSString *title = button.title;
        
        if (i == index) {
            // 选中状态 - 白色背景，深色文字
            button.layer.backgroundColor = [NSColor whiteColor].CGColor;
            button.layer.cornerRadius = 6;
            
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
            [attributedTitle addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0] range:NSMakeRange(0, title.length)];
            [attributedTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:12 weight:NSFontWeightMedium] range:NSMakeRange(0, title.length)];
            [button setAttributedTitle:attributedTitle];
        } else {
            // 未选中状态 - 透明背景，浅色文字
            button.layer.backgroundColor = [NSColor clearColor].CGColor;
            button.layer.cornerRadius = 6;
            
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
            [attributedTitle addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0] range:NSMakeRange(0, title.length)];
            [attributedTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:12] range:NSMakeRange(0, title.length)];
            [button setAttributedTitle:attributedTitle];
        }
    }
}

- (void)selectParamButton:(NSInteger)index {
    for (NSInteger i = 0; i < self.paramButtons.count; i++) {
        NSButton *button = self.paramButtons[i];
        NSString *title = button.title;
        
        if (i == index) {
            // 选中状态 - 蓝色背景，白色文字
            button.layer.backgroundColor = [NSColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0].CGColor;
            button.layer.borderColor = [[NSColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:1.0] CGColor];
            button.layer.borderWidth = 1.0;
            
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
            [attributedTitle addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, title.length)];
            [attributedTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:11 weight:NSFontWeightMedium] range:NSMakeRange(0, title.length)];
            [button setAttributedTitle:attributedTitle];
        } else {
            // 未选中状态 - 深灰色背景，白色文字
            button.layer.backgroundColor = [NSColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9].CGColor;
            button.layer.borderColor = [[NSColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.8] CGColor];
            button.layer.borderWidth = 1.0;
            
            NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:title];
            [attributedTitle addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, title.length)];
            [attributedTitle addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:11] range:NSMakeRange(0, title.length)];
            [button setAttributedTitle:attributedTitle];
        }
    }
}

#pragma mark - Panel Visibility Control

- (void)togglePanelVisibility {
    if (self.isPanelVisible) {
        [self hidePanel];
    } else {
        [self showPanel];
    }
}

- (void)showPanel {
    if (self.isPanelVisible) return;
    
    self.isPanelVisible = YES;
    
    // 动画显示面板
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.3;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        // 恢复到正常位置
        self.panelTrailingConstraint.constant = -15;
        self.panelBottomConstraint.constant = -15;
        
        // 设置动画属性
        self.panelTrailingConstraint.animator.constant = -15;
        self.panelBottomConstraint.animator.constant = -15;
        
        // 淡入效果
        self.containerView.animator.alphaValue = 1.0;
        
    } completionHandler:^{
        // 动画完成后的处理
        [self updateHideTipVisibility];
    }];
}

- (void)hidePanel {
    if (!self.isPanelVisible) return;
    
    self.isPanelVisible = NO;
    
    // 动画隐藏面板
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
        context.duration = 0.3;
        context.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        // 移动到右下角边缘外
        self.panelTrailingConstraint.constant = 320; // 面板宽度，完全移出视野
        self.panelBottomConstraint.constant = -15;   // 保持底部对齐
        
        // 设置动画属性
        self.panelTrailingConstraint.animator.constant = 320;
        self.panelBottomConstraint.animator.constant = -15;
        
        // 淡出效果
        self.containerView.animator.alphaValue = 0.0;
        
    } completionHandler:^{
        // 动画完成后的处理
        [self updateHideTipVisibility];
    }];
}

#pragma mark - Hide Tip Label

- (void)setupHideTipLabel {
    // 创建提示标签
    self.hideTipLabel = [[NSTextField alloc] init];
    self.hideTipLabel.stringValue = @"按 Cmd+B 隐藏面板";
    self.hideTipLabel.font = [NSFont systemFontOfSize:10];
    self.hideTipLabel.textColor = [NSColor colorWithWhite:0.7 alpha:0.8];
    self.hideTipLabel.backgroundColor = [NSColor clearColor];
    self.hideTipLabel.bordered = NO;
    self.hideTipLabel.editable = NO;
    self.hideTipLabel.selectable = NO;
    self.hideTipLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 添加到容器视图
    [self.containerView addSubview:self.hideTipLabel];
    
    // 设置约束 - 右下角，增加边距让位置更美观
    [NSLayoutConstraint activateConstraints:@[
        [self.hideTipLabel.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-12],
        [self.hideTipLabel.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor constant:-8]
    ]];
    
    // 初始状态：显示提示
    [self updateHideTipVisibility];
}

- (void)updateHideTipVisibility {
    if (self.hideTipLabel) {
        // 当面板可见时显示提示，隐藏时不显示
        self.hideTipLabel.hidden = !self.isPanelVisible;
    }
}

@end
