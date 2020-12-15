//
//  YdChartView.m
//  DzhChart
//
//  Created by dxd on 2020/5/7.
//  Copyright © 2020 dzh. All rights reserved.
//

#import "YdChartView.h"
#import "YdFormulaBase.hpp"
#import "YdChartUtil.h"
#import "UIDefine.h"
#import "YdKLineView.h"
#import "YdChartPanelView.h"

@interface YdChartView () {
    YdColor upColor;
    YdColor downColor;
    YdColor backgroundColor;
}

@end

@implementation YdChartView

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
        upColor.setColor(COLOR_UP);
        downColor.setColor(COLOR_DOWN);
        backgroundColor.setColor(COLOR_BACKGROUND);
        self.legendPos = -1;
    }
    return self;
}

- (NSInteger)showCount {
    return _showCount;
}

- (void)setShowCount:(NSInteger)count {
    _showCount = count;
    
    if (_startPos > self.endPos) return;
    
    [self.parentView calcAxis];
    
    [self.parentView updateAxisLabel];
    
    [self setNeedsDisplay];
}

- (void)setStartPos:(NSInteger)pos {
    if (pos < 0) {
        pos = 0;
    }
    
    _startPos = pos;
    
    if (_startPos > self.endPos) return;
    
    [self.parentView calcAxis];
    
    [self.parentView updateAxisLabel];
    
    [self setNeedsDisplay];
}

- (NSInteger)startPos {
    return _startPos;
}

- (NSInteger)endPos {
    NSInteger e = min(self.startPos+self.showCount-1, (NSInteger)self.parentView.drawdata.count-1);
    return e;
}

- (void)setLegendPos:(NSInteger)legendPos {
    _legendPos = legendPos;
    [self.parentView updateLegend];
}

- (NSInteger)legendPos {
    return _legendPos;
}

#pragma mark - 绘图
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();// 获取绘图上下文
    CGContextSetShouldAntialias(context, NO);

    CGContextSetRGBFillColor(context, backgroundColor.r(), backgroundColor.g(), backgroundColor.b(), self.alpha);
    CGContextFillRect(context, rect);
    
    if (self.showCount <= 0) return;
    
    [self drawAxisTicks:context];
    [self drawFormula:context region:CGRectMake(self.parentView.mainChartRect.origin.x, self.parentView.mainChartRect.origin.y, self.bounds.size.width, self.parentView.mainChartRect.size.height) axisY:self.parentView.mainYAxis formula:self.parentView.mainFormula];//self.parentView.mainChartRect不同于YdKLineView
    [self drawKLine:context];
    [self drawHighLowMark:context];

    [self drawFormula:context region:CGRectMake(self.parentView.viceChartRect.origin.x, self.parentView.viceChartRect.origin.y, self.bounds.size.width, self.parentView.viceChartRect.size.height) axisY:self.parentView.viceYAxis formula:self.parentView.viceFormula];
    if (self.parentView.isLand != 1) {
        [self drawFormula:context region:CGRectMake(self.parentView.viceChartRect2.origin.x, self.parentView.viceChartRect2.origin.y, self.bounds.size.width, self.parentView.viceChartRect2.size.height) axisY:self.parentView.viceYAxis2 formula:self.parentView.viceFormula1];
    }

    [self.parentView updateLegend];
}

//分隔线
- (void)drawAxisTicks:(CGContextRef)context {
    
    YdColor clr(COLOR_SEPERATOR);
    CGContextSetRGBStrokeColor(context, clr.r(), clr.g(), clr.b(),1.0);
    CGContextSetLineWidth(context,1.0f);
    CGContextBeginPath(context);

    CGFloat PointStartX = 0.0f; // 起始点坐标
    CGFloat PointStartY = 0.0f;
    CGFloat PointEndX = self.bounds.size.width; // 起始点坐标
    CGFloat PointEndY = 0.0f;
    for (int num = 1; num < 5; num++) {
        PointStartX = 0.0f, PointEndX = self.bounds.size.width;
        PointEndY = PointStartY = self.parentView.mainChartRect.origin.y + self.parentView.mainChartRect.size.height * num * 0.25;
        CGContextMoveToPoint(context, PointStartX, PointStartY);
        CGContextAddLineToPoint(context, PointEndX, PointEndY);
    }

    for (int num = 0; num < 1; num++) {
        PointStartX = 0.0f, PointEndX = self.bounds.size.width;
        PointEndY = PointStartY = self.parentView.viceChartRect.origin.y + self.parentView.viceChartRect.size.height * num * 0.5;
        CGContextMoveToPoint(context, PointStartX, PointStartY);
        CGContextAddLineToPoint(context, PointEndX, PointEndY);
    }
    {
        // 主副图分割线
        PointStartX = self.parentView.viceTextRect.origin.x;
        PointEndX = PointStartX + self.parentView.viceTextRect.size.width;
        PointStartY = PointEndY = self.parentView.viceTextRect.origin.y;
        CGContextMoveToPoint(context, PointStartX, PointStartY);
        CGContextAddLineToPoint(context, PointEndX, PointEndY);
    }
    CGContextStrokePath(context);
}

