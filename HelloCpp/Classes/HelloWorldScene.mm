//
//  HelloWorldScene.cpp
//  mybox2dtest
//
//  Created by apple on 13-7-4.
//  Copyright __MyCompanyName__ 2013年. All rights reserved.
//
#include <vector>
#include <string>

#include "HelloWorldScene.h"
#include "AppMacros.h"

#include "SimpleAudioEngine.h"
#include "CCControlButton.h"
#include "myContactListener.h"
#include "myDef.h"
#include "player.h"
#include "myBox2dFunc.h"
#include "tinyxml2.h"
#include "myfunc.h"
#include "thingManager.h"
#include "tiledSceneLoader.h"
#import "WXApiObject.h"
#import "WXApi.h"

using namespace cocos2d;
using namespace CocosDenshion;
using namespace tinyxml2;
using namespace std;




Cmouse mos;



// on "init" you need to initialize your instance
bool HelloWorld::init()
{
    //////////////////////////////
    // 1. super init first
    if ( !CCLayer::init() )
    {
        return false;
    }
    
    CCSize visibleSize = CCDirector::sharedDirector()->getVisibleSize();
    CCPoint origin = CCDirector::sharedDirector()->getVisibleOrigin();

    CCSize winSize = CCDirector::sharedDirector()->getWinSize();
    /////////////////////////////
    // 2. add a menu item with "X" image, which is clicked to quit the program
    //    you may modify it.

    // add a "close" icon to exit the progress. it's an autorelease object
    CCMenuItemImage *pCloseItem = CCMenuItemImage::create(
                                        "CloseNormal.png",
                                        "CloseSelected.png",
                                        this,
                                        menu_selector(HelloWorld::menuCloseCallback));
    
	pCloseItem->setPosition(ccp(origin.x + visibleSize.width - pCloseItem->getContentSize().width/2 ,
                                origin.y + pCloseItem->getContentSize().height/2));

    // create menu, it's an autorelease object
    CCMenu* pMenu = CCMenu::create(pCloseItem, NULL);
    pMenu->setPosition(CCPointZero);
    this->addChild(pMenu, 1);

    /////////////////////////////
    // 3. add your codes below...
    //set projection to 2D (default is 3D). if use 3D projection, may cause tiny projection error, in some situation, if the error accumulated across frames, may cause effect wrong.
    CCDirector::sharedDirector()->setProjection(kCCDirectorProjection2D);
    setTouchEnabled( true );
    setAccelerometerEnabled( true );
	//CCDirector::sharedDirector()->setDepthTest(true);//没必要开启深度测试
	// glClearColor(0, 0, 1, 1);
    CCDirector::sharedDirector()->setDisplayStats(false);//不显示帧率等信息


    //----创建物理world
    b2Vec2 gravity;
    gravity.Set(0.0f, -10.0f);
    world = new b2World(gravity);
    world->SetAllowSleeping(true); // Do we want to let bodies sleep?
    world->SetContinuousPhysics(true);
    world->SetContactListener(&myContactListener);
	//----创建卷动场景node
	CCNode *node_rolling=CCNode::create();
	addChild(node_rolling,0,tag_root_scene_rolling);
	
    //----创建无卷动场景node
    CCNode *node_nonRolling= CCNode::create();
    addChild(node_nonRolling,-10,tag_root_scene_nonRolling);
    //----创建UI node
    CCNode*node_ui=CCNode::create();
    addChild(node_ui,0,tag_root_ui);
	//----根据tiled map创建场景
	CtiledSceneLoader tiledSceneLoader;
	CCNode*tiledSceneRootNode=tiledSceneLoader.loadScene("data/levels/level1/scene/map/map.tmx",world);
	node_rolling->addChild(tiledSceneRootNode);
    //----根据xml创建对象
    {
        //场景
        {
            vector<CmyObj*> objList=CmyObj::createObjsWithXML("data/levels/level1/scene/objGroup.xml",world);
            int nObj=(int)objList.size();
            //加入到场景树
            for(int i=0;i<nObj;i++){
                CmyObj*obj=objList[i];
                if(obj->sceneNodeType=="scene_rolling"){
                    node_rolling->addChild(obj);
                }else if(obj->sceneNodeType=="scene_nonRolling"){
                    node_nonRolling->addChild(obj);
                }else if(obj->sceneNodeType=="ui"){
                    node_ui->addChild(obj);
                }else{
                    cout<<"error:未知类型!"<<endl;
                    exit(0);
                }
            }
        }
        //子弹模板(向右)
        {
            string fullPath = CCFileUtils::sharedFileUtils()->fullPathForFilename("data/global/objs/shotBall_right_template/objGroup.xml");
            tinyxml2::XMLDocument doc;
            doc.LoadFile(fullPath.c_str());
            XMLElement *root=doc.RootElement();
            CmyObjGroupInfo objInfoList;
            objInfoList.initWithXMLElement(root);
            if((int)objInfoList.myObjInfoList.size()!=1){
                cout<<"error:obj个数不等于1!"<<endl;
                exit(0);
            }
            this->objInfo_shotBall_right=objInfoList.myObjInfoList[0];
        }
        //子弹模板(向左)
        {
            string fullPath = CCFileUtils::sharedFileUtils()->fullPathForFilename("data/global/objs/shotBall_left_template/objGroup.xml");
            tinyxml2::XMLDocument doc;
            doc.LoadFile(fullPath.c_str());
            XMLElement *root=doc.RootElement();
            CmyObjGroupInfo objInfoList;
            objInfoList.initWithXMLElement(root);
            if((int)objInfoList.myObjInfoList.size()!=1){
                cout<<"error:obj个数不等于1!"<<endl;
                exit(0);
            }
            this->objInfo_shotBall_left=objInfoList.myObjInfoList[0];
        }


    }
    //----创建player
    //创建myObj
    const float rx=64;
    const float ry=64;
    CCPoint p(300, 300+300);
    pPlayer = Cplayer::create(world);
	this->getChildByTag(tag_root_scene_rolling)->addChild(pPlayer,100);
    pPlayer->set_showSprite(true);
	pPlayer->set_showb2Body(showb2BodyWireFrame);

	pPlayer->tex_still_right=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/stand_right.png");
    pPlayer->tex_still_left=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/stand_left.png");
    pPlayer->tex_jump_still_right=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/jump_right.png");
    pPlayer->tex_jump_still_left=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/jump_left.png");
    pPlayer->tex_jump_forward_right=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/jump_right.png");
    pPlayer->tex_jump_forward_left=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/jump_left.png");
    pPlayer->tex_swim_still_right=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/stand_right.png");
    pPlayer->tex_swim_still_left=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/stand_left.png");
    pPlayer->tex_forward_right_first=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/run_right_first.png");
    pPlayer->tex_forward_left_first=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/run_left_first.png");
    pPlayer->initWithTexture(pPlayer->tex_still_right, CCRectMake( 0,0,2*rx,2*ry));


    b2Filter filter;
    filter.categoryBits=0x0004;//必须只有一个二进制位为1
    filter.maskBits=0xFFFF & ~0x0008;
    pPlayer->create_pb2Body(world,rx/PTM_RATIO,ry/PTM_RATIO,&filter);
 
	

    //设定位置
    pPlayer->setPosition( CCPointMake( p.x, p.y) );
    pPlayer->pb2Body->SetTransform(b2Vec2(p.x/PTM_RATIO, p.y/PTM_RATIO), 0);
    pPlayer->pb2Body->SetType(b2_dynamicBody);
    pPlayer->pb2Body->SetFixedRotation(true);
    pPlayer->setTag(tag_player);
    //tex
    pPlayer->tex_shotBall_left=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/shotBall.png");
    pPlayer->tex_shotBall_right=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/shotBall.png");
    //----定义控件
    //--label
    CCLabelTTF *label = CCLabelTTF::create("Hellow COCO -- demo 2.0 -- by wantnon (2013-10-6)", "Helvetica", 32);
    addChild(label, 0);
    label->setColor(ccc3(0,0,255));
    label->setPosition(ccp( winSize.width/2, winSize.height-50));
    //--按钮left
    {
        cocos2d::extension::CCScale9Sprite* btnUp=cocos2d::extension::CCScale9Sprite::create("data/global/tex/button.png");
        cocos2d::extension::CCScale9Sprite* btnDn=cocos2d::extension::CCScale9Sprite::create("data/global/tex/button_dn.png");
        CCLabelTTF*title=CCLabelTTF::create("<--", "Helvetica", 30);
        cocos2d::extension::CCControlButton* controlButton=cocos2d::extension::CCControlButton::create(title, btnUp);
        controlButton->setBackgroundSpriteForState(btnDn,cocos2d::extension::CCControlStateHighlighted);
        controlButton->setPreferredSize(CCSize(100,100));
        controlButton->setPosition(ccp(120+100,60));
        controlButton->addTargetWithActionForControlEvents(this, (cocos2d::extension::SEL_CCControlHandler)(&HelloWorld::leftKeyDown), cocos2d::extension::CCControlEventTouchDown);
        controlButton->addTargetWithActionForControlEvents(this, (cocos2d::extension::SEL_CCControlHandler)(&HelloWorld::leftKeyUpInside), cocos2d::extension::CCControlEventTouchUpInside);
        controlButton->addTargetWithActionForControlEvents(this, (cocos2d::extension::SEL_CCControlHandler)(&HelloWorld::leftKeyDragEnter), cocos2d::extension::CCControlEventTouchDragEnter);
        controlButton->addTargetWithActionForControlEvents(this, (cocos2d::extension::SEL_CCControlHandler)(&HelloWorld::leftKeyDragExit), cocos2d::extension::CCControlEventTouchDragExit);
        this->getChildByTag(tag_root_ui)->addChild(controlButton);
        m_controlButton_leftKey=controlButton;
    }
    //--按钮right
    {
        cocos2d::extension::CCScale9Sprite* btnUp=cocos2d::extension::CCScale9Sprite::create("data/global/tex/button.png");
        cocos2d::extension::CCScale9Sprite* btnDn=cocos2d::extension::CCScale9Sprite::create("data/global/tex/button_dn.png");
        CCLabelTTF*title=CCLabelTTF::create("-->", "Helvetica", 30);
        cocos2d::extension::CCControlButton* controlButton=cocos2d::extension::CCControlButton::create(title, btnUp);
        controlButton->setBackgroundSpriteForState(btnDn,cocos2d::extension::CCControlStateHighlighted);
        controlButton->setPreferredSize(CCSize(100,100));
        controlButton->setPosition(ccp(300+100,60));
        controlButton->addTargetWithActionForControlEvents(this, (cocos2d::extension::SEL_CCControlHandler)(&HelloWorld::rightKeyDown), cocos2d::extension::CCControlEventTouchDown);
        controlButton->addTargetWithActionForControlEvents(this, (cocos2d::extension::SEL_CCControlHandler)(&HelloWorld::rightKeyUpInside), cocos2d::extension::CCControlEventTouchUpInside);
        controlButton->addTargetWithActionForControlEvents(this, (cocos2d::extension::SEL_CCControlHandler)(&HelloWorld::rightKeyDragEnter), cocos2d::extension::CCControlEventTouchDragEnter);
        controlButton->addTargetWithActionForControlEvents(this, (cocos2d::extension::SEL_CCControlHandler)(&HelloWorld::rightKeyDragExit), cocos2d::extension::CCControlEventTouchDragExit);
        this->getChildByTag(tag_root_ui)->addChild(controlButton);
        m_controlButton_rightKey=controlButton;
    }
    //--按钮jump
    {
        cocos2d::extension::CCScale9Sprite* btnUp=cocos2d::extension::CCScale9Sprite::create("data/global/tex/button.png");
        cocos2d::extension::CCScale9Sprite* btnDn=cocos2d::extension::CCScale9Sprite::create("data/global/tex/button_dn.png");
        CCLabelTTF*title=CCLabelTTF::create("jump", "Helvetica", 30);
        cocos2d::extension::CCControlButton* controlButton=cocos2d::extension::CCControlButton::create(title, btnUp);
        controlButton->setBackgroundSpriteForState(btnDn,cocos2d::extension::CCControlStateHighlighted);
        controlButton->setPreferredSize(CCSize(100,100));
        controlButton->setPosition(ccp(850,60));
        controlButton->addTargetWithActionForControlEvents(this, (cocos2d::extension::SEL_CCControlHandler)(&HelloWorld::jumpKeyDown), cocos2d::extension::CCControlEventTouchDown);
       
        this->getChildByTag(tag_root_ui)->addChild(controlButton);
        m_controlButton_jumpKey=controlButton;
    }
    //--按钮shot
    {
        cocos2d::extension::CCScale9Sprite* btnUp=cocos2d::extension::CCScale9Sprite::create("data/global/tex/button.png");
        cocos2d::extension::CCScale9Sprite* btnDn=cocos2d::extension::CCScale9Sprite::create("data/global/tex/button_dn.png");
        CCLabelTTF*title=CCLabelTTF::create("shot", "Helvetica", 30);
        cocos2d::extension::CCControlButton* controlButton=cocos2d::extension::CCControlButton::create(title, btnUp);
        controlButton->setBackgroundSpriteForState(btnDn,cocos2d::extension::CCControlStateHighlighted);
        controlButton->setPreferredSize(CCSize(100,100));
        controlButton->setPosition(ccp(850,200));
        controlButton->addTargetWithActionForControlEvents(this, (cocos2d::extension::SEL_CCControlHandler)(&HelloWorld::shotKeyDown), cocos2d::extension::CCControlEventTouchDown);
        
        this->getChildByTag(tag_root_ui)->addChild(controlButton);
        m_controlButton_shotKey=controlButton;
    }
    //--weixin share
    {
        cocos2d::extension::CCScale9Sprite* btnUp=cocos2d::extension::CCScale9Sprite::create("data/global/tex/button.png");
        cocos2d::extension::CCScale9Sprite* btnDn=cocos2d::extension::CCScale9Sprite::create("data/global/tex/button_dn.png");
        CCLabelTTF*title=CCLabelTTF::create("share", "Helvetica", 30);
        cocos2d::extension::CCControlButton* controlButton=cocos2d::extension::CCControlButton::create(title, btnUp);
        controlButton->setBackgroundSpriteForState(btnDn,cocos2d::extension::CCControlStateHighlighted);
        controlButton->setPreferredSize(CCSize(100,100));
        controlButton->setPosition(ccp(200,500));
        controlButton->addTargetWithActionForControlEvents(this, (cocos2d::extension::SEL_CCControlHandler)(&HelloWorld::weixinShare), cocos2d::extension::CCControlEventTouchDown);
        
        this->getChildByTag(tag_root_ui)->addChild(controlButton);
        controlButton->setVisible(false);
        m_controlButton_weixinShare=controlButton;
    }
    //--shot screen
    {
        cocos2d::extension::CCScale9Sprite* btnUp=cocos2d::extension::CCScale9Sprite::create("data/global/tex/button.png");
        cocos2d::extension::CCScale9Sprite* btnDn=cocos2d::extension::CCScale9Sprite::create("data/global/tex/button_dn.png");
        CCLabelTTF*title=CCLabelTTF::create("shot screen", "Helvetica", 30);
        cocos2d::extension::CCControlButton* controlButton=cocos2d::extension::CCControlButton::create(title, btnUp);
        controlButton->setBackgroundSpriteForState(btnDn,cocos2d::extension::CCControlStateHighlighted);
        controlButton->setPreferredSize(CCSize(100,100));
        controlButton->setPosition(ccp(500,500));
        controlButton->addTargetWithActionForControlEvents(this, (cocos2d::extension::SEL_CCControlHandler)(&HelloWorld::shotScreen), cocos2d::extension::CCControlEventTouchDown);
        
        this->getChildByTag(tag_root_ui)->addChild(controlButton);
        controlButton->setVisible(true);
        m_controlButton_shotScreen=controlButton;
    }

	/*
    //----定义悬挂点
    const float32 y = 640.0/PTM_RATIO;//15.0f;
    const float32 x= 1136.0/PTM_RATIO;
    //创建myObj 
    CmyObj *pinnerObj=NULL;
    
    {
        // Define the  body.
        b2BodyDef BodyDef;
        BodyDef.position.Set(x/2, y/2); // bottom-left corner
        
        BodyDef.type = b2_staticBody;
        
        // Call the body factory which allocates memory for the ground body
        // from a pool and creates the ground box shape (also from a pool).
        // The body is also added to the world.
        b2Body* Body = world->CreateBody(&BodyDef);
        
        
        const float w=0.5;
        const float h=0.5;
        
        b2PolygonShape gBox;
        gBox.SetAsBox(w,h);//These are mid points for our 1m box
        
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &gBox;
        fixtureDef.density =10.0f;
        fixtureDef.friction = 0.3f;
        Body->CreateFixture(&fixtureDef);
        
        //创建绘图节点
        CCNode* node = getChildByTag(tag_root_scene_rolling);
        pinnerObj= CmyObj::create(world);
        CCTexture2D*texture=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/hungPoint.png");
        pinnerObj->initWithTexture(texture, CCRectMake( 0,0,w*2*PTM_RATIO,h*2*PTM_RATIO));
        pinnerObj->set_quadTexCoords(ccp(0,0), ccp(1,0),
                                  ccp(0,1), ccp(1,1));
        
        pinnerObj->pb2Body=Body;
        pinnerObj->pb2Body->SetUserData(pinnerObj);
        node->addChild(pinnerObj);
        
    }

    //----定义绳子
    b2RopeJointDef m_ropeDef;
    b2Joint* m_rope;
    {
        const float halfSegLen=0.5f;
        const float halfSegThick=0.25f;//0.125f;
        const float halfBoxW=1.5f;
        const float halfBoxH=1.5f;
        
        b2PolygonShape shape;
        shape.SetAsBox(halfSegLen, halfSegThick);//一节绳子
        
        b2FixtureDef fd;
        fd.shape = &shape;
        fd.density = 40.0f;//各节绳子质量不能太小，否则容易被打散
        fd.friction = 0;//0.2f;
    //    fd.filter.categoryBits = 0x0001;
     //   fd.filter.maskBits = 0xFFFF & ~0x0002;//唯独不与0x0002碰撞
        
        b2RevoluteJointDef jd;
        jd.collideConnected = false;
        
        const int32 N = 10;

        m_ropeDef.localAnchorA.Set(0,0);//(x/2,y/2);//(0.0f, y);
        
        vector<float> halfWList;
        vector<float> halfHList;
        for(int i=0;i<N;i++){
            if(i==N-1){
                halfWList.push_back(halfBoxW);
                halfHList.push_back(halfBoxH);
            }else{
                halfWList.push_back(halfSegLen);
                halfHList.push_back(halfSegThick);
            }
        }
        
        b2Body* prevBody = pinnerObj->pb2Body;
        for (int32 i = 0; i < N; ++i)
        {
            b2BodyDef bd;
            bd.type = b2_dynamicBody;
            bd.position.Set(x/2+0.5f + 1.0f * i, y/2);
            if (i == N - 1)
            {
                shape.SetAsBox(1.5f, 1.5f);
                fd.density = 6.0f;
                fd.friction=0.8;
            //    fd.filter.categoryBits = 0x0002;
            //    fd.filter.maskBits = 0xFFFF;
                bd.position.Set(x/2+1.0f * i+1.5f, y/2);
                bd.angularDamping = 0.4f;//角衰减，防止转动过快
            }

            
            b2Body* body = world->CreateBody(&bd);
            
            body->CreateFixture(&fd);
            
            b2Vec2 anchor(x/2+float32(i), y/2);
            jd.Initialize(prevBody, body, anchor);
            world->CreateJoint(&jd);
            
            prevBody = body;
            //创建绘图节点
            CCNode* node = getChildByTag(tag_root_scene_rolling);
            //创建myObj
            CmyObj *sprite = CmyObj::create(world);
            CCTexture2D*_texture=NULL;
            if(i==N-1){
                CCTexture2D*texture=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/stone.png");
                _texture=texture;
            }else{
                CCTexture2D*texture=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/ropeSeg.png");
                _texture=texture;
            }
            sprite->initWithTexture(_texture,CCRect(0,0,halfWList[i]*2*PTM_RATIO,halfHList[i]*2*PTM_RATIO));
            sprite->set_quadTexCoords(ccp(0,0), ccp(1,0),
                                      ccp(0,1), ccp(1,1));

            sprite->pb2Body=body;
            sprite->pb2Body->SetUserData(sprite);
            node->addChild(sprite);
        }
        
        m_ropeDef.localAnchorB.SetZero();
        m_ropeDef.collideConnected=true;//让悬点与摆锤碰撞（默认是不碰撞的）
        float32 extraLength = 0.01f;//此有何用
        m_ropeDef.maxLength = N - 1.0f + extraLength;
        m_ropeDef.bodyB = prevBody;
    }
    
    {
        m_ropeDef.bodyA = pinnerObj->pb2Body;
        m_rope = world->CreateJoint(&m_ropeDef);
    }*/
    //----开始更新
    scheduleUpdate();

    
    return true;
}

