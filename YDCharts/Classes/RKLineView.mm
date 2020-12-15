//
//  RKLineView.m
//  huitu
//
//  Created by dzh on 15/11/3.
//  Copyright (c) 2015年 dzh. All rights reserved.
//

#import "RKLineView.h"
#import "YdChartUtil.h"
#import "UIDefine.h"
#import "YdFormulaBase.hpp"


#define kCountOfTwoHour 120
// 普通股票显示的线个数
#define kShowLineCountForNormalStock 241
// 固定价格交易时段显示的线个数
#define kShowLineCountForFixedPrice 25
// 科创板股票显示的线个数
#define kShowLineCountForKeChuangBan (kShowLineCountForNormalStock+kShowLineCountForFixedPrice)

typedef void(^CallBackBlock)(NSData *data);

@interface RKLineView() {
    UILabel *fenshiPrince1;
    UILabel *fenshiPrince2;
    UILabel *fenshiPrince3;
    UILabel *fenshiPrince4;
    UILabel *fenshiPrince5;
    
    UILabel *fenshizhangfu1;
    UILabel *fenshizhangfu2;
    UILabel *fenshizhangfu3;
    UILabel *fenshizhangfu4;
    UILabel *fenshizhangfu5;
    
    UILabel *fenshiLabelVol1;
    UILabel *fenshiLabelVol2;
    UILabel *fenshiLabelTime1;
    UILabel *fenshiLabelTime2;
    UILabel *fenshiLabelTime3;
    NSString *fenshiTime1;
    NSString *fenshiTime2;
    NSString *fenshiTime3;
    
//    UILabel *mainTextLable;
    UILabel *viceTextLable;

    
    YdYAxis mainYAxis;
    YdYAxis viceYAxis;
    
//    CGRect mainTextRect;
    CGRect mainChartRect;
    CGRect viceTextRect;
    CGRect viceChartRect;
    CGRect XAxisRect;
    
    YdColor upClr;
    YdColor downClr;
    YdColor fixedClr;
    YdColor priceClr;
    YdColor averageClr;
    YdColor fundFlowLargeClr; // 大单曲线颜色
    YdColor fundFlowMediumClr; // 中单曲线颜色
    YdColor fundFlowLittleClr; // 小单曲线颜色
    
    shared_ptr<Formula> mainFormula;
    NSDictionary *stockInfo;
}

@property (nonatomic, assign) CGFloat fundFlowMax;// 资金流入最大值
@property (nonatomic, assign) CGFloat fundFlowMin;// 资金流入最小值

@end

@implementation RKLineView {
    NSString *_stockCode;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initSet];
        [self initSubviews];
        
        self.clipsToBounds = YES;
//        mainFormula = FormulaManager::getFormula("分时走势");
        //长按
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognizer:)];
        [self addGestureRecognizer:longPressGesture];
        //点按
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGestureRecognizer:)];
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}

- (void)initSet {
    self.fenshipricemax = 0;
    self.fenshipricemin = CGFLOAT_MAX;
    self.fenshizuoshou = 0;
    self.fenshiVolMax = 0;
    
    self.fundFlowMax = 0;
    self.fundFlowMin = CGFLOAT_MAX;
    
    self.drawDataCount = 0;

    self.backgroundColor = [UIColor clearColor];

    self.lineWidth = 1.0f;

    self.isVol = NO;
    
    self.fenshijunxian = YES;
    self.fenshiVol = NO;
    self.fenshiCount = 0;
    
    priceClr = YdColor(COLOR_LINE);
    averageClr = YdColor(COLOR_AVG_LINE);
    upClr = YdColor(COLOR_UP);
    downClr = YdColor(COLOR_DOWN);
    fixedClr = YdColor(COLOR_ORANGE);
    fundFlowLargeClr = YdColor(0xFF33CC);
    fundFlowMediumClr = YdColor(0xFF9933);
    fundFlowLittleClr = YdColor(0x3399FF);
}

