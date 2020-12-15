//
//  YDFormulaBase.hpp
//  DzhChart
//
//  Created by apple on 16/5/19.
//  Copyright © 2016年 dzh. All rights reserved.
//

#ifndef YDFormulaBase_hpp
#define YDFormulaBase_hpp

#include <stdio.h>
#include <vector>
#include <string>
#include <limits>
#include <memory>
#include <algorithm>

using namespace std;

const int invalid_int = INT_MAX;
const double invalid_dbl = std::numeric_limits<double>::lowest() ;

const int COLORWHITE = 0xFFFFFF;
const int COLORYELLOW = 0xFFFF00;
const int COLORRED = 0xFFFF0000;
const int COLORGREEN = 0xFF00FF00;
const int COLORBLUE = 0x0000FF;
const int COLORMAGENTA = 0xFF00FF;
const int COLORGRAY = 0x888888;
const int COLORBLACK = 0xFF000000;
const int COLORCYAN = 0x00FFFF;
const int COLORGOLD = 0xFFD700;
const int COLORROYALBLUE = 0x4169E1;
const int COLORBROWN = 0xA52A2A;

const int COLOR01 = 0x1F76E1;
const int COLOR02 = 0xFF8D1D;
const int COLOR03 = 0xFF35FF;
const int COLOR04 = 0x26AF73;
const int COLOR05 = 0x0064FF;
const int COLOR06 = 0x009900;
const int COLOR07 = 0xFF8181;
const int COLOR08 = 0x81FF81;
const int COLOR09 = 0x2DC8FF;
const int COLOR10 = 0x800080;

#pragma mark 公式运行环境
struct KLineStick
{
    time_t time;//日期
    time_t datetime;//日期时间
    double open;
    double high;
    double low;
    double close;
    double volume;
    double amount;
};

struct FundFlowStick
{
    double littleIn;
    double littleOut;
    double mediumIn;
    double mediumOut;
    double hugeIn;
    double hugeOut;
    double largeIn;
    double largeOut;
    double superIn;
    double superOut;
    double total;
};

struct MinStick
{
    time_t time;
    double price;
    double avgprice;
    double volume;
    double amount;
};

struct MinOtherData
{
    double preClose;
    double circulateEquityA;
};

typedef struct ExRight{
    time_t lastUpdateTime;    //最后更新时间
    std::string stockCode;         //股票代码
    std::string subType;           //'A':A股、'B'：B股
    time_t exright_date;      //除权日期
    double alloc_interest;    //分红派息（每股）
    double give;              //送股（每股）
    double extend;            //转增股（每股）
    double match;             //配股（每股）
    double match_price;       //配股价
} ExRight_t;

typedef enum {
    NONE,
    FORMER,
    LATTER,
}SplitT;

typedef enum {
    ONEMIN,
    FIVEMIN,
    FIFTEENMIN,
    THIRTYMIN,
    SIXTYMIN,
    DAY,
    WEEK,
    MONTH,
}PeriodT;


class FormulaEnvironment
{
public:
    FormulaEnvironment(){};
    void setSticks(const vector<KLineStick>& sticks){this->_sticks = sticks;};
    void setFundFlowSticks(const vector<FundFlowStick>& sticks){this->_sticksFundFlow = sticks;};
    void setSticks(const vector<MinStick>& sticks){this->_sticksMin = sticks;};
    void setOtherData(const MinOtherData& minOtherData){this->_minOtherData = minOtherData;};
    
protected:
    vector<KLineStick> _sticks;
    vector<FundFlowStick> _sticksFundFlow;
    vector<MinStick> _sticksMin;
    MinOtherData _minOtherData;
    vector<int>  _parameters;
};


#pragma mark 公式运行结果
typedef enum {
    STICKLINE,
    DRAWTEXT,
    PARTLINE,
    FILLRGN,
    DRAWKLINE,
    DRAWNUMBER,
    COLORSTICKS,
    CURVESHADOW

}FormulaDrawType;

struct FormulaDraw
{
    string          _name;
    FormulaDrawType	_type;
    
    vector<double>	_drawPositon1;
    vector<double>	_drawPositon2;
    vector<double>	_drawPositon3;
    vector<double>	_drawPositon4;
    
    double		_para1;
    double		_para2;

    string      _text;
    
    int         _color;
    int         _color2;
    int         _color3;
    int         _color4;
};

typedef enum {
    LINE,
    COLORSTICK,
    VOLSTICK,
    STICK,
    POINTDOT,
    AREA
}FormulaLineType;


struct FormulaLine
{
    string              _name;
    vector<double>      _data;
    
    FormulaLineType     _type;
    double              _thick;
    int                 _color;
    int                 _color2;
    bool                _nodraw;
    FormulaLine()
    {
        _type = LINE;
        _thick = 1.0;
        _color = 0x000000;
        _nodraw = false;
    }
};

struct FormulaResult
{
    shared_ptr<FormulaLine>     _line;
    shared_ptr<FormulaDraw>     _draw;
    