void HelloWorld::menuCloseCallback(CCObject* pSender)
{
#if (CC_TARGET_PLATFORM == CC_PLATFORM_WINRT) || (CC_TARGET_PLATFORM == CC_PLATFORM_WP8)
	CCMessageBox("You pressed the close button. Windows Store Apps do not implement a close button.","Alert");
#else
    CCDirector::sharedDirector()->end();
#if (CC_TARGET_PLATFORM == CC_PLATFORM_IOS)
    exit(0);
#endif
#endif
}

HelloWorld::~HelloWorld()
{
	//先清楚场景，再释放box2d的world，原因是场景中的某些节点的析构函数中引用了world，如果先清除world，会导致这部分场景节点析构时出错
	this->removeAllChildrenWithCleanup(true);
    delete world;
    world = NULL;
    
}

void HelloWorld::weixinShare(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent){
    /*   cout<<"hi"<<endl;
     SendMessageToWXReq* req = [[[SendMessageToWXReq alloc] init]autorelease];
     req.text = @"let's play hellow COCO!";
     req.bText = YES;
     req.scene = WXSceneSession;//_scene;
     
     [WXApi sendReq:req];*/
    
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = @"hellow COCO";
    message.description = @"see my screenshot!";
   // [message setThumbImage:[UIImage imageNamed:@"iphone/weixin_share_image.png"]];
    string fileName="myScreenShot.png";
    string fullpath = CCFileUtils::sharedFileUtils()->getWritablePath() + fileName;
    NSString *fullpath_NS=[NSString stringWithUTF8String:fullpath.c_str()];
    [message setThumbImage:[UIImage imageNamed:fullpath_NS]];
    
    WXWebpageObject *ext = [WXWebpageObject object];
    ext.webpageUrl = @"http://user.qzone.qq.com/350479720/blog/1375017261";
    
    message.mediaObject = ext;
    
    SendMessageToWXReq* req = [[[SendMessageToWXReq alloc] init]autorelease];
    req.bText = NO;
    req.message = message;
    req.scene = WXSceneSession;//_scene;
    
    [WXApi sendReq:req];
    
    
    
}

