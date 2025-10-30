//
//  BeautyPanelViewController.m
//  FBExampleObjc
//
//  Created by admin on 2025/9/8.
//

#import "BeautyPanelViewController.h"

@interface BeautyPanelViewController ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UISlider *valueSlider;
@property (nonatomic, strong) UILabel *valueLabel;
@property (nonatomic, strong) UIScrollView *paramScrollView;
@property (nonatomic, strong) UIView *paramSelectionView;
@property (nonatomic, strong) NSMutableArray<UIButton *> *paramButtons;
@property (nonatomic, strong) UIView *beautyTypeView;
@property (nonatomic, strong) NSMutableArray<UIButton *> *beautyTypeButtons;
@property (nonatomic, assign) FBBeautyType currentBeautyType;
@property (nonatomic, assign) NSInteger currentParamType;
@property (nonatomic, strong) NSArray<NSDictionary *> *beautyTypeData;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *paramValues;

@end

@implementation BeautyPanelViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentBeautyType = FBBeautyType_Basic;
        _paramValues = [[NSMutableDictionary alloc] init];
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
                @{@"title": @"背景图片", @"type": @(FBSegmentationParam_BackgroundImage)}
            ]
        }
    ];
}

- (void)initializeParamValues {
    // 使用 组合键(beautyType << 12 | paramType) 存储，避免不同美颜类型的枚举值冲突
    for (NSDictionary *beautyType in self.beautyTypeData) {
        FBBeautyType type = [beautyType[@"type"] integerValue];
        NSArray *params = beautyType[@"params"];
        for (NSDictionary *param in params) {
            NSInteger paramType = [param[@"type"] integerValue];
            NSNumber *key = [self compositeKeyForBeautyType:type param:paramType];
            // 默认值可自定义，这里统一初始化为 0
            self.paramValues[key] = @(0.0);
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
    self.view.backgroundColor = [UIColor clearColor];
    
    [self setupContainerView];
    [self setupSliderView];
    [self setupParamSelectionView];
    [self setupBeautyTypeView];
    [self setupConstraints];
    [self updateParamSelectionView];
}

- (void)setupContainerView {
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [[UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:0.5] colorWithAlphaComponent:0.5];
    self.containerView.layer.cornerRadius = 15;
    self.containerView.layer.borderWidth = 1.0;
    self.containerView.layer.borderColor = [[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.5] CGColor];
    
    self.containerView.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.containerView.layer.shadowOffset = CGSizeMake(0, -2);
    self.containerView.layer.shadowRadius = 8;
    self.containerView.layer.shadowOpacity = 0.3;
    
    self.containerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.containerView];
}

- (void)setupSliderView {
    self.valueSlider = [[UISlider alloc] init];
    self.valueSlider.minimumValue = 0.0;
    self.valueSlider.maximumValue = 1.0;
    self.valueSlider.value = 0.5;
    [self.valueSlider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    
    self.valueSlider.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.valueSlider];
    
    self.valueLabel = [[UILabel alloc] init];
    self.valueLabel.text = @"50%";
    self.valueLabel.textColor = [UIColor whiteColor];
    self.valueLabel.font = [UIFont systemFontOfSize:12];
    self.valueLabel.textAlignment = NSTextAlignmentCenter;
    self.valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.valueLabel];
}

- (void)setupParamSelectionView {
    self.paramScrollView = [[UIScrollView alloc] init];
    self.paramScrollView.showsHorizontalScrollIndicator = NO;
    self.paramScrollView.showsVerticalScrollIndicator = NO;
    self.paramScrollView.backgroundColor = [UIColor clearColor];
    self.paramScrollView.userInteractionEnabled = YES; // 确保滚动视图启用用户交互
    self.paramScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.paramScrollView];
    
    self.paramSelectionView = [[UIView alloc] init];
    self.paramSelectionView.backgroundColor = [UIColor clearColor];
    self.paramSelectionView.userInteractionEnabled = YES; // 确保内容视图启用用户交互
    self.paramSelectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.paramScrollView addSubview:self.paramSelectionView];
    
    self.paramButtons = [[NSMutableArray alloc] init];
}

- (void)setupBeautyTypeView {
    self.beautyTypeView = [[UIView alloc] init];
    self.beautyTypeView.backgroundColor = [UIColor clearColor];
    self.beautyTypeView.userInteractionEnabled = YES; // 确保美颜类型视图启用用户交互
    self.beautyTypeView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.containerView addSubview:self.beautyTypeView];
    
    self.beautyTypeButtons = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0; i < self.beautyTypeData.count; i++) {
        NSDictionary *beautyType = self.beautyTypeData[i];
        NSString *title = beautyType[@"title"];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitleColor:[UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0] forState:UIControlStateNormal];
        button.backgroundColor = [UIColor clearColor];
        button.layer.cornerRadius = 6;
        button.titleLabel.font = [UIFont systemFontOfSize:12];
        button.tag = i;
        button.userInteractionEnabled = YES; // 确保用户交互启用
        [button addTarget:self action:@selector(beautyTypeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.beautyTypeView addSubview:button];
        [self.beautyTypeButtons addObject:button];
    }
    
    [self selectBeautyTypeButton:0];
}

