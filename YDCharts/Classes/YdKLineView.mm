//
//  RKLineView.m
//  huitu
//
//  Created by dzh on 15/11/3.
//  Copyright (c) 2015年 dzh. All rights reserved.
//

#import "YdKLineView.h"
#import "UIDefine.h"
#import "YdChartPanelView.h"
#import "YdChartView.h"
#import <objc/runtime.h>

@implementation YdKLineStick


//object -> dictionary
+ (NSDictionary*)getObjectData:(id)obj
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    unsigned int propsCount;
    objc_property_t *props = class_copyPropertyList([obj class], &propsCount);//获得属性列表
    for(int i = 0;i < propsCount; i++)
    {
        objc_property_t prop = props[i];
        
        NSString *propName = [NSString stringWithUTF8String:property_getName(prop)];//获得属性的名称
        id value = [obj valueForKey:propName];//kvc读值
        if(value == nil)
        {
            value = [NSNull null];
        }
        else
        {
            value = [self getObjectInternal:value];//自定义处理数组，字典，其他类
        }
        [dic setObject:value forKey:propName];
    }
    return dic;
}

+ (id)getObjectInternal:(id)obj
{
    if([obj isKindOfClass:[NSString class]]
       || [obj isKindOfClass:[NSNumber class]]
       || [obj isKindOfClass:[NSNull class]])
    {
        return obj;
    }
    
    if([obj isKindOfClass:[NSArray class]])
    {
        NSArray *objarr = obj;
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:objarr.count];
        for(int i = 0;i < objarr.count; i++)
        {
            [arr setObject:[self getObjectInternal:[objarr objectAtIndex:i]] atIndexedSubscript:i];
        }
        return arr;
    }
    
    if([obj isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *objdic = obj;
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:[objdic count]];
        for(NSString *key in objdic.allKeys)
        {
            [dic setObject:[self getObjectInternal:[objdic objectForKey:key]] forKey:key];
        }
        return dic;
    }
    return [self getObjectData:obj];
}

@end

@implementation YDKLineSplitStick
@end

typedef void(^CallBackBlock)(NSData *data); 

@interface YdKLineView() {
    
    UILabel *klineVolLabFull;
    UILabel *klineVolLabHalf;
    
    UILabel *klineVolTime1;
    UILabel *klineVolTime2;
    UILabel *klineVolTime3;
    
    UILabel *klinePrince1;
    UILabel *klinePrince2;
    UILabel *klinePrince3;
    UILabel *klinePrince4;
    UILabel *klinePrince5;
    
    UILabel *VicePrince1;
    UILabel *VicePrince2;
    
    UILabel *VicePrince3;
    UILabel *VicePrince4;
    
    UILabel *mainTextLable;
    UILabel *viceTextLable;
    UILabel *viceTextLable2;
    
//    YdChartPanelView * chartPV;   //K线 滚动 ScrollView
    
//    YdYAxis mainYAxis;
//    YdYAxis viceYAxis;
//    YdYAxis viceYAxis2;
    
    CGRect mainTextRect;
//    CGRect mainChartRect;
//    CGRect viceTextRect;
//    CGRect viceTextRect2;
//    CGRect viceChartRect;
//    CGRect viceChartRect2;
//    CGRect XAxisRect;
    
//    shared_ptr<Formula> mainFormula;
//    shared_ptr<Formula> viceFormula;
//    shared_ptr<Formula> viceFormula1;
    vector<KLineStick> drawSticks;
    
}
//@property (nonatomic,strong) NSMutableArray *drawdata;//画线数据
@property (nonatomic,copy) NSString * split;//除复权状态
@property (nonatomic,strong) NSMutableArray *splitData;//除复权数据
@property (nonatomic,assign) BOOL isFirstSplit;

@property (nonatomic,assign) BOOL formulaIsRun;
@property (nonatomic,assign) CGFloat circulateEquityA;//流通股A

//Kline
@property (nonatomic,assign) CGFloat mainMin;//K线最小价格
@property (nonatomic,assign) CGFloat mainMax;//K线最大价格
@property (nonatomic,assign) CGFloat viceMin;//K线最小价格
@property (nonatomic,assign) CGFloat viceMax;//K线最大价格
@property (nonatomic,assign) CGFloat vice1Min;//K线最小价格
@property (nonatomic,assign) CGFloat vice1Max;//K线最大价格

@property (nonatomic, assign) CGFloat totalVolMax; // 总成交量最大值(竞价交易+盘后交易)
@property (nonatomic, assign) CGFloat totalVolMin; // 总成交量最小值(竞价交易+盘后交易)

@property (nonatomic, strong) NSMutableDictionary* dictTextSize;
@end


@implementation YdKLineView

@synthesize _mainName=_mainName, _viceName=_viceName, _chartLoc=_chartLoc;
@synthesize drawdata=drawdata;
@synthesize mainFormula=mainFormula, viceFormula=viceFormula, viceFormula1=viceFormula1;
@synthesize mainChartRect=mainChartRect, viceTextRect=viceTextRect, viceTextRect2=viceTextRect2, viceChartRect=viceChartRect, viceChartRect2=viceChartRect2, XAxisRect;
@synthesize mainYAxis=mainYAxis, viceYAxis=viceYAxis, viceYAxis2=viceYAxis2;

- (instancetype)init {
    self = [super init];
    [self initSubViews];
    self.mainMax = self.viceMax = self.vice1Max = -CGFLOAT_MAX;
    self.mainMin = self.viceMin = self.vice1Min = CGFLOAT_MAX;
    self.chartPV.chartView.showCount = 55;
    self.chartPV.chartView.startPos = 405;
    mainFormula = FormulaManager::getFormula("MA");
    viceFormula = FormulaManager::getFormula("MACD");
    viceFormula1 = FormulaManager::getFormula("RSI");
    
    return self;
}

- (void) dealloc {
//    [[NSNotificationCenter defaultCenter] removeObserver:@"KLineCrossNotification"];
}