    FormulaResult(){
        
    }
    explicit FormulaResult(shared_ptr<FormulaLine> line){
        _line = line;
    }
    explicit FormulaResult(shared_ptr<FormulaDraw> draw){
        _draw = draw;
    }
};

class FormulaResults : public vector<FormulaResult>
{
public:
//    double max_value_from_postion(size_t pos) const{
//        double max = numeric_limits<double>::lowest();
//        for(auto iter = begin(); iter != end(); ++iter)
//        {
//            if( iter->_line ){
//                for_each(iter->_line->_data.begin()+pos, iter->_line->_data.end(), [&max](double value){
//                    if( value != invalid_dbl && max < value ) max = value;
//                });
//            }
//        }
//        return max;
//    };
//    double min_value_from_position(size_t pos) const{
//        double min = numeric_limits<double>::max();
//        for(auto iter = begin();  iter != end(); ++iter)
//        {
//            if( iter->_line  && iter->_line->_type == VOLSTICK){
//                if( min > 0.0 ) {min = 0.0;}
//            }else if( iter->_line ){
//                for_each(iter->_line->_data.begin()+pos, iter->_line->_data.end(), [&min](double value){
//                    if( value != invalid_dbl && min > value ) {min = value;}
//                });
//            }
//        }
//        return min;
//    };
    
    void min_max_in_range(size_t _start, size_t _end, double& rMax, double& rMin) const{
        double max = numeric_limits<double>::lowest();
        double min = numeric_limits<double>::max();
        for(auto iter = begin(); iter != end(); ++iter)
        {
            if( auto line = iter->_line ){
                for_each(line->_data.begin()+_start, line->_data.begin()+_end+1, [&max,&min](double value){
                    if( value != invalid_dbl && max < value )
                        max = value;
                    if( value != invalid_dbl && min > value )
                        min = value;
                });
                
                if(line->_type == VOLSTICK && min > 0.0){
                    min = 0.0;
                }
            }
            else if( auto draw = iter->_draw){
                if( draw->_type == STICKLINE){
                    for(size_t i = _start ; i <= _end; ++i){
                        if( draw->_drawPositon1[i] == 1.0 )
                        {
                            if( draw->_drawPositon2[i] > max )  max = draw->_drawPositon2[i];
                            if( draw->_drawPositon2[i] < min )  min = draw->_drawPositon2[i];
                            if( draw->_drawPositon3[i] > max )  max = draw->_drawPositon3[i];
                            if( draw->_drawPositon3[i] < min )  min = draw->_drawPositon3[i];
                        }
                    }
                }else if( draw->_type == DRAWTEXT){
                    for(size_t i = _start ; i <= _end; ++i){
                        if( draw->_drawPositon1[i] == 1.0)
                        {
                            if( draw->_drawPositon2[i] > max )  max = draw->_drawPositon2[i];
                            if( draw->_drawPositon2[i] < min )  min = draw->_drawPositon2[i];
                        }
                    }
                }else if( draw->_type == DRAWKLINE){
                    for(size_t i = _start ; i <= _end; ++i){
                        if( draw->_drawPositon1[i] > max )  max = draw->_drawPositon1[i];
                        if( draw->_drawPositon1[i] < min )  min = draw->_drawPositon1[i];
                        if( draw->_drawPositon3[i] > max )  max = draw->_drawPositon3[i];
                        if( draw->_drawPositon3[i] < min )  min = draw->_drawPositon3[i];
                    }
                }else if ( draw->_type == COLORSTICKS){
                    for(size_t i = _start ; i <= _end; ++i){
                        if( draw->_drawPositon1[i] > max )  max = draw->_drawPositon1[i];
                        if( draw->_drawPositon1[i] < min )  min = draw->_drawPositon1[i];
//                        if( draw->_drawPositon2[i] > max )  max = draw->_drawPositon2[i];
//                        if( draw->_drawPositon2[i] < min )  min = draw->_drawPositon2[i];
                        if( -draw->_drawPositon2[i] > max )  max = -draw->_drawPositon2[i];
                        if( -draw->_drawPositon2[i] < min )  min = -draw->_drawPositon2[i];
                        if( draw->_drawPositon3[i] > max )  max = draw->_drawPositon3[i];
                        if( draw->_drawPositon3[i] < min )  min = draw->_drawPositon3[i];
//                        if( draw->_drawPositon4[i] > max )  max = draw->_drawPositon4[i];
//                        if( draw->_drawPositon4[i] < min )  min = draw->_drawPositon4[i];
                        if( -draw->_drawPositon4[i] > max )  max = -draw->_drawPositon4[i];
                        if( -draw->_drawPositon4[i] < min )  min = -draw->_drawPositon4[i];
                    }
                }else if ( draw->_type == CURVESHADOW){
                    for(size_t i = _start ; i <= _end; ++i){
                        if( draw->_drawPositon1[i] > max )  max = draw->_drawPositon1[i];
                        if( draw->_drawPositon1[i] < min && draw->_drawPositon1[i] != invalid_dbl )  min = draw->_drawPositon1[i];
                    }
                }
            }
            
            rMax = max;
            rMin = min;
        }
    }
    
