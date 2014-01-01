//
//  simpleClasses.h
//  HelloCpp
//
//  Created by ck02-084 on 13-12-4.
//
//

#ifndef __HelloCpp__simpleClasses__
#define __HelloCpp__simpleClasses__

#include <iostream>
class CIDTriangle final
{
public:
    short vID[3];
    CIDTriangle(){}
    ~CIDTriangle(){}
    CIDTriangle(short ID0,short ID1,short ID2){
        setvID(ID0, ID1, ID2);
    }
    void setvID(short ID0,short ID1,short ID2){
        vID[0]=ID0;
        vID[1]=ID1;
        vID[2]=ID2;
    }
    
    
};
class CIDLine final
{
public:
    short vID[2];
    CIDLine(){}
    ~CIDLine(){}
    CIDLine(short ID0,short ID1){
        setvID(ID0, ID1);
    }
    void setvID(short ID0,short ID1){
        vID[0]=ID0;
        vID[1]=ID1;
    }
    
};
class Cv2 final
{
public:
    float v[2];
    Cv2(){}
    Cv2(float _x,float _y){
        init(_x, _y);
    }
    ~Cv2(){};
    void init(float _x,float _y){
        v[0]=_x;
        v[1]=_y;
    }
    
};
#endif /* defined(__HelloCpp__simpleClasses__) */