- (void)initSubViews {
    // ScrollView
    YdChartPanelView * chartPView = [[YdChartPanelView alloc]init];
    [self addSubview:chartPView];
    self.chartPV = chartPView;
    self.chartPV.parentView = self;
    self.chartPV.chartView.parentView = self;
    
#define INIT_LABEL(label) \
if(label == nil){\
label = [[UILabel alloc] init];\
label.font = [UIFont systemFontOfSize:FONT_SIZE1];\
label.textAlignment = NSTextAlignmentLeft;\
[label setTextColor:UIColorFromRGB(COLOR_TEXT3)];\
[self addSubview:label];\
}
    
//    float timeY = self.frame.size.height*2/3;
//    float timeWid = 80;
//    float timeHgt = 8;
    
    INIT_LABEL(klineVolTime1)
    INIT_LABEL(klineVolTime2)
    INIT_LABEL(klineVolTime3)
    INIT_LABEL(klineVolLabFull)
    INIT_LABEL(klineVolLabHalf)
    INIT_LABEL(klinePrince1)
    INIT_LABEL(klinePrince2)
    INIT_LABEL(klinePrince3)
    INIT_LABEL(klinePrince4)
    INIT_LABEL(klinePrince5)
    INIT_LABEL(VicePrince1)
    INIT_LABEL(VicePrince2)
    INIT_LABEL(VicePrince3)
    INIT_LABEL(VicePrince4)
    INIT_LABEL(mainTextLable)
    INIT_LABEL(viceTextLable)
    INIT_LABEL(viceTextLable2)
    
    klineVolTime2.textAlignment = NSTextAlignmentCenter;
    klineVolTime3.textAlignment = NSTextAlignmentRight;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    NSDictionary *attribute = @{NSFontAttributeName: [UIFont systemFontOfSize:FONT_SIZE1]};
    CGSize textSize = [@"XXXX-XX-XX" boundingRectWithSize:CGSizeMake(self.bounds.size.width, 0)
                                                  options:
                       NSStringDrawingTruncatesLastVisibleLine |
                       NSStringDrawingUsesLineFragmentOrigin |
                       NSStringDrawingUsesFontLeading
                                               attributes:attribute
                                                  context:nil].size;
    
    float top = 0.0f, height = 30;
    mainTextRect = CGRectMake(_isLand == 1 ? 0 : 70, top, self.bounds.size.width, height);
    
    top += height;
    if (_isLand != 1) {
        height = (self.bounds.size.height - top - 20 - 20 /*- textSize.height/2*/) * 3.0 / 6;
    } else {
        height = (self.bounds.size.height - top - 20 - 20 /*- textSize.height/2*/) * 3.4 / 5;
    }
    mainChartRect = CGRectMake(0, top, self.bounds.size.width, height);
    
    top += height;
    height = 20;
    XAxisRect = CGRectMake(0, top, self.bounds.size.width, height);
    
    top += height;
    height = 30;;
    viceTextRect = CGRectMake(_isLand == 1 ? 0 : 70, top, self.bounds.size.width, height);
    
    top += height;
    if (_isLand != 1) {
        height = (self.bounds.size.height - top)/2-15;
    } else {
        height = self.bounds.size.height - top;
    }
    viceChartRect = CGRectMake(0, top, self.bounds.size.width, height);
    
    top += height;
    height = 30;
    viceTextRect2 = CGRectMake(70, top, self.bounds.size.width, height);
    
    top += height;
    height = viceChartRect.size.height;
    viceChartRect2 = CGRectMake(0, top, self.bounds.size.width, height);
    
    float timeY = XAxisRect.origin.y;
    float timeWid = textSize.width;
    float timeHgt = textSize.height;
    
    klineVolTime1.frame = CGRectMake(0, XAxisRect.origin.y, timeWid, 20);
    klineVolTime2.frame = CGRectMake(XAxisRect.size.width/2-timeWid/2, timeY, timeWid, 20);
    klineVolTime3.frame = CGRectMake(XAxisRect.size.width-timeWid, timeY, timeWid, 20);
    
    klineVolLabFull.frame = CGRectMake(axisLableMargin, viceChartRect.origin.y, timeWid,timeHgt);
    klineVolLabHalf.frame = CGRectMake(axisLableMargin, viceChartRect.origin.y+viceChartRect.size.height/2, timeWid,timeHgt);
    
    klinePrince1.frame = CGRectMake(axisLableMargin, mainChartRect.origin.y + 5, timeWid, timeHgt);
    //klinePrince2.frame = CGRectMake(axisLableMargin, mainChartRect.origin.y+mainChartRect.size.height/4, timeWid, timeHgt);
    klinePrince3.frame = CGRectMake(axisLableMargin, mainChartRect.origin.y+mainChartRect.size.height/4*2 - 5 - textSize.height, timeWid, timeHgt);
    //klinePrince4.frame = CGRectMake(axisLableMargin, mainChartRect.origin.y+mainChartRect.size.height/4*3, timeWid, timeHgt);
    klinePrince5.frame = CGRectMake(axisLableMargin, mainChartRect.origin.y+mainChartRect.size.height-5-textSize.height, timeWid, timeHgt);
    
    VicePrince1.frame = CGRectMake(axisLableMargin, viceChartRect.origin.y, timeWid, timeHgt);
    VicePrince2.frame = CGRectMake(axisLableMargin, viceChartRect.origin.y + viceChartRect.size.height - textSize.height, timeWid, timeHgt);
    if (self.isLand != 1) {
        VicePrince3.frame = CGRectMake(axisLableMargin, viceChartRect2.origin.y, timeWid, timeHgt);
        VicePrince4.frame = CGRectMake(axisLableMargin, viceChartRect2.origin.y + viceChartRect2.size.height - textSize.height, timeWid, timeHgt);
    }
    mainTextLable.frame = mainTextRect;
    viceTextLable.frame = viceTextRect;
    viceTextLable2.frame = viceTextRect2;
    
    //浮层ScrollView接收滚动、缩放事件
    float containerLastWidth = self.chartPV.contentSize.width;
    float containerWidth=self.chartPV.chartView.kLineWidth*(self.drawdata.count+.5), containerHeight=top+height;
    self.chartPV.frame = CGRectMake(0, 0, self.bounds.size.width, containerHeight);
    self.chartPV.contentSize = CGSizeMake(containerWidth, containerHeight);
//    self.chartPV.chartView.frame = CGRectMake(0, 0, containerWidth, containerHeight);
    self.chartPV.chartView.frame = CGRectMake(0, 0, self.frame.size.width/(SHOW_KLINE_MIN_COUNT-1)*(self.drawdata.count+.5), containerHeight);

    
    if (self.chartPV.isFirstShow || //首次显示
        ((containerLastWidth != containerWidth) && (self.chartPV.containerLastOffsetX==self.chartPV.contentOffset.x))   //看最新的一分钟K线
        ) {
        self.chartPV.contentOffset = CGPointMake((containerWidth-self.bounds.size.width<0?0:containerWidth - self.bounds.size.width), 0);
        self.chartPV.containerLastOffsetX =  self.chartPV.contentOffset.x;
    }
//    NSLog(@"last=%f, %f,  %f", self.chartPV.containerLastOffsetX, self.chartPV.contentOffset.x, (containerWidth- self.bounds.size.width));
    if ((int)self.chartPV.contentOffset.x == (int)containerWidth-self.bounds.size.width) {
        self.chartPV.containerLastOffsetX =  self.chartPV.contentOffset.x;
    }
    
    [self calcAxis];
    [self updateAxisLabel];
    
    //十字光标主图指标更新
    WS(weakSelf);
    [[NSNotificationCenter defaultCenter] addObserverForName:@"KLineCrossNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull notification) {
        NSDictionary *dic = [notification object];
        NSNumber *curKlineIndex = [dic objectForKey:@"curKlineIndex"];
        int intCurKlineIndex = [curKlineIndex intValue];
        intCurKlineIndex = intCurKlineIndex==-1 ? (int)weakSelf.drawdata.count-1 : intCurKlineIndex;
        weakSelf.chartPV.chartView.legendPos = intCurKlineIndex;
    }];

}