    void min_max_from_position(size_t pos, double& rMax, double& rMin) const{
        return min_max_in_range(pos, this->size()-1, rMax, rMin);
    }

    vector<time_t> _vTime;
};


#pragma mark 公式基类
class Formula : public FormulaEnvironment
{
public:
    Formula(){};
    virtual ~Formula(){};
    
    virtual const FormulaResults& run() = 0;
    const FormulaResults& getResult(){ return _result;};

protected:
    const FormulaResult addFormulaDraw(FormulaDrawType  _type,
                                       vector<double>	_drawPositon1,
                                       vector<double>	_drawPositon2,
                                       vector<double>	_drawPositon3,
                                       double		_para1,
                                       double		_para2,
                                       int          _color) {

        shared_ptr<FormulaDraw> D1 = make_shared<FormulaDraw>();

        D1->_type  = _type;
        D1->_color = _color;
        D1->_drawPositon1 = _drawPositon1;
        D1->_drawPositon2 = _drawPositon2;
        D1->_drawPositon3 = _drawPositon3;
        D1->_para1 = _para1;
        D1->_para2 = _para2;
        return FormulaResult(D1);
    }

    const FormulaResult addFormulaDraw(FormulaDrawType  _type,
                                       vector<double>	_drawPositon1,
                                       vector<double>	_drawPositon2,
                                       vector<double>	_drawPositon3,
                                       int          _color) {

        shared_ptr<FormulaDraw> D1 = make_shared<FormulaDraw>();

        D1->_type  = _type;
        D1->_color = _color;
        D1->_drawPositon1 = _drawPositon1;
        D1->_drawPositon2 = _drawPositon2;
        D1->_drawPositon3 = _drawPositon3;
        return FormulaResult(D1);
    }

    const FormulaResult addFormulaDraw(FormulaDrawType  _type,
                                       vector<double>	_drawPositon1,
                                       vector<double>	_drawPositon2,
                                       vector<double>	_drawPositon3,
                                       double		_para1,
                                       int          _color) {

        shared_ptr<FormulaDraw> D1 = make_shared<FormulaDraw>();

        D1->_type  = _type;
        D1->_color = _color;
        D1->_drawPositon1 = _drawPositon1;
        D1->_drawPositon2 = _drawPositon2;
        D1->_drawPositon3 = _drawPositon3;
        D1->_para1 = _para1;
        return FormulaResult(D1);
    }

    const FormulaResult addFormulaDraw(FormulaDrawType  _type,
                                       vector<double>	_drawPositon1,
                                       vector<double>	_drawPositon2,
                                       double		_para1,
                                       int          _color) {

        shared_ptr<FormulaDraw> D1 = make_shared<FormulaDraw>();

        D1->_type  = _type;
        D1->_color = _color;
        D1->_drawPositon1 = _drawPositon1;
        D1->_drawPositon2 = _drawPositon2;
        D1->_para1 = _para1;
        return FormulaResult(D1);
    }

    const FormulaResult addFormulaDraw(FormulaDrawType  _type,
                                       vector<double>	_drawPositon1) {

        shared_ptr<FormulaDraw> D1 = make_shared<FormulaDraw>();

        D1->_type  = _type;
        D1->_drawPositon1 = _drawPositon1;
        return FormulaResult(D1);
    }

    const FormulaResult addFormulaDraw(FormulaDrawType  _type,
                                       string           _name,
                                       vector<double>	_drawPositon1,
                                       vector<double>	_drawPositon2,
                                       vector<double>	_drawPositon3,
                                       vector<double>	_drawPositon4,
                                       double		_para1,
                                       int          _color,
                                       int          _color2,
                                       int          _color3,
                                       int          _color4) {

        shared_ptr<FormulaDraw> D1 = make_shared<FormulaDraw>();

        D1->_type  = _type;
        D1->_name  = _name;
        D1->_color = _color;
        D1->_color2 = _color2;
        D1->_color3 = _color3;
        D1->_color4 = _color4;
        D1->_drawPositon1 = _drawPositon1;
        D1->_drawPositon2 = _drawPositon2;
        D1->_drawPositon3 = _drawPositon3;
        D1->_drawPositon4 = _drawPositon4;
        D1->_para1 = _para1;
        return FormulaResult(D1);
    }


    
protected:
    FormulaResults _result;
};

#pragma mark 公式管理器
class FormulaManager
{
public:
    static shared_ptr<Formula> getFormula(string formulaName);
};

#pragma mark 除复权
class SplitManager
{
public:
    static void getSplit(const std::vector<KLineStick> source, std::vector<ExRight> exrights, int split, int period, std::vector<KLineStick>& des);
};

#endif /* YDFormulaBase_hpp */