- (void)drawKLine:(CGContextRef)context {
    CGFloat width = self.kLineWidth*3/5;
    CGContextSaveGState(context);
    CGFloat PointStartXOffset = [(YdChartPanelView*)self.superview contentOffset].x;//scroll偏移量
    CGFloat PointStartXOffsetK = fmod(PointStartXOffset, self.kLineWidth);//半根K线
    PointStartXOffset = PointStartXOffset>=0 ? PointStartXOffset-PointStartXOffsetK : 0;//最左边
    CGFloat PointStartX = PointStartXOffset+self.kLineWidth/2;//画线点是蜡烛线中间
    CGFloat zuoshou = 0;
    for (NSInteger i = self.startPos ; i <= self.endPos; ++i, PointStartX += self.kLineWidth) {
        YdKLineStick* stick = (YdKLineStick*)[self.parentView.drawdata objectAtIndex:i];
        CGFloat yHigh = self.parentView.mainYAxis.transform(stick.high);
        CGFloat yLow = self.parentView.mainYAxis.transform(stick.low);
        CGFloat yOpen = self.parentView.mainYAxis.transform(stick.open);
        CGFloat yClose = self.parentView.mainYAxis.transform(stick.close);
        if (i == 0) {
            zuoshou = stick.open;
        } else {
            zuoshou = ((YdKLineStick*)[self.parentView.drawdata objectAtIndex:i-1]).close;
        }
        
        if (stick.open > stick.close) {
            CGContextSetRGBStrokeColor(context, downColor.r(), downColor.g(), downColor.b(), self.alpha);
        } else if (stick.open < stick.close) {
            CGContextSetRGBStrokeColor(context, upColor.r(), upColor.g(), upColor.b(), self.alpha);
        } else {
            if (stick.close < zuoshou) {
                CGContextSetRGBStrokeColor(context, downColor.r(), downColor.g(), downColor.b(), self.alpha);
            } else {
                CGContextSetRGBStrokeColor(context, upColor.r(), upColor.g(), upColor.b(), self.alpha);
            }
        }
        
        CGContextBeginPath(context);
        CGContextSetLineWidth(context, width/6); // 上下阴影线的宽度
        CGContextMoveToPoint(context, PointStartX, yLow);
        CGContextAddLineToPoint(context, PointStartX, yHigh);
        CGContextStrokePath(context);
        
        CGContextBeginPath(context);
        CGContextSetLineWidth(context, width); // 改变线的宽度
        if (yOpen == yClose) {
            yClose += 0.5;
        }
        CGContextMoveToPoint(context, PointStartX, yOpen);
        CGContextAddLineToPoint(context, PointStartX, yClose);
        
        CGContextStrokePath(context);
    }
    CGContextRestoreGState(context);
}

- (void)drawFormula:(CGContextRef)context region:(CGRect)region axisY:(YdYAxis)axisY  formula:(shared_ptr<Formula>)formula {
    CGContextSaveGState(context);
    
    CGContextSetShouldAntialias(context, YES);
    CGContextClipToRect(context, region);
    
    const FormulaResults & results = formula->getResult();
    for(const auto& result : results) {
        if (shared_ptr<FormulaLine> line = result._line) {
            if (line->_nodraw) continue;
            if (line->_type == VOLSTICK) {
                [self drawVolStick:context line:line axisY:axisY];
            } else if (line->_type == COLORSTICK) {
                [self drawColorStick:context line:line axisY:axisY];
            } else if (line->_type == STICK) {
                [self drawStick:context line:line axisY:axisY];
            } else {
                [self drawLine:context line:line axisY:axisY];
            }
        }
        else if (shared_ptr<FormulaDraw> draw = result._draw) {
            if (draw->_type == STICKLINE) {
                [self STICKLINE:context draw:draw axisY:axisY];
            } else if (draw->_type == DRAWTEXT) {
                [self DRAWTEXT:context draw:draw axisY:axisY];
            } else if (draw->_type == DRAWKLINE) {
                [self DRAWKLINE:context draw:draw axisY:axisY];
            } else if (draw->_type == PARTLINE) {
                [self RAINBOWLINE:context draw:draw axisY:axisY];
            } else if (draw->_type == FILLRGN) {
                [self RAINBOW:context draw:draw axisY:axisY];
            } else if (draw->_type == COLORSTICKS) {
                [self drawColorSticks:context draw:draw axisY:axisY];
            } else if (draw->_type == CURVESHADOW) {
                [self drawCurve:context draw:draw axisY:axisY];
            }
        }
    }
    CGContextRestoreGState(context);
}