void HelloWorld::shotScreen(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent){
   // cout<<"hi"<<endl;
    
    //mask visit to render to texture
    CCSize winSize = CCDirector::sharedDirector()->getWinSize();
    
    //set all button invisible
    m_controlButton_weixinShare->setVisible(false);
    m_controlButton_shotScreen->setVisible(false);
    m_controlButton_jumpKey->setVisible(false);
    m_controlButton_leftKey->setVisible(false);
    m_controlButton_rightKey->setVisible(false);
    m_controlButton_shotKey->setVisible(false);
    
    
    // create a render texture, this is what we are going to draw into
    CCRenderTexture* renderTarget = CCRenderTexture::create(winSize.width, winSize.height, kCCTexture2DPixelFormat_RGBA8888);
    renderTarget->retain();
    renderTarget->setPosition(ccp(winSize.width / 2, winSize.height / 2));
    
    // begin drawing to the render texture
    renderTarget->begin();
    
    this->visit();
    
    // finish drawing and return context back to the screen
    renderTarget->end();
    
    
    string fileName="myScreenShot.png";
    bool succ=renderTarget->saveToFile(fileName.c_str(), kCCImageFormatPNG);
    
    cout<<"succ:"<<succ<<endl;
    string fullpath = CCFileUtils::sharedFileUtils()->getWritablePath() + fileName;
    cout<<"full path:"<<fullpath<<endl;
    if(m_screenShotSprite==NULL){
        m_screenShotSprite=CCSprite::create();
        this->addChild(m_screenShotSprite,0);
    }
    m_screenShotSprite->setVisible(true);
    m_screenShotSprite->initWithFile(fullpath.c_str());
    m_screenShotSprite->setScale(0.5);
    m_screenShotSprite->setPosition(ccp(winSize.width/2,winSize.height/2));
    //set game scene invisible
    this->getChildByTag(tag_root_scene_rolling)->setVisible(false);
    this->getChildByTag(tag_root_scene_nonRolling)->setVisible(false);
    //set weixin share button visible
    m_controlButton_weixinShare->setVisible(true);
    
}