- (void)setupConstraints {
    [NSLayoutConstraint activateConstraints:@[
        [self.containerView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:15],
        [self.containerView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-15],
        [self.containerView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-15],
        [self.containerView.heightAnchor constraintEqualToConstant:170]
    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.valueSlider.topAnchor constraintEqualToAnchor:self.containerView.topAnchor constant:15],
        [self.valueSlider.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [self.valueSlider.trailingAnchor constraintEqualToAnchor:self.valueLabel.leadingAnchor constant:-10],
        [self.valueSlider.heightAnchor constraintEqualToConstant:25]
    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.valueLabel.topAnchor constraintEqualToAnchor:self.valueSlider.topAnchor constant:4],
        [self.valueLabel.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-20],
        [self.valueLabel.widthAnchor constraintEqualToConstant:50],
        [self.valueLabel.heightAnchor constraintEqualToConstant:25]
    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.paramScrollView.topAnchor constraintEqualToAnchor:self.valueSlider.bottomAnchor constant:8],
        [self.paramScrollView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:15],
        [self.paramScrollView.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-15],
        [self.paramScrollView.heightAnchor constraintEqualToConstant:50]
    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.beautyTypeView.topAnchor constraintEqualToAnchor:self.paramScrollView.bottomAnchor constant:5],
        [self.beautyTypeView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:15],
        [self.beautyTypeView.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-15],
        [self.beautyTypeView.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor constant:-10]
    ]];
    
    [self setupBeautyTypeButtonConstraints];
}

- (void)setupBeautyTypeButtonConstraints {
    if (self.beautyTypeButtons.count == 0) return;
    
    CGFloat totalWidth = 200;
    CGFloat buttonWidth = totalWidth / self.beautyTypeButtons.count;
    CGFloat buttonHeight = 32;
    
    for (NSInteger i = 0; i < self.beautyTypeButtons.count; i++) {
        UIButton *button = self.beautyTypeButtons[i];
        
        [NSLayoutConstraint activateConstraints:@[
            [button.leadingAnchor constraintEqualToAnchor:self.beautyTypeView.leadingAnchor constant:i * buttonWidth],
            [button.centerYAnchor constraintEqualToAnchor:self.beautyTypeView.centerYAnchor],
            [button.widthAnchor constraintEqualToConstant:buttonWidth],
            [button.heightAnchor constraintEqualToConstant:buttonHeight]
        ]];
    }
}