#pragma mark - 顶底
- (void)drawHighLowMark:(CGContextRef)context {
    CGPoint highPt, lowPt;
    NSInteger highPos = 0, lowPos = 0;
    CGFloat highest = -CGFLOAT_MAX, lowest = CGFLOAT_MAX;
    
    CGFloat PointStartXOffset = [(YdChartPanelView*)self.superview contentOffset].x;//scroll偏移量
    CGFloat PointStartXOffsetK = fmod(PointStartXOffset, self.kLineWidth);//半根K线
    PointStartXOffset = PointStartXOffset>=0 ? PointStartXOffset-PointStartXOffsetK : 0;//最左边
    CGFloat PointStartX = PointStartXOffset+self.kLineWidth/2;//画线点是蜡烛线中间
    for (NSInteger i = self.startPos ; i <= self.endPos; ++i, PointStartX += self.kLineWidth) {
        YdKLineStick* stick = (YdKLineStick*)[self.parentView.drawdata objectAtIndex:i];
        if (stick.high > highest) {
            highest = stick.high;
            highPos = i;
            highPt = CGPointMake(PointStartX, self.parentView.mainYAxis.transform(stick.high));
        }
        if (stick.low < lowest) {
            lowest = stick.low;
            lowPos = i;
            lowPt = CGPointMake(PointStartX, self.parentView.mainYAxis.transform(stick.low));
        }
    }
    
    CGContextSaveGState(context);
    CGContextBeginPath(context);
    CGContextSetShouldAntialias(context, YES);
    
    UIFont *font = [UIFont systemFontOfSize:FONT_SIZE1];
    UIColor *clr = UIColorFromRGB(COLOR_TEXT3);
    NSDictionary *attribute = @{NSFontAttributeName: font,
                                NSForegroundColorAttributeName:clr};
    
    CGContextSetLineWidth(context, 1.0/[UIScreen mainScreen].scale);
    CGContextSetLineCap(context, kCGLineCapSquare);
    
    NSString *highStr = [NSString stringWithFormat:@"%.2f", highest];
    CGSize hiSize = stringSizeWithFont(highStr, font);
    if (highPos < (self.startPos+self.endPos)/2) {
        [self drawLineWithArrow:context x0:highPt.x + 15 y0:highPt.y x1:highPt.x + 3 y1:highPt.y];
        [highStr drawInRect:CGRectMake( highPt.x+20, highPt.y-hiSize.height/2, hiSize.width, hiSize.height) withAttributes: attribute];
    } else {
        [self drawLineWithArrow:context x0:highPt.x - 15 y0:highPt.y x1:highPt.x - 3 y1:highPt.y];
        [highStr drawInRect:CGRectMake( highPt.x-20-hiSize.width, highPt.y-hiSize.height/2, hiSize.width, hiSize.height) withAttributes: attribute];
    }
    
    NSString *lowStr = [NSString stringWithFormat:@"%.2f", lowest];
    CGSize loSize = stringSizeWithFont(lowStr, font);
    if (lowPos < (self.startPos+self.endPos)/2) {
        [self drawLineWithArrow:context x0:lowPt.x + 15 y0:lowPt.y x1:lowPt.x + 3 y1:lowPt.y];
        [lowStr drawInRect:CGRectMake( lowPt.x+20, lowPt.y-loSize.height/2, loSize.width, loSize.height) withAttributes: attribute];
    } else {
        [self drawLineWithArrow:context x0:lowPt.x - 15 y0:lowPt.y x1:lowPt.x - 3 y1:lowPt.y];
        [lowStr drawInRect:CGRectMake( lowPt.x-20-loSize.width, lowPt.y-loSize.height/2, loSize.width, loSize.height) withAttributes: attribute];
    }
    
    CGContextStrokePath(context);
    CGContextRestoreGState(context);
}

- (void)drawLineWithArrow:(CGContextRef)context x0:(CGFloat)x0 y0:(CGFloat)y0 x1:(CGFloat)x1 y1:(CGFloat)y1 {
    static YdColor ydBlack100(COLOR_BLACK100);
    
    CGContextSaveGState(context);
    CGContextSetRGBFillColor(context, ydBlack100.r(), ydBlack100.g(), ydBlack100.b(), 1.0);
    CGContextSetRGBStrokeColor(context, ydBlack100.r(), ydBlack100.g(), ydBlack100.b(), self.alpha);
    
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, x0, y0);
    CGContextAddLineToPoint(context, x1, y1);
    CGContextStrokePath(context);
    
    if (y0 == y1) {
        CGContextBeginPath(context);
        CGContextMoveToPoint(context, x1, y1);
        CGContextAddLineToPoint(context, x0<x1?x1-6:x1+6, y1+3);
        CGContextAddLineToPoint(context, x0<x1?x1-6:x1+6, y1-3);
        CGContextFillPath(context);
    }
    CGContextRestoreGState(context);
}