- (void)updateAxisLabel {
    NSInteger drawDataCount = self.chartPV.chartView.showCount;
    if (drawDataCount > 0 && self.drawdata.count > 0 && self.chartPV.chartView.startPos < self.drawdata.count) {
        klineVolTime1.text = ((YdKLineStick*)self.drawdata[self.chartPV.chartView.startPos]).time;
        klineVolTime2.text = ((YdKLineStick*)self.drawdata[(self.chartPV.chartView.startPos+self.chartPV.chartView.endPos + 1)/2]).time;
        klineVolTime3.text = ((YdKLineStick*)self.drawdata[self.chartPV.chartView.endPos]).time;
        
        klinePrince1.text = [NSString stringWithFormat:@"%.2f",self.mainMax];
        //klinePrince2.text = [NSString stringWithFormat:@"%.2f",self.mainMax - 1*(self.mainMax-self.mainMin)/4];
        klinePrince3.text = [NSString stringWithFormat:@"%.2f",self.mainMax - 2*(self.mainMax-self.mainMin)/4];
        //klinePrince4.text = [NSString stringWithFormat:@"%.2f",self.mainMax - 3*(self.mainMax-self.mainMin)/4];
        klinePrince5.text = [NSString stringWithFormat:@"%.2f",self.mainMin];
        
        //画成交量的标签
        CGFloat max, min;
        if ([[_viceName uppercaseString] isEqualToString:@"VOL"]) {
            max = self.totalVolMax;
            min = self.totalVolMin;
            
        } else {
            max = self.viceMax;
            min = self.viceMin;
        }

        NSString *unit = @"";
        if (max>10000*10000) {
            max = max/(10000*10000);
            min = min/(10000*10000);
            unit = @"亿";
        } else if (max>10000) {
            max = max/(10000);
            min = min/(10000);
            unit = @"万";
        } else {
            unit = @"";
        }
        if (max > 100000000000 || max < -100000000000) {
            max = 0.0;
        }
        if (min > 100000000000 || min < -100000000000) {
            min = 0.0;
        }
        
        VicePrince1.text = [NSString stringWithFormat:@"%.2f%@",max, unit];
        VicePrince2.text = [NSString stringWithFormat:@"%.2f%@",min, unit];
        
        //画成交量的标签
        CGFloat max1, min1;
        if ([[_chartLoc uppercaseString] isEqualToString:@"VOL"]) {
            max1 = self.totalVolMax;
            min1 = self.totalVolMin;
        } else {
            max1 = self.vice1Max;
            min1 = self.vice1Min;
        }
        NSString *unit1 = @"";
        if (max1>10000*10000) {
            max1 = max1/(10000*10000);
            min1 = min1/(10000*10000);
            unit1 = @"亿";
        } else if (max1>10000) {
            max1 = max1/(10000);
            min1 = min1/(10000);
            unit1 = @"万";
        } else {
            unit1 = @"";
        }
        
        if (max1 > 100000000000 || max1 < -100000000000) {
            max1 = 0.0;
        }
        if (min1 > 100000000000 || min1 < -100000000000) {
            min1 = 0.0;
        }
        
        VicePrince3.text = [NSString stringWithFormat:@"%.2f%@",max1, unit1];
        VicePrince4.text = [NSString stringWithFormat:@"%.2f%@",min1, unit1];
        
        //        if( self.viceMax != -CGFLOAT_MAX)
        //            klineVolLabFull.text = [NSString stringWithFormat:@"%.2f%@",max, unit];//更新Label数值
        //        else
        //            klineVolLabFull.text = @"";
        // klineVolLabHalf.text = [NSString stringWithFormat:@"%.2f%@",(max+min)/2, unit];//更新Label数值
    }
}

#pragma mark - 数据处理
- (NSString *)chartData {
    return _chartData;
}

- (void)setChartData:(NSString *)chartData {
    self.formulaIsRun = false;
    self.isFirstSplit = true;
    _chartData = chartData;
    
    __weak __typeof(self) weakSelf = self;
    [self parseData:^(NSData *data) {
        
        if (weakSelf.chartPV.isFirstShow) {
            weakSelf.chartPV.chartView.startPos = (self.drawdata.count-SHOW_KLINE_COUNT)>0 ? (self.drawdata.count-SHOW_KLINE_COUNT) : 0;
            weakSelf.chartPV.chartView.showCount = SHOW_KLINE_COUNT;
        }
        
        [weakSelf updateFormulaData];
        
        if (weakSelf.chartPV.chartView.startPos > weakSelf.chartPV.chartView.endPos)
            return;
        
        [weakSelf calcAxis];
        [weakSelf updateAxisLabel];
        //先要计算出chartView 的frame，width为0是不会drawrect；所以没有使用 [self.chartPV.chartView setNeedsDisplay];
        [weakSelf setNeedsLayout];
        [weakSelf layoutIfNeeded];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [weakSelf setNeedsDisplay];
//        });
    }];
}

- (void)getSplitData:(NSString *)code andCallBack:(CallBackBlock)callBack {
    NSString *codeString = [code substringFromIndex:2];
    NSString *urlString = [NSString stringWithFormat:@"http://cdnapp.ydtg.com.cn/fenhongkuosan/%@.txt", codeString];
    
    //1.确定请求路径
    //    NSURL *url = [NSURL URLWithString:@"http://cdnapp.ydtg.com.cn/fenhongkuosan/600157.txt"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error == nil) {
            [self parseSplitData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                callBack(nil);
            });
        }
    }];
    [dataTask resume];
}