- (void)initSubviews {
#define INIT_LABEL(label) \
if(label == nil){\
label = [[UILabel alloc] init];\
label.font = [UIFont systemFontOfSize:FONT_SIZE1];\
label.textAlignment = NSTextAlignmentLeft;\
[label setTextColor:UIColorFromRGB(COLOR_TEXT3)];\
[self addSubview:label];\
}
    INIT_LABEL(fenshiPrince1)
//    INIT_LABEL(fenshiPrince2)
    INIT_LABEL(fenshiPrince3)
//    INIT_LABEL(fenshiPrince4)
    INIT_LABEL(fenshiPrince5)
    
    INIT_LABEL(fenshizhangfu1)
//    INIT_LABEL(fenshizhangfu2)
    INIT_LABEL(fenshizhangfu3)
//    INIT_LABEL(fenshizhangfu4)
    INIT_LABEL(fenshizhangfu5)
    fenshizhangfu1.textAlignment = NSTextAlignmentRight;
//    fenshizhangfu2.textAlignment = NSTextAlignmentRight;
    fenshizhangfu3.textAlignment = NSTextAlignmentRight;
//    fenshizhangfu4.textAlignment = NSTextAlignmentRight;
    fenshizhangfu5.textAlignment = NSTextAlignmentRight;
    
    INIT_LABEL(fenshiLabelVol1)
    INIT_LABEL(fenshiLabelVol2)
    
    INIT_LABEL(fenshiLabelTime1)
    INIT_LABEL(fenshiLabelTime2)
    INIT_LABEL(fenshiLabelTime3)
    fenshiLabelTime2.textAlignment = NSTextAlignmentCenter;
    
//    INIT_LABEL(mainTextLable)
    INIT_LABEL(viceTextLable)
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    NSDictionary *attribute = @{NSFontAttributeName: [UIFont systemFontOfSize:FONT_SIZE1]};
    CGSize textSize = [@"XXXX-XX-XX" boundingRectWithSize:CGSizeMake(self.bounds.size.width,0)
                                                  options:
                       NSStringDrawingTruncatesLastVisibleLine |
                       NSStringDrawingUsesLineFragmentOrigin |
                       NSStringDrawingUsesFontLeading
                                               attributes:attribute
                                                  context:nil].size;
    
    float top = 0.0f, height = 0;
//    mainTextRect = CGRectMake(0, top, self.bounds.size.width, height);
    
    top += height;
    height = (self.bounds.size.height - top - 20 - 24) * 3.0 / 4 ;
    mainChartRect = CGRectMake(0, top, self.bounds.size.width, height);
    
    top += height;
    height = 20;
    XAxisRect = CGRectMake(0, top, self.bounds.size.width, height);
    
    top += height;
    height = 24;
    viceTextRect = CGRectMake(0, top, self.bounds.size.width, height);
    
    top += height;
    height = self.bounds.size.height - top;
    viceChartRect = CGRectMake(0, top, self.bounds.size.width, height);
    
    float timeY = XAxisRect.origin.y;
    float timeWid = textSize.width;
    float timeHgt = textSize.height;
    CGFloat widthForMinute = [self getWidthForMinute];
    fenshiLabelTime1.frame = CGRectMake(0, XAxisRect.origin.y, timeWid, 20);
    CGFloat fenShiLabel2X = widthForMinute*kCountOfTwoHour-timeWid/2.f;
    fenshiLabelTime2.frame = CGRectMake(fenShiLabel2X, timeY, timeWid, 20);
    CGFloat fenShiLabel3X = [self isKeChuangBanStock:_stockCode] ? widthForMinute*kShowLineCountForNormalStock-timeWid/2.f : widthForMinute*kShowLineCountForNormalStock-timeWid;
    fenshiLabelTime3.frame = CGRectMake(fenShiLabel3X, timeY, timeWid, 20);
    
    fenshiLabelVol1.frame = CGRectMake(axisLableMargin,viceChartRect.origin.y, timeWid,timeHgt);
    fenshiLabelVol2.frame = CGRectMake(axisLableMargin,viceChartRect.origin.y+viceChartRect.size.height-15, timeWid,timeHgt);
    
    fenshiPrince1.frame = CGRectMake(axisLableMargin, mainChartRect.origin.y + 5, timeWid, timeHgt);
    //fenshiPrince2.frame = CGRectMake(axisLableMargin, mainChartRect.origin.y+mainChartRect.size.height/4, timeWid, timeHgt);
    fenshiPrince3.frame = CGRectMake(axisLableMargin, mainChartRect.origin.y+mainChartRect.size.height/4*2 - 5 - textSize.height, timeWid, timeHgt);
    //fenshiPrince4.frame = CGRectMake(axisLableMargin, mainChartRect.origin.y+mainChartRect.size.height/4*3, timeWid, timeHgt);
    fenshiPrince5.frame = CGRectMake(axisLableMargin, mainChartRect.origin.y+mainChartRect.size.height-5-textSize.height, timeWid, timeHgt);
   
    int xPos = CGRectGetMaxX(mainChartRect)-timeWid-axisLableMargin;
    fenshizhangfu1.frame = CGRectMake(xPos, mainChartRect.origin.y+5, timeWid, timeHgt);
    //fenshizhangfu2.frame = CGRectMake(xPos, mainChartRect.origin.y+mainChartRect.size.height/4, timeWid, timeHgt);
    fenshizhangfu3.frame = CGRectMake(xPos, mainChartRect.origin.y+mainChartRect.size.height/4*2 - 5 - textSize.height, timeWid, timeHgt);
    //fenshizhangfu4.frame = CGRectMake(xPos, mainChartRect.origin.y+mainChartRect.size.height/4*3, timeWid, timeHgt);
    fenshizhangfu5.frame = CGRectMake(xPos, mainChartRect.origin.y+mainChartRect.size.height- 5 - textSize.height, timeWid, timeHgt);
    
//    mainTextLable.frame = mainTextRect;
    viceTextLable.frame = viceTextRect;
    
    [self calcAxis];
    
    fenshiLabelTime3.textAlignment = [self isKeChuangBanStock:_stockCode] ? NSTextAlignmentCenter : NSTextAlignmentRight;
}

// 设置数据源参数
- (void)setChartData:(NSString *)chartData {
    
    _chartData = chartData;
    
    
    
    [self parseData:^(NSData *data) {
        
        
        // #1
        [self getshishidata];//获取实时数据
        
        [self calcAxis];

        [self updateAxisLabel];
        
        // #2
        if (_mainName) {
            mainFormula = FormulaManager::getFormula([_mainName UTF8String]);
            [self updateFormulaData];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setNeedsDisplay];
        });
    }];
}

- (void)updateFormulaData {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setDateFormat:@"mm:ss"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Shanghai"]];
    
    MinOtherData minData;
    minData.circulateEquityA = [stockInfo[@"CirculateEquityA"] floatValue];
    minData.preClose = [stockInfo[@"ZuoShou"] floatValue];
    mainFormula->setOtherData(minData);
    
    vector<MinStick> sticks;
    int ii=0;
    for (NSObject *obj in self.drawdata){
        if ([(NSArray*)obj count]>5) {//判断是否有数据
            MinStick stick;
            stick.time = [[(NSArray*)obj objectAtIndex:1] intValue];
            stick.price = [[(NSArray*)obj objectAtIndex:2] floatValue];
            stick.avgprice = [[(NSArray*)obj objectAtIndex:5] floatValue];
            stick.volume = [[(NSArray*)obj objectAtIndex:3] floatValue];
            stick.amount = [[(NSArray*)obj objectAtIndex:4] floatValue];
            sticks.push_back(stick);
        }
        ii++;
    }
    
    if (sticks.size() == 0) return;
    mainFormula->setSticks(sticks);
    mainFormula->run();
}

- (NSString *)chartData {
    return _chartData;
}

- (void)setLegendPos:(NSInteger)legendPos {
    _legendPos = legendPos;
    [self updateLegend];
}

- (NSInteger)legendPos {
    return _legendPos;
}