#pragma mark - 线型
- (void)drawLine:(CGContextRef)context line:(shared_ptr<FormulaLine>)line axisY:(YdYAxis)axisY {
    if (line->_type == POINTDOT) {
        CGFloat lengths[] = {3,7};
        CGContextSetLineDash(context, 0, lengths, 2);
    }
    
    CGContextBeginPath(context);
    
    YdColor clr(line->_color);
    CGContextSetLineWidth(context, (float)line->_thick);
    CGContextSetRGBStrokeColor(context, clr.r(), clr.g(), clr.b(), self.alpha);
    
    BOOL isFirst = YES;
    CGFloat PointStartXOffset = [(YdChartPanelView*)self.superview contentOffset].x;//scroll偏移量
    CGFloat PointStartXOffsetK = fmod(PointStartXOffset, self.kLineWidth);//半根K线
    PointStartXOffset = PointStartXOffset>=0 ? PointStartXOffset-PointStartXOffsetK : 0;//最左边
    CGFloat PointStartX = PointStartXOffset+self.kLineWidth/2;//画线点是蜡烛线中间
    for (NSInteger i = self.startPos; i <= self.endPos; ++i) {
        double y = line->_data[i];
        if (y != invalid_dbl) {
            if (isFirst) {
                isFirst = NO;
                if (!isnan(axisY.transform(y))) {
                    CGContextMoveToPoint(context, PointStartX, axisY.transform(y));
                }
            } else {
                if (!isnan(axisY.transform(y))) {
                    CGContextAddLineToPoint(context, PointStartX, axisY.transform(y));
                }
            }
        } else {
            if (!isFirst ) {
                isFirst = YES;
            }
        }
        PointStartX += self.kLineWidth;
    }
    
    CGContextStrokePath(context);
    
    if (line->_type == POINTDOT) {
        CGContextSetLineDash(context, 0, {}, 0);
    }
}

- (void)drawVolStick:(CGContextRef)context line:(shared_ptr<FormulaLine>)line axisY:(YdYAxis)axisY {
    CGContextSetLineWidth(context, self.kLineWidth*3/5);
    CGFloat PointStartXOffset = [(YdChartPanelView*)self.superview contentOffset].x;//scroll偏移量
    CGFloat PointStartXOffsetK = fmod(PointStartXOffset, self.kLineWidth);//半根K线
    PointStartXOffset = PointStartXOffset>=0 ? PointStartXOffset-PointStartXOffsetK : 0;//最左边
    CGFloat PointStartX = PointStartXOffset+self.kLineWidth/2;//画线点是蜡烛线中间
    for (NSInteger i = self.startPos; i < line->_data.size(); ++i, PointStartX += self.kLineWidth) {
        double y = line->_data[i];
        if (y == invalid_dbl) continue;

        CGContextBeginPath(context);

        YdKLineStick *kline = (YdKLineStick*)[self.parentView.drawdata objectAtIndex:i];

        if (kline.open > kline.close) {
            CGContextSetRGBStrokeColor(context, downColor.r(), downColor.g(), downColor.b(), self.alpha);
        } else {
            CGContextSetRGBStrokeColor(context, upColor.r(), upColor.g(), upColor.b(), self.alpha);
        }
        // 绘制集合竞价成交量
        CGPoint volP1 = CGPointMake(PointStartX, axisY.transform(0));
        CGPoint volP2 = CGPointMake(PointStartX, axisY.transform(y));
        CGContextMoveToPoint(context, volP1.x, volP1.y);
        CGContextAddLineToPoint(context, volP2.x, volP2.y);
        CGContextStrokePath(context);

        // 绘制固定价格成交量
        if (kline.fpVolumn > 0.f) {
            if (kline.open > kline.close) {
                YdColor clr(0x5AA0F0);
                CGContextSetRGBStrokeColor(context, clr.r(), clr.g(), clr.b(), self.alpha);
            } else {
                YdColor clr(0xFFA762);
                CGContextSetRGBStrokeColor(context, clr.r(), clr.g(), clr.b(), self.alpha);
            }
            CGPoint fpVolP1 = CGPointMake(PointStartX, volP2.y);
            CGPoint fpVolP2 = CGPointMake(PointStartX, axisY.transform(kline.fpVolumn+y));
            CGContextMoveToPoint(context, fpVolP1.x, fpVolP1.y);
            CGContextAddLineToPoint(context, fpVolP2.x, fpVolP2.y);
            CGContextStrokePath(context);
        }
    }
}