void HelloWorld::rightKeyDown(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent){
    inputSignal.rightKeyDown=true;
    if(pPlayer->is_jump()){
        pPlayer->update_state(player_state_jump_forward_right);
    }else if(pPlayer->is_forward()||pPlayer->is_still()){
        pPlayer->update_state(player_state_forward_right);
    }else if(pPlayer->is_swim()){
        pPlayer->update_state(player_state_swim_forward_right);
    }
    //----动画（animation只能现用现创建，且runAction一次后不能再次使用）
    pPlayer->stopAllActions();
    CCAnimation*animation_runRight=CCAnimation::create();
    CCTexture2D*texture_run;
    int nFrame;
    if(pPlayer->state==player_state_swim_forward_right){
        texture_run=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/player_swim_right.png");
        nFrame=4;
    }else{
        texture_run=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/player_run_right.png");
        nFrame=6;
    }
    for(int i=0;i<nFrame;i++){
        animation_runRight->addSpriteFrameWithTexture(texture_run, CCRect(i*128,0,128,128));
    }
    animation_runRight->setDelayPerUnit(0.13f);
    animation_runRight->setRestoreOriginalFrame(true);
    CCAnimate* animate_runRight=CCAnimate::create(animation_runRight);
    CCRepeatForever*repeatForever=CCRepeatForever::create(animate_runRight);
    pPlayer->runAction(repeatForever);

}

void HelloWorld::rightKeyUpInside(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent){
    b2Vec2 v=pPlayer->pb2Body->GetLinearVelocity();
    pPlayer->pb2Body->SetLinearVelocity(b2Vec2(0,v.y));
    inputSignal.rightKeyDown=false;
    if(pPlayer->is_jump()){
        pPlayer->update_state(player_state_jump_still_right);
    }else if(pPlayer->is_forward()||pPlayer->is_still()){
        pPlayer->update_state(player_state_still_right);
    }else if(pPlayer->is_swim()){
        pPlayer->update_state(player_state_swim_still_right);
    }
    //---停止动画
    pPlayer->stopAllActions();
    //重设贴图
    pPlayer->setTexture(pPlayer->tex_still_right);
    pPlayer->set_quadTexCoords(ccp(0,0), ccp(1,0), ccp(0,1), ccp(1,1));

}
void HelloWorld::rightKeyDragExit(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent){
    b2Vec2 v=pPlayer->pb2Body->GetLinearVelocity();
    pPlayer->pb2Body->SetLinearVelocity(b2Vec2(0,v.y));
    inputSignal.rightKeyDown=false;
    if(pPlayer->is_jump()){
        pPlayer->update_state(player_state_jump_still_right);
    }else if(pPlayer->is_forward()||pPlayer->is_still()){
        pPlayer->update_state(player_state_still_right);
    }else if(pPlayer->is_swim()){
        pPlayer->update_state(player_state_swim_still_right);
    }
    //---停止动画
    pPlayer->stopAllActions();
    //重设贴图
    pPlayer->setTexture(pPlayer->tex_still_right);
    pPlayer->set_quadTexCoords(ccp(0,0), ccp(1,0), ccp(0,1), ccp(1,1));

}
void HelloWorld::rightKeyDragEnter(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent){
    inputSignal.rightKeyDown=true;
    if(pPlayer->is_jump()){
        pPlayer->update_state(player_state_jump_forward_right);
    }else if(pPlayer->is_forward()||pPlayer->is_still()){
        pPlayer->update_state(player_state_forward_right);
    }else if(pPlayer->is_swim()){
        pPlayer->update_state(player_state_swim_forward_right);
    }
    //----动画（animation只能现用现创建，且runAction一次后不能再次使用）
        pPlayer->stopAllActions();
    CCAnimation*animation_runRight=CCAnimation::create();
    CCTexture2D*texture_run;
    int nFrame;
    if(pPlayer->state==player_state_swim_forward_right){
        texture_run=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/player_swim_right.png");
        nFrame=4;
    }else{
        texture_run=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/player_run_right.png");
        nFrame=6;
    }

    for(int i=0;i<nFrame;i++){
        animation_runRight->addSpriteFrameWithTexture(texture_run, CCRect(i*128,0,128,128));
    }
    animation_runRight->setDelayPerUnit(0.13f);
    animation_runRight->setRestoreOriginalFrame(true);
    CCAnimate* animate_runRight=CCAnimate::create(animation_runRight);
    CCRepeatForever*repeatForever=CCRepeatForever::create(animate_runRight);
    pPlayer->runAction(repeatForever);
  
}

