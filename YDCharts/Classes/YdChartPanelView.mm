//
//  YdChartPanelView.m
//  DzhChart
//
//  Created by dxd on 2020/5/7.
//  Copyright © 2020 dzh. All rights reserved.
//

#import "YdChartPanelView.h"
#import "UIDefine.h"
#import "YdChartUtil.h"
#import "YdChartView.h"
#import "YdKLineView.h"

@implementation YdChartPanelView

@synthesize delegate = _myDelegate;//重载父类delegate属性


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (id)init {
    self = [super init];
    if (self) {
        [super setDelegate:self];
        //缩放
        UIPinchGestureRecognizer *pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchAction:)];
        pinch.delegate = self;
        [self addGestureRecognizer:pinch];
        
        //长按
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognizer:)];
        [self addGestureRecognizer:longPressGesture];
        //点按
        UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapGestureRecognizer:)];
        [self addGestureRecognizer:tapGesture];
        
        YdChartView * view = [[YdChartView alloc]init];
        [self addSubview:view];
        self.chartView = view;
        self.showsVerticalScrollIndicator = NO;
        self.showsHorizontalScrollIndicator = NO;

        self.isFirstShow = YES;
    }
    return self;
}

- (void)layoutSubviews {
//    self.chartView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);//缩放易产生长影
    [self.chartView setNeedsDisplay];
}

#pragma mark - ScrollView
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    int kBeginNum = scrollView.contentOffset.x / self.chartView.kLineWidth;
    
    self.isFirstShow = NO;
    self.chartView.startPos = kBeginNum;
    [self hiddenCrossLine];
}

// 捏合手势监听方法
- (void)pinchAction:(UIPinchGestureRecognizer *)recognizer {
    NSInteger showCountTemp = self.chartView.showCount - 5 * recognizer.velocity; //缩放速度
    NSInteger  showCountTemp2 = showCountTemp<SHOW_KLINE_MIN_COUNT?SHOW_KLINE_MIN_COUNT:(showCountTemp>SHOW_KLINE_MAX_COUNT?SHOW_KLINE_MAX_COUNT:showCountTemp);
    
    //YdChartView 改变frame，contentSize 改变
    self.chartView.showCount = showCountTemp2;
    float containerWidth= self.chartView.kLineWidth * (self.parentView.drawdata.count+.5), containerHeight=self.contentSize.height; //.5 半根K线
    self.contentSize = CGSizeMake(containerWidth, containerHeight);
    
}

- (void)zoomIn {
    NSInteger showCountTemp = self.chartView.showCount - 5; //缩放速度
    NSInteger  showCountTemp2 = showCountTemp<SHOW_KLINE_MIN_COUNT?SHOW_KLINE_MIN_COUNT:(showCountTemp>SHOW_KLINE_MAX_COUNT?SHOW_KLINE_MAX_COUNT:showCountTemp);
    
    //YdChartView 改变frame，contentSize 改变
    self.chartView.showCount = showCountTemp2;
    float containerWidth= self.chartView.kLineWidth * (self.parentView.drawdata.count+.5), containerHeight=self.contentSize.height; //.5 半根K线
    self.contentSize = CGSizeMake(containerWidth, containerHeight);
}

- (void)zoomOut {
    NSInteger showCountTemp = self.chartView.showCount + 5; //缩放速度
    NSInteger  showCountTemp2 = showCountTemp<SHOW_KLINE_MIN_COUNT?SHOW_KLINE_MIN_COUNT:(showCountTemp>SHOW_KLINE_MAX_COUNT?SHOW_KLINE_MAX_COUNT:showCountTemp);
    
    //YdChartView 改变frame，contentSize 改变
    self.chartView.showCount = showCountTemp2;
    float containerWidth= self.chartView.kLineWidth * (self.parentView.drawdata.count+.5), containerHeight=self.contentSize.height; //.5 半根K线
    self.contentSize = CGSizeMake(containerWidth, containerHeight);
    
}