- (void)drawColorStick:(CGContextRef)context line:(shared_ptr<FormulaLine>)line axisY:(YdYAxis)axisY {
    if (line->_thick == -1) {
        CGContextSetLineWidth(context, self.kLineWidth*3/5);
    } else {
        CGContextSetLineWidth(context, (float)line->_thick/[UIScreen mainScreen].scale);
    }
    
    CGFloat PointStartXOffset = [(YdChartPanelView*)self.superview contentOffset].x;//scroll偏移量
    CGFloat PointStartXOffsetK = fmod(PointStartXOffset, self.kLineWidth);//半根K线
    PointStartXOffset = PointStartXOffset>=0 ? PointStartXOffset-PointStartXOffsetK : 0;//最左边
    CGFloat PointStartX = PointStartXOffset+self.kLineWidth/2;//画线点是蜡烛线中间
    for (NSInteger i = self.startPos; i <= self.endPos; ++i, PointStartX += self.kLineWidth) {
        double y = line->_data[i];
        if (y == invalid_dbl) continue;
//        NSString *name = [NSString stringWithCString:line->_name.c_str() encoding:NSUTF8StringEncoding];
        CGContextBeginPath(context);
        if ( y < 0.0) {
//            if ([name isEqualToString:@"净额"]) {
                YdColor clr(line->_color2);//0x66FFCC
                CGContextSetRGBStrokeColor(context, clr.r(), clr.g(), clr.b(), self.alpha);
//            } else {
//                CGContextSetRGBStrokeColor(context, downColor.r(), downColor.g(), downColor.b(), self.alpha);
//            }
        } else {
//            if ([name isEqualToString:@"净额"]) {
                YdColor clr(line->_color);//0xFF6666
                CGContextSetRGBStrokeColor(context, clr.r(), clr.g(), clr.b(), self.alpha);
//            } else {
//                CGContextSetRGBStrokeColor(context, upColor.r(), upColor.g(), upColor.b(), self.alpha);
//            }
        }
        
        CGContextMoveToPoint(context, PointStartX, axisY.transform(0));
        CGContextAddLineToPoint(context, PointStartX, axisY.transform(y));
        CGContextStrokePath(context);
    }
}

- (void)drawColorSticks:(CGContextRef)context draw:(shared_ptr<FormulaDraw>)draw axisY:(YdYAxis)axisY {
    if (draw->_para1 == -1) {
        CGContextSetLineWidth(context, self.kLineWidth*3/5);
    } else {
        CGContextSetLineWidth(context, (float)draw->_para1/[UIScreen mainScreen].scale);
    }
    
    CGFloat PointStartXOffset = [(YdChartPanelView*)self.superview contentOffset].x;//scroll偏移量
    CGFloat PointStartXOffsetK = fmod(PointStartXOffset, self.kLineWidth);//半根K线
    PointStartXOffset = PointStartXOffset>=0 ? PointStartXOffset-PointStartXOffsetK : 0;//最左边
    CGFloat PointStartX = PointStartXOffset+self.kLineWidth/2;//画线点是蜡烛线中间
    for (NSInteger i = self.startPos; i <= self.endPos; ++i, PointStartX += self.kLineWidth) {
        // _drawPositon1 大单流入 _drawPositon2 大单流出 _drawPositon3 超大单流入 _drawPositon4 超大单流出
        double y1 = draw->_drawPositon1[i], y2 = draw->_drawPositon2[i], y3 = draw->_drawPositon3[i], y4 = draw->_drawPositon4[i];
        if (y3 != invalid_dbl && y1 != invalid_dbl) {
            CGContextBeginPath(context);
            YdColor clr3(draw->_color3);
            CGContextSetRGBStrokeColor(context, clr3.r(), clr3.g(), clr3.b(), self.alpha);
            CGContextMoveToPoint(context, PointStartX, axisY.transform(0));
            CGContextAddLineToPoint(context, PointStartX, axisY.transform(y1+y3));
            CGContextStrokePath(context);
        }
        
        if (y1 != invalid_dbl) {
            CGContextBeginPath(context);
            YdColor clr1(draw->_color);
            CGContextSetRGBStrokeColor(context, clr1.r(), clr1.g(), clr1.b(), self.alpha);
            CGContextMoveToPoint(context, PointStartX, axisY.transform(0));
            CGContextAddLineToPoint(context, PointStartX, axisY.transform(y1));
            CGContextStrokePath(context);
        }

        if (y4 != invalid_dbl && y2 != invalid_dbl) {
            CGContextBeginPath(context);
            YdColor clr4(draw->_color4);
            CGContextSetRGBStrokeColor(context, clr4.r(), clr4.g(), clr4.b(), self.alpha);
            CGContextMoveToPoint(context, PointStartX, axisY.transform(0));
            CGContextAddLineToPoint(context, PointStartX, axisY.transform((y4+y2)*(-1)));
            CGContextStrokePath(context);
        }

        if (y2 != invalid_dbl) {
            CGContextBeginPath(context);
            YdColor clr2(draw->_color2);
            CGContextSetRGBStrokeColor(context, clr2.r(), clr2.g(), clr2.b(), self.alpha);
            CGContextMoveToPoint(context, PointStartX, axisY.transform(0));
            CGContextAddLineToPoint(context, PointStartX, axisY.transform(y2*(-1)));
            CGContextStrokePath(context);
        }
    }
}

