//
//  YdChartUtil.h
//  DzhChart
//
//  Created by apple on 16/9/14.
//  Copyright © 2016年 dzh. All rights reserved.
//

#ifndef YdChartUtil_h
#define YdChartUtil_h

#import <UIKit/UIKit.h>


class YdYAxis
{
public:
    void setScale(float lowerScale, float upperScale){
        _minScale = lowerScale; _maxScale = upperScale;
    };
    void setBound(float lowerBound, float upperBound){
        _minBound = lowerBound, _maxBound = upperBound;
    };
    float transform(float value){
        if( _maxScale == _minScale ) {
            return _minBound;
        }else{
            float  retTransform = _minBound + (value-_minScale)/(_maxScale-_minScale)*(_maxBound-_minBound);
            return retTransform<0?0:retTransform;
        }
    };
    float restore(float value) {
        return _minScale + (_minBound - value) * (_maxScale - _minScale) / (_minBound - _maxBound);
    };
    float minScale(){ return _minScale; };
    float maxScale(){ return _maxScale; };
    float minBound(){ return _minBound; };
    float maxBound(){ return _maxBound; };
private:
    float _minScale, _maxScale;
    float _minBound, _maxBound;
};

class YdColor
{
public:
    YdColor():_color(0){};
    YdColor(unsigned int clr):_color(clr){};
    YdColor(unsigned char r, unsigned char g, unsigned char b){
        _color =  (((unsigned)r) << 16) ;
        _color |= (((unsigned)g) << 8) ;
        _color |= ((unsigned)b);
    }
    void setColor(unsigned clr){ _color = clr;};
    float a(){ return 1-((_color >> 24) & 0xFF) / 255.0; } ;
    float r(){ return ((_color >> 16) & 0xFF) / 255.0; } ;
    float g(){ return ((_color >>  8) & 0xFF) / 255.0; } ;
    float b(){ return (_color & 0xFF) / 255.0; } ;
    void parse(NSString* color){
        NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
        
        if ([cString length] < 6) {
            return;
        }
        
        if ([cString hasPrefix:@"0X"])
            cString = [cString substringFromIndex:2];
        if ([cString hasPrefix:@"#"])
            cString = [cString substringFromIndex:1];
        if ([cString length] != 6)
            NSLog(@"color Length not 6");
        //        return [UIColor clearColor];
        
        [[NSScanner scannerWithString:cString] scanHexInt:&_color];
    };
    
    UIColor* toUIColor(){
        return [UIColor colorWithRed:r()
                               green:g()
                                blue:b()
                               alpha:a()];
    }

private:
    unsigned _color;
};

UIColor* UIColorFromRGB(unsigned rgbValue);
NSString* formatNumber(double num);
CGSize stringSizeWithFont(NSString* str, UIFont* font);
CGFloat SystemFontHeight(CGFloat fontSize);
CGFloat adjustWidth(NSString* text, UIFont* font);
NSString* code2symbol(NSString * code);
#endif /* YdChartUtil_h */