- (void)parseSplitData:(NSData *)data {
    
    NSArray *splitArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    //本地存储，备用
    NSDictionary *objModel = splitArray[0];
    NSString *codeString = [objModel objectForKey:@"gpdm"];
    if (splitArray && objModel && codeString) {
        NSDictionary *splits = @{
                                @"split": data,
                                @"obj": codeString
                                };
        [[NSUserDefaults standardUserDefaults] setObject:splits forKey:@"CYGPSplitMessage"];
    }
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    for (NSDictionary *obj in splitArray) {
        YDKLineSplitStick * stick = [[YDKLineSplitStick alloc] init];
        stick.zhgxsj = [obj objectForKey:@"zhgxsj"];
        stick.gpdm =[obj objectForKey:@"gpdm"];
        stick.zqlb =[obj objectForKey:@"zqlb"];
        stick.cqrq = [obj objectForKey:@"cqrq"];
        stick.fhpx = [(NSNumber*)[obj objectForKey:@"fhpx"] floatValue]/10 ;
        stick.sg = [(NSNumber*)[obj objectForKey:@"sg"] floatValue]/10;
        stick.zzg = [(NSNumber*)[obj objectForKey:@"zzg"] floatValue]/10 ;
        stick.pg = [(NSNumber*)[obj objectForKey:@"pg"] floatValue]/10;
        stick.pgj = [(NSNumber*)[obj objectForKey:@"pgj"] floatValue];
        
        [tempArray addObject:stick];
    }
    self.splitData = tempArray;
}

//获取实时数据
- (void)parseData:(CallBackBlock)callBack {
    NSError *error;
    NSData *data =[self.chartData dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *drawLineDataDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    
    [self parseKLineData:drawLineDataDic];
    
    self.split = [NSString stringWithFormat:@"%@",[drawLineDataDic objectForKey:@"split"]];
    self.tempPeriod = [NSString stringWithFormat:@"%@",[drawLineDataDic objectForKey:@"tempPeriod"]];
    NSDictionary *stockInfo = [drawLineDataDic objectForKey:@"stkInfo"];
    self.stockCodes = [NSString stringWithFormat:@"%@",[stockInfo objectForKey:@"Obj"]];
    self.stockName = [NSString stringWithFormat:@"%@",[stockInfo objectForKey:@"MingCheng"]];
    self.circulateEquityA = [[drawLineDataDic objectForKey:@"circulateEquityA"] floatValue];
   
    //除权不处理，日k除外不处理
    @try {
        if ([self.split isEqualToString:@"0"] || ![self.tempPeriod isEqualToString:@"5"]) {
            callBack(nil);
        } else {
            NSDictionary *dict = [[NSUserDefaults standardUserDefaults] objectForKey:@"CYGPSplitMessage"];
            NSString *objString =[dict objectForKey:@"obj"];
            if ([objString isEqualToString:self.stockCodes]) {
                [self parseSplitData:[dict objectForKey:@"split"]];
                callBack(nil);
            } else {
                [self getSplitData:self.stockCodes andCallBack:^(NSData *data) {
                    callBack(nil);
                }];
            }
        }
    }
    @catch (NSException *e) {
        callBack(nil);
    }
    @finally {
        
    }
}

//get Kline data
- (void)parseKLineData:(NSDictionary *)drawLineDataDic {
    //获取实际数据
    NSDictionary *weatherInfo = [drawLineDataDic objectForKey:@"chartData"];
    
    NSEnumerator *enumerator = [weatherInfo objectEnumerator];
    
    NSDateFormatter *formatter1 = [[NSDateFormatter alloc]init];
    formatter1.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT+0800"];
    [formatter1 setDateFormat:@"yyyy-MM-dd"];
    
    NSDateFormatter *formatter2 = [[NSDateFormatter alloc]init];
    formatter2.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT+0800"];
    [formatter2 setDateFormat:@"yyyy-MM-dd HH:mm"];

    CGFloat preClose = -1;
    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
    for (NSObject *obj in enumerator) {
        
        YdKLineStick *stick = [[YdKLineStick alloc] init];
        if ((NSNull *)[(NSDictionary *)obj objectForKey:@"ChengJiaoJia"] != [NSNull null]) {
            //time
            int nnu = [[(NSDictionary *)obj objectForKey:@"ShiJian"] intValue];
            NSDate *d = [NSDate dateWithTimeIntervalSince1970:nnu];
            
            NSString *showtimeNew = [formatter1 stringFromDate:d];
            stick.time = showtimeNew;
            stick.datetime = [formatter2 stringFromDate:d];
            
            stick.open = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"KaiPanJia"] floatValue];
            stick.close = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"ShouPanJia"] floatValue];
            
            stick.high = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"ZuiGaoJia"] floatValue];
            stick.low = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"ZuiDiJia"] floatValue];
            
            stick.volumn = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"ChengJiaoLiang"] floatValue];
            stick.fpVolumn = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"fpVolume"] floatValue];
            stick.fpAmount = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"fpAmount"] floatValue];

            stick.littleIn = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"littleIn"] floatValue];
            stick.littleOut = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"littleOut"] floatValue];
            stick.mediumIn = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"mediumIn"] floatValue];
            stick.mediumOut = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"mediumOut"] floatValue];
            stick.hugeIn = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"hugeIn"] floatValue];
            stick.hugeOut = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"hugeOut"] floatValue];
            stick.largeIn = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"largeIn"] floatValue];
            stick.largeOut = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"largeOut"] floatValue];
            stick.superIn = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"superIn"] floatValue];
            stick.superOut = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"superOut"] floatValue];
            stick.total = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"total"] floatValue];
            
            stick.preClose = preClose==-1 ? stick.open : preClose;
            stick.turnoverRate = stick.volumn/[(NSNumber*)[drawLineDataDic objectForKey:@"circulateEquityA"] floatValue];
            stick.change = stick.close - stick.preClose;
            stick.changeRate = stick.change/stick.preClose;
            stick.amount = [(NSNumber*)[(NSDictionary *)obj objectForKey:@"ChengJiaoE"] floatValue];
            
            preClose = stick.close;
            [tempArray addObject:stick];
        }
    }
    self.drawdata = tempArray;
}