- (void)updateAxisLabel {
    float minPrice = mainYAxis.minScale();
    float maxPrice = mainYAxis.maxScale();
    
    fenshiPrince1.text = [NSString stringWithFormat:@"%.2f",maxPrice];
    //fenshiPrince2.text = [NSString stringWithFormat:@"%.2f",(maxPrice+self.fenshizuoshou)/2];
    fenshiPrince3.text = [NSString stringWithFormat:@"%.2f",self.fenshizuoshou];
    //fenshiPrince4.text = [NSString stringWithFormat:@"%.2f",(self.fenshizuoshou+minPrice)/2];
    fenshiPrince5.text = [NSString stringWithFormat:@"%.2f",minPrice];
    
    fenshiPrince1.textColor = upClr.toUIColor();
    //fenshiPrince2.textColor = upClr.toUIColor();
    //fenshiPrince4.textColor = downClr.toUIColor();
    fenshiPrince5.textColor = downClr.toUIColor();
    
    CGFloat zhangFu1 = (maxPrice/self.fenshizuoshou - 1)*100.f;
    NSString *zhangFu1Str = isnan(zhangFu1) || isinf(zhangFu1) ? @"--" : [NSString stringWithFormat:@"%.2f%%", zhangFu1];
    fenshizhangfu1.text = zhangFu1Str;
    //fenshizhangfu2.text = [NSString stringWithFormat:@"%.2f%%",(maxPrice/self.fenshizuoshou - 1)/2*100];
    CGFloat zhangFu3 = (self.fenshizuoshou/self.fenshizuoshou - 1)*100.f;
    NSString *zhangFu3Str = isnan(zhangFu3) || isinf(zhangFu3) ? @"--" : [NSString stringWithFormat:@"%.2f%%", zhangFu3];
    fenshizhangfu3.text = zhangFu3Str;
    //fenshizhangfu4.text = [NSString stringWithFormat:@"%.2f%%",(minPrice/self.fenshizuoshou - 1)/2*100];
    CGFloat zhangFu5 = (minPrice/self.fenshizuoshou - 1)*100.f;
    NSString *zhangFu5Str = isnan(zhangFu5) || isinf(zhangFu5) ? @"--" : [NSString stringWithFormat:@"%.2f%%", zhangFu5];
    fenshizhangfu5.text = zhangFu5Str;
    
    fenshizhangfu1.textColor = upClr.toUIColor();
    //fenshizhangfu2.textColor = upClr.toUIColor();
    //fenshizhangfu4.textColor = downClr.toUIColor();
    fenshizhangfu5.textColor = downClr.toUIColor();

    if (self.drawdata.count > 0) {
        fenshiTime1 = [self.drawdata[0] objectAtIndex:0];
        fenshiTime2 = [self.drawdata[self.fenshiCount/2] objectAtIndex:0];
        if ([self isKeChuangBanStock:_stockCode]) {
            fenshiTime2 = [self.drawdata[(self.fenshiCount-kShowLineCountForFixedPrice)/2] objectAtIndex:0];
        }
        fenshiTime3 = [self.drawdata[self.fenshiCount-1] objectAtIndex:0];
        if ([self isKeChuangBanStock:_stockCode]) {
            fenshiTime3 = [self.drawdata[self.fenshiCount-kShowLineCountForFixedPrice-1] objectAtIndex:0];
        }
        fenshiLabelTime1.text = fenshiTime1;
        fenshiLabelTime2.text = fenshiTime2;
        fenshiLabelTime3.text = fenshiTime3;
    }
    if ([self.viceName isEqualToString:@"成交量"]) {
        fenshiLabelVol1.text = formatNumber(self.fenshiVolMax/100);
        fenshiLabelVol2.text = formatNumber(0);
    } else if ([self.viceName isEqualToString:@"资金流入"]) {
        fenshiLabelVol1.text = formatNumber(self.fundFlowMax);
        fenshiLabelVol2.text = formatNumber(self.fundFlowMin);
    }
}

- (void)updateLegend {
    NSInteger cursor = self.legendPos;
    if (cursor == -1) {
        cursor = self.drawdata.count-1;
    } else if (cursor >= self.drawdata.count) {
        cursor = self.drawdata.count - 1;
    }
    
    while (cursor >= 0 && ((NSArray*)self.drawdata[cursor]).count == 2)
        cursor=cursor-2;
    
    if (cursor == -1) {
        return;
    }
    
    {
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] init];
        {
            NSString* timeStr = [self.drawdata[cursor] objectAtIndex:0];
            NSString* fmlData = [NSString stringWithFormat:@"时间:%@ ", timeStr];
            UIColor* clr = [UIColor blackColor];
            NSMutableAttributedString *fmlStr = [[NSMutableAttributedString alloc] initWithString:fmlData];
            [fmlStr addAttribute:NSForegroundColorAttributeName value:clr range:NSMakeRange(0, fmlStr.string.length)];
            [str appendAttributedString:fmlStr];
        }

        // 成交价转换成实际坐标
        {
            CGFloat price = [[self.drawdata[cursor] objectAtIndex:2] floatValue];
            NSString* fmlData = [NSString stringWithFormat:@"现价:%.2f ", price];
            UIColor* clr = priceClr.toUIColor();
            NSMutableAttributedString *fmlStr = [[NSMutableAttributedString alloc] initWithString:fmlData];
            [fmlStr addAttribute:NSForegroundColorAttributeName value:clr range:NSMakeRange(0, fmlStr.string.length)];
            [str appendAttributedString:fmlStr];
        }

        // 均价换算成实际的坐标
        {
            CGFloat averagePrice = [[self.drawdata[cursor] objectAtIndex:5] floatValue];
            NSString* fmlData = [NSString stringWithFormat:@"均价:%.2f ", averagePrice];
            UIColor* clr = averageClr.toUIColor();
            NSMutableAttributedString *fmlStr = [[NSMutableAttributedString alloc] initWithString:fmlData];
            [fmlStr addAttribute:NSForegroundColorAttributeName value:clr range:NSMakeRange(0, fmlStr.string.length)];
            [str appendAttributedString:fmlStr];
        }
        
        // 均价换算成实际的坐标
        {
            CGFloat rate = ([[self.drawdata[cursor] objectAtIndex:2] floatValue]/self.fenshizuoshou-1)*100;
            NSString* fmlData = [NSString stringWithFormat:@"涨幅:%.2f ", rate];
            UIColor* clr = rate >=0 ? upClr.toUIColor() : downClr.toUIColor();
            NSMutableAttributedString *fmlStr = [[NSMutableAttributedString alloc] initWithString:fmlData];
            [fmlStr addAttribute:NSForegroundColorAttributeName value:clr range:NSMakeRange(0, fmlStr.string.length)];
            [str appendAttributedString:fmlStr];
        }
    }
}

