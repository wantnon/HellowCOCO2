//
//  myfunc.cpp
//  mybox2dtest
//
//  Created by apple on 13-8-1.
//
//

#include "myfunc.h"
string toString(const char* cstr){
    if(cstr==NULL)return string();//如果cstr为NULL，则返回空string
    string str=cstr;
    return str;
}
vector<float> strToValueList(const string&_str)
//从string中提取数值
//如果string中存在数字、点号、负号或空格之外的字符，则返回列表为empty
//如果_str为空或只有空格，则返回列表为empty
{
    const vector<float> emptyValueList;
    if(_str.empty())return emptyValueList;
    //将str后面补充一个空格，以便最后一个数值能提取出来
    string str=_str+" ";
    vector<float> valueList;//数值列表
    string tstr;//用于提取单个数值的字串
    int len=(int)str.size();
    for(int i=0;i<len;i++){
        bool isNumberOrDotOrSpace=((str[i]>='0'&&str[i]<='9')||str[i]=='.'||str[i]=='-'||str[i]==' '||str[i]=='('||str[i]==')'||str[i]==',');//是数字，点号，负号，空格，括号，逗号
        if(isNumberOrDotOrSpace==false){
            cout<<"warning:不是数字，点号，负号，空格，括号，逗号!"<<endl;
            return emptyValueList;//如果不可能是数值字符串，则返回空数值列表
        }
        if(str[i]!=' '&&str[i]!=','&&str[i]!=')'&&str[i]!='('){//如果不是空格，逗号，括号
            //加入到tstr
            tstr+=str[i];
        }else{//如果是空格，逗号，括号
            if(tstr.empty()){//如果tstr为空
                //无动作
            }else{//如果tstr非空
                //tstr提取完成
                //将tstr转化成数值并添加到valueList
                float value=atof(tstr.c_str());
                valueList.push_back(value);
                //将tstr清空，以便提取下一个数值的字串
                tstr.clear();
            }
        }
    }//得到valueList
    return valueList;

}