#pragma mark - 计算
- (void)calcAxis {
    
    if (self.drawdata.count == 0) return;
    
    if (!self.formulaIsRun) return;
    
    if (self.chartPV.chartView.showCount == 0 || self.chartPV.chartView.startPos > self.chartPV.chartView.endPos) return;
    
    // K线极值
    CGFloat kMax = self.mainMax = self.viceMax = self.vice1Max = -CGFLOAT_MAX;
    CGFloat kMin = self.mainMin = self.viceMin = self.vice1Min = CGFLOAT_MAX;
    self.totalVolMax = 0;
    self.totalVolMin = 0;
    
    for (NSInteger i = self.chartPV.chartView.startPos; i <= self.chartPV.chartView.endPos; ++i) {
        YdKLineStick *stick = (YdKLineStick*)[self.drawdata objectAtIndex:i];
        kMax = MAX( kMax, stick.high);
        kMin = MIN( kMin, stick.low);
        if (stick.volumn + stick.fpVolumn > self.totalVolMax) {
            self.totalVolMax = stick.volumn + stick.fpVolumn;
        }
    }
    // 公式极值
    double max, min;
    mainFormula->getResult().min_max_in_range(self.chartPV.chartView.startPos, self.chartPV.chartView.endPos, max, min);
    kMax = MAX(kMax, max);
    kMin = MIN(kMin, min);
    
//    CGFloat fontHeight = SystemFontHeight(FONT_SIZE1);
    CGFloat expendRange = (kMax-kMin)/(mainChartRect.size.height-FONT_SIZE1)*mainChartRect.size.height;
    
    self.mainMax = (kMax+kMin)/2+expendRange/2;
    self.mainMin = (kMax+kMin)/2-expendRange/2;
    mainYAxis.setScale( self.mainMin, self.mainMax);
    mainYAxis.setBound(mainChartRect.origin.y+mainChartRect.size.height,  mainChartRect.origin.y);

    viceFormula->getResult().min_max_in_range(self.chartPV.chartView.startPos, self.chartPV.chartView.endPos, max, min);
    if (min == invalid_dbl) {
        min = 0;
    }
    self.viceMin = min;
    self.viceMax = MAX(0.0001, max);
    if ([[_viceName uppercaseString] isEqualToString:@"VOL"]) {
        viceYAxis.setScale(self.totalVolMin, self.totalVolMax);
    } else if ([_viceName isEqualToString:@"多空资金"]) {
//        double absVal = MAX(self.viceMax, self.viceMin);
//        self.viceMin = -absVal;
//        self.viceMax = absVal;
        viceYAxis.setScale(self.viceMin, self.viceMax);
    } else {
        viceYAxis.setScale(self.viceMin, self.viceMax);
    }
    viceYAxis.setBound(viceChartRect.origin.y+viceChartRect.size.height,  viceChartRect.origin.y);
    
    viceFormula1->getResult().min_max_in_range(self.chartPV.chartView.startPos, self.chartPV.chartView.endPos, max, min);
    if (min == invalid_dbl) {
        min = 0;
    }
    self.vice1Min = min;
    self.vice1Max = MAX(0.0001, max);
    if ([[_chartLoc uppercaseString] isEqualToString:@"VOL"]) {
        viceYAxis2.setScale(self.totalVolMin, self.totalVolMax);
    } else if ([_viceName isEqualToString:@"多空资金"]) {
//        double absVal = MAX(self.viceMax, self.viceMin);
//        self.vice1Min = -absVal;
//        self.vice1Max = absVal;
        viceYAxis2.setScale(self.vice1Min, self.vice1Max);
    } else {
        viceYAxis2.setScale(self.vice1Min, self.vice1Max);
    }
    viceYAxis2.setBound(viceChartRect2.origin.y+viceChartRect2.size.height,  viceChartRect2.origin.y);
    self.chartPV.chartView.kLineWidth = self.frame.size.width/(self.chartPV.chartView.showCount-1);//减一根，半根显示的情况
}

- (void)reactSetFrame:(CGRect)frame {
//    [super reactSetFrame:frame];
    [self calcAxis];
    [self updateAxisLabel];
}

- (NSInteger)isLand {
    return _isLand;
}

- (void)setIsLand:(NSInteger)land {
    _isLand = land;
    [self updateFormulaData];
    
    [self calcAxis];
    
    [self updateAxisLabel];
    
    [self setNeedsDisplay];
}

- (NSString *)chartLoc {
    return _chartLoc;
}

// 设置附图2指标
- (void)setChartLoc:(NSString *)cl {
    _chartLoc = cl;
    
    viceFormula1 = FormulaManager::getFormula([_chartLoc UTF8String]);
    
    if (self.chartPV.chartView.startPos > self.chartPV.chartView.endPos) return;
    
    [self updateFormulaData];
    
    [self calcAxis];
    
    [self updateAxisLabel];
    
    [self setNeedsDisplay];
    
}
#pragma mark - Formula
- (NSString *)mainName {
    return _mainName;
}

- (void)setMainName:(NSString*)fmlName {
    _mainName = fmlName;
    mainFormula = FormulaManager::getFormula([fmlName UTF8String]);
    
    if (self.chartPV.chartView.startPos > self.chartPV.chartView.endPos) return;
    
    [self updateFormulaData];
    
    [self calcAxis];
    
    [self updateAxisLabel];
    
     [self.chartPV.chartView setNeedsDisplay];
//    [self setNeedsDisplay];
//    [self setNeedsLayout];
//    [self layoutIfNeeded];
}

- (NSString *)viceName {
    return _viceName;
}
// 设置附图1指标
- (void)setViceName:(NSString*)fmlName {
    
    _viceName = fmlName;
    viceFormula = FormulaManager::getFormula([fmlName UTF8String]);
    
    if (self.chartPV.chartView.startPos > self.chartPV.chartView.endPos) return;
    
    [self updateFormulaData];
    
    [self calcAxis];
    
    [self updateAxisLabel];
    
//    [self setNeedsDisplay];
    [self.chartPV.chartView setNeedsDisplay];
}