- (void)drawStick:(CGContextRef)context line:(shared_ptr<FormulaLine>)line axisY:(YdYAxis)axisY {
    YdColor clr(line->_color);
    CGContextSetRGBStrokeColor(context, clr.r(), clr.g(), clr.b(), self.alpha);
    CGContextSetLineWidth(context, (float)line->_thick);
    CGFloat PointStartX = self.kLineWidth/2;
    for(NSInteger i = self.startPos; i <= self.endPos; ++i, PointStartX += self.kLineWidth) {
        double y = line->_data[i];
        if (y == invalid_dbl) continue;
        
        CGContextBeginPath(context);
        
        double y0 = axisY.transform(0);
        double y1 = axisY.transform(y);
        if (y0 == y1) {
            y1--;
        }
        
        CGContextMoveToPoint(context, PointStartX, y0);
        CGContextAddLineToPoint(context, PointStartX, y1);
        CGContextStrokePath(context);
    }
}

- (void)drawCurve:(CGContextRef)context draw:(shared_ptr<FormulaDraw>)draw axisY:(YdYAxis)axisY {
    //线
    YdColor clr(draw->_color);
    YdColor clr2(draw->_color2);
    YdColor clr3(draw->_color3);

    CGContextSetRGBStrokeColor(context, clr.r(), clr.g(), clr.b(), self.alpha);
    CGContextSetLineWidth(context, 1);
    CGFloat PointStartXOffset = [(YdChartPanelView*)self.superview contentOffset].x;//scroll偏移量
    CGFloat PointStartXOffsetK = fmod(PointStartXOffset, self.kLineWidth);//半根K线
    PointStartXOffset = PointStartXOffset>=0 ? PointStartXOffset-PointStartXOffsetK : 0;//最左边
    CGFloat PointStartX = PointStartXOffset+self.kLineWidth/2;//画线点是蜡烛线中间
//    CGContextBeginPath(context);
//
//    for (NSInteger i = self.startPos; i <= self.endPos; ++i, PointStartX += self.kLineWidth) {
//        double pointY = draw->_drawPositon1[i];
//        if (pointY == invalid_dbl) continue;
//
//        if (i==self.startPos) {
//            CGContextMoveToPoint(context, PointStartX, axisY.transform(pointY));
//        } else {
//            CGContextAddLineToPoint(context, PointStartX, axisY.transform(pointY));
//        }
//    }
//    CGContextStrokePath(context);
    
    //阴影
    CGMutablePathRef path = CGPathCreateMutable();
    CGContextBeginPath(context);
    PointStartX = PointStartXOffset+self.kLineWidth/2;//画线点是蜡烛线中间
    int lastChangePos = 0;
    int curChangePos = 0;

    for (NSInteger i = self.startPos; i <= self.endPos; i++, PointStartX += self.kLineWidth) {
        double pointY = draw->_drawPositon1[i];
        if (pointY == invalid_dbl) continue;
        double pointY1 = axisY.transform(draw->_drawPositon1[i]);

        curChangePos = pointY>0 ? 1 : -1;
        
        if (i == self.startPos) {
            CGPathMoveToPoint(path, nullptr, PointStartX, axisY.transform(0));
            CGPathAddLineToPoint(path, nullptr, PointStartX, pointY1);
        } else if (i == self.endPos) {
            if (curChangePos != lastChangePos) {
                CGPathAddLineToPoint(path, nullptr, PointStartX - self.kLineWidth/2, axisY.transform(0));
                CGContextAddPath(context, path);
                CGPathRelease(path);
                if (lastChangePos>=0) {
                    CGContextSetRGBFillColor(context, clr2.r(), clr2.g(), clr2.b(), self.alpha);
                } else {
                    CGContextSetRGBFillColor(context, clr3.r(), clr3.g(), clr3.b(), self.alpha);
                }
                CGContextFillPath(context);
                CGContextStrokePath(context);
                
                path = CGPathCreateMutable();
                CGPathMoveToPoint(path, nullptr, PointStartX - self.kLineWidth/2, axisY.transform(0));
                CGPathAddLineToPoint(path, nullptr, PointStartX, pointY1);
            }
            CGPathAddLineToPoint(path, nullptr, PointStartX, pointY1);
            CGPathAddLineToPoint(path, nullptr, PointStartX, axisY.transform(0));
            CGContextAddPath(context, path);
            if (curChangePos>=0) {
                CGContextSetRGBFillColor(context, clr2.r(), clr2.g(), clr2.b(), self.alpha);
            } else {
                CGContextSetRGBFillColor(context, clr3.r(), clr3.g(), clr3.b(), self.alpha);
            }
            CGContextFillPath(context);
            CGContextStrokePath(context);

        } else {
            if (curChangePos == lastChangePos) {
                CGPathAddLineToPoint(path, nullptr, PointStartX, pointY1);
            } else {
                CGPathAddLineToPoint(path, nullptr, PointStartX - self.kLineWidth/2, axisY.transform(0));
                CGContextAddPath(context, path);
                CGPathRelease(path);
                if (lastChangePos>=0) {
                    CGContextSetRGBFillColor(context, clr2.r(), clr2.g(), clr2.b(), self.alpha);
                } else {
                    CGContextSetRGBFillColor(context, clr3.r(), clr3.g(), clr3.b(), self.alpha);
                }
                CGContextFillPath(context);
                CGContextStrokePath(context);
                
                path = CGPathCreateMutable();
                CGPathMoveToPoint(path, nullptr, PointStartX - self.kLineWidth/2, axisY.transform(0));
                CGPathAddLineToPoint(path, nullptr, PointStartX, pointY1);
            }
        }
        lastChangePos = curChangePos;
    }
}