// 把股市数据换算成分时价格和成交量坐标
- (NSArray*)getFemShiZuoBiaoData {
    NSMutableArray *fenshishuju = [[NSMutableArray alloc] init];
    
    NSMutableArray *fenshijiage = [[NSMutableArray alloc] init];
    NSMutableArray *fenshiCJL = [[NSMutableArray alloc] init];
    NSMutableArray *fenshiJunJia = [[NSMutableArray alloc] init];
    NSMutableArray *fundFlowLarge = @[].mutableCopy;
    NSMutableArray *fundFlowMedium = @[].mutableCopy;
    NSMutableArray *fundFlowLittle = @[].mutableCopy;
    
    CGFloat PointStartX = 0.0f; // 起始点坐标

    CGFloat currentPointY = 0.0f;

    CGFloat lastPrince = 0.0f;
    for (int i = 0; i < [self.drawdata count]; ++i) {
        if ([self.drawdata[i] count] > 2) {
            // 成交价转换成实际坐标
            CGFloat chengjiaojia = [[self.drawdata[i] objectAtIndex:2] floatValue];// 得到成交价
            currentPointY = mainYAxis.transform(chengjiaojia);
            
            CGPoint chengjiaojiaPoint =  CGPointMake(PointStartX, currentPointY); // 换算到当前的坐标值
            [fenshijiage addObject:NSStringFromCGPoint(chengjiaojiaPoint)]; // 把坐标添加进新数组mainYAxis
            
            // 均价换算成实际的坐标
            CGFloat chengjiaojunjia = [[self.drawdata[i] objectAtIndex:5] floatValue];// 得到均价价格
            currentPointY = mainYAxis.transform(chengjiaojunjia);

            CGPoint chengjiaojunjiaPoint =  CGPointMake(PointStartX, currentPointY); // 换算到当前的坐标值
            [fenshiJunJia addObject:NSStringFromCGPoint(chengjiaojunjiaPoint)]; // 把坐标添加进新数组
            
            //成交量转换成实际坐标
            CGFloat chengjiaoliangValue = [[self.drawdata[i] objectAtIndex:3] floatValue];// 获取分时成交量
            
            CGFloat chengjiaoliangValuePointYD = viceYAxis.transform(chengjiaoliangValue);
            CGPoint chengjiaoliangValuePointD =  CGPointMake(PointStartX, chengjiaoliangValuePointYD);
            CGPoint chengjiaoliangValuePointH =  CGPointMake(PointStartX, viceChartRect.origin.y + viceChartRect.size.height);
            // 计算成交量的的颜色
            NSString *volLineColor = @"";
            // 交易类型 0 集合竞价交易 1 固定价格交易
//            if ([self.drawdata[i] count] > 5) {
//                if ([[self.drawdata[i] objectAtIndex:5] integerValue] == 0) {
//                    if (chengjiaojia >= lastPrince) {
//                        volLineColor = @"up";
//                    } else {
//                        volLineColor = @"down";
//                    }
//                } else {
//                    volLineColor = @"fixed";
//                }
//            } else {
                if (chengjiaojia >= lastPrince) {
                    volLineColor = @"up";
                } else {
                    volLineColor = @"down";
                }
//            }
            
            lastPrince = chengjiaojia;
            NSArray *currentArray = [[NSArray alloc] initWithObjects:
                                     NSStringFromCGPoint(chengjiaoliangValuePointD),
                                     NSStringFromCGPoint(chengjiaoliangValuePointH), // 保存成交量
                                     volLineColor,
                                     nil];
            [fenshiCJL addObject:currentArray]; // 把坐标添加进新数组
//            PointStartX += self.frame.size.width/(self.fenshiCount - 1); // 生成下一个点的x轴
            PointStartX += [self getWidthForMinute]; // 生成下一个点的x轴
            
            // 资金流向大单换算成实际的坐标
            CGFloat large = [[self.drawdata[i] objectAtIndex:6] floatValue];// 得到资金大单净流入
            currentPointY = viceYAxis.transform(large);
            [fundFlowLarge addObject:NSStringFromCGPoint(CGPointMake(PointStartX, currentPointY))];
            
            // 资金流向中单换算成实际的坐标
            CGFloat medium = [[self.drawdata[i] objectAtIndex:7] floatValue];// 得到资金中单净流入
            currentPointY = viceYAxis.transform(medium);
            [fundFlowMedium addObject:NSStringFromCGPoint(CGPointMake(PointStartX, currentPointY))];
            // 资金流向小单换算成实际的坐标
            CGFloat little = [[self.drawdata[i] objectAtIndex:8] floatValue];// 得到资金小单净流入
            currentPointY = viceYAxis.transform(little);
            [fundFlowLittle addObject:NSStringFromCGPoint(CGPointMake(PointStartX, currentPointY))];
        }
        
        if (i == 0) {
            fenshiTime1 = [self.drawdata[i] objectAtIndex:0];
        }
        if (i == self.fenshiCount/2) {
            fenshiTime2 = [self.drawdata[i] objectAtIndex:0];
            if ([self isKeChuangBanStock:_stockCode]) {
                fenshiTime2 = [self.drawdata[(self.fenshiCount-kShowLineCountForFixedPrice)/2] objectAtIndex:0];
            }
        }
        if (i == self.fenshiCount-1) {
            fenshiTime3 = [self.drawdata[i] objectAtIndex:0];
            if ([self isKeChuangBanStock:_stockCode]) {
                fenshiTime3 = [self.drawdata[self.fenshiCount-kShowLineCountForFixedPrice-1] objectAtIndex:0];
            }
        }
    }
    [fenshishuju addObject:fenshijiage]; // 下标0代表，价格数组；
    [fenshishuju addObject:fenshiJunJia]; // 下标1代表，均价数组；
    [fenshishuju addObject:fenshiCJL]; // 下标2代表，成交量数组；
    [fenshishuju addObject:fundFlowLarge];
    [fenshishuju addObject:fundFlowMedium];
    [fenshishuju addObject:fundFlowLittle];
    return fenshishuju;
}