- (void)updateFormulaData {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init] ;
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Shanghai"]];
    
    NSDateFormatter *formatter2 = [[NSDateFormatter alloc] init] ;
    [formatter2 setDateStyle:NSDateFormatterMediumStyle];
    [formatter2 setDateFormat:@"yyyy-MM-dd HH:mm"];
    [formatter2 setTimeZone:[NSTimeZone timeZoneWithName:@"Asia/Shanghai"]];
    
    vector<KLineStick> sticks;
    for (NSObject *obj in self.drawdata){
        KLineStick stick;
        stick.time = [[formatter dateFromString:((YdKLineStick *)obj).time] timeIntervalSince1970];
        stick.datetime = [[formatter2 dateFromString:((YdKLineStick *)obj).datetime] timeIntervalSince1970];
        stick.open = ((YdKLineStick *)obj).open;
        stick.high = ((YdKLineStick *)obj).high;
        stick.low = ((YdKLineStick *)obj).low;
        stick.close = ((YdKLineStick *)obj).close;
        stick.volume = ((YdKLineStick *)obj).volumn;
        stick.amount = ((YdKLineStick *)obj).amount;
        sticks.push_back(stick);
    }
    drawSticks = sticks;
    
    vector<FundFlowStick> fundFlows;
    for (NSObject *obj in self.drawdata){
        FundFlowStick fundFlow;
        fundFlow.littleIn = ((YdKLineStick *)obj).littleIn;
        fundFlow.littleOut = ((YdKLineStick *)obj).littleOut;
        fundFlow.mediumIn = ((YdKLineStick *)obj).mediumIn;
        fundFlow.mediumOut =((YdKLineStick *)obj).mediumOut;
        fundFlow.hugeIn = ((YdKLineStick *)obj).hugeIn;
        fundFlow.hugeOut = ((YdKLineStick *)obj).hugeOut;
        fundFlow.largeIn = ((YdKLineStick *)obj).largeIn;
        fundFlow.largeOut = ((YdKLineStick *)obj).largeOut;
        fundFlow.superIn = ((YdKLineStick *)obj).superIn;
        fundFlow.superOut = ((YdKLineStick *)obj).superOut;
        fundFlow.total= ((YdKLineStick *)obj).total;
        fundFlows.push_back(fundFlow);
    }
    
    vector<ExRight> splitSticks;
    
    for (NSObject *obj in self.splitData) {
        ExRight splitStick;

        splitStick.lastUpdateTime = [((YDKLineSplitStick *)obj).zhgxsj integerValue];
        splitStick.stockCode = [((YDKLineSplitStick *)obj).gpdm UTF8String];
        splitStick.subType = [((YDKLineSplitStick *)obj).zqlb UTF8String];
        splitStick.exright_date = [((YDKLineSplitStick *)obj).cqrq integerValue];
        splitStick.alloc_interest = ((YDKLineSplitStick *)obj).fhpx ;
        splitStick.give = ((YDKLineSplitStick *)obj).sg;
        splitStick.extend = ((YDKLineSplitStick *)obj).zzg;
        splitStick.match = ((YDKLineSplitStick *)obj).pg;
        splitStick.match_price = ((YDKLineSplitStick *)obj).pgj;

        splitSticks.push_back(splitStick);
    }
    
    vector<KLineStick> returnSticks;
    if ([self.split isEqualToString:@"0"] || ![self.tempPeriod isEqualToString:@"5"] || !self.isFirstSplit) {
        returnSticks = sticks;
    } else {
        SplitManager::getSplit(sticks,splitSticks,[self.split intValue],[self.tempPeriod intValue], returnSticks);
//        drawSticks = returnSticks;
        self.isFirstSplit = false;
        
    }
    
    //数据回传给RN
    NSDateFormatter *formatter1 = [[NSDateFormatter alloc]init];
    formatter1.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT+0800"];
    [formatter1 setDateFormat:@"yyyy-MM-dd"];
        
    NSMutableArray *arrayStick = [[NSMutableArray alloc] init];
    
    NSMutableArray *chartData = [[NSMutableArray alloc] init];
    int i = 0;
    for (auto &obj : returnSticks) {
        YdKLineStick * stick = [[YdKLineStick alloc] init] ;
        NSDate *d = [NSDate dateWithTimeIntervalSince1970:obj.time];
        NSString *showtimeNew = [formatter1 stringFromDate:d];
        stick.time = showtimeNew;
        NSDate *d2 = [NSDate dateWithTimeIntervalSince1970:obj.datetime];
        stick.datetime = [formatter2 stringFromDate:d2];
        stick.open = obj.open;
        stick.high = obj.high;
        stick.low = obj.low;
        stick.close = obj.close;
        stick.volumn = obj.volume;
        stick.amount = obj.amount;
        stick.fpVolumn = [[self.drawdata objectAtIndex:i] fpVolumn];
        stick.fpAmount = [[self.drawdata objectAtIndex:i] fpAmount];
        
        stick.littleIn = [[self.drawdata objectAtIndex:i] littleIn];
        stick.littleOut = [[self.drawdata objectAtIndex:i] littleOut];
        stick.mediumIn = [[self.drawdata objectAtIndex:i] mediumIn];
        stick.mediumOut = [[self.drawdata objectAtIndex:i] mediumOut];
        stick.hugeIn = [[self.drawdata objectAtIndex:i] hugeIn];
        stick.hugeOut = [[self.drawdata objectAtIndex:i] hugeOut];
        stick.largeIn = [[self.drawdata objectAtIndex:i] largeIn];
        stick.largeOut = [[self.drawdata objectAtIndex:i] largeOut];
        stick.superIn = [[self.drawdata objectAtIndex:i] superIn];
        stick.superOut = [[self.drawdata objectAtIndex:i] superOut];
        stick.total = [[self.drawdata objectAtIndex:i] total];
        
        stick.turnoverRate = [[self.drawdata objectAtIndex:i] turnoverRate];
        stick.changeRate = [[self.drawdata objectAtIndex:i] changeRate];
        
        [arrayStick addObject:stick];
        i++;
        
        NSDictionary *chartDict = @{
                                    @"KaiPanJia":[NSNumber numberWithDouble:obj.open],
                                    @"ZuiGaoJia":[NSNumber numberWithDouble:obj.high],
                                    @"ZuiDiJia":[NSNumber numberWithDouble:obj.low],
                                    @"ShouPanJia":[NSNumber numberWithDouble:obj.close],
                                    @"ChengJiaoLiang":[NSNumber numberWithDouble:obj.volume]};
        [chartData addObject:chartDict];
    }
    self.drawdata = arrayStick;
    
//    if (self.onSplitDataBlock) {
//        self.onSplitDataBlock(@{@"chartData":chartData});
//    }
    if (returnSticks.size() == 0) return;
    mainFormula->setSticks(returnSticks);
    mainFormula->run();
    
    viceFormula->setSticks(returnSticks);
    viceFormula->setFundFlowSticks(fundFlows);
    MinOtherData minData;
    minData.circulateEquityA = self.circulateEquityA;
    viceFormula->setOtherData(minData);
    viceFormula->run();
    
    viceFormula1->setSticks(returnSticks);
    viceFormula1->setFundFlowSticks(fundFlows);
    viceFormula1->setOtherData(minData);
    viceFormula1->run();
    
    if (self.drawdata.count > 0) {
        self.formulaIsRun = YES;
    }
}