- (void)updateParamSelectionView {
    for (UIButton *button in self.paramButtons) {
        [button removeFromSuperview];
    }
    [self.paramButtons removeAllObjects];
    
    NSDictionary *currentBeautyTypeData = nil;
    for (NSDictionary *beautyType in self.beautyTypeData) {
        if ([beautyType[@"type"] integerValue] == self.currentBeautyType) {
            currentBeautyTypeData = beautyType;
            break;
        }
    }
    
    if (!currentBeautyTypeData) return;
    
    NSArray *params = currentBeautyTypeData[@"params"];
    
    for (NSInteger i = 0; i < params.count; i++) {
        NSDictionary *param = params[i];
        NSString *title = param[@"title"];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        [button setTitle:title forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.backgroundColor = [[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9] colorWithAlphaComponent:0.9];
        button.layer.cornerRadius = 15;
        button.layer.borderWidth = 1.0;
        button.layer.borderColor = [[UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.8] CGColor];
        button.titleLabel.font = [UIFont systemFontOfSize:11];
        button.tag = i;
        button.userInteractionEnabled = YES;
        button.enabled = YES;
        [button addTarget:self action:@selector(paramButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self.paramSelectionView addSubview:button];
        [self.paramButtons addObject:button];
    }
    
    [self setupParamButtonConstraints];
    
    if (self.paramButtons.count > 0) {
        [self selectParamButton:0];
        // 重要：更新当前参数类型为第一个参数，确保滑块调节的是正确的参数
        // 这解决了切换美颜类型时滑块调节值与实际参数不匹配的问题
        NSDictionary *firstParam = params[0];
        self.currentParamType = [firstParam[@"type"] integerValue];
        [self updateSliderForCurrentParam];
    }
}

- (void)setupParamButtonConstraints {
    if (self.paramButtons.count == 0) return;
    
    CGFloat buttonWidth = 50;
    CGFloat buttonHeight = 32;
    CGFloat spacing = 8;
    
    CGFloat totalWidth = self.paramButtons.count * buttonWidth + (self.paramButtons.count - 1) * spacing;
    
    // 设置 paramSelectionView 的约束
    [NSLayoutConstraint activateConstraints:@[
        [self.paramSelectionView.leadingAnchor constraintEqualToAnchor:self.paramScrollView.leadingAnchor],
        [self.paramSelectionView.trailingAnchor constraintEqualToAnchor:self.paramScrollView.trailingAnchor],
        [self.paramSelectionView.topAnchor constraintEqualToAnchor:self.paramScrollView.topAnchor],
        [self.paramSelectionView.bottomAnchor constraintEqualToAnchor:self.paramScrollView.bottomAnchor],
        [self.paramSelectionView.heightAnchor constraintEqualToConstant:50],
        [self.paramSelectionView.widthAnchor constraintEqualToConstant:totalWidth]
    ]];
    
    for (NSInteger i = 0; i < self.paramButtons.count; i++) {
        UIButton *button = self.paramButtons[i];
        
        if (i == 0) {
            [NSLayoutConstraint activateConstraints:@[
                [button.leadingAnchor constraintEqualToAnchor:self.paramSelectionView.leadingAnchor],
                [button.centerYAnchor constraintEqualToAnchor:self.paramSelectionView.centerYAnchor],
                [button.widthAnchor constraintEqualToConstant:buttonWidth],
                [button.heightAnchor constraintEqualToConstant:buttonHeight]
            ]];
        } else {
            UIButton *previousButton = self.paramButtons[i-1];
            [NSLayoutConstraint activateConstraints:@[
                [button.leadingAnchor constraintEqualToAnchor:previousButton.trailingAnchor constant:spacing],
                [button.centerYAnchor constraintEqualToAnchor:self.paramSelectionView.centerYAnchor],
                [button.widthAnchor constraintEqualToConstant:buttonWidth],
                [button.heightAnchor constraintEqualToConstant:buttonHeight]
            ]];
        }
    }
    
    // 强制布局更新
    [self.paramScrollView setNeedsLayout];
    [self.paramScrollView layoutIfNeeded];
    [self.paramSelectionView setNeedsLayout];
    [self.paramSelectionView layoutIfNeeded];
    
    // 设置 contentSize
    self.paramScrollView.contentSize = CGSizeMake(totalWidth, 50);
}

#pragma mark - Button Actions

- (void)sliderValueChanged:(UISlider *)slider {
    float value = slider.value;
    self.valueLabel.text = [NSString stringWithFormat:@"%.0f%%", value * 100];
    // 以组合键存储当前美颜类型下当前参数的值
    NSNumber *key = [self compositeKeyForBeautyType:self.currentBeautyType param:self.currentParamType];
    self.paramValues[key] = @(value);
    
    if ([self.delegate respondsToSelector:@selector(beautyPanelDidChangeParam:param:value:)]) {
        [self.delegate beautyPanelDidChangeParam:self.currentBeautyType param:self.currentParamType value:value];
    }
}

- (void)beautyTypeButtonClicked:(UIButton *)button {
    NSInteger index = button.tag;
    [self selectBeautyTypeButton:index];
    
    NSDictionary *beautyTypeData = self.beautyTypeData[index];
    self.currentBeautyType = [beautyTypeData[@"type"] integerValue];
    
    [self updateParamSelectionView];
    // updateParamSelectionView 内部已经调用了 updateSliderForCurrentParam，这里不需要重复调用
}

- (void)paramButtonClicked:(UIButton *)button {
    NSInteger index = button.tag;
    [self selectParamButton:index];
    
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
            [self updateSliderForCurrentParam];
        }
    }
}

#pragma mark - Helper Methods

- (void)updateSliderForCurrentParam {
    // 按组合键获取当前美颜类型下当前参数的值
    NSNumber *paramValue = self.paramValues[[self compositeKeyForBeautyType:self.currentBeautyType param:self.currentParamType]];
    if (paramValue) {
        float value = paramValue.floatValue;
        self.valueSlider.value = value;
        self.valueLabel.text = [NSString stringWithFormat:@"%.0f%%", value * 100];
    }
}

// 组合键：使用高 4 位记录美颜类型，低 12 位记录参数值
- (NSNumber *)compositeKeyForBeautyType:(FBBeautyType)type param:(NSInteger)paramType {
    NSInteger key = (((NSInteger)type & 0xF) << 12) | (paramType & 0xFFF);
    return @(key);
}

- (void)selectBeautyTypeButton:(NSInteger)index {
    for (NSInteger i = 0; i < self.beautyTypeButtons.count; i++) {
        UIButton *button = self.beautyTypeButtons[i];
        
        if (i == index) {
            button.backgroundColor = [UIColor whiteColor];
            [button setTitleColor:[UIColor colorWithRed:0.2 green:0.2 blue:0.2 alpha:1.0] forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:12 weight:UIFontWeightMedium];
        } else {
            button.backgroundColor = [UIColor clearColor];
            [button setTitleColor:[UIColor colorWithRed:0.7 green:0.7 blue:0.7 alpha:1.0] forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:12];
        }
    }
}

- (void)selectParamButton:(NSInteger)index {
    for (NSInteger i = 0; i < self.paramButtons.count; i++) {
        UIButton *button = self.paramButtons[i];
        
        if (i == index) {
            button.backgroundColor = [[UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0] colorWithAlphaComponent:1.0];
            button.layer.borderColor = [[UIColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:1.0] CGColor];
            button.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightMedium];
        } else {
            button.backgroundColor = [[UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:0.9] colorWithAlphaComponent:0.9];
            button.layer.borderColor = [[UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:0.8] CGColor];
            button.titleLabel.font = [UIFont systemFontOfSize:11];
        }
    }
}

@end