//获取实时数据
- (void)getshishidata {
    NSError *error;
    NSData *data = [self.chartData dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *drawLineDataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    //获取图表类型
    self.chartType = [drawLineDataDic objectForKey:@"chartType"];
    if ([self.chartType isEqualToString:@"min"]) {
        [self getFSData:drawLineDataDic];
    }
}

- (void)getFSData:(NSDictionary *)drawLineDataDic {
    self.fenshipricemax = 0;
    self.fenshipricemin = CGFLOAT_MAX;
    self.fenshizuoshou = 0;
    self.fenshiVolMax = 0;
    
    // 获取股票代码
    _stockCode = [[drawLineDataDic objectForKey:@"stkInfo"] objectForKey:@"Obj"];
    //获取昨收
    NSDictionary *zuoshou = [drawLineDataDic objectForKey:@"stkInfo"];
    self.fenshizuoshou = [[zuoshou objectForKey:@"ZuoShou"] floatValue];
    
    //停盘
//    self.isTingPan = (0 == ([[zuoshou objectForKey:@"ShiJian"] integerValue]));
    self.isTingPan = (8 == [[zuoshou objectForKey:@"ShiFouTingPai"] integerValue]);

    //获取实际数据
    NSDictionary *weatherInfo = [drawLineDataDic objectForKey:@"chartData"];
    self.fenshiCount = (int)[weatherInfo count];
    
    NSEnumerator *enumerator = [weatherInfo objectEnumerator];
    
    NSMutableArray *temshuju = [[NSMutableArray alloc] init];
    for (NSObject *obj in enumerator) {
        
        NSMutableArray *temfield = [[NSMutableArray alloc] init];
        int nnu = [[(NSDictionary *)obj objectForKey:@"ShiJian"] intValue];
        NSDate *d = [NSDate dateWithTimeIntervalSince1970:nnu];
        NSDateFormatter *formatter1 = [[NSDateFormatter alloc]init];
        //formatter1.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        formatter1.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT+0800"];
        [formatter1 setDateFormat:@"HH:mm"];
        NSString *showtimeNew = [formatter1 stringFromDate:d];
    
        [temfield addObject:showtimeNew];//9:30格式
        [temfield addObject: [NSString stringWithFormat:@"%d",nnu] ];//时间戳
        
        if (!self.isTingPan) {
            
            if ((NSNull *)[(NSDictionary *)obj objectForKey:@"ChengJiaoJia"] != [NSNull null]) {
                // 成交价
                [temfield addObject:[(NSDictionary *)obj objectForKey:@"ChengJiaoJia"]];
                
                if ([[(NSDictionary *)obj objectForKey:@"ChengJiaoJia"] floatValue] > self.fenshipricemax) {
                    self.fenshipricemax = [[(NSDictionary *)obj objectForKey:@"ChengJiaoJia"] floatValue];
                }
                if ([[(NSDictionary *)obj objectForKey:@"ChengJiaoJia"] floatValue] < self.fenshipricemin) {
                    self.fenshipricemin = [[(NSDictionary *)obj objectForKey:@"ChengJiaoJia"] floatValue];
                }
                // 成交量
                [temfield addObject:[(NSDictionary *)obj objectForKey:@"ChengJiaoLiang"]];
                if ([[(NSDictionary *)obj objectForKey:@"ChengJiaoLiang"] floatValue] > self.fenshiVolMax) {
                    self.fenshiVolMax = [[(NSDictionary *)obj objectForKey:@"ChengJiaoLiang"] floatValue];
                }
                
                // 成交额
                [temfield addObject:[(NSDictionary *)obj objectForKey:@"ChengJiaoE"]];
                // 均价
                [temfield addObject:[(NSDictionary *)obj objectForKey:@"JunJia"]];
                // 交易类型
//                if ([[(NSDictionary *)obj allKeys] containsObject:@"tradeType"]) {
//                    [temfield addObject:[(NSDictionary *)obj objectForKey:@"tradeType"]];
//                }
                // 资金流入大单(超大+大单)
                CGFloat largeAmt = [[(NSDictionary *)obj objectForKey:@"superIn"] floatValue] - [[(NSDictionary *)obj objectForKey:@"superOut"] floatValue] + [[(NSDictionary *)obj objectForKey:@"largeIn"] floatValue] - [[(NSDictionary *)obj objectForKey:@"largeOut"] floatValue];
                [temfield addObject:@(largeAmt)];
                if (largeAmt > self.fundFlowMax) {
                    self.fundFlowMax = largeAmt;
                }
                if (largeAmt < self.fundFlowMin) {
                    self.fundFlowMin = largeAmt;
                }
                // 资金流入中单
                CGFloat mediumAmt = [[(NSDictionary *)obj objectForKey:@"mediumIn"] floatValue] - [[(NSDictionary *)obj objectForKey:@"mediumOut"] floatValue];
                [temfield addObject:@(mediumAmt)];
                if (mediumAmt > self.fundFlowMax) {
                    self.fundFlowMax = mediumAmt;
                }
                if (mediumAmt < self.fundFlowMin) {
                    self.fundFlowMin = mediumAmt;
                }
                // 资金流入小单
                CGFloat littleAmt = [[(NSDictionary *)obj objectForKey:@"littleIn"] floatValue] - [[(NSDictionary *)obj objectForKey:@"littleOut"] floatValue];
                [temfield addObject:@(littleAmt)];
                if (littleAmt > self.fundFlowMax) {
                    self.fundFlowMax = littleAmt;
                }
                if (littleAmt < self.fundFlowMin) {
                    self.fundFlowMin = littleAmt;
                }
            }
        }
        [temshuju addObject:temfield];
    }
    self.drawdata = temshuju;
}

- (void)calcAxis {

//    if( self.showCount == 0)
//        return ;

    CGFloat offset;
    if (self.fenshipricemin == CGFLOAT_MAX) {
        offset = self.fenshizuoshou * 0.1; //默认 10% 涨跌幅
    } else {
        CGFloat delta1 = fabs(self.fenshizuoshou - self.fenshipricemax);
        CGFloat delta2 = fabs(self.fenshizuoshou - self.fenshipricemin);
        offset = fmax(delta1, delta2); // 2.34
        if (offset == 0.0) {
            offset = 0.1;
        }
    }
//    mainFormula->getResult();

    mainYAxis.setScale( self.fenshizuoshou - offset, self.fenshizuoshou + offset );
    mainYAxis.setBound(mainChartRect.origin.y+mainChartRect.size.height,  mainChartRect.origin.y);
    
    if ([[self viceName] isEqualToString:@"成交量"]) {
        viceYAxis.setScale(0, self.fenshiVolMax);
        viceYAxis.setBound(viceChartRect.origin.y+viceChartRect.size.height,  viceChartRect.origin.y);
    } else if ([[self viceName] isEqualToString:@"资金流入"]) {
        viceYAxis.setScale(self.fundFlowMin, self.fundFlowMax);
        viceYAxis.setBound(viceChartRect.origin.y+viceChartRect.size.height,  viceChartRect.origin.y);
    }
}

#pragma mark - Formula
- (NSString *)mainName {
    return _mainName;
}

- (void)setMainName:(NSString*)fmlName {
    _mainName = fmlName;
    mainFormula = FormulaManager::getFormula([fmlName UTF8String]);

    [self updateFormulaData];
    
    [self setNeedsDisplay];
}

- (NSString *)viceName {
    return _viceName;
}

- (void)setViceName:(NSString*)fmlName {
    _viceName = fmlName;
    [self getshishidata];
    [self calcAxis];
    [self updateLegend];
    [self updateAxisLabel];
    [self setNeedsDisplay];
}

- (void)setCirculateEquityA:(NSInteger)count {
    _circulateEquityA = count;
    
}

- (NSInteger)circulateEquityA {
    return _circulateEquityA;
}

#pragma mark - 手势
//十字线
- (void) longPressGestureRecognizer:(UILongPressGestureRecognizer*)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state==UIGestureRecognizerStateChanged) {
        
        CGFloat positionX = [gesture locationInView:self].x;
        CGFloat positionY = [gesture locationInView:self].y;
//        positionY = positionY<0 ? 0 : (positionY>self.frame.size.height ? self.frame.size.height : positionY);
        
        if (!sniperVLayer) {
           sniperVLayer = [[CALayer alloc]init];
            sniperVLayer.backgroundColor = [UIColor lightGrayColor].CGColor;
            [self.layer addSublayer:sniperVLayer];
        }
        if (positionX >= mainChartRect.origin.x && positionX <= mainChartRect.size.width) {
            if (!tipVLayer) {
                // 十字浮层
                CATextLayer * tipVTextLayer = [CATextLayer layer];
                tipVTextLayer.fontSize = CROSS_TIP_FONT_SIZE;
                tipVTextLayer.foregroundColor = UIColorFromRGB(COLOR_TEXT3).CGColor;
                tipVTextLayer.alignmentMode = kCAAlignmentLeft;
                tipVTextLayer.contentsScale = [UIScreen mainScreen].scale; // Retina屏渲染
                
                tipVLayer = [[CALayer alloc]init];
                tipVLayer.backgroundColor = [UIColor lightGrayColor].CGColor;
                [tipVLayer addSublayer:tipVTextLayer];
                [self.layer addSublayer:tipVLayer];
            }
        } else {
            [tipVLayer removeFromSuperlayer];
            tipVLayer = nil;
        }
        if (!sniperHLayer) {
            sniperHLayer = [[CALayer alloc]init];
            sniperHLayer.backgroundColor = [UIColor lightGrayColor].CGColor;
            [self.layer addSublayer:sniperHLayer];
        }
        if (positionY <= mainYAxis.minBound() || (positionY <= viceYAxis.minBound() && positionY >= viceYAxis.maxBound()) ) {
            if (!tipHLayer) {
                // 十字浮层
                CATextLayer * tipHTextLayer = [CATextLayer layer];
                tipHTextLayer.fontSize = CROSS_TIP_FONT_SIZE;
                tipHTextLayer.foregroundColor = UIColorFromRGB(COLOR_TEXT3).CGColor;
                tipHTextLayer.alignmentMode = kCAAlignmentLeft;
                tipHTextLayer.contentsScale = [UIScreen mainScreen].scale; // Retina屏渲染
                
                tipHLayer = [[CALayer alloc]init];
                tipHLayer.backgroundColor = [UIColor lightGrayColor].CGColor;
                [tipHLayer addSublayer:tipHTextLayer];
                [self.layer addSublayer:tipHLayer];
            }
        } else {
            [tipHLayer removeFromSuperlayer];
            tipHLayer = nil;
        }
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:.1];
        
        sniperVLayer.frame = CGRectMake(positionX, 0, 1,self.frame.size.height);
        sniperHLayer.frame = CGRectMake(0, positionY, self.frame.size.width, 1);
        
        //十字线浮层 价格
        float price = 0;
        NSString * floatPrice = 0;
        if (positionY <= mainYAxis.minBound()) {
            price = mainYAxis.restore(positionY);
            floatPrice = [NSString stringWithFormat:@"%.2f", price];
        } else if (positionY <= viceYAxis.minBound() && positionY >= viceYAxis.maxBound()) {
            price = viceYAxis.restore(positionY);
            price = ([[self viceName] isEqualToString:@"成交量"]) ? price/100 : price;
            floatPrice = formatNumber(price);
        }
        CGFloat priceWidth = adjustWidth(floatPrice, [UIFont systemFontOfSize:CROSS_TIP_FONT_SIZE]);
        
        tipHLayer.frame = CGRectMake(0, positionY-(CROSS_TIP_FONT_SIZE+4)/2, priceWidth+3+3, CROSS_TIP_FONT_SIZE+4); // 3+3左右边距
        CATextLayer * tipHTextLayer = tipHLayer.sublayers.firstObject;
        tipHTextLayer.frame = CGRectMake(3, 0, priceWidth, CROSS_TIP_FONT_SIZE+4); //左边距:3
        tipHTextLayer.string = floatPrice;
        
        //十字线浮层 时间
        CGFloat widthForMinute = [self getWidthForMinute];
        int cursorIndex = positionX /widthForMinute;
        cursorIndex = cursorIndex>0 ? cursorIndex : 0;