- (void)updateLegend {
    NSInteger cursor = self.chartPV.chartView.legendPos == -1 ? self.chartPV.chartView.endPos : min(self.chartPV.chartView.endPos, self.chartPV.chartView.legendPos);
    if (cursor == -1) return;
    
    YdKLineStick* stick = (YdKLineStick*)[self.drawdata objectAtIndex:cursor];
    {
        NSString* strTime = [stick.time stringByAppendingString: @" "];
        
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:_isLand == 1 ? strTime : @""];
        [str addAttribute:NSForegroundColorAttributeName value:[UIColor darkGrayColor] range:NSMakeRange(0, str.string.length)];
        int flag = 0;
        const FormulaResults & results = mainFormula->getResult();
        for (const auto& result : results) {
            if (shared_ptr<FormulaLine> line = result._line) {
                if (invalid_dbl != line->_data[cursor]) {
                    NSString *name = [NSString stringWithUTF8String:line->_name.c_str()];
                    NSString *fmlData = [NSString stringWithFormat:@" %@:%.2f  ",name, line->_data[cursor]];
                    UIColor *clr = UIColorFromRGB(line->_color);
                    NSMutableAttributedString *fmlStr = [[NSMutableAttributedString alloc] initWithString:fmlData];
                    [fmlStr addAttribute:NSForegroundColorAttributeName value:clr range:NSMakeRange(0, fmlStr.string.length)];
                    if (_isLand != 1) {
                        if (flag < 3) {
                            [str appendAttributedString:fmlStr];
                        }
                        flag ++;
                    } else {
                        [str appendAttributedString:fmlStr];
                    }
                }
            }
        }
        NSString *mainName = [NSString stringWithFormat:@"%@  ",_mainName];
        NSMutableAttributedString *fmlStr1 = [[NSMutableAttributedString alloc] initWithString:mainName];
        [fmlStr1 appendAttributedString:str];
        if (_isLand != 1) {
            mainTextLable.attributedText = str;
        } else {
            mainTextLable.attributedText = fmlStr1;
        }
    }
    
    {
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] init];
        int flag = 0;
        int flagDraw = 0;
        const FormulaResults & results = viceFormula->getResult();
        for (const auto& result : results) {
            if (shared_ptr<FormulaLine> line = result._line) {
                if (invalid_dbl != line->_data[cursor]) {
                    NSString *name = [NSString stringWithUTF8String:line->_name.c_str()];
                    
                    NSString *numS = @"0.00";
                    if (([formatNumber(line->_data[cursor]) length] <50)) {
                        numS = [NSString stringWithFormat:@"%@",formatNumber((line->_data[cursor]))];
                    }
                    
                    NSString *fmlData = [NSString stringWithFormat:@" %@:%@  ",name, numS];
                    UIColor *clr = UIColorFromRGB(line->_color);
                    if ([self.viceName isEqualToString:@"主力资金"]) {
                        clr = line->_data[cursor] > 0 ? [UIColor colorWithRed:249/255.0 green:36/255.0 blue:0 alpha:1] : [UIColor colorWithRed:51/255.0 green:153/255.0 blue:0 alpha:1];
                    }
                    NSMutableAttributedString *fmlStr = [[NSMutableAttributedString alloc] initWithString:fmlData];
                    [fmlStr addAttribute:NSForegroundColorAttributeName value:clr range:NSMakeRange(0, fmlStr.string.length)];
                    if (_isLand != 1) {
                        if ([_viceName isEqualToString:@"操盘提醒"]) {
                            if (([name containsString:@"波段"] || [name containsString:@"反弹"]) && name.length > 0) {
                                [str appendAttributedString:fmlStr];
                            }
                        } else {
                            if (flag < 3) {
                                if (name.length > 0) {
                                    [str appendAttributedString:fmlStr];
                                }
                            }
                        }
                        flag ++;
                    } else {
                        if (name.length > 0) {
                            [str appendAttributedString:fmlStr];
                        }
                    }
                }
            } else if (shared_ptr<FormulaDraw> draw = result._draw) {
                NSString *name = [NSString stringWithUTF8String:draw->_text.c_str()];
                
                NSString *numS = @"0.00";
                if (([formatNumber(draw->_drawPositon3[cursor]) length] < 50)) {
                    numS = [NSString stringWithFormat:@"%@",formatNumber(draw->_drawPositon3[cursor])];
                }
                
                NSString *fmlData = [NSString stringWithFormat:@" %@:%@  ", name, numS];
                UIColor *clr = UIColorFromRGB(draw->_color);
                NSMutableAttributedString *fmlStr = [[NSMutableAttributedString alloc] initWithString:fmlData];
                [fmlStr addAttribute:NSForegroundColorAttributeName value:clr range:NSMakeRange(0, fmlStr.string.length)];
                
                if (_isLand != 1) {
                    if ([_viceName isEqual:@"操盘提醒"]) {
                        if (([name containsString:@"波段"] || [name containsString:@"反弹"]) && name.length > 0) {
                            [str appendAttributedString:fmlStr];
                        }
                    } else {
                        if (flagDraw < 3) {
                            if (name.length > 0) {
                                [str appendAttributedString:fmlStr];
                            }
                        }
                    }
                    flagDraw ++;
                } else {
                    if (name.length > 0) {
                        [str appendAttributedString:fmlStr];
                    }
                }
            }
        }
        NSString *viceName = [NSString stringWithFormat:@"%@  ", _viceName];
        NSMutableAttributedString *fmlStr1 = [[NSMutableAttributedString alloc] initWithString:viceName];
        [fmlStr1 appendAttributedString:str];
        if (_isLand != 1) {
            viceTextLable.attributedText = str;
        } else {
            viceTextLable.attributedText = fmlStr1;
        }
    }
    {
        
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] init];
        int flag = 0;
        int flagDraw = 0;
        const FormulaResults & results = viceFormula1->getResult();
        for (const auto& result : results) {
            if (shared_ptr<FormulaLine> line = result._line) {
                if (invalid_dbl != line->_data[cursor]) {
                    NSString *name = [NSString stringWithUTF8String:line->_name.c_str()];
                    
                    NSString *numS = @"0.00";
                    if (([formatNumber(line->_data[cursor]) length] < 50)) {
                        numS = [NSString stringWithFormat:@"%@", formatNumber(line->_data[cursor])];
                    }
                    
                    NSString *fmlData = [NSString stringWithFormat:@" %@:%@  ", name, numS];
                    UIColor *clr = UIColorFromRGB(line->_color);
                    if ([self.chartLoc isEqualToString:@"主力资金"]) {
                        clr = line->_data[cursor] > 0 ? [UIColor colorWithRed:249/255.0 green:36/255.0 blue:0 alpha:1] : [UIColor colorWithRed:51/255.0 green:153/255.0 blue:0 alpha:1];
                    }
                    NSMutableAttributedString *fmlStr = [[NSMutableAttributedString alloc] initWithString:fmlData];
                    [fmlStr addAttribute:NSForegroundColorAttributeName value:clr range:NSMakeRange(0, fmlStr.string.length)];
                    if (_isLand != 1) {
                        if ([_chartLoc isEqual:@"操盘提醒"]) {
                            if (([name containsString:@"波段"] || [name containsString:@"反弹"]) && name.length > 0) {
                                [str appendAttributedString:fmlStr];
                            }
                        } else {
                            if (flag < 3) {
                                if (name.length > 0) {
                                    [str appendAttributedString:fmlStr];
                                }
                            }
                        }
                        flag ++;
                    }
                }
            } else if (shared_ptr<FormulaDraw> draw = result._draw) {
                NSString *name = [NSString stringWithUTF8String:draw->_text.c_str()];
                NSString *numS = @"0.00";
                if (([formatNumber(draw->_drawPositon3[cursor]) length] < 50)) {
                    numS = [NSString stringWithFormat:@"%@",formatNumber(draw->_drawPositon3[cursor])];
                }
                
                NSString *fmlData = [NSString stringWithFormat:@" %@:%@  ", name, numS];
                UIColor *clr = UIColorFromRGB(draw->_color);
                NSMutableAttributedString *fmlStr = [[NSMutableAttributedString alloc] initWithString:fmlData];
                [fmlStr addAttribute:NSForegroundColorAttributeName value:clr range:NSMakeRange(0, fmlStr.string.length)];
                if (_isLand != 1) {
                    if ([_chartLoc isEqual:@"操盘提醒"]) {
                        if (([name containsString:@"波段"] || [name containsString:@"反弹"]) && name.length > 0) {
                            [str appendAttributedString:fmlStr];
                        }
                    } else {
                        if (flagDraw < 3) {
                            if (name.length > 0) {
                                [str appendAttributedString:fmlStr];
                            }
                        }
                    }
                    flagDraw ++;
                }
            }
        }
        viceTextLable2.attributedText = str;
    }
}

