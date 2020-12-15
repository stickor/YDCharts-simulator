//
//  RKLineView.h
//  testDraw
//
//  Created by dzh on 15/11/15.
//  Copyright (c) 2015年 dzh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RKLineView : UIView <UIGestureRecognizerDelegate> {
    NSString *_chartData; // 数据源 名字不能改动
    NSInteger _legendPos;
    NSString *_mainName; // 主图指标
    NSString *_viceName; // 附图指标
    NSInteger _circulateEquityA; // 流通A股
    
    CALayer * sniperHLayer; // 十字光标
    CALayer * sniperVLayer;
    CALayer * tipHLayer; //浮层价格提示
    CALayer * tipVLayer; //浮层时间提示
    int lastLineIndex; //十字光标最后一次分时线index
}

@property (nonatomic,assign) CGFloat kLineWidth; // k线的宽度 用来计算可存放K线实体的个数，也可以由此计算出起始日期和结束日期的时间段
@property (nonatomic,strong) NSMutableArray *drawdata;//画线数据
@property (nonatomic,copy) NSString *chartType;// 画线类型
@property (nonatomic,assign) int drawDataCount;// 画线数据的个数
//fenshi
@property (nonatomic,assign) CGFloat fenshipricemin;//分时最小价格
@property (nonatomic,assign) CGFloat fenshipricemax;//分时最大价格
@property (nonatomic,assign) CGFloat fenshizuoshou;//分时昨收
@property (nonatomic,assign) CGFloat fenshiVolMax;// 分时成交量
@property (nonatomic,assign) int fenshiCount;// 分时成交量
@property (nonatomic,assign) BOOL isTingPan; //是否停盘

//画线的变量
@property (nonatomic,copy) NSArray *points; // 多点连线数组
@property (nonatomic,assign) CGFloat lineWidth; // 线条宽度KLine
@property (nonatomic,assign) BOOL isK;// 是否是实体K线
@property (nonatomic,assign) BOOL isVol;// 是否是画成交量的实体
@property (nonatomic,assign) BOOL fenshijunxian;// 是否分时均线
@property (nonatomic,assign) BOOL fenshiVol;// 分时成交量
//画阴影线
@property (nonatomic,copy) NSArray *xianpoints; // 画线点的集合

- (void)setChartData:(NSString *)chartData;
- (NSString *)chartData;



- (void)setMainName:(NSString*)fmlName;
- (NSString *)mainName;

- (void)setViceName:(NSString *)fmlName;
- (NSString*)viceName;

- (void)setCirculateEquityA:(NSInteger)count;
- (NSInteger)circulateEquityA;

@end