//        NSLog(@"%f,%f,%d",positionX,widthForMinute,cursorIndex);
        MinStick stick;
        if (cursorIndex < self.drawdata.count) {
            NSObject *obj = self.drawdata[cursorIndex];
            stick.time = [[(NSArray*)obj objectAtIndex:1] intValue];
        }
        
        NSDate *d = [NSDate dateWithTimeIntervalSince1970:stick.time];
        NSDateFormatter *formatter1 = [[NSDateFormatter alloc]init];
        formatter1.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT+0800"];
        [formatter1 setDateFormat:@"HH:mm"];
        NSString *showtimeNew = [formatter1 stringFromDate:d];
        
        CGFloat xx = positionX-(30+3+3)/2;
        xx = xx>0 ? ( xx<(mainChartRect.size.width-30-3-3) ? xx : mainChartRect.size.width-30-3-3) : 0; //tip最左，最右
        tipVLayer.frame = CGRectMake(xx, mainChartRect.size.height, 30+3+3, CROSS_TIP_FONT_SIZE+4); // 3+3左右边距
        CATextLayer * tipVTextLayer = tipVLayer.sublayers.firstObject;
        tipVTextLayer.frame = CGRectMake(3, 0, 120, CROSS_TIP_FONT_SIZE+4); //左边距:3
        tipVTextLayer.string = showtimeNew;
        
        [CATransaction commit];
        
        //当前 分时索引
       int curLineIndex = positionX / [self getWidthForMinute];
       curLineIndex = (curLineIndex>self.drawdata.count-1) ? (int)self.drawdata.count-1 : curLineIndex;
       if (lastLineIndex != curLineIndex) {
           [[NSNotificationCenter defaultCenter] postNotificationName:@"MinCrossNotification" object:@{ @"curKlineIndex":[NSNumber numberWithInt:curLineIndex]}];
       }
       lastLineIndex = curLineIndex;
    } else {
        [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(hiddenCrossLine) userInfo:nil repeats:NO];
    }
}
//取消十字光标
- (void)tapGestureRecognizer:(UITapGestureRecognizer*)tap {
    [self hiddenCrossLine];
}

- (void)hiddenCrossLine {
    [sniperVLayer removeFromSuperlayer];
    [sniperHLayer removeFromSuperlayer];
    sniperVLayer = nil;
    sniperHLayer = nil;
    [tipHLayer removeFromSuperlayer];
    tipHLayer = nil;
    [tipVLayer removeFromSuperlayer];
    tipVLayer = nil;
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"MinCrossNotification" object:@{ @"curKlineIndex":[NSNumber numberWithInt:-1]}];
}

#pragma mark - Draw
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    self.points = [self getFemShiZuoBiaoData];
    
    CGContextRef context = UIGraphicsGetCurrentContext();// 获取绘图上下文
    
    YdColor clr(COLOR_BACKGROUND);
    CGContextSetRGBFillColor(context, clr.r(), clr.g(), clr.b(), self.alpha);
    CGContextFillRect(context, rect);
    
    [self drawAxisTicks:context];
    
    if (!self.isTingPan) {
        NSArray *pricearray = self.points[0];
        self.fenshijunxian = NO;
        self.fenshiVol = NO;
        [self drawLineWithContext:context dravArray:pricearray lineColor:priceClr.toUIColor()];
        
        NSArray *junpricearray = self.points[1];
        self.fenshijunxian = YES;
        self.fenshiVol = NO;
        [self drawLineWithContext:context dravArray:junpricearray lineColor:averageClr.toUIColor()];
        
        if ([self.mainName isEqualToString:@"分时冲关"]) {
            [self drawFormula:context region:mainChartRect axisY:mainYAxis dravArray:pricearray formula:mainFormula];
        }
        
        if ([self.viceName isEqualToString:@"成交量"]) {
            NSArray *Volearray = self.points[2];
            self.fenshijunxian = NO;
            self.fenshiVol = YES;
            [self drawLineWithContext:context dravArray:Volearray lineColor:NULL];
        } else if ([self.viceName isEqualToString:@"资金流入"]) {
            NSArray *fundFlowLarge = self.points[3];
            self.fenshijunxian = YES;
            self.fenshiVol = NO;
            [self drawLineWithContext:context dravArray:fundFlowLarge lineColor:fundFlowLargeClr.toUIColor()];
            
            NSArray *fundFlowMedium = self.points[4];
            self.fenshijunxian = YES;
            self.fenshiVol = NO;
            [self drawLineWithContext:context dravArray:fundFlowMedium lineColor:fundFlowMediumClr.toUIColor()];
            
            NSArray *fundFlowLittle = self.points[5];
            self.fenshijunxian = YES;
            self.fenshiVol = NO;
            [self drawLineWithContext:context dravArray:fundFlowLittle lineColor:fundFlowLittleClr.toUIColor()];
            
        }
    }
    
    [self updateLegend];