- (NSArray *)getViceFormulaData:(NSInteger)pos {
    
    NSMutableArray* array = [[NSMutableArray alloc] init];
    [array addObject:@{@"str":_viceName, @"color":[NSNull null]}];
    [array addObject:@{@"str":@"--", @"color":[NSNull null]}];
    
    if (pos >= (NSInteger)self.drawdata.count || pos < 0) {
        pos = self.chartPV.chartView.endPos;
    }

    const FormulaResults & results = viceFormula->getResult();
    
    for (const auto& result : results) {
        if (shared_ptr<FormulaLine> line = result._line) {
            NSMutableString *str = [NSMutableString stringWithUTF8String:line->_name.c_str()];
            NSString* val = @"--";
            if (invalid_dbl != line->_data[pos]) {
                val = formatNumber(line->_data[pos]);
            }
            if (str.length != 0) {
                [str appendString:@": "];
            }
            [str appendString:val];
            
            NSString *clr = [NSString stringWithFormat:@"#%06x", line->_color];
            [array addObject:@{@"str":str, @"color":clr}];
        } else if (shared_ptr<FormulaDraw> draw = result._draw) {
            if (invalid_dbl != draw->_drawPositon3[pos] && draw->_drawPositon1[pos] > 0.000001) {
                NSMutableString* name = [NSMutableString stringWithUTF8String:draw->_text.c_str()];
                if (name.length != 0) {
                    [name appendString:@": "];
                }
                [name appendString: formatNumber(draw->_drawPositon3[pos])];
                
                NSString* clr = [NSString stringWithFormat:@"#%06x", draw->_color ];
                [array addObject:@{@"str":name, @"color":clr}];
            }
        }
    }
    return array;
}

- (NSArray *)getViceFormulaData1:(NSInteger)pos {
    
    NSMutableArray* array = [[NSMutableArray alloc] init];
    [array addObject:@{@"str":_chartLoc, @"color":[NSNull null]}];
    [array addObject:@{@"str":@"--", @"color":[NSNull null]}];
    
    if (pos >= (NSInteger)self.drawdata.count || pos < 0) {
        pos = self.chartPV.chartView.endPos;
    }
    
    const FormulaResults & results = viceFormula1->getResult();
    
    for (const auto& result : results) {
        if (shared_ptr<FormulaLine> line = result._line) {
            NSMutableString *str = [NSMutableString stringWithUTF8String:line->_name.c_str()];
            NSString *val = @"--";
            if (invalid_dbl != line->_data[pos]) {
                val = formatNumber(line->_data[pos]);
            }
            if (str.length != 0) {
                [str appendString:@": "];
            }
            [str appendString:val];
            
            NSString *clr = [NSString stringWithFormat:@"#%06x", line->_color];
            
            [array addObject:@{@"str":str, @"color":clr}];
        } else if (shared_ptr<FormulaDraw> draw = result._draw) {
            
            if (invalid_dbl != draw->_drawPositon3[pos] && draw->_drawPositon1[pos] > 0.000001) {
                NSMutableString *name = [NSMutableString stringWithUTF8String:draw->_text.c_str()];
                if (name.length != 0) {
                    [name appendString:@": "];
                }
                [name appendString: formatNumber(draw->_drawPositon3[pos])];
                
                NSString* clr = [NSString stringWithFormat:@"#%06x", draw->_color ];
                [array addObject:@{@"str":name, @"color":clr}];
            }
        }
    }
    return array;
}


- (NSDictionary*)getMainFormulaData:(NSInteger)pos {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:0];
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    if (pos >= (NSInteger)self.drawdata.count || pos < 0) {
        pos = self.chartPV.chartView.endPos;
    }
    
    NSMutableArray *viceArray = [[NSMutableArray alloc] init];
    [viceArray addObject:@{@"str":_viceName, @"color":[NSNull null]}];
    
    NSMutableArray *viceArray1 = [[NSMutableArray alloc] init];
    [viceArray1 addObject:@{@"str":_chartLoc, @"color":[NSNull null]}];
    
    [dic setObject:viceArray forKey:@"vice"];
    [dic setObject:viceArray1 forKey:@"vice1"];
    NSString *strTime = @"--";
    if (self.drawdata.count > 0) {
        YdKLineStick* stick = (YdKLineStick*)[self.drawdata objectAtIndex:pos];
        strTime = stick.time;
    }
    [array addObject:@{@"str":_mainName, @"color":[NSNull null]}];
    [dic setObject:array forKey:@"main"];
    return dic;
}

#pragma mark - 缩放
- (void)zoomIn {
    [self.chartPV zoomIn];
}
- (void)zoomOut {
    [self.chartPV zoomOut];
}
#pragma mark - 移动
- (void)moveLeft {
    [self.chartPV moveLeft];
}
- (void)moveRight {
    [self.chartPV moveRight];
}

@end