void HelloWorld::leftKeyDown(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent){
    
    inputSignal.leftKeyDown=true;
    if(pPlayer->is_jump()){
        pPlayer->update_state(player_state_jump_forward_left);
    }else if(pPlayer->is_forward()||pPlayer->is_still()){
        pPlayer->update_state(player_state_forward_left);
    }else if(pPlayer->is_swim()){
        pPlayer->update_state(player_state_swim_forward_left);
    
    }
    //----动画（animation只能现用现创建，且runAction一次后不能再次使用）
        pPlayer->stopAllActions();
    CCAnimation*animation_runRight=CCAnimation::create();
    CCTexture2D*texture_run;
    int nFrame;
    if(pPlayer->state==player_state_swim_forward_left){
        texture_run=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/player_swim_left.png");
        nFrame=4;
    }else{
        texture_run=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/player_run_left.png");
        nFrame=6;
    }
    CCSize texSize=texture_run->getContentSize();
    for(int i=0;i<nFrame;i++){
        animation_runRight->addSpriteFrameWithTexture(texture_run, CCRect(texSize.width-128-i*128,0,128,128));
    }
    animation_runRight->setDelayPerUnit(0.13f);
    animation_runRight->setRestoreOriginalFrame(true);
    CCAnimate* animate_runRight=CCAnimate::create(animation_runRight);
    CCRepeatForever*repeatForever=CCRepeatForever::create(animate_runRight);
    pPlayer->runAction(repeatForever);
}

void HelloWorld::leftKeyUpInside(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent){
    b2Vec2 v=pPlayer->pb2Body->GetLinearVelocity();
    pPlayer->pb2Body->SetLinearVelocity(b2Vec2(0,v.y));
    inputSignal.leftKeyDown=false;
    if(pPlayer->is_jump()){
        pPlayer->update_state(player_state_jump_still_left);
    }else if(pPlayer->is_forward()||pPlayer->is_still()){
        pPlayer->update_state(player_state_still_left);
    }else if(pPlayer->is_swim()){
        pPlayer->update_state(player_state_swim_still_left);
    }
    //---停止动画
    pPlayer->stopAllActions();
    //重设贴图
    pPlayer->setTexture(pPlayer->tex_still_left);
    pPlayer->set_quadTexCoords(ccp(0,0), ccp(1,0), ccp(0,1), ccp(1,1));

}
void HelloWorld::leftKeyDragExit(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent){
    b2Vec2 v=pPlayer->pb2Body->GetLinearVelocity();
    pPlayer->pb2Body->SetLinearVelocity(b2Vec2(0,v.y));
    inputSignal.leftKeyDown=false;
    if(pPlayer->is_jump()){
        pPlayer->update_state(player_state_jump_still_left);
    }else if(pPlayer->is_forward()||pPlayer->is_still()){
        pPlayer->update_state(player_state_still_left);
        
    }else if(pPlayer->is_swim()){
        pPlayer->update_state(player_state_swim_still_left);
    }
    //---停止动画
    pPlayer->stopAllActions();
    //重设贴图
    pPlayer->setTexture(pPlayer->tex_still_left);
    pPlayer->set_quadTexCoords(ccp(0,0), ccp(1,0), ccp(0,1), ccp(1,1));

}
void HelloWorld::leftKeyDragEnter(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent){
    
    inputSignal.leftKeyDown=true;
    if(pPlayer->is_jump()){
        pPlayer->update_state(player_state_jump_forward_left);
    }else if(pPlayer->is_forward()||pPlayer->is_still()){
        pPlayer->update_state(player_state_forward_left);
        
    }else if(pPlayer->is_swim()){
        pPlayer->update_state(player_state_swim_forward_left);
    }
    //----动画（animation只能现用现创建，且runAction一次后不能再次使用）
        pPlayer->stopAllActions();
    CCAnimation*animation_runRight=CCAnimation::create();
    CCTexture2D*texture_run;
    int nFrame;
    if(pPlayer->state==player_state_swim_forward_left){
        texture_run=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/player_swim_left.png");
        nFrame=4;
    }else{
        texture_run=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/player_run_left.png");
        nFrame=6;
    }
    CCSize texSize=texture_run->getContentSize();
    for(int i=0;i<nFrame;i++){
        animation_runRight->addSpriteFrameWithTexture(texture_run, CCRect(texSize.width-128-i*128,0,128,128));
    }
    animation_runRight->setDelayPerUnit(0.13f);
    animation_runRight->setRestoreOriginalFrame(true);
    CCAnimate* animate_runRight=CCAnimate::create(animation_runRight);
    CCRepeatForever*repeatForever=CCRepeatForever::create(animate_runRight);
    pPlayer->runAction(repeatForever);
}


void HelloWorld::jumpKeyDown(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent){

    if(pPlayer->is_jump()==false){

            pPlayer->pushVyToTagvy(10.8);
     
    }

}
void HelloWorld::shotKeyDown(CCObject *senderz, cocos2d::extension::CCControlEvent controlEvent){
    CCPoint playerPos=pPlayer->getPosition();
    CshotBall *pShotBall=CshotBall::create(world);
	pShotBall->set_showSprite(true);
	pShotBall->set_showb2Body(showb2BodyWireFrame);
    

    pShotBall->initWithInfo(pPlayer->isFacingRight()?this->objInfo_shotBall_right:this->objInfo_shotBall_left);
    this->getChildByTag(tag_root_scene_rolling)->addChild(pShotBall,99);
    pShotBall->pb2Body->SetTransform(b2Vec2(playerPos.x/PTM_RATIO,playerPos.y/PTM_RATIO), 0);
    pShotBall->pb2Body->SetAngularVelocity(pPlayer->isFacingRight()?-7:7);
    pShotBall->pushVxToTagvx(pPlayer->isFacingRight()?10:-10);
    pShotBall->schedule(schedule_selector(CshotBall::removeMeFromSceneAndDestroyBodyCallBack),2.5);
	
}



void HelloWorld::visit(void){
    
    CCLayer::visit();
    
}