//    self.fenshipricemax = 0;
//    self.fenshipricemin = CGFLOAT_MAX;
    //self.fenshizuoshou = 0;
//    self.fenshiVolMax = 0;//十字浮窗
}

- (void)drawFormula:(CGContextRef)context region:(CGRect)region axisY:(YdYAxis)axisY dravArray:pricearray formula:(shared_ptr<Formula>)formula {
    CGContextSaveGState(context);
    
    CGContextSetShouldAntialias(context, YES);
    CGContextClipToRect(context, region);
    
    const FormulaResults & results = formula->getResult();
    for(const auto& result : results) {
        if (shared_ptr<FormulaDraw> draw = result._draw) {
            if (draw->_type == DRAWTEXT) {
                [self DRAWTEXT:context draw:draw axisY:axisY dravArray:pricearray];
            }
        }
    }
    CGContextRestoreGState(context);
}

- (void)DRAWTEXT:(CGContextRef)context draw:(shared_ptr<FormulaDraw>)draw axisY:(YdYAxis)axisY dravArray:pricearray {
    YdColor clr(draw->_color);
    UIFont  *font = [UIFont boldSystemFontOfSize:9.0];
    NSDictionary *attr = @{ NSFontAttributeName:font,
                            NSForegroundColorAttributeName:[UIColor colorWithRed:clr.r() green:clr.g() blue:clr.b() alpha:self.alpha]};
    NSString *strText = [NSString stringWithUTF8String:draw->_text.c_str()];
    NSString *name = [NSString stringWithUTF8String:draw->_name.c_str()];
    NSString *value = @"0.00";
    for (NSInteger i=0;i<draw->_drawPositon1.size();i++) {
        if (i >= [pricearray count]) break;
        double x = draw->_drawPositon1[i];
        double y = draw->_drawPositon2[i];
        id item = pricearray[i];
        CGPoint currentPoint = CGPointFromString(item);
        double y0 = axisY.transform(y);
        if (x==1) {
            // CGFloat chengjiaojia = [[self.drawdata[i] objectAtIndex:2] floatValue];// 得到成交价
            value = @"1.00";
            NSDictionary *attribute = @{NSFontAttributeName: font};
            CGSize textSize = [strText boundingRectWithSize:CGSizeMake(self.bounds.size.width,10)
                                                             options:
                                  NSStringDrawingTruncatesLastVisibleLine |
                                  NSStringDrawingUsesLineFragmentOrigin |
                                  NSStringDrawingUsesFontLeading
                                                          attributes:attribute
                                                             context:nil].size;
            [strText drawAtPoint:CGPointMake(currentPoint.x-textSize.width/2 , y0) withAttributes:attr];
        }
    }
    [NSNotificationCenter.defaultCenter postNotificationName:@"MinMainResult" object:@{@"name": name, @"value": value}];
}

// 绘制连接线
- (void)drawLineWithContext:(CGContextRef)context dravArray:(NSArray *)points lineColor:(nullable UIColor *)color {
    CGContextSetLineWidth(context,0.5f);
    CGContextSetShouldAntialias(context, YES);
    
    const CGFloat *colors = CGColorGetComponents(color.CGColor);
    if (color) {
        CGContextSetRGBStrokeColor(context, colors[0], colors[1], colors[2], self.alpha);
        CGContextSetLineWidth(context,1.f);
    }
    
//    if (self.fenshijunxian){//#fcaf17
//        CGContextSetRGBStrokeColor(context, averageClr.r(), averageClr.g(), averageClr.b(), self.alpha);
//        CGContextSetLineWidth(context,1.f);
//    } else {//#33a3dc
//        CGContextSetRGBStrokeColor(context, priceClr.r(), priceClr.g(), priceClr.b(), self.alpha);
//        CGContextSetLineWidth(context,1.f);
//    }
    if (!self.fenshiVol) {
        CGMutablePathRef path = CGPathCreateMutable();
        if ([self isKeChuangBanStock:_stockCode] && self.fenshijunxian) {
            for (int i = 0; i < points.count; i++) {
                // 科创板固定价格交易时间段不绘制均线
                if (i == kShowLineCountForNormalStock) break;
                id item = points[i];
                CGPoint currentPoint = CGPointFromString(item);
                if ((int)currentPoint.y <= (int)self.frame.size.height && currentPoint.y >= 0) {
                    if ([points indexOfObject:item] == 0) {
                        CGPathMoveToPoint(path, nullptr, currentPoint.x, currentPoint.y);
                        continue;
                    }
                    CGPathAddLineToPoint(path, nullptr, currentPoint.x, currentPoint.y);
                }
            }
        } else {
            for (id item in points) {
                CGPoint currentPoint = CGPointFromString(item);
                if ((int)currentPoint.y <= (int)self.frame.size.height && currentPoint.y >= 0) {
                    if ([points indexOfObject:item] == 0) {
                        CGPathMoveToPoint(path, nullptr, currentPoint.x, currentPoint.y);
                        continue;
                    }
                    CGPathAddLineToPoint(path, nullptr, currentPoint.x, currentPoint.y);
                }
            }
        }
        
        CGContextBeginPath(context);
        CGContextAddPath(context, path);
        CGContextStrokePath(context);
        
        // 填充时价的阴影
        if (!self.fenshijunxian && [points count] > 0) {
            YdColor shadowClr(COLOR_SHADOW);
            CGPoint firstPoint = CGPointFromString([points firstObject]);
            CGPoint lastPoint = CGPointFromString([points lastObject]);

            CGPathAddLineToPoint(path, nullptr, lastPoint.x, CGRectGetMaxY(mainChartRect));
            CGPathAddLineToPoint(path, nullptr, CGRectGetMinX(mainChartRect), CGRectGetMaxY(mainChartRect));
            CGPathAddLineToPoint(path, nullptr, CGRectGetMinX(mainChartRect), firstPoint.y);

            CGContextBeginPath(context);
            CGContextSetRGBFillColor(context, shadowClr.r(), shadowClr.g(), shadowClr.b(), 0.25);
            CGContextAddPath(context, path);
            CGContextFillPath(context);
        }
        CGPathRelease(path);
    } else {
        CGContextBeginPath(context);
        for (int i = 0; i < points.count; i++) {
            id item = points[i];
            CGPoint chengjiaoliangDPoint, chengjiaoliangHPoint;
            chengjiaoliangDPoint = CGPointFromString([item objectAtIndex:0]);
            chengjiaoliangHPoint = CGPointFromString([item objectAtIndex:1]);

            // 画成交量
            NSString *color = [item objectAtIndex:2];
            if ([color isEqualToString:@"up"]) {
                CGContextSetRGBStrokeColor(context, upClr.r(), upClr.g(), upClr.b(), 1.0);
            } else if ([color isEqualToString:@"down"]) {
                CGContextSetRGBStrokeColor(context, downClr.r(), downClr.g(), downClr.b(), 1.0);
            } else if ([color isEqualToString:@"fixed"]) {
                CGContextSetRGBStrokeColor(context, fixedClr.r(), fixedClr.g(), fixedClr.b(), 1.0);
            }
            // 测试环境TradeType没有变为TradeType_FixedPrice，所以需要按时间再设置一次绘制颜色
            if (i >= kShowLineCountForNormalStock) {
                CGContextSetRGBStrokeColor(context, fixedClr.r(), fixedClr.g(), fixedClr.b(), 1.0);
            }
            
            CGContextSetLineWidth(context, [self getWidthForMinute] < 1.f ? [self getWidthForMinute] : 1.f); // 改变线的宽度
            const CGPoint cjlpoints[] = {chengjiaoliangDPoint, chengjiaoliangHPoint};
            CGContextStrokeLineSegments(context, cjlpoints, 2);  // 绘制线段（默认不绘制端点）
        }
    }
}

