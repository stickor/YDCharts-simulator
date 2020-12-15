//
//  RKLineView.h
//  testDraw
//
//  Created by dzh on 15/11/15.
//  Copyright (c) 2015年 dzh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YdFormulaBase.hpp"
#import "YdChartUtil.h"


@interface YdKLineStick : NSObject
@property (nonatomic,copy)   NSString* time;
@property (nonatomic,copy)   NSString* datetime;
@property (nonatomic,assign) CGFloat open;
@property (nonatomic,assign) CGFloat high;
@property (nonatomic,assign) CGFloat low;
@property (nonatomic,assign) CGFloat close;
@property (nonatomic,assign) CGFloat volumn;
@property (nonatomic,assign) CGFloat amount;
@property (nonatomic,assign) CGFloat fpVolumn; // 盘后成交量
@property (nonatomic,assign) CGFloat fpAmount; // 盘后成交额
@property (nonatomic,assign) CGFloat turnoverRate; //换手率
@property (nonatomic,assign) CGFloat preClose; //昨收
@property (nonatomic,assign) CGFloat change; //涨跌额
@property (nonatomic,assign) CGFloat changeRate; //涨跌幅


//资金流入流出数据
@property (nonatomic,assign) CGFloat littleIn;
@property (nonatomic,assign) CGFloat littleOut;
@property (nonatomic,assign) CGFloat mediumIn;
@property (nonatomic,assign) CGFloat mediumOut;
@property (nonatomic,assign) CGFloat hugeIn;
@property (nonatomic,assign) CGFloat hugeOut;
@property (nonatomic,assign) CGFloat largeIn;
@property (nonatomic,assign) CGFloat largeOut;
@property (nonatomic,assign) CGFloat superIn;
@property (nonatomic,assign) CGFloat superOut;
@property (nonatomic,assign) CGFloat total;

+ (NSDictionary*)getObjectData:(id)obj;

@end

@interface YDKLineSplitStick: NSObject
@property (nonatomic,copy) NSString* zhgxsj;    //最后更新时间
@property (nonatomic,copy) NSString* gpdm;       //股票代码
@property (nonatomic,copy) NSString* zqlb;         //'A':A股、'B'：B股
@property (nonatomic,copy) NSString* cqrq;      //除权日期
@property (nonatomic,assign) CGFloat fhpx;    //分红派息（每股）
@property (nonatomic,assign) CGFloat sg;              //送股（每股）
@property (nonatomic,assign) CGFloat zzg;            //转增股（每股）
@property (nonatomic,assign) CGFloat pg;             //配股（每股）
@property (nonatomic,assign) CGFloat pgj;       //配股价
@end


@class YdChartPanelView;

@interface YdKLineView : UIView {
    NSString *_chartData; //数据源 名字不能改动
    NSString *_mainName; // 主图指标
    NSString *_viceName; // 附图1指标
    NSString *_chartLoc; // 附图2指标
    
    
    
    NSInteger _isLand;
}

@property (nonatomic, copy) NSString *_mainName;
@property (nonatomic, copy) NSString *_viceName;
@property (nonatomic, copy) NSString *_chartLoc;
//@property (nonatomic, copy) RCTBubblingEventBlock onSplitDataBlock;

@property (nonatomic, strong) NSMutableArray *drawdata;//画线数据
@property (nonatomic,copy) NSString * stockName; //股票名称
@property (nonatomic,copy) NSString * stockCodes; //股票代码
@property (nonatomic,copy) NSString * tempPeriod;//周k

@property (nonatomic, readonly) CGRect mainChartRect;
@property (nonatomic, readonly) CGRect viceTextRect;
@property (nonatomic, readonly) CGRect viceTextRect2;
@property (nonatomic, readonly) CGRect viceChartRect;
@property (nonatomic, readonly) CGRect viceChartRect2;
@property (nonatomic, readonly) CGRect XAxisRect;

@property (nonatomic, readonly) YdYAxis mainYAxis;
@property (nonatomic, readonly) YdYAxis viceYAxis;
@property (nonatomic, readonly) YdYAxis viceYAxis2;

@property (nonatomic, readonly) shared_ptr<Formula> mainFormula;
@property (nonatomic, readonly) shared_ptr<Formula> viceFormula;
@property (nonatomic, readonly) shared_ptr<Formula> viceFormula1;

@property (nonatomic, weak) YdChartPanelView * chartPV;

//画阴影线
- (void)setChartData:(NSString *)chartData;
- (NSString *)chartData;

- (void)setMainName:(NSString*)fmlName;
- (NSString *)mainName;

- (void)setViceName:(NSString *)fmlName;
- (NSString*)viceName;


- (void)setChartLoc:(NSString*)cl;
- (NSString *)chartLoc;

- (void)setIsLand:(NSInteger)land;
- (NSInteger)isLand;

- (NSDictionary *)getMainFormulaData:(NSInteger)pos;
- (NSArray *)getViceFormulaData:(NSInteger)pos;
- (NSArray *)getViceFormulaData1:(NSInteger)pos;

- (void)calcAxis;
- (void)updateAxisLabel;
- (void)updateLegend;

//缩放
- (void)zoomIn;
- (void)zoomOut;
- (void)moveLeft;
- (void)moveRight;

@end
