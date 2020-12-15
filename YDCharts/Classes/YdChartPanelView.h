//
//  YdChartPanelView.h
//  DzhChart
//
//  Created by dxd on 2020/5/7.
//  Copyright © 2020 dzh. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class YdKLineView,YdChartView;

@interface YdChartPanelView : UIScrollView<UIScrollViewDelegate, UIGestureRecognizerDelegate> {
    CALayer * sniperHLayer; // 十字光标
    CALayer * sniperVLayer;
    CALayer * tipHLayer; //浮层价格提示
    CALayer * tipVLayer; //浮层时间提示
    int lastLineIndex; //十字光标最后一次k线index
    UIView * tipView;

}

@property (nonatomic, assign) BOOL isFirstShow;
@property (nonatomic, weak) YdKLineView * parentView;
@property (nonatomic, weak) YdChartView * chartView;
@property (nonatomic, assign) float containerLastOffsetX;

- (void)zoomIn;
- (void)zoomOut;
- (void)moveLeft;
- (void)moveRight;

@end

NS_ASSUME_NONNULL_END