void HelloWorld::update(float dt)
{
    //It is recommended that a fixed time step is used with Box2D for stability
    //of the simulation, however, we are using a variable time step here.
    //You need to make an informed choice, the following URL is useful
    //http://gafferongames.com/game-physics/fix-your-timestep/
    
    int velocityIterations = 8;
    int positionIterations = 1;
    
    // Instruct the world to perform a single step of simulation. It is
    // generally best to keep the time step and iterations fixed.
    world->Step(dt, velocityIterations, positionIterations);
    
    //Iterate over the bodies in the physics world
    for (b2Body* body = world->GetBodyList(); body; body = body->GetNext())
    {
		//求body的box2d世界坐标
		b2Vec2 bodyPos_b2d=body->GetPosition();
		//求body的cocos2d世界坐标
		CCPoint bodyPos=ccp(bodyPos_b2d.x * PTM_RATIO, bodyPos_b2d.y * PTM_RATIO);
        if (body->GetUserData() != NULL) {
            //Synchronize the AtlasSprites position and rotation with the corresponding body
            CmyObj* myObj = (CmyObj*)body->GetUserData();
			//设法使myObj的世界坐标与bodyPos相等
			//将bodyPos转化到myObj的父节点空间
			CCPoint posInFather=myObj->getParent()->convertToNodeSpace(bodyPos);
            myObj->setPosition( posInFather );//按posInFather来设置myObj在父节点中的位置，myObj的世界坐标就等于bodyPos了
			//设置myObj的旋转角度与body相同
            myObj->setRotation( -1 * CC_RADIANS_TO_DEGREES(body->GetAngle()) );
        }    
    }
      
    //----计算pPlayer->touchSolid（必须放在是否在水中之后，必须放在其它之前）
    {
        //统计player的foot上碰撞的个数
        int nContact=0;//player的foot上碰撞的个数
        for(b2ContactEdge*ce=pPlayer->pb2Body->GetContactList();ce;ce=ce->next){
            b2Contact* contact=ce->contact;
            b2Fixture*fixtureA=contact->GetFixtureA();
            b2Fixture*fixtureB=contact->GetFixtureB();
            if(fixtureA==pPlayer->fixture_foot){
                nContact++;
            }
            if(fixtureB==pPlayer->fixture_foot){
                nContact++;
            }
        }//得到nContact
        pPlayer->touchSolid=(nContact>0);
    }
    
    //----着陆
    if(pPlayer->is_jump()&&pPlayer->touchSolid){
        //转为非跳起
        if(pPlayer->state==player_state_jump_forward_right){
            pPlayer->update_state(player_state_forward_right);
        }else if(pPlayer->state==player_state_jump_still_right){
            pPlayer->update_state(player_state_still_right);
        }else if(pPlayer->state==player_state_jump_forward_left){
            pPlayer->update_state(player_state_forward_left);
        }else if(pPlayer->state==player_state_jump_still_left){
            pPlayer->update_state(player_state_still_left);
        }
    }
    if(pPlayer->is_jump()==false&&pPlayer->touchSolid==false){
        //转为跳起或swim
        //判断是否swim
        const float sinkH=0;
        CCRect playerRect=pPlayer->boundingBox();
        if(playerRect.getMinY()<=m_waterSurfaceHeight-sinkH){//swim
            if(pPlayer->is_forward()){
                if(pPlayer->isFacingRight()){
                    if(pPlayer->state!=player_state_swim_forward_right){
                        pPlayer->state=player_state_swim_forward_right;
                        //播放动画
                        pPlayer->stopAllActions();//先停止先前的动画
                        CCAnimation*animation=CCAnimation::create();
                        CCTexture2D*texture;
                        texture=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/player_swim_right.png");
                        int nFrame=4;
                        CCSize texSize=texture->getContentSize();
                        for(int i=0;i<nFrame;i++){
                            animation->addSpriteFrameWithTexture(texture, CCRect(i*128,0,128,128));
                        }
                        animation->setDelayPerUnit(0.13f);
                        animation->setRestoreOriginalFrame(true);
                        CCAnimate* animate=CCAnimate::create(animation);
                        CCRepeatForever*repeatForever=CCRepeatForever::create(animate);
                        pPlayer->runAction(repeatForever);

                    }
                }else{
                    if(pPlayer->state!=player_state_swim_forward_left){
                        pPlayer->state=player_state_swim_forward_left;
                        //播放动画
                        pPlayer->stopAllActions();//先停止先前的动画
                        CCAnimation*animation=CCAnimation::create();
                        CCTexture2D*texture;
                        texture=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/player_swim_left.png");
                        int nFrame=4;
                        CCSize texSize=texture->getContentSize();
                        for(int i=0;i<nFrame;i++){
                            animation->addSpriteFrameWithTexture(texture, CCRect(texSize.width-128-i*128,0,128,128));
                        }
                        animation->setDelayPerUnit(0.13f);
                        animation->setRestoreOriginalFrame(true);
                        CCAnimate* animate=CCAnimate::create(animation);
                        CCRepeatForever*repeatForever=CCRepeatForever::create(animate);
                        pPlayer->runAction(repeatForever);

                    }
                }
            }else if(pPlayer->is_still()){
                if(pPlayer->isFacingRight()){
                    pPlayer->state=player_state_swim_still_right;
                }else{
                    pPlayer->state=player_state_swim_still_left;
                }
                
            }
        }else{
            if(pPlayer->state==player_state_still_right){
                pPlayer->update_state(player_state_jump_still_right);
            }else if(pPlayer->state==player_state_forward_right){
                pPlayer->update_state(player_state_jump_forward_right);
            }else if(pPlayer->state==player_state_still_left){
                pPlayer->update_state(player_state_jump_still_left);
            }else if(pPlayer->state==player_state_forward_left){
                pPlayer->update_state(player_state_jump_forward_left);
            }
   
        }
    }


    //----计算主角是否swim（必须放在判断是否着陆之前）
    //脚接触水面不算swim状态，要吃水到一定深度才算swim
    {
        const float sinkH=20;
        CCRect playerRect=pPlayer->boundingBox();
        if(playerRect.getMinY()<=m_waterSurfaceHeight-sinkH){//swim
            if(pPlayer->isFacingRight()){
                if(pPlayer->is_xx_still()){
                    pPlayer->state=player_state_swim_still_right;
                }else if(pPlayer->is_xx_forward()){
                    if(pPlayer->state!=player_state_swim_forward_right){
                        pPlayer->state=player_state_swim_forward_right;
                        //播放动画
                        pPlayer->stopAllActions();//先停止先前的动画
                        CCAnimation*animation=CCAnimation::create();
                        CCTexture2D*texture;
                        texture=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/player_swim_right.png");
                        int nFrame=4;
                        CCSize texSize=texture->getContentSize();
                        for(int i=0;i<nFrame;i++){
                            animation->addSpriteFrameWithTexture(texture, CCRect(i*128,0,128,128));
                        }
                        animation->setDelayPerUnit(0.13f);
                        animation->setRestoreOriginalFrame(true);
                        CCAnimate* animate=CCAnimate::create(animation);
                        CCRepeatForever*repeatForever=CCRepeatForever::create(animate);
                        pPlayer->runAction(repeatForever);
                        
                    }
                }
            }else{//facingLeft
                if(pPlayer->is_xx_still()){
                    pPlayer->state=player_state_swim_still_left;
                }else if(pPlayer->is_xx_forward()){
                    if(pPlayer->state!=player_state_swim_forward_left){
                        pPlayer->state=player_state_swim_forward_left;
                        //播放动画
                        pPlayer->stopAllActions();//先停止先前的动画
                        CCAnimation*animation=CCAnimation::create();
                        CCTexture2D*texture;
                        texture=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/player_swim_left.png");
                        int nFrame=4;
                        CCSize texSize=texture->getContentSize();
                        for(int i=0;i<nFrame;i++){
                            animation->addSpriteFrameWithTexture(texture, CCRect(texSize.width-128-i*128,0,128,128));
                        }
                        animation->setDelayPerUnit(0.13f);
                        animation->setRestoreOriginalFrame(true);
                        CCAnimate* animate=CCAnimate::create(animation);
                        CCRepeatForever*repeatForever=CCRepeatForever::create(animate);
                        pPlayer->runAction(repeatForever);
                        
                    }
                }
            }
        }else{//不swim
            if(pPlayer->isFacingRight()){
                if(pPlayer->is_xx_still()){
                    if(/*pPlayer->touchSolid*/pPlayer->is_jump()==false){
                        pPlayer->state=player_state_still_right;
                    }else{
                        pPlayer->state=player_state_jump_still_right;
                    }
                }else if(pPlayer->is_xx_forward()){
                    if(/*pPlayer->touchSolid*/pPlayer->is_jump()==false){
                        if(pPlayer->state!=player_state_forward_right){
                            pPlayer->state=player_state_forward_right;
                            //播放动画
                            pPlayer->stopAllActions();//先停止先前的动画
                            CCAnimation*animation=CCAnimation::create();
                            CCTexture2D*texture;
                            texture=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/player_run_right.png");
                            int nFrame=6;
                            CCSize texSize=texture->getContentSize();
                            for(int i=0;i<nFrame;i++){
                                animation->addSpriteFrameWithTexture(texture, CCRect(i*128,0,128,128));
                            }
                            animation->setDelayPerUnit(0.13f);
                            animation->setRestoreOriginalFrame(true);
                            CCAnimate* animate=CCAnimate::create(animation);
                            CCRepeatForever*repeatForever=CCRepeatForever::create(animate);
                            pPlayer->runAction(repeatForever);
                            
                        }
                    }else{
                        
                        pPlayer->state=player_state_jump_forward_right;
                    }
                    
                }
            }else{//facingLeft
                if(pPlayer->is_xx_still()){
                    if(/*pPlayer->touchSolid*/pPlayer->is_jump()==false){
                        pPlayer->state=player_state_still_left;
                    }else{
                        pPlayer->state=player_state_jump_still_left;
                    }
                }else if(pPlayer->is_xx_forward()){
                    if(/*pPlayer->touchSolid*/pPlayer->is_jump()==false){
                        if(pPlayer->state!=player_state_forward_left){
                            pPlayer->state=player_state_forward_left;
                            //播放动画
                            pPlayer->stopAllActions();//先停止先前的动画
                            CCAnimation*animation=CCAnimation::create();
                            CCTexture2D*texture;
                            texture=CCTextureCache::sharedTextureCache()->addImage("data/global/tex/player_run_left.png");
                            int nFrame=6;
                            CCSize texSize=texture->getContentSize();
                            for(int i=0;i<nFrame;i++){
                                animation->addSpriteFrameWithTexture(texture, CCRect(texSize.width-128-i*128,0,128,128));
                            }
                            animation->setDelayPerUnit(0.13f);
                            animation->setRestoreOriginalFrame(true);
                            CCAnimate* animate=CCAnimate::create(animation);
                            CCRepeatForever*repeatForever=CCRepeatForever::create(animate);
                            pPlayer->runAction(repeatForever);
                        }
                    }else{
                        pPlayer->state=player_state_jump_forward_left;
                    }
                    
                }
            }
            
        }
    }
 
    //----根据player状态设置player的动画，贴图和动作
  /*  cout<<"state:";
    pPlayer->print_sate();
    cout<<endl;*/
    if(pPlayer->isChange_state()){//如果player状态有变
        //根据变到的状态state更新player
        switch(pPlayer->state){
            case player_state_still_right:
            {
                //重设贴图
                pPlayer->setTexture(pPlayer->tex_still_right);
                pPlayer->set_quadTexCoords(ccp(0,0), ccp(1,0), ccp(0,1), ccp(1,1));
            }break;
            case player_state_still_left:
                //重设贴图
                pPlayer->setTexture(pPlayer->tex_still_left);
                pPlayer->set_quadTexCoords(ccp(0,0), ccp(1,0), ccp(0,1), ccp(1,1));
            {
            }break;
            case player_state_forward_right:
            {
                float m=pPlayer->pb2Body->GetMass();
                b2Vec2 v=pPlayer->pb2Body->GetLinearVelocity();
                const float vx=5;
                //将v的x分量弄成vx
                b2Vec2 dv=b2Vec2(vx-v.x,0);
                b2Vec2 impluse=m*dv;
                pPlayer->pb2Body->ApplyLinearImpulse(impluse, pPlayer->pb2Body->GetWorldCenter());
         /*       //重设贴图
                pPlayer->setTexture(pPlayer->tex_forward_right_first);
                pPlayer->set_quadTexCoords(ccp(0,0), ccp(1,0), ccp(0,1), ccp(1,1));*/
                
            }break;
            case player_state_forward_left:
            {
                float m=pPlayer->pb2Body->GetMass();
                b2Vec2 v=pPlayer->pb2Body->GetLinearVelocity();
                const float vx=-5;
                //将v的x分量弄成vx
                b2Vec2 dv=b2Vec2(vx-v.x,0);
                b2Vec2 impluse=m*dv;
                pPlayer->pb2Body->ApplyLinearImpulse(impluse, pPlayer->pb2Body->GetWorldCenter());
            /*    //重设贴图
                pPlayer->setTexture(pPlayer->tex_forward_left_first);
                pPlayer->set_quadTexCoords(ccp(0,0), ccp(1,0), ccp(0,1), ccp(1,1));*/
            }break;
            case player_state_jump_still_right:
            {
                //重设贴图
                pPlayer->setTexture(pPlayer->tex_jump_still_right);
                pPlayer->set_quadTexCoords(ccp(0,0), ccp(1,0), ccp(0,1), ccp(1,1));
            }break;
            case player_state_jump_still_left:
            {
                //重设贴图
                pPlayer->setTexture(pPlayer->tex_jump_still_left);
                pPlayer->set_quadTexCoords(ccp(0,0), ccp(1,0), ccp(0,1), ccp(1,1));
            }break;
            case player_state_jump_forward_right:
            {
                float m=pPlayer->pb2Body->GetMass();
                b2Vec2 v=pPlayer->pb2Body->GetLinearVelocity();
                const float vx=5;
                //将v的x分量弄成vx
                b2Vec2 dv=b2Vec2(vx-v.x,0);
                b2Vec2 impluse=m*dv;
                pPlayer->pb2Body->ApplyLinearImpulse(impluse, pPlayer->pb2Body->GetWorldCenter());
                //重设贴图
                pPlayer->setTexture(pPlayer->tex_jump_forward_right);
                pPlayer->set_quadTexCoords(ccp(0,0), ccp(1,0), ccp(0,1), ccp(1,1));
            }break;
            case player_state_jump_forward_left:
            {
                float m=pPlayer->pb2Body->GetMass();
                b2Vec2 v=pPlayer->pb2Body->GetLinearVelocity();
                const float vx=-5;
                //将v的x分量弄成vx
                b2Vec2 dv=b2Vec2(vx-v.x,0);
                b2Vec2 impluse=m*dv;
                pPlayer->pb2Body->ApplyLinearImpulse(impluse, pPlayer->pb2Body->GetWorldCenter());
                //重设贴图
                pPlayer->setTexture(pPlayer->tex_jump_forward_left);
                pPlayer->set_quadTexCoords(ccp(0,0), ccp(1,0), ccp(0,1), ccp(1,1));
            }break;
            case player_state_swim_still_right:
            {
                //重设贴图
                pPlayer->setTexture(pPlayer->tex_swim_still_right);
                pPlayer->set_quadTexCoords(ccp(0,0), ccp(1,0), ccp(0,1), ccp(1,1));

               
     
            }break;
            case player_state_swim_still_left:
            {
                //重设贴图
                pPlayer->setTexture(pPlayer->tex_swim_still_left);
                pPlayer->set_quadTexCoords(ccp(0,0), ccp(1,0), ccp(0,1), ccp(1,1));

                
            }break;
            case player_state_swim_forward_right:
            {
                float m=pPlayer->pb2Body->GetMass();
                b2Vec2 v=pPlayer->pb2Body->GetLinearVelocity();
                const float vx=5;
                //将v的x分量弄成vx
                b2Vec2 dv=b2Vec2(vx-v.x,0);
                b2Vec2 impluse=m*dv;
                pPlayer->pb2Body->ApplyLinearImpulse(impluse, pPlayer->pb2Body->GetWorldCenter());
                
            }break;
            case player_state_swim_forward_left:
            {
                float m=pPlayer->pb2Body->GetMass();
                b2Vec2 v=pPlayer->pb2Body->GetLinearVelocity();
                const float vx=-5;
                //将v的x分量弄成vx
                b2Vec2 dv=b2Vec2(vx-v.x,0);
                b2Vec2 impluse=m*dv;
                pPlayer->pb2Body->ApplyLinearImpulse(impluse, pPlayer->pb2Body->GetWorldCenter());
            
            }break;
                default:
                cout<<"warning:未知状态!"<<endl;
                break;
        }
        
    }
  //  cout<<"player state:";pPlayer->print_sate();cout<<endl;
    //----相机跟随主角
    CCSize s = CCDirector::sharedDirector()->getWinSize();
    CCPoint playerPos=pPlayer->getParent()->convertToWorldSpace(pPlayer->getPosition());
 //   cout<<"playerPos:"<<playerPos.x<<" "<<playerPos.y<<" "<<endl;
    CCCamera*camera=this->getChildByTag(tag_root_scene_rolling)->getCamera();
    float cx,cy,cz;
    float eyex,eyey,eyez;
 //   cout<<eyex<<" "<<eyey<<" "<<eyez<<endl;
    camera->getCenterXYZ(&cx, &cy, &cz);
    camera->getEyeXYZ(&eyex, &eyey, &eyez);
    //
    camera->setCenterXYZ(playerPos.x-s.width/2, playerPos.y-s.height/2, cz);
    camera->setEyeXYZ(playerPos.x-s.width/2, playerPos.y-s.height/2, eyez);
    //----背景循环
    {
        vector<CCSprite*> pBackGroundList;
        pBackGroundList.push_back((CCSprite*)this->getChildByTag(tag_root_scene_rolling)->getChildByTag(tag_backGround));
        pBackGroundList.push_back((CCSprite*)this->getChildByTag(tag_root_scene_rolling)->getChildByTag(tag_backGround2));
        //看player处在backGroundList中哪个元素上
        int index=-1;
        CCPoint playerPos=pPlayer->getParent()->convertToWorldSpace(pPlayer->getPosition());
        int nBackGround=(int)pBackGroundList.size();
        for(int i=0;i<nBackGround;i++){
            CCSprite*pBackGround=pBackGroundList[i];
            CCRect rect=pBackGround->boundingBox();//在父坐标系中的坐标
            if(playerPos.x>rect.getMinX()&&playerPos.x<rect.getMaxX()){//只要横坐标在此范围内就算，不考虑纵坐标
                index=i;
                break;
            }
        }//得到index
        if(index!=-1){//如果找到
       //     cout<<"index:"<<index<<endl;
            CCSprite*pBackGround1=pBackGroundList[index];
            CCSprite*pBackGround2=pBackGroundList[1-index];
            //看pBackGround1是在边缘暴漏还是右边缘暴露
            //求相机视野范围
            CCSize winSize = CCDirector::sharedDirector()->getWinSize();
            CCCamera*camera=this->getChildByTag(tag_root_scene_rolling)->getCamera();
            float eyex,eyey,eyez;
            camera->getEyeXYZ(&eyex, &eyey, &eyez);
            CCRect viewRect(eyex,eyey,winSize.width,winSize.height);
            CCRect rect1=pBackGround1->boundingBox();
            if(rect1.getMaxX()<viewRect.getMaxX()){//右边缘暴露
                //把pBackGround2补到右边
              //     cout<<"右边缘暴露"<<endl;
                pBackGround2->setPosition(ccp(rect1.getMaxX(),rect1.getMinY()));
            }
            if(rect1.getMinX()>viewRect.getMinX()){//左边缘暴露
                //把pBackGround2补充到左边
             //      cout<<"左边缘暴露"<<endl;
                pBackGround2->setPosition(ccp(rect1.getMinX()-rect1.size.width,rect1.getMinY()));
            }
        }
    }
    //一旦子弹超出画面，就删除
    {
        //求相机视野范围
        CCSize winSize = CCDirector::sharedDirector()->getWinSize();
        CCCamera*camera=this->getChildByTag(tag_root_scene_rolling)->getCamera();
        float eyex,eyey,eyez;
        camera->getEyeXYZ(&eyex, &eyey, &eyez);
        CCRect viewRect(eyex,eyey,winSize.width,winSize.height);
        //将超出视野的子弹删除
        CCNode *sceneRoot=this->getChildByTag(tag_root_scene_rolling);
        CCArray *arr=sceneRoot->getChildren();
        CCObject* obj = NULL;
        CCARRAY_FOREACH(arr, obj) {
            CmyObj* pObj = (CmyObj*) obj;
            if(pObj->getTag()!=tag_shotBall_right&&pObj->getTag()!=tag_shotBall_left)continue;
            //看pObj是否超出视野
            CCRect rect=pObj->boundingBox();
            if(rect.getMinX()>viewRect.getMaxX()||rect.getMaxX()<viewRect.getMinX()){//超出视野
                pObj->removeMeFromSceneAndDestroyBody(true);
            }
        }
    }
    //---
//    cout<<pPlayer->numberOfRunningActions()<<endl;
   //----thing受浮力
	int thingCount=CthingManager::GetInstance()->getThingCount();
	for(int i=0;i<thingCount;i++){
		CmyObj*thing=CthingManager::GetInstance()->getThingAt(i);
		thing->buoyancyEffect(this->m_waterSurfaceHeight);
	}
	//----player受浮力
	pPlayer->buoyancyEffect(this->m_waterSurfaceHeight);
 //    cout<<dt<<endl;
/*    //审计world中的body数
    {
        cout<<"bodyCount:"<<world->GetBodyCount()<<endl;
    }
*/
  //  cout<<pPlayer->touchSolid<<endl;
    
    
    
    

}