#pragma mark - 绘图函数
- (void)RAINBOW:(CGContextRef)context draw:(shared_ptr<FormulaDraw>)draw axisY:(YdYAxis)axisY {
    YdColor clr(draw->_color);
    CGContextSetRGBFillColor(context, clr.r(), clr.g(), clr.b(), self.alpha);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGFloat PointStartX = self.kLineWidth/2;
    for (NSInteger i = self.startPos; i <= self.endPos; i++, PointStartX += self.kLineWidth) {
        double mark = draw->_drawPositon1[i];
        
        if (mark >= 1 && i > 0) {
            if (draw->_drawPositon2[i] == invalid_dbl || draw->_drawPositon3[i] == invalid_dbl) continue;
            if (draw->_drawPositon2[i-1] == invalid_dbl || draw->_drawPositon3[i-1] == invalid_dbl) continue;
            
            double pointY1 = axisY.transform(draw->_drawPositon2[i]);
            double pointY2 = axisY.transform(draw->_drawPositon2[i-1]);
            
            double pointY3 = axisY.transform(draw->_drawPositon3[i-1]);
            double pointY4 = axisY.transform(draw->_drawPositon3[i]);
            
            if (pointY1 == pointY4) {
                pointY4++;
            }
            if (pointY2 == pointY3) {
                pointY3++;
            }
            CGPathMoveToPoint(path, nullptr, PointStartX, pointY1);
            CGPathAddLineToPoint(path, nullptr, PointStartX - self.kLineWidth, pointY2);
            CGPathAddLineToPoint(path, nullptr, PointStartX - self.kLineWidth, pointY3);
            CGPathAddLineToPoint(path, nullptr, PointStartX, pointY4);
            CGPathAddLineToPoint(path, nullptr, PointStartX, pointY1);
            CGContextBeginPath(context);
            CGContextAddPath(context, path);
            CGContextFillPath(context);
        }
    }
}

- (void)RAINBOWLINE:(CGContextRef)context draw:(shared_ptr<FormulaDraw>)draw axisY:(YdYAxis)axisY {
    YdColor clr(draw->_color);
    CGContextSetRGBStrokeColor(context, clr.r(), clr.g(), clr.b(), self.alpha);
    CGContextSetLineWidth(context, (float)draw->_para1 * self.kLineWidth / 10.0);
    CGFloat PointStartX = self.kLineWidth/2;
    for (NSInteger i = self.startPos; i <= self.endPos; i++, PointStartX += self.kLineWidth) {
        double y = draw->_drawPositon1[i];
        if (draw->_drawPositon2[i] == invalid_dbl) continue;
        if (draw->_drawPositon2[i-1] == invalid_dbl) continue;
        if (y >=1 && i > 0) {
            double y0 = axisY.transform(draw->_drawPositon2[i]);
            double y3 = axisY.transform(draw->_drawPositon2[i -1]);
            
            CGContextBeginPath(context);
            CGContextMoveToPoint(context, PointStartX, y0);
            CGContextAddLineToPoint(context, PointStartX -self.kLineWidth, y3);
            CGContextStrokePath(context);
        }
    }
}

