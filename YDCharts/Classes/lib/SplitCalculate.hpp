#pragma once
//#include "static_offer/ExRightManager.h"
//#include "data_define.pb.h"
//#include "util/singleton.h"
//#include "util/stl.h"

#include "YDFormulaBase.hpp"
#include "singleton.hpp"



//using namespace yuanda;
//using namespace std;

class CSplitCalculate:public singleton<CSplitCalculate>
{
public:
	CSplitCalculate();
	virtual ~CSplitCalculate();

	// 重新计算除复权数据,返回新的成功除复权日期map 与除复权数据
//	void calcSplitData(const std::vector<KLineStick>& source, SplitT split, std::map<std::string, int>& mSucceedSplitDate, std::vector<KLineStick>& des);
	// 重新计算除复权数据, 除复权数据
	void calcSplitData(const std::vector<KLineStick> source, std::vector<ExRight> exrights, SplitT split, PeriodT period, std::vector<KLineStick>& des);

private:
	/// 重新计算前复权历史数据的方法
	/// param vExRight 除复权信息数据
	/// param noneCandleStick 不复权历史数据
	/// formerStick 前复权历史数据
	std::vector<KLineStick> reCalcHisFormerData(const vector<ExRight_t>& , const std::vector<KLineStick>&);
	/// 重新计算后复权历史数据的方法
	/// param vExRight 除复权信息数据
	/// param noneCandleStick 不复权历史数据
	/// latterStick 后复权历史数据
	std::vector<KLineStick> reCalcHisLatterData(const vector<ExRight_t>& , const std::vector<KLineStick>& );
	/// 前复权计算公式
    /// 前复权：复权后价格＝[(复权前价格-现金红利)＋配(新)股价格×流通股份变动比例]÷(1＋流通股份变动比例)
    /// 流通股份变动比例=送股（每股）+ 转增股（每股）+ 配股（每股）;
	double calcFormerData(const double& price, const ExRight_t& exRight);
	/// 后复权计算公式
    /// 后复权：复权后价格＝复权前价格×(1＋流通股份变动比例)-配(新)股价格×流通股份变动比例＋现金红利
    /// 流通股份变动比例=送股（每股）+ 转增股（每股）+ 配股（每股）;
	double calcLatterData(const double& price, const ExRight_t& exRight);
};