- (void)moveLeft {
    if (self.contentOffset.x<=0) {
        return;
    } else {
        self.contentOffset = CGPointMake(self.contentOffset.x-self.chartView.kLineWidth, 0);
    }
}

- (void)moveRight {
    /*
     * 滑到最右侧时，滑动偏移量 + ScrollView宽度 < content.size宽度
     * self.contentOffset.x+self.bounds.size.width+self.contentInset.left+self.contentInset.right<self.contentSize.width
     * 内边距是0，判断右移还有没有一根K线的宽度
     */
    if (self.contentSize.width - self.contentOffset.x - self.bounds.size.width < self.chartView.kLineWidth) {
        return;
    } else {
        self.contentOffset = CGPointMake(self.contentOffset.x+self.chartView.kLineWidth, 0);
    }
}

//十字线
- (void) longPressGestureRecognizer:(UILongPressGestureRecognizer*)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state==UIGestureRecognizerStateChanged) {
        
        CGFloat positionX = [gesture locationInView:self].x;
        CGFloat positionY = [gesture locationInView:self].y;
        CGFloat positionParentX = [gesture locationInView:self.parentView].x;
        //十字线在K线中心
        CGFloat PointStartXOffset = self.contentOffset.x;//scroll偏移量
        CGFloat PointStartXOffsetK = fmod(PointStartXOffset, self.chartView.kLineWidth);//半根K线
        CGFloat PointStartXOffsetV = PointStartXOffset>=0 ? PointStartXOffset-PointStartXOffsetK : 0;//K线开始画的 最左边
        CGFloat positionXOffset = fmod(positionX-PointStartXOffsetV, self.chartView.kLineWidth);
        positionX = positionX-positionXOffset+self.chartView.kLineWidth/2;
        //当前是第几根K线
        int curLineIndex = positionX / self.chartView.kLineWidth;
        curLineIndex = (curLineIndex>self.parentView.drawdata.count-1) ? (int)self.parentView.drawdata.count-1 : curLineIndex;
        
        if (!sniperVLayer) {
            sniperVLayer = [[CALayer alloc]init];
            sniperVLayer.backgroundColor = [UIColor lightGrayColor].CGColor;
            [self.layer addSublayer:sniperVLayer];
            
        }
        if (!sniperHLayer) {
            sniperHLayer = [[CALayer alloc]init];
            sniperHLayer.backgroundColor = [UIColor lightGrayColor].CGColor;
            [self.layer addSublayer:sniperHLayer];
        }
        if (positionY <= self.parentView.mainYAxis.minBound()
            || (positionY <= self.parentView.viceYAxis.minBound() && positionY >= self.parentView.viceYAxis.maxBound())
            || (positionY <= self.parentView.viceYAxis2.minBound() && positionY >= self.parentView.viceYAxis2.maxBound())
            ) {
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
                [self.parentView.layer addSublayer:tipHLayer];
            }
        } else {
            [tipHLayer removeFromSuperlayer];
            tipHLayer = nil;
        }
        
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
            [self.parentView.layer addSublayer:tipVLayer];
        }
        
        //stock info
        YdKLineStick* stick = (YdKLineStick*)[self.parentView.drawdata objectAtIndex:curLineIndex];
        if(!tipView) {
            tipView = [[UIView alloc]init];
            CGFloat tipViewWidth = !self.parentView.isLand ? SCREEN_WIDTH : self.frame.size.width;
            tipView.frame = !self.parentView.isLand ? CGRectMake(-15, -55, tipViewWidth, 55) : CGRectMake(-10, -55, self.frame.size.width+100, 50);
            tipView.backgroundColor = RGB16(0xf5f5f5);
            [self.superview addSubview:tipView];
            
            UIFont * fontSize = [UIFont systemFontOfSize:12];
            UIColor * fontColor = RGB16(0x444444);
            CGFloat tipBorderValue = 15;
            CGFloat tipTextWidth = 25;
            CGFloat tipTextHigh = 15;
            CGFloat tipValueWidth = (tipViewWidth-tipBorderValue*2-tipTextWidth*4)/4;
            
            CGFloat tipLandTipBorderValue = 150+10;
            CGFloat tipLandTextHigh = 20;
            CGFloat tipLandValueWidth = (tipViewWidth-tipLandTipBorderValue-tipTextWidth*4)/4;
            
            if (self.parentView.isLand) {
                UILabel * nameLbl = [[UILabel alloc]init];
                nameLbl.frame = CGRectMake(tipBorderValue, 5, 70, tipLandTextHigh);
                nameLbl.font = fontSize;
                nameLbl.textColor = fontColor;
                nameLbl.tag = 13;
                nameLbl.text = self.parentView.stockName;
                [tipView addSubview:nameLbl];
                
                UILabel * symbolLbl = [[UILabel alloc]init];
                symbolLbl.frame = CGRectMake(tipBorderValue+70, 5, 70, tipLandTextHigh);
                symbolLbl.font = fontSize;
                symbolLbl.textColor = fontColor;
                symbolLbl.tag = 12;
                symbolLbl.text = code2symbol(self.parentView.stockCodes);
                [tipView addSubview:symbolLbl];
            }
            
            UILabel * timeValueLbl = [[UILabel alloc]init];
            timeValueLbl.frame = !self.parentView.isLand ? CGRectMake(tipBorderValue, 5, tipValueWidth*2, tipTextHigh) : CGRectMake(tipBorderValue, 5+tipLandTextHigh, tipLandTipBorderValue, tipLandTextHigh);
            timeValueLbl.font = fontSize;
            timeValueLbl.textColor = fontColor;
            timeValueLbl.tag = 11;
            timeValueLbl.text = [self.parentView.tempPeriod intValue]>=5 ? stick.time : stick.datetime;
            [tipView addSubview:timeValueLbl];
            
            UILabel * openLbl = [[UILabel alloc]init];
            openLbl.frame = !self.parentView.isLand ? CGRectMake(tipBorderValue, 5+tipTextHigh, tipTextWidth, tipTextHigh) : CGRectMake(tipLandTipBorderValue+tipBorderValue, 5, tipTextWidth, tipLandTextHigh);
            openLbl.font = fontSize;
            openLbl.textColor = fontColor;
            openLbl.text = @"开：";
            [tipView addSubview:openLbl];
            
            UILabel * openValueLbl = [[UILabel alloc]init];
            openValueLbl.frame = !self.parentView.isLand ? CGRectMake(tipBorderValue+tipTextWidth, openLbl.frame.origin.y, tipValueWidth, tipTextHigh) : CGRectMake(tipLandTipBorderValue+tipBorderValue+tipTextWidth, openLbl.frame.origin.y, tipLandValueWidth, tipLandTextHigh);
            openValueLbl.font = fontSize;
            openValueLbl.textColor = fontColor;
            openValueLbl.tag = 21;
            openValueLbl.text = [NSString stringWithFormat:@"%.2f", stick.open];
            [tipView addSubview:openValueLbl];
            
            UILabel * highLbl = [[UILabel alloc]init];
            highLbl.frame = !self.parentView.isLand ? CGRectMake(tipBorderValue+tipTextWidth+tipValueWidth, openLbl.frame.origin.y, tipTextWidth, tipTextHigh) : CGRectMake(tipLandTipBorderValue+tipBorderValue+tipTextWidth+tipLandValueWidth, openLbl.frame.origin.y, tipTextWidth, tipLandTextHigh);
            highLbl.font = fontSize;
            highLbl.textColor = fontColor;
            highLbl.text = @"高：";
            [tipView addSubview:highLbl];
            
            UILabel * highValueLbl = [[UILabel alloc]init];
            highValueLbl.frame = !self.parentView.isLand ? CGRectMake(tipBorderValue+tipTextWidth*2+tipValueWidth, openLbl.frame.origin.y, tipValueWidth, tipTextHigh) : CGRectMake(tipLandTipBorderValue+tipBorderValue+tipTextWidth*2+tipLandValueWidth, openLbl.frame.origin.y, tipLandValueWidth, tipLandTextHigh);
            highValueLbl.font = fontSize;
            highValueLbl.textColor = fontColor;
            highValueLbl.tag = 22;
            highValueLbl.text = [NSString stringWithFormat:@"%.2f", stick.high];
            [tipView addSubview:highValueLbl];
            
            UILabel * zdfLbl = [[UILabel alloc]init];
            zdfLbl.frame = !self.parentView.isLand ? CGRectMake(tipBorderValue+tipTextWidth*2+tipValueWidth*2, openLbl.frame.origin.y, tipTextWidth, tipTextHigh) : CGRectMake(tipLandTipBorderValue+tipBorderValue+tipTextWidth*2+tipLandValueWidth*2, openLbl.frame.origin.y, tipTextWidth, tipLandTextHigh);
            zdfLbl.font = fontSize;
            zdfLbl.textColor = fontColor;
            zdfLbl.text = @"幅：";
            [tipView addSubview:zdfLbl];
            
            UILabel * zdfValueLbl = [[UILabel alloc]init];
            zdfValueLbl.frame = !self.parentView.isLand ? CGRectMake(tipBorderValue+tipTextWidth*3+tipValueWidth*2, openLbl.frame.origin.y, tipValueWidth, tipTextHigh) : CGRectMake(tipLandTipBorderValue+tipBorderValue+tipTextWidth*3+tipLandValueWidth*2, openLbl.frame.origin.y, tipLandValueWidth, tipLandTextHigh);
            zdfValueLbl.font = fontSize;
            zdfValueLbl.textColor = fontColor;
            zdfValueLbl.tag = 23;
            zdfValueLbl.text =[NSString stringWithFormat:@"%.2f%%", stick.changeRate*100];
            [tipView addSubview:zdfValueLbl];
            
            UILabel * hsLbl = [[UILabel alloc]init];
            hsLbl.frame = !self.parentView.isLand ? CGRectMake(tipBorderValue+tipTextWidth*3+tipValueWidth*3, openLbl.frame.origin.y, tipTextWidth, tipTextHigh) : CGRectMake(tipLandTipBorderValue+tipBorderValue+tipTextWidth*3+tipLandValueWidth*3, openLbl.frame.origin.y, tipTextWidth, tipLandTextHigh);
            hsLbl.font = fontSize;
            hsLbl.textColor = fontColor;
            hsLbl.text = @"换：";
            [tipView addSubview:hsLbl];
            
            UILabel * hsValueLbl = [[UILabel alloc]init];
            hsValueLbl.frame = !self.parentView.isLand ? CGRectMake(tipBorderValue+tipTextWidth*4+tipValueWidth*3, openLbl.frame.origin.y, tipValueWidth, tipTextHigh) : CGRectMake(tipLandTipBorderValue+tipBorderValue+tipTextWidth*4+tipLandValueWidth*3, openLbl.frame.origin.y, tipLandValueWidth, tipLandTextHigh);
            hsValueLbl.font = fontSize;
            hsValueLbl.textColor = fontColor;
            hsValueLbl.tag = 24;
            hsValueLbl.text = isinf(stick.turnoverRate)? @"--" : [NSString stringWithFormat:@"%.2f%%", stick.turnoverRate*100];
            [tipView addSubview:hsValueLbl];
            
            //
            UILabel * closeLbl = [[UILabel alloc]init];
            closeLbl.frame = !self.parentView.isLand ? CGRectMake(tipBorderValue, 5+tipTextHigh*2, tipTextWidth, tipTextHigh) : CGRectMake(tipLandTipBorderValue+tipBorderValue, 5+tipLandTextHigh, tipTextWidth, tipLandTextHigh);
            closeLbl.font = fontSize;
            closeLbl.textColor = fontColor;
            closeLbl.text = @"收：";
            [tipView addSubview:closeLbl];
            
            UILabel * closeValueLbl = [[UILabel alloc]init];
            closeValueLbl.frame = !self.parentView.isLand ? CGRectMake(tipBorderValue+tipTextWidth, closeLbl.frame.origin.y, tipValueWidth, tipTextHigh) : CGRectMake(tipLandTipBorderValue+tipBorderValue+tipTextWidth, closeLbl.frame.origin.y, tipLandValueWidth, tipLandTextHigh);
            closeValueLbl.font = fontSize;
            closeValueLbl.textColor = fontColor;
            closeValueLbl.tag = 31;
            closeValueLbl.text = [NSString stringWithFormat:@"%.2f", stick.close];
            [tipView addSubview:closeValueLbl];
            
            UILabel * lowLbl = [[UILabel alloc]init];
            lowLbl.frame = !self.parentView.isLand ? CGRectMake(tipBorderValue+tipTextWidth+tipValueWidth, closeLbl.frame.origin.y, tipTextWidth, tipTextHigh) : CGRectMake(tipLandTipBorderValue+tipBorderValue+tipTextWidth+tipLandValueWidth, closeLbl.frame.origin.y, tipTextWidth, tipLandTextHigh);
            lowLbl.font = fontSize;
            lowLbl.textColor = fontColor;
            lowLbl.text = @"低：";
            [tipView addSubview:lowLbl];
            
            UILabel * lowValueLbl = [[UILabel alloc]init];
            lowValueLbl.frame = !self.parentView.isLand ? CGRectMake(tipBorderValue+tipTextWidth*2+tipValueWidth, closeLbl.frame.origin.y, tipValueWidth, tipTextHigh) : CGRectMake(tipLandTipBorderValue+tipBorderValue+tipTextWidth*2+tipLandValueWidth, closeLbl.frame.origin.y, tipLandValueWidth, tipLandTextHigh);
            lowValueLbl.font = fontSize;
            lowValueLbl.textColor = fontColor;
            lowValueLbl.tag = 32;
            lowValueLbl.text = [NSString stringWithFormat:@"%.2f", stick.low];
            [tipView addSubview:lowValueLbl];
            
            UILabel * amountLbl = [[UILabel alloc]init];
            amountLbl.frame = !self.parentView.isLand ? CGRectMake(tipBorderValue+tipTextWidth*2+tipValueWidth*2, closeLbl.frame.origin.y, tipTextWidth, tipTextHigh) : CGRectMake(tipLandTipBorderValue+tipBorderValue+tipTextWidth*2+tipLandValueWidth*2, closeLbl.frame.origin.y, tipTextWidth, tipLandTextHigh);
            amountLbl.font = fontSize;
            amountLbl.textColor = fontColor;
            amountLbl.text = @"额：";
            [tipView addSubview:amountLbl];
            
            UILabel * amoutValueLbl = [[UILabel alloc]init];
            amoutValueLbl.frame =  !self.parentView.isLand ? CGRectMake(tipBorderValue+tipTextWidth*3+tipValueWidth*2, closeLbl.frame.origin.y, tipValueWidth, tipTextHigh) : CGRectMake(tipLandTipBorderValue+tipBorderValue+tipTextWidth*3+tipLandValueWidth*2, closeLbl.frame.origin.y, tipLandValueWidth, tipLandTextHigh);
            amoutValueLbl.font = fontSize;
            amoutValueLbl.textColor = fontColor;
            amoutValueLbl.tag = 33;
            amoutValueLbl.text = [NSString stringWithFormat:@"%@", formatNumber(stick.amount)];
            [tipView addSubview:amoutValueLbl];
            
            UILabel * volumeLbl = [[UILabel alloc]init];
            volumeLbl.frame = !self.parentView.isLand ? CGRectMake(tipBorderValue+tipTextWidth*3+tipValueWidth*3, closeLbl.frame.origin.y, tipTextWidth, tipTextHigh) : CGRectMake(tipLandTipBorderValue+tipBorderValue+tipTextWidth*3+tipLandValueWidth*3, closeLbl.frame.origin.y, tipTextWidth, tipLandTextHigh);
            volumeLbl.font = fontSize;
            volumeLbl.textColor = fontColor;
            volumeLbl.text = @"量：";
            [tipView addSubview:volumeLbl];
            
            UILabel * volumeValueLbl = [[UILabel alloc]init];
            volumeValueLbl.frame = !self.parentView.isLand ? CGRectMake(tipBorderValue+tipTextWidth*4+tipValueWidth*3, closeLbl.frame.origin.y, tipValueWidth, tipTextHigh) : CGRectMake(tipLandTipBorderValue+tipBorderValue+tipTextWidth*4+tipLandValueWidth*3, closeLbl.frame.origin.y, tipLandValueWidth, tipLandTextHigh);
            volumeValueLbl.font = fontSize;
            volumeValueLbl.textColor = fontColor;
            volumeValueLbl.tag = 34;
            volumeValueLbl.text = [NSString stringWithFormat:@"%@手", formatNumber(stick.volumn/100)];
            [tipView addSubview:volumeValueLbl];
        } else {
            UILabel * timeValueLbl = [tipView viewWithTag:11];
            timeValueLbl.text = [self.parentView.tempPeriod intValue]>=5 ? stick.time : stick.datetime;
            
            UILabel * openValueLbl = [tipView viewWithTag:21];
            openValueLbl.text = [NSString stringWithFormat:@"%.2f", stick.open];
            
            UILabel * highValueLbl = [tipView viewWithTag:22];
            highValueLbl.text = [NSString stringWithFormat:@"%.2f", stick.high];

            UILabel * zdfValueLbl = [tipView viewWithTag:23];
            zdfValueLbl.text =[NSString stringWithFormat:@"%.2f%%", stick.changeRate*100];
            
            UILabel * hsValueLbl = [tipView viewWithTag:24];
            hsValueLbl.text = isinf(stick.turnoverRate)? @"--" : [NSString stringWithFormat:@"%.2f%%", stick.turnoverRate*100];

            UILabel * closeValueLbl = [tipView viewWithTag:31];
            closeValueLbl.text = [NSString stringWithFormat:@"%.2f", stick.close];

            UILabel * lowValueLbl = [tipView viewWithTag:32];
            lowValueLbl.text = [NSString stringWithFormat:@"%.2f", stick.low];

            UILabel * amoutValueLbl = [tipView viewWithTag:33];
            amoutValueLbl.text = [NSString stringWithFormat:@"%@", formatNumber(stick.amount)];

            UILabel * volumeValueLbl = [tipView viewWithTag:34];
            volumeValueLbl.text = [NSString stringWithFormat:@"%@手", formatNumber(stick.volumn/100)];
        }
        
        
        [CATransaction begin];
        [CATransaction setAnimationDuration:.1];
        
        
        //十字线
        if (!self.parentView.isLand) {
            sniperVLayer.frame = CGRectMake(positionX, self.parentView.mainChartRect.origin.y, 1,self.bounds.size.height-self.parentView.mainChartRect.origin.y);
        } else {
            sniperVLayer.frame = CGRectMake(positionX, self.parentView.mainChartRect.origin.y, 1,self.parentView.viceChartRect.origin.y+self.parentView.viceChartRect.size.height/2-2);
        }
        sniperHLayer.frame = CGRectMake(0, positionY, PointStartXOffset+self.bounds.size.width, 1);
        
        //十字线浮层 价格
        float price = 0;
        NSString * floatPrice = 0;
        if (positionY <= self.parentView.mainYAxis.minBound()) {
            price = self.parentView.mainYAxis.restore(positionY);
            floatPrice = [NSString stringWithFormat:@"%.2f", price];
        } else if (positionY <= self.parentView.viceYAxis.minBound() && positionY >= self.parentView.viceYAxis.maxBound()) {
            price = self.parentView.viceYAxis.restore(positionY);
            floatPrice = formatNumber(price);
        } else if (positionY <= self.parentView.viceYAxis2.minBound() && positionY >= self.parentView.viceYAxis2.maxBound()) {
            price = self.parentView.viceYAxis2.restore(positionY);
            floatPrice = formatNumber(price);
        }
        CGFloat priceWidth = adjustWidth(floatPrice, [UIFont systemFontOfSize:CROSS_TIP_FONT_SIZE]);
        
        //十字线浮层
        tipHLayer.frame = CGRectMake(0, positionY-(CROSS_TIP_FONT_SIZE+4)/2, priceWidth+3+3, CROSS_TIP_FONT_SIZE+4); // 3+3左右边距
        CATextLayer * tipHTextLayer = tipHLayer.sublayers.firstObject;
        tipHTextLayer.frame = CGRectMake(3, 0, priceWidth, CROSS_TIP_FONT_SIZE+4); //左边距:3
        tipHTextLayer.string = floatPrice;
        
        
        //