- (void)drawAxisTicks:(CGContextRef)context {
    
    YdColor clr(COLOR_SEPERATOR);
    CGContextSetRGBStrokeColor(context, clr.r(), clr.g(), clr.b() ,1.0);
    CGContextSetLineWidth(context,1.0);
    CGContextBeginPath(context);
    
    CGFloat PointStartX = 0.0f; // 起始点坐标
    CGFloat PointStartY = 0.0f;
    CGFloat PointEndX = self.bounds.size.width; // 起始点坐标
    CGFloat PointEndY = 0.0f;
    for (int num = 1; num < 5; num++) {
        PointStartX = 0.0f, PointEndX = self.bounds.size.width;
        PointEndY = PointStartY = mainChartRect.origin.y + mainChartRect.size.height * num * 0.25;
        CGContextMoveToPoint(context, PointStartX, PointStartY);
        CGContextAddLineToPoint(context, PointEndX, PointEndY);
    }
    
    for (int num = 0; num < 1; num++) {
        PointStartX = 0.0f, PointEndX = self.bounds.size.width;
        PointEndY = PointStartY = viceChartRect.origin.y + viceChartRect.size.height * num * 0.5;
        CGContextMoveToPoint(context, PointStartX, PointStartY);
        CGContextAddLineToPoint(context, PointEndX, PointEndY);
    }
    CGFloat widthOfMinute = [self getWidthForMinute];
    // 绘制主图X轴中心线
    {
        PointEndX = PointStartX = widthOfMinute*kCountOfTwoHour;
        PointStartY = mainChartRect.origin.y;
        PointEndY = mainChartRect.origin.y + mainChartRect.size.height;
        CGContextMoveToPoint(context, PointStartX, PointStartY);
        CGContextAddLineToPoint(context, PointEndX, PointEndY);
    }
    // 绘制幅图X轴中心线
    {
        PointEndX = PointStartX = widthOfMinute*kCountOfTwoHour;
        PointStartY = viceChartRect.origin.y;
        PointEndY = viceChartRect.origin.y + viceChartRect.size.height;
        CGContextMoveToPoint(context, PointStartX, PointStartY);
        CGContextAddLineToPoint(context, PointEndX, PointEndY);
    }
    // 绘制成交量与时间之间的分割线
    {
        PointStartX = viceTextRect.origin.x;
        PointEndX = viceTextRect.origin.x + viceTextRect.size.width;
        PointStartY = PointEndY = viceTextRect.origin.y;
        CGContextMoveToPoint(context, PointStartX, PointStartY);
        CGContextAddLineToPoint(context, PointEndX, PointEndY);
    }
    CGContextStrokePath(context);
    
    if ([self isKeChuangBanStock:_stockCode]) {
        
        YdColor clr(COLOR_ORANGE_LINE);
        CGContextSetRGBStrokeColor(context, clr.r(), clr.g(), clr.b(), 1.0);
        CGFloat lengths[] = {4, 1};
        CGContextSetLineDash(context, 0, lengths, 2);
        // 绘制主图X轴盘中和盘后的分界线
        PointEndX = PointStartX = widthOfMinute*(kShowLineCountForNormalStock-1);
        PointStartY = mainChartRect.origin.y;
        PointEndY = mainChartRect.origin.y + mainChartRect.size.height;
        CGContextMoveToPoint(context, PointStartX, PointStartY);
        CGContextAddLineToPoint(context, PointEndX, PointEndY);
    
        // 绘制副图X轴盘中和盘后的分界线
        PointEndX = PointStartX = widthOfMinute*(kShowLineCountForNormalStock-1);
        PointStartY = viceChartRect.origin.y;
        PointEndY = viceChartRect.origin.y + viceChartRect.size.height;
        CGContextMoveToPoint(context, PointStartX, PointStartY);
        CGContextAddLineToPoint(context, PointEndX, PointEndY);
        CGContextDrawPath(context, kCGPathStroke);
        CGContextSetLineDash(context, 0, {}, 0);
    }
    CGContextStrokePath(context);
}

- (BOOL)isKeChuangBanStock:(NSString *)code {
    if ([code containsString:@"SH"]) {
        return [code hasPrefix:@"SH688"];
    }
    return [code hasPrefix:@"688"];
}

// 获取1分钟对应的宽度
- (CGFloat)getWidthForMinute {
    return [self isKeChuangBanStock:_stockCode] ? self.frame.size.width/kShowLineCountForKeChuangBan : self.frame.size.width/kShowLineCountForNormalStock;
}

//获取实时数据
- (void)parseData:(CallBackBlock)callBack {
    NSError *error;
    NSData *data =[self.chartData dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *drawLineDataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    
//    [self parseKLineData:drawLineDataDic];
    
//    self.split = [NSString stringWithFormat:@"%@",[drawLineDataDic objectForKey:@"split"]];
//    self.tempPeriod = [NSString stringWithFormat:@"%@",[drawLineDataDic objectForKey:@"tempPeriod"]];
    stockInfo = [drawLineDataDic objectForKey:@"stkInfo"];
//    self.stockCodes = [NSString stringWithFormat:@"%@",[stockInfo objectForKey:@"Obj"]];
    callBack(nil);
}

@end
