//
//  YdChartView.h
//  DzhChart
//
//  Created by dxd on 2020/5/7.
//  Copyright © 2020 dzh. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class YdKLineView;

@interface YdChartView : UIView {
    NSInteger _showCount; // 显示线的数量
    NSInteger _startPos;
    NSInteger _legendPos;
}

@property (nonatomic, weak) YdKLineView * parentView;
@property (nonatomic,assign) CGFloat kLineWidth; // k线的宽度 用来计算可存放K线实体的个数，也可以由此计算出起始日期和结束日期的时间段

- (void)setShowCount:(NSInteger)count;
- (NSInteger)showCount;

- (void)setStartPos:(NSInteger)pos;
- (NSInteger)startPos;

- (NSInteger)endPos;

- (void)setLegendPos:(NSInteger)legendPos;
- (NSInteger)legendPos;



@end

NS_ASSUME_NONNULL_END
