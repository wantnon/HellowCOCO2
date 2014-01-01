//
//  HelloWorldScene.h
//  mybox2dtest
//
//  Created by apple on 13-7-4.
//  Copyright __MyCompanyName__ 2013��. All rights reserved.
//
#ifndef __HELLO_WORLD_H__
#define __HELLO_WORLD_H__

// When you import this file, you import all the cocos2d classes
#include "cocos2d.h"
#include "Box2D.h"
#include "myObj.h"
#include "mouse.h"
#include "cocos-ext.h"
#include "myContactListener.h"
#include "inputSignal.h"
#include "player.h"

using namespace cocos2d;

class HelloWorld : public CCLayer {
public:
    // Here's a difference. Method 'init' in cocos2d-x returns bool, instead of returning 'id' in cocos2d-iphone
    virtual bool init();  

    // there's no 'id' in cpp, so we recommend returning the class instance pointer
	// returns a Scene that contains the HelloWorld as the only child
    static CCScene* scene();

    // a selector callback
    void menuCloseCallback(CCObject* pSender);

    // implement the "static node()" method manually
    CREATE_FUNC(HelloWorld);
public:
	//����
    b2World* world;
	CmyContactListener myContactListener;
	CinputSignal inputSignal;
public:
    Cplayer*pPlayer;
    float m_waterSurfaceHeight;//ˮ��߶�
public:
    //ģ����Ϣģ��
    CmyObjInfo objInfo_shotBall_right;
    CmyObjInfo objInfo_shotBall_left;
public:
    cocos2d::extension::CCControlButton* m_controlButton_weixinShare;
    cocos2d::extension::CCControlButton* m_controlButton_shotScreen;
    cocos2d::extension::CCControlButton* m_controlButton_rightKey;
    cocos2d::extension::CCControlButton* m_controlButton_leftKey;
    cocos2d::extension::CCControlButton* m_controlButton_jumpKey;
    cocos2d::extension::CCControlButton* m_controlButton_shotKey;
public:
    
    CCSprite*m_screenShotSprite;
public:
	HelloWorld(){
		m_waterSurfaceHeight=0;
        m_screenShotSprite=NULL;
        m_controlButton_weixinShare=NULL;
        m_controlButton_shotScreen=NULL;
        m_controlButton_rightKey=NULL;
        m_controlButton_leftKey=NULL;
        m_controlButton_shotKey=NULL;
        m_controlButton_jumpKey=NULL;
        
	};
	~HelloWorld();
public:
    virtual void visit(void);
    virtual void update(float dt);
public:
	//----touch
 //   virtual void ccTouchesBegan(cocos2d::CCSet* touches , cocos2d::CCEvent* event);
 //   virtual void ccTouchesMoved(cocos2d::CCSet* touches , cocos2d::CCEvent* event);
 //   virtual void ccTouchesEnded(cocos2d::CCSet* touches , cocos2d::CCEvent* event);
	//----key
	//rightKey
    void rightKeyDown(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent);
    void rightKeyUpInside(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent);
    void rightKeyDragExit(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent);
    void rightKeyDragEnter(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent);
    //leftKey
    void leftKeyDown(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent);
    void leftKeyUpInside(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent);
    void leftKeyDragExit(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent);
    void leftKeyDragEnter(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent);
    //jumpKey
    void jumpKeyDown(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent);
    //shotKey
    void shotKeyDown(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent);
    //weixin share
    void weixinShare(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent);
    //shot screen
    void shotScreen(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent);


  };

#endif // __HELLO_WORLD_H__
