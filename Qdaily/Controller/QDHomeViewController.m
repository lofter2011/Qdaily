//
//  QDHomeViewController.m
//  Qdaily
//
//  Created by Envy15 on 15/10/7.
//  Copyright (c) 2015年 c344081. All rights reserved.
//

#import "QDHomeViewController.h"
#import "QDHomeFeedArticleViewController.h"
#import "QDHomeLabFeedViewController.h"
#import "QDScrollView.h"

@interface QDHomeViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate, QDHomeFeedArticleViewCollectionViewDelegate>
/** ScrollView */
@property (nonatomic, weak) QDScrollView *scrollView;
/** 自定义的NaviBar */
@property (nonatomic, weak) UIView *naviBar;
/** Q 选项 */
@property (nonatomic, weak)  UIButton *qButton;
/** Lab 选项 */
@property (nonatomic, weak)  UIButton *labButton;
/** 选项底部指示器 */
@property (nonatomic, weak)  UIView *indicator;
/** 记录当前选中按钮 */
@property (nonatomic, weak)  UIButton *selectedButton;
/** 首页文章控制器 */
@property (nonatomic, strong)  QDHomeFeedArticleViewController *homeFeedVc;
/** 实验室控制器 */
@property (nonatomic, strong)  QDHomeLabFeedViewController *labFeedVc;
/** 将要显示的控制器 */
@property (nonatomic, weak)  UIViewController *willShowVc;
/** 选项卡按钮数组 */
@property (nonatomic, strong) NSMutableArray *tabButtons;

/** 定时器 */
@property (nonatomic, weak) NSTimer *timer;
@end

@implementation QDHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 设置背景色
    self.view.backgroundColor = QDLightGrayColor;
    
    [self setupChildVc];
    
    [self setupScrollView];
    
    [self setupNaviBar];
}

#pragma mark -
#pragma mark - lazyload
- (QDHomeFeedArticleViewController *)homeFeedVc {
    if (!_homeFeedVc) {
        _homeFeedVc = [[QDHomeFeedArticleViewController alloc] init];
        _homeFeedVc.delegate = self;
    }
    return _homeFeedVc;
}

- (QDHomeLabFeedViewController *)labFeedVc {
    if (!_labFeedVc) {
        _labFeedVc = [[QDHomeLabFeedViewController alloc] init];
    }
    return _labFeedVc;
}

- (NSMutableArray *)tabButtons {
    if (!_tabButtons) {
        _tabButtons = [NSMutableArray array];
    }
    return _tabButtons;
}

#pragma mark -
#pragma mark - 添加子控制器
- (void)setupChildVc {
    [self addChildViewController:self.homeFeedVc];
    [self addChildViewController:self.labFeedVc];
}

#pragma mark - 设置 ScrollView
- (void)setupScrollView {
    QDScrollView *scrollView = [[QDScrollView alloc] init];
    scrollView.frame = self.view.bounds;
    
    // 隐藏滚动条
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    
    // 取消回弹
    scrollView.bounces = NO;
    
    // 设置分页
    scrollView.pagingEnabled = YES;
    
    // 设置代理
    scrollView.delegate = self;
    
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
    
    NSInteger count = self.childViewControllers.count;
    scrollView.contentSize = CGSizeMake(QDScreenW * count, QDScreenH);
    
    // 默认选中首页,下面这个方法懒加载视图
    [self scrollViewDidEndScrollingAnimation:scrollView];
}

