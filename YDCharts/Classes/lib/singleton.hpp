#pragma once

#ifndef WHG_SINGLETON
#define WHG_SINGLETON

#include <mutex>

using namespace std;

template<typename T>
class singleton{
protected:
	static T* ins_;
	static std::mutex ins_mtx_;
public:
	static T* ins(){
		if( !ins_ ){
			std::lock_guard<std::mutex> lock(ins_mtx_);
			if( !ins_ ){
				ins_ = new T();
			}
		}
		return ins_;
	};
};

template<typename T>  T*  singleton<T>::ins_;
template<typename T>  std::mutex  singleton<T>::ins_mtx_;

#endif /* WHG_SINGLETON */