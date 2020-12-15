//
//  UIDefine.h
//  DzhChart
//
//  Created by apple on 16/10/13.
//  Copyright © 2016年 dzh. All rights reserved.
//

#ifndef UIDefine_h
#define UIDefine_h

#import <UIKit/UIKit.h>

// 颜色
#define RGB(r, g, b) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:1]
#define RGBA(r, g, b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

#define RGB16(rgbValue) \
[UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0x0000FF))/255.0 \
alpha:1.0]

#define RGBA16(rgbValue,a) \
[UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0x00FF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0x0000FF))/255.0 \
alpha:a]

const unsigned int COLOR_LINE       = 0x2289E7; //分时线颜色
const unsigned int COLOR_AVG_LINE   = 0xFF842B; //均线颜色
const unsigned int COLOR_SHADOW     = 0x332289E7; //分时图阴影
//#define kColorChartAircraft                         RGB16(0x4b93f3).CGColor         //移动点(飞行器)
//#define kColorChartAircraftWave                     RGBA16(0x4b93f3,.5).CGColor     //移动点水波

const unsigned int COLOR_UP         = 0xFF4141; //上涨颜色
const unsigned int COLOR_DOWN       = 0x379637; //下跌颜色
const unsigned int COLOR_TEXT1      = 0x444444; //正文文本
const unsigned int COLOR_TEXT2      = 0x666666; //次要文本
const unsigned int COLOR_TEXT3      = 0x4C262628; //辅助性文本
const unsigned int COLOR_SEPERATOR  = 0xF1F1F1; //分割线文本
const unsigned int COLOR_BACKGROUND = 0xFFFFFF; //背景色
const unsigned int COLOR_UP2        = 0xFF6666; //指标公式上涨颜色_主力资金、主力动态、资金雷达
const unsigned int COLOR_DOWN2      = 0x66FFCC; //指标公式下跌颜色

const unsigned int COLOR_BLACK100   = 0x2262628;

const unsigned int COLOR_ORANGE     = 0xFF9933; // 科创板用的颜色，分时图盘后成交量，k线盘后成交量
const unsigned int COLOR_ORANGE_LINE = 0xFFCC33; // 科创板用的颜色，分时图盘中与盘后的分界线
const int axisLableMargin = 0;

#define RATE(x) ([UIScreen mainScreen].bounds.size.width*x)/750
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width

const CGFloat FONT_SIZE1 = RATE(20);
const CGFloat FONT_SIZE2 = RATE(18);

//k线的缩放根数按照斐波那契数列进行缩放   [5, 8, 13, 21, 34, 55, 89, 144, 233, 250];
#define SHOW_KLINE_COUNT        34      //默认显示的K线数
#define SHOW_KLINE_MAX_COUNT    144     //最多显示的K线数
#define SHOW_KLINE_MIN_COUNT    21      //最少显示的K线数

//十字线 浮层 价格提示
#define CROSS_TIP_FONT_SIZE     10

#define WS(weakSelf) __weak __typeof(self) weakSelf = self  //__typeof 用于C++


#endif /* UIDefine_h */