#pragma mark - 设置顶部自定义导航条
- (void)setupNaviBar {
    UIView *naviBar = [[UIView alloc] init];
    naviBar.frame = CGRectMake(0, 0, QDScreenW, QDNaviBarMaxY);
    [self.view addSubview:naviBar];
    self.naviBar = naviBar;

    // 添加透明模糊层
    [naviBar addBlurViewWithAlpha:0.5];
    
    // 添加选项卡按钮
    UIButton *qButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [qButton setImage:[UIImage imageNamed:@"home_tab_q"] forState:UIControlStateNormal];
    [qButton setImage:[UIImage imageNamed:@"home_tab_q_h"] forState:UIControlStateDisabled];
    [naviBar addSubview:qButton];
    [self.tabButtons addObject:qButton];
    self.qButton = qButton;

    UIButton *labButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [labButton setImage:[UIImage imageNamed:@"home_tab_lab"] forState:UIControlStateNormal];
    [labButton setImage:[UIImage imageNamed:@"home_tab_lab_h"] forState:UIControlStateDisabled];
    [naviBar addSubview:labButton];
    [self.tabButtons addObject:labButton];
    self.labButton = labButton;
    
    
    // 设置按钮的 Frame
    NSInteger count = self.childViewControllers.count;
    CGFloat buttonW = 1.0 * QDScreenW / count;
    CGFloat buttonH = QDNaviBarH;
    CGFloat buttonY = QDStatusBarH;
    CGFloat buttonX = 0;
    
    for (NSInteger i = 0; i < count; i++) {
        
        UIButton *button = self.tabButtons[i];
        buttonX = buttonW * i;
        button.frame = CGRectMake(buttonX, buttonY, buttonW, buttonH);
        
        // 取消按钮高亮
        button.adjustsImageWhenHighlighted = NO;
        
        // 添加点击事件
        [button addTarget:self action:@selector(selectTabButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    // 设置指示器
    UIView *indicator = [[UIView alloc] init];
    indicator.backgroundColor = QDHighlightColor;
    indicator.width = buttonW * 0.5;
    indicator.height = 3;
    indicator.y = QDNaviBarMaxY - indicator.height;
    [naviBar addSubview:indicator];
    self.indicator = indicator;
    
     // 默认选中第一个
    qButton.enabled = NO;
    indicator.centerX = qButton.centerX;
    self.selectedButton = qButton;
}

#pragma mark - 更新选项卡状态(包括指示器位置)
- (void)selectTabButton: (UIButton *)button {
    
    // 更改按钮选中状态
    button.enabled = !button.enabled;
    // 修改之前选中按钮的状态
    self.selectedButton.enabled = !self.selectedButton.enabled;
    
    // 更改指示器的位置
    [UIView animateWithDuration:0.25 animations:^{
        self.indicator.centerX = button.centerX;
    }];
    
    // 记录当前选中按钮
    self.selectedButton = button;
    
    // 计算 offset
    NSInteger index = [self.tabButtons indexOfObject:button];
    CGFloat offsetX = self.scrollView.width * index;
    
    // 更改Offset, 切换子控制器
    [self.scrollView setContentOffset:CGPointMake(offsetX, self.scrollView.contentOffset.y) animated:YES];
}

#pragma mark - 定时器相关
- (void)startTimer {
    // 停掉上一个定时器
    [self stopTimer];
    // 开启新的定时器
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(showMenuButton) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    _timer = timer;
}

- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)showMenuButton {
    
}

#pragma mark -
#pragma mark - 选择指定 Index 的选项
- (void)selectTabAtIndex:(NSInteger)index {
    [self selectTabButton:self.tabButtons[index]];
}

#pragma mark - ScrollView Delegate
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    // 获取偏移值
    CGFloat offsetX = scrollView.contentOffset.x;
    
    // 计算 index
    NSInteger index = offsetX / scrollView.width;
    
    // 获取将要显示的控制器
    self.willShowVc = self.childViewControllers[index];
    
    // 懒加载视图
    if (self.willShowVc.isViewLoaded) { // 视图加载过
        return;
    } else {
        // Frame
        self.willShowVc.view.frame = scrollView.bounds;
        
        // 添加到 ScrollView 上
        [scrollView addSubview:self.willShowVc.view];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // 懒加载子控制器视图
    [self scrollViewDidEndScrollingAnimation:scrollView];
    
    // 取出 index, 加快选项卡状态更新
    CGFloat offsetX = scrollView.contentOffset.x;
    NSInteger index = 1.0 * offsetX / scrollView.width;
    [self selectTabButton:self.tabButtons[index]];
}

#pragma mark - QDHomeFeedArticleViewCollectionViewDelegate
- (void)homeFeedArticleViewCollectionView:(UICollectionView *)collectionView offsetChannged:(NSDictionary *)change {
    CGPoint newOffset = [change[NSKeyValueChangeNewKey] CGPointValue];
    
    CGPoint oldOffset = [change[NSKeyValueChangeOldKey] CGPointValue];
    
    CGFloat offsetY = newOffset.y - oldOffset.y;
    
    if (newOffset.y > -QDNaviBarMaxY) {
        // 变化比例
        CGFloat sy = ((- newOffset.y) / QDNaviBarMaxY);
        
        self.qButton.transform = CGAffineTransformMakeScale(1.0, sy);
        self.qButton.alpha = sy;
    
        self.labButton.transform = CGAffineTransformMakeScale(sy, sy);
        self.labButton.alpha = sy;
        
        self.indicator.alpha = sy;
        
        self.naviBar.y -= offsetY;
        
    } else {
        // 恢复
        self.naviBar.y = 0;
        
        self.qButton.transform = CGAffineTransformIdentity;
        self.qButton.alpha = 1.0;
        
        self.labButton.transform = CGAffineTransformIdentity;
        self.labButton.alpha = 1.0;
        
        self.indicator.alpha = 1.0;
    }
    
    QDLogVerbose(@"%f******%f", self.naviBar.height, self.indicator.alpha);
   
}


@end