//        CGFloat xx = positionX-(30+3+3)/2;
//        xx = xx>0 ? ( xx<(self.parentView.mainChartRect.size.width-30-3-3) ? xx : self.parentView.mainChartRect.size.width-30-3-3) : 0; //tip最左，最右
        
        CATextLayer * tipVTextLayer = tipVLayer.sublayers.firstObject;
        tipVTextLayer.frame = CGRectMake(3, 0, 100, CROSS_TIP_FONT_SIZE+4); //左边距:3
        if ([self.parentView.tempPeriod intValue] < 5) { //
            CGFloat xx = positionParentX-(80+3+3)/2;
            xx = xx>(self.parentView.mainChartRect.size.width-80-3-3) ? (self.parentView.mainChartRect.size.width-80-3-3) : xx;
            xx = xx<0 ? 0 : xx;
            
            tipVTextLayer.string = stick.datetime;
            tipVLayer.frame = CGRectMake(xx, self.parentView.mainChartRect.origin.y+self.parentView.mainChartRect.size.height, 80+3+3, CROSS_TIP_FONT_SIZE+4); // 3+3左右边距
        } else {
            CGFloat xx = positionParentX-(54+3+3)/2;
            xx = xx>(self.parentView.mainChartRect.size.width-54-3-3) ? (self.parentView.mainChartRect.size.width-54-3-3) : xx;
            xx = xx<0 ? 0 : xx;
            
            tipVTextLayer.string = stick.time;
            tipVLayer.frame = CGRectMake(xx, self.parentView.mainChartRect.origin.y+self.parentView.mainChartRect.size.height, 54+3+3, CROSS_TIP_FONT_SIZE+4); // 3+3左右边距
        }
        
        [CATransaction commit];
        
        if (lastLineIndex != curLineIndex) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"KLineCrossNotification" object:@{ @"curKlineIndex":[NSNumber numberWithInt:curLineIndex]} ];
        }
        lastLineIndex = curLineIndex;
    } else {
        [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(hiddenCrossLine) userInfo:nil repeats:NO];
    }
}
//取消十字光标
- (void)tapGestureRecognizer:(UITapGestureRecognizer*)tap {
    CGFloat positionY = [tap locationInView:self].y;

    if (sniperVLayer) {
        [self hiddenCrossLine];
    } else if (positionY > self.parentView.viceYAxis.maxBound() && positionY < self.parentView.viceYAxis.minBound()) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"nextFormulaNotification" object:@{ @"formula":@"vice"}];
    } else if (positionY > self.parentView.viceYAxis2.maxBound() && positionY < self.parentView.viceYAxis2.minBound()) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"nextFormulaNotification" object:@{ @"formula":@"vice2"}];
    }
}

- (void)hiddenCrossLine {
    int curLineIndex = -1 ;//(int)self.parentView.drawdata.count-1;
       if(sniperVLayer){
           [[NSNotificationCenter defaultCenter] postNotificationName:@"KLineCrossNotification" object:@{ @"curKlineIndex":[NSNumber numberWithInt:curLineIndex]} ];
       }
    [sniperVLayer removeFromSuperlayer];
    [sniperHLayer removeFromSuperlayer];
    sniperVLayer = nil;
    sniperHLayer = nil;
    [tipHLayer removeFromSuperlayer];
    tipHLayer = nil;
    [tipVLayer removeFromSuperlayer];
    tipVLayer = nil;
    [tipView removeFromSuperview];
    tipView = nil;
}

@end