/*void HelloWorld::ccTouchesEnded(CCSet* touches, CCEvent* event)
{
    //Add a new body/atlas sprite at the touched location
    CCSetIterator it;
    CCTouch* touch;
    
 /*   for( it = touches->begin(); it != touches->end(); it++)
    {
        touch = (CCTouch*)(*it);
        
        if(!touch)
            break;
        
        CCPoint location = touch->getLocationInView();
        
        location = CCDirector::sharedDirector()->convertToGL(location);
   //     cout<<"mos pos:"<<location.x<<" "<<location.y<<endl;
    }*/
  /*  //获得单点坐标
    touch=(CCTouch*)(*touches->begin());
    if(!touch)return;
    CCPoint location=touch->getLocationInView();
    location=CCDirector::sharedDirector()->convertToGL(location);
    mos.x=location.x;
    mos.y=location.y;
    //移动主角
    if(pPlayer!=NULL){
        pPlayer->pb2Body->SetLinearVelocity(b2Vec2(1.0,0));
    }else{
        cout<<"pPlayer==NULL!"<<endl;
    }
}*/
/*void HelloWorld::ccTouchesMoved(cocos2d::CCSet* touches , cocos2d::CCEvent* event)
{
    CCSetIterator it;
    CCTouch* touch;
    //获得单点坐标
    touch=(CCTouch*)(*touches->begin());
    if(!touch){
        return;
    }
    CCPoint location=touch->getLocationInView();
    location=CCDirector::sharedDirector()->convertToGL(location);
    mos.x=location.x;
    mos.y=location.y;
    
   
}*/
/*
void HelloWorld::ccTouchesBegan(CCSet* touches, CCEvent* event)
{
    CCSetIterator it;
    CCTouch* touch;
 /*   for( it = touches->begin(); it != touches->end(); it++)
    {
        touch = (CCTouch*)(*it);
        
        if(!touch)
            break;
        
        CCPoint location = touch->getLocationInView();
        
        location = CCDirector::sharedDirector()->convertToGL(location);
        
        addNewSpriteAtPosition( location );
        //遍历body，看哪个被选中
   }*/
  /*   //获得单点坐标
    touch=(CCTouch*)(*touches->begin());
    if(!touch)return;
    CCPoint location=touch->getLocationInView();
    location=CCDirector::sharedDirector()->convertToGL(location);
    mos.x=location.x;
    mos.y=location.y;
}*/

CCScene* HelloWorld::scene()
{
    // 'scene' is an autorelease object
    CCScene *scene = CCScene::create();
    
    // 'layer' is an autorelease object
    HelloWorld *layer = HelloWorld::create();

    // add layer as a child to scene
    scene->addChild(layer);

    // return the scene
    return scene;
}