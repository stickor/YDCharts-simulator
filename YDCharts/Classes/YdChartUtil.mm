//
//  YdChartUtil.m
//  DzhChart
//
//  Created by apple on 2016/11/2.
//  Copyright © 2016年 dzh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YdChartUtil.h"
#include <map>

UIColor* UIColorFromRGB(unsigned rgbValue){
    return [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0
                           green:((float)((rgbValue & 0xFF00) >> 8))/255.0
                            blue:((float)(rgbValue & 0xFF))/255.0
                           alpha:(1.0 - ((rgbValue & 0xFF000000)>>24)/255.0)];
}

NSString* formatNumber(double num) {
    BOOL isNegative = num < 0;
    num = fabs(num);
    NSString *unit = @"";
    if(num>10000*10000){
        num = num/(10000*10000);
        unit = @"亿";
    }else if(num>10000){
        num = num/(10000);
        unit = @"万";
    }else{
        unit = @"";
    }
    // 对num取整
    double i = round(num);
    // 若取整后的数与原数相等，则说明原数小数点后均为0
    if (i == num) {
        return isNegative ? [NSString stringWithFormat:@"-%.0f%@",num, unit] : [NSString stringWithFormat:@"%.0f%@",num, unit];
    } else {
        return isNegative ? [NSString stringWithFormat:@"-%.2f%@",num, unit] : [NSString stringWithFormat:@"%.2f%@",num, unit];
    }
}

CGSize stringSizeWithFont(NSString* str, UIFont* font)
{
    NSDictionary *attribute = @{NSFontAttributeName: font};
    CGSize textSize = [str boundingRectWithSize:CGSizeMake(CGFLOAT_MAX,0)
                                                  options: NSStringDrawingTruncatesLastVisibleLine |
                                                           NSStringDrawingUsesLineFragmentOrigin |
                                                           NSStringDrawingUsesFontLeading
                                               attributes:attribute
                                                  context:nil].size;
    return textSize;
}


std::map<CGFloat, CGFloat> dictFontSize;

CGFloat SystemFontHeight(CGFloat fontSize){

    auto iter = dictFontSize.find(fontSize);
    if(  iter != dictFontSize.end() ){
        return iter->second;
    }
    else{
        UIFont* font = [UIFont systemFontOfSize:fontSize];
        NSDictionary *attribute = @{NSFontAttributeName: font};
        CGSize textSize = [@"X" boundingRectWithSize:CGSizeMake(CGFLOAT_MAX,0)
                                            options: NSStringDrawingTruncatesLastVisibleLine |
                           NSStringDrawingUsesLineFragmentOrigin |
                           NSStringDrawingUsesFontLeading
                                         attributes:attribute
                                            context:nil].size;
        dictFontSize[fontSize] = textSize.height;
        return textSize.height;
    }

}


CGFloat adjustWidth(NSString* text, UIFont* font) {
    CGSize size = CGSizeMake(1000,font.pointSize);
    NSDictionary *attributes = @{NSFontAttributeName: font};
    CGSize labelSize = [text boundingRectWithSize:size options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:attributes context:nil].size;
    CGFloat width = labelSize.width;
    return width;
}

//code -> symbol
NSString* code2symbol(NSString * code) {
    NSString * symbole = code.length>=8 ? [code substringFromIndex:2] : code;
    return  symbole;
}