- (void)DRAWTEXT:(CGContextRef)context draw:(shared_ptr<FormulaDraw>)draw axisY:(YdYAxis)axisY {
    YdColor clr(draw->_color);
    UIFont  *font = [UIFont boldSystemFontOfSize:9.0];
    NSDictionary *attr = @{ NSFontAttributeName:font,
                            NSForegroundColorAttributeName:[UIColor colorWithRed:clr.r() green:clr.g() blue:clr.b() alpha:self.alpha]};
    NSString *strText = [NSString stringWithUTF8String:draw->_text.c_str()];
    
    CGFloat PointStartXOffset = [(YdChartPanelView*)self.superview contentOffset].x;//scroll偏移量
    CGFloat PointStartXOffsetK = fmod(PointStartXOffset, self.kLineWidth);//半根K线
    PointStartXOffset = PointStartXOffset>=0 ? PointStartXOffset-PointStartXOffsetK : 0;//最左边
    CGFloat PointStartX = PointStartXOffset+self.kLineWidth/2;//画线点是蜡烛线中间
    for (NSInteger i = self.startPos; i <= self.endPos; ++i, PointStartX += self.kLineWidth) {
        double y = draw->_drawPositon1[i];
        if (y == invalid_dbl || y == 0) continue;
        
        double y0 = axisY.transform(draw->_drawPositon2[i]);
        double x0 = PointStartX - 4.5;  // 对准K线中间
        
//        if([strText hasPrefix:@"1"]) {
//            ;
//        }
        
        [strText drawAtPoint:CGPointMake(x0 , y0) withAttributes:attr];
    }
}

- (void)STICKLINE:(CGContextRef)context draw:(shared_ptr<FormulaDraw>)draw axisY:(YdYAxis)axisY {
    YdColor clr(draw->_color);
    CGContextSetRGBStrokeColor(context, clr.r(), clr.g(), clr.b(), self.alpha);
    
    double lineW = (float)draw->_para1 * self.kLineWidth /10.0;
    if (lineW < 0) {
        lineW = self.kLineWidth*3/5;
    }
    CGFloat PointStartXOffset = [(YdChartPanelView*)self.superview contentOffset].x;//scroll偏移量
    CGFloat PointStartXOffsetK = fmod(PointStartXOffset, self.kLineWidth);//半根K线
    PointStartXOffset = PointStartXOffset>=0 ? PointStartXOffset-PointStartXOffsetK : 0;//最左边
    CGFloat PointStartX = PointStartXOffset+self.kLineWidth/2;//画线点是蜡烛线中间
    if (draw->_para1 == -2) {
        lineW += self.kLineWidth/2;
    }
    CGContextSetLineWidth(context, lineW);
    for (NSInteger i = self.startPos; i <= self.endPos; ++i, PointStartX += self.kLineWidth) {
        double y = draw->_drawPositon1[i];
        if (y == invalid_dbl || y == 0) continue;
        if( draw->_drawPositon2[i] == invalid_dbl || draw->_drawPositon3[i] == invalid_dbl) continue;
        
        double y0 = axisY.transform(draw->_drawPositon2[i]);
        double y1 = axisY.transform(draw->_drawPositon3[i]);
        
        if (y0 == y1) {
            y1++;
        }
        
        CGContextBeginPath(context);
        if (!isnan(y0)) {
            CGContextMoveToPoint(context, PointStartX, y0);
            CGContextAddLineToPoint(context, PointStartX, y1);
        }
        CGContextStrokePath(context);
    }
}

- (void)DRAWKLINE:(CGContextRef)context draw:(shared_ptr<FormulaDraw>)draw axisY:(YdYAxis)axisY {
    CGFloat width = self.kLineWidth*3/5;
    CGFloat PointStartX = self.kLineWidth/2;
    for (NSInteger i = self.startPos; i <= self.endPos; ++i, PointStartX += self.kLineWidth) {
        
        CGFloat yHigh = self.parentView.mainYAxis.transform(draw->_drawPositon1[i]);
        CGFloat yOpen = self.parentView.mainYAxis.transform(draw->_drawPositon2[i]);
        CGFloat yLow = self.parentView.mainYAxis.transform(draw->_drawPositon3[i]);
        CGFloat yClose = self.parentView.mainYAxis.transform(draw->_drawPositon4[i]);
        
        if (draw->_drawPositon2[i] >= draw->_drawPositon4[i]) {
            CGContextSetRGBStrokeColor(context, downColor.r(), downColor.g(), downColor.b(), self.alpha);
        } else {
            CGContextSetRGBStrokeColor(context, upColor.r(), upColor.g(), upColor.b(), self.alpha);
        }
        
        CGContextBeginPath(context);
        CGContextSetLineWidth(context, width/6); // 上下阴影线的宽度
        CGContextMoveToPoint(context, PointStartX, yLow);
        CGContextAddLineToPoint(context, PointStartX, yHigh);
        CGContextStrokePath(context);
        
        CGContextBeginPath(context);
        CGContextSetLineWidth(context, width); // 改变线的宽度
        if (yOpen == yClose) {
            yClose += 0.5;
        }
        CGContextMoveToPoint(context, PointStartX, yOpen);
        CGContextAddLineToPoint(context, PointStartX, yClose);
        
        CGContextStrokePath(context);
    }
}

@end
