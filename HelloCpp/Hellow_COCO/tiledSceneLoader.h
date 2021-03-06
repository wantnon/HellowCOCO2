
#ifndef __mybox2dtest__tiledSceneLoader__
#define __mybox2dtest__tiledSceneLoader__

#include <iostream>
using namespace std;
#include "cocos2d.h"
#include "Box2D.h"
#include "myfunc.h"
#include "myDef.h"
#include "myBox2dFunc.h"
#include "myObj.h"
#include "thingManager.h"
using namespace cocos2d;
class CtiledSceneLoader
{
public:
	CtiledSceneLoader(){
	}
	virtual ~CtiledSceneLoader(){
	}
	CCNode*loadScene(string tmxFilePathShort,b2World*world)//加载tmx场景,返回tiled场景的根节点
	{
		CCNode*tiledSceneRootNode=CCNode::create();
		//
		CCPoint mapOffset(0,-100);//地图偏移量
		CCTMXTiledMap*map=CCTMXTiledMap::create(tmxFilePathShort.c_str());
		tiledSceneRootNode->addChild(map);
		map->setPosition(mapOffset);
		map->setVisible(false);
		//获得map信息
		CCSize mapSize=map->getMapSize();//s.height是layer行数，s.width是layer列数
		CCSize tileSize=map->getTileSize();//每个tile的大小
		//获得层或objGroup
		CCTMXLayer*layer=map->layerNamed("groundLayer");
		assert(layer);
		CCTMXObjectGroup* objGroup=map->objectGroupNamed("thingLayer_polygon");
		assert(objGroup);
		CCTMXLayer*layer_thing_tile=map->layerNamed("thingLayer_tile");
		assert(layer_thing_tile);
		//遍历objGroup中的各object
		cout<<"--------------------tiledmap thingLayer:"<<endl;
		CCObject* pObj = NULL;
        CCARRAY_FOREACH(objGroup->getObjects(), pObj)
        {
			//----属性
			string name;
			string type;//polygon,ellipse,...
			b2BodyType bodyType;
			float friction;
			float restitution;
			float density;
			bool isSensor;
			int categoryBits;
			int maskBits;
			int groupIndex;
			float gravityScale;
			//----获得属性
            CCDictionary* pDict = (CCDictionary*)pObj;
			name= ((CCString*)pDict->objectForKey("name"))->getCString();
			type= ((CCString*)pDict->objectForKey("type"))->getCString();
		    bodyType=bodyTypeStrTobodyTypeValue(((CCString*)pDict->objectForKey("bodyType"))->getCString());
			friction= ((CCString*)pDict->objectForKey("friction"))->floatValue();
			restitution= ((CCString*)pDict->objectForKey("restitution"))->floatValue();
			density= ((CCString*)pDict->objectForKey("density"))->floatValue();
			isSensor= ((CCString*)pDict->objectForKey("isSensor"))->boolValue();
			categoryBits= ((CCString*)pDict->objectForKey("categoryBits"))->intValue();
			maskBits= ((CCString*)pDict->objectForKey("maskBits"))->intValue();
			groupIndex= ((CCString*)pDict->objectForKey("groupIndex"))->intValue();
			gravityScale= ((CCString*)pDict->objectForKey("gravityScale"))->floatValue();
			cout<<"--------"<<endl;
			cout<<"name:"<<name<<endl;
			cout<<"type:"<<type<<endl;
			cout<<"bodyType:"<<bodyType<<endl;
			cout<<"friction:"<<friction<<endl;
			cout<<"restitution:"<<restitution<<endl;
			cout<<"density:"<<density<<endl;
			cout<<"isSensor:"<<isSensor<<endl;
			cout<<"categoryBits:"<<categoryBits<<endl;
			cout<<"maskBits:"<<maskBits<<endl;
			cout<<"groupIndex:"<<groupIndex<<endl;
			cout<<"gravityScale:"<<gravityScale<<endl;
			//--------生成myObj
			CmyObj*myObj=CmyObj::create(world);
			CthingManager::GetInstance()->addThing(myObj);
			//--------创建b2Body
			if(type=="ellipse"){//是椭圆
				//----提取信息
				//x,y是椭圆包围盒的左下角
				float x = pDict->valueForKey("x")->floatValue();
				float y = pDict->valueForKey("y")->floatValue();//此值与tmx文件中存的值不同，需用mapSize.height*tileSize.height减去此值才得tmx文件中的值
				float width = pDict->valueForKey("width")->floatValue();
				float height = pDict->valueForKey("height")->floatValue();
				//----输出信息
				cout<<"xy:"<<x<<","<<y<<endl;
				cout<<"wh:"<<width<<" "<<height<<endl;
				//----转化信息
				//求圆心
				float cx_inWorld_b2d=(x+width/2+map->getPositionX())/PTM_RATIO;
				float cy_inWorld_b2d=(y+height/2+map->getPositionY())/PTM_RATIO;
				//求半径
				float r_b2d=(width/2+height/2)/2/PTM_RATIO;
				//----生成body
				myObj->create_pb2Body_circle(r_b2d,bodyType,friction,restitution,density,isSensor,categoryBits,maskBits,groupIndex,gravityScale);
				myObj->pb2Body->SetTransform(b2Vec2(cx_inWorld_b2d ,cy_inWorld_b2d),0);
			}else if(type=="polygon"){//是多边形
				//----提取信息
				float x = pDict->valueForKey("x")->floatValue();
				float y = pDict->valueForKey("y")->floatValue();//此值与tmx文件中存的值不同，需用mapSize.height*tileSize.height减去此值才得tmx文件中的值
				CCArray* points = (CCArray*)pDict->objectForKey("points");//得到顶点列表
				assert(points);
				//----输出信息
				cout<<"xy:"<<x<<","<<y<<endl;
				//points
				{
					cout<<"points:";
					int npoint=points->count();
					for(int i=0;i<npoint;i++){
						CCDictionary* dict = (CCDictionary*)points->objectAtIndex(i);
						float x=dict->valueForKey("x")->floatValue();
						float y=dict->valueForKey("y")->floatValue();
						cout<<x<<" "<<y<<" ";
					}cout<<endl;
				}
				//----转化信息
				//生成polygon
				vector<b2Vec2> polygon;
				int npoint=points->count();
				float begx=x;
				float begy=mapSize.height*tileSize.height-y;
				for(int i=0;i<npoint;i++){
					CCDictionary* dict = (CCDictionary*)points->objectAtIndex(i);
					float x_inMap=begx+ dict->valueForKey("x")->floatValue();
					float y_inMap=mapSize.height*tileSize.height-(begy+ dict->valueForKey("y")->floatValue());
					//(x_inMap,y_inMap)是以map左下角为原点的坐标，下面加上map偏移，即得在世界中的坐标
					float x_inWorld=map->getPositionX()+x_inMap;
					float y_inWorld=map->getPositionY()+y_inMap;
					b2Vec2 v(x_inWorld/PTM_RATIO,y_inWorld/PTM_RATIO);
					polygon.push_back(v);
				}//得到polygon
				//求polygon的重心
				b2Vec2 wc=getAveragePoint(polygon);
				//将polygon所有顶点均转为相对于wc
				for(int i=0;i<npoint;i++)polygon[i]-=wc;
				//----生成body
				myObj->create_pb2Body_polygon(polygon,bodyType,friction,restitution,density,isSensor,categoryBits,maskBits,groupIndex,gravityScale);
				myObj->pb2Body->SetTransform(b2Vec2(wc.x ,wc.y),0);
			}
			//----生成sprite
			//求layer_thing_tile中所有与myObj->pb2Body相交的块
			//求世界空间中的aabb
			b2AABB aabb=getAABB(myObj->pb2Body->GetFixtureList()->GetShape(),myObj->pb2Body->GetTransform());
			//将aabb转化为ccrect
			CCRect rect(aabb.lowerBound.x*PTM_RATIO,aabb.lowerBound.y*PTM_RATIO,
				(aabb.upperBound.x-aabb.lowerBound.x)*PTM_RATIO,(aabb.upperBound.y-aabb.lowerBound.y)*PTM_RATIO);
			//求layer_thing_tile中所有与rect相交的块
			//求rect在map中（以map左下角为原点）的样子
			CCRect rect_inMap_OatLD=rect;
			rect_inMap_OatLD.origin=rect_inMap_OatLD.origin-map->getPosition();
			//求rect在map中（以map左上角为原点）的样子(注意此时rect的origin要改作用rect的左上角)
			CCRect rect_inMap_OatLU=rect_inMap_OatLD;
			rect_inMap_OatLU.origin.y=rect_inMap_OatLU.origin.y+rect_inMap_OatLU.size.height;//原点改用rect左上角，但map原点仍取map左下角
			rect_inMap_OatLU.origin.y=mapSize.height*tileSize.height-rect_inMap_OatLU.origin.y;//将map原点改用左上角，得到最终的rect_inMap_OatLU
			float xmin=rect_inMap_OatLU.getMinX();
			float ymin=rect_inMap_OatLU.getMinY();
			float xmax=rect_inMap_OatLU.getMaxX();
			float ymax=rect_inMap_OatLU.getMaxY();
			int jmin=xmin/tileSize.width;
			int imin=ymin/tileSize.height;
			int jmax=xmax/tileSize.width;
			int imax=ymax/tileSize.height;
			cout<<"AABB cover tilemap:"<<endl;
			cout<<" i range:"<<imin<<" "<<imax<<endl;
			cout<<" j range:"<<jmin<<" "<<jmax<<endl;
			//将layer_thing_tile的(imin,jmin)至(imax,jmax)区域内各格的sprite的拷贝均加为myObj的子节点（之所以要用拷贝，是因为这些sprite已经通过map加入到场景了，不能重复添加到场景）
			CCSpriteBatchNode*batchNode_small=CCSpriteBatchNode::createWithTexture(layer_thing_tile->getTexture());
			myObj->addChild(batchNode_small);
			myObj->set_showb2Body(showb2BodyWireFrame);
			myObj->set_showSprite(false);
			for(int i=imin;i<=imax;i++){
				for(int j=jmin;j<=jmax;j++){
					CCSprite*sprite=layer_thing_tile->tileAt(ccp(j,i));//注意，j为横，i为纵，所以ccp(j,i)
					if(sprite==NULL)continue;
					CCSprite*_sprite=CCSprite::create();
					_sprite->setTexture(sprite->getTexture());
					_sprite->setTextureRect(sprite->getTextureRect());
					_sprite->setAnchorPoint(sprite->getAnchorPoint());
					//求sprite相对于body的坐标
					b2Vec2 bodyPos_inWorld_box2d=myObj->pb2Body->GetPosition();
					CCPoint bodyPos_inWorld(bodyPos_inWorld_box2d.x*PTM_RATIO,bodyPos_inWorld_box2d.y*PTM_RATIO);
					CCPoint spritePos_inWorld=sprite->getPosition()+map->getPosition();
					CCPoint offset_spriteRelativeToBody=spritePos_inWorld-bodyPos_inWorld;
					_sprite->setPosition(offset_spriteRelativeToBody);//转化为相对于
					batchNode_small->addChild(_sprite);
				}
			}
			tiledSceneRootNode->addChild(myObj);



        }
		//标记各格是否有内容
		vector<vector<bool> > mat;
		mat.resize(mapSize.height);
		for(int i=0;i<mapSize.height;i++){
			mat[i].resize(mapSize.width);
			for(int j=0;j<mapSize.width;j++){
				mat[i][j]=false;
			}
		}
		//填充mat
		for(int i=0;i<mapSize.height;i++){
			for(int j=0;j<mapSize.width;j++){
				CCPoint gridxy(j,i);
				int grid=layer->tileGIDAt(gridxy);
				CCDictionary* poperDic=(CCDictionary*)map->propertiesForGID(grid);
				//检查isNoContent
				if(poperDic!=NULL){
					CCObject*ccobj=poperDic->objectForKey("nothing");
					if(ccobj!=NULL){
						CCString *ccs_value=(CCString*)ccobj;
						string str_value=ccs_value->getCString();
						if(str_value=="true")continue;
					}
				}
				//获得sprite
				CCSprite*sprite=layer->tileAt(ccp(j,i));//注意，j为横，i为纵，所以ccp(j,i)
				if(sprite==NULL)continue;
				mat[i][j]=true;

			}
		}
		//标记各格是否在边缘
		vector<vector<bool> > mat_isOnEdge;
		mat_isOnEdge.resize(mapSize.height);
		for(int i=0;i<mapSize.height;i++){
			mat_isOnEdge[i].resize(mapSize.width);
			for(int j=0;j<mapSize.width;j++){
				mat_isOnEdge[i][j]=false;
			}
		}
		//填充mat_isOnEdge
		for(int i=0;i<(int)mat_isOnEdge.size();i++)
		{
			for(int j=0;j<(int)mat_isOnEdge[i].size();j++)
			{
				if(mat[i][j]==true){
					//判断mat[i][j]是否为边缘格
					int up=i-1>0?mat[i-1][j]:0;
					int dn=i+1<(int)mat.size()?mat[i+1][j]:0;
					int left=j-1>0?mat[i][j-1]:0;
					int right=j+1<(int)mat[i].size()?mat[i][j+1]:0;
					if(up!=0&&dn!=0&&left!=0&&right!=0){//是非边缘格
						//无动作
					}else{//是边缘格
						mat_isOnEdge[i][j]=true;
					}
				}
			}
		}
		//记录各格的polygon都覆盖除自身以外的哪些格
		vector<vector<vector<Cij> > > mat_polygonCoveredTileSet;
		mat_polygonCoveredTileSet.resize(mapSize.height);
		for(int i=0;i<mapSize.height;i++){
			mat_polygonCoveredTileSet[i].resize(mapSize.width);
		}
		//填充mat_polygonCoveredTileSet
		for(int i=0;i<(int)mat_polygonCoveredTileSet.size();i++)
		{
			for(int j=0;j<(int)mat_polygonCoveredTileSet[i].size();j++)
			{
				int grid=layer->tileGIDAt(ccp(j,i));//因为ccp，所以j,i
				CCDictionary* poperDic=(CCDictionary*)map->propertiesForGID(grid);
				if(poperDic!=NULL){
					CCObject*ccobj=poperDic->objectForKey("polygon");
					if(ccobj!=NULL){
						CCString *ccs_value=(CCString*)ccobj;
						string str=ccs_value->getCString();
						if(str.substr(0,3)=="use"){
							string valueListStr=str.substr(3,-1);
							vector<float> valueList=strToValueList(valueListStr);
							assert((int)valueList.size()==2);
							float dix=valueList[0];
							float diy=valueList[1];
							mat_polygonCoveredTileSet[i+diy][j+dix].push_back(Cij(i,j));
						}
					}
				}
			}
		}

		//生成myObjs

		CCSpriteBatchNode*batchNode=CCSpriteBatchNode::createWithTexture(layer->getTexture());//此batchNode用于存放非边缘块
		tiledSceneRootNode->addChild(batchNode);

		for(int i=0;i<mapSize.height;i++)
		{
			for(int j=0;j<mapSize.width;j++)
			{	
				if(mat_isOnEdge[i][j]==true){//是边缘块		
					CCPoint gridxy(j,i);
					int grid=layer->tileGIDAt(gridxy);
					CCDictionary* poperDic=(CCDictionary*)map->propertiesForGID(grid);
					CCSprite*sprite=layer->tileAt(ccp(j,i));
					//----将sprite做成myObj
					CmyObj*pmyObj=CmyObj::create(world);
					CCSize s=sprite->getContentSize();
					CCPoint p=sprite->convertToWorldSpace(ccp(0,0));
					//生成多边形
					vector<b2Vec2> polygon;
					bool polygonGot=false;
					if(poperDic!=NULL){
						CCObject*ccobj=poperDic->objectForKey("polygon");
						if(ccobj!=NULL){
							CCString *ccs_value=(CCString*)ccobj;
							string str=ccs_value->getCString();
							if(str.substr(0,3)=="use")continue;
							vector<float> valueList=strToValueList(str);
							int nvalue=(int)valueList.size();
							for(int k=0;k<nvalue;k+=2){
								float x=valueList[k];
								float y=valueList[k+1];
								x*=tileSize.width/PTM_RATIO;
								y*=tileSize.height/PTM_RATIO;
								b2Vec2 v=b2Vec2(x,y);
								polygon.push_back(v);
							}//得到polygon
							polygonGot=true;
						}
					}
					if(polygonGot==false){//直接生成矩形
						if((int)polygon.size()!=0){
							cout<<"error:polygon.size()!=0"<<endl;
							exit(0);
						}
						float w=tileSize.width/PTM_RATIO;
						float h=tileSize.height/PTM_RATIO;
						b2Vec2 v0=b2Vec2(0,0);
						b2Vec2 v1=b2Vec2(w,0);
						b2Vec2 v2=b2Vec2(w,h);
						b2Vec2 v3=b2Vec2(0,h);
						polygon.push_back(v0);
						polygon.push_back(v1);
						polygon.push_back(v2);
						polygon.push_back(v3);
					
					}
					b2Filter filter;
					{
						filter.categoryBits=1;
						filter.maskBits=65535;
						filter.groupIndex=0;
					}
					pmyObj->create_pb2Body_polygon(polygon,b2_staticBody,0.5,&filter);
					pmyObj->pb2Body->SetTransform(b2Vec2(p.x/PTM_RATIO ,p.y/PTM_RATIO),0);
					
					//----用sprite生成myObj的sprite
					//求pmyObj的polygon覆盖除自身外哪些格子
					vector<Cij> polygonCoveredTileSet=mat_polygonCoveredTileSet[i][j];
					//将自身也加入其中
					polygonCoveredTileSet.push_back(Cij(i,j));
					int nCoveredTile=(int)polygonCoveredTileSet.size();
					//将polygonCoveredTileSet中所有格子的sprite添加为myObj的子节点(由于这些sprite已通过map添加到了场景，所以不能重复添加，只能制作副本再添加)
					CCSpriteBatchNode*batchNode_small=CCSpriteBatchNode::createWithTexture(layer->getTexture());
					pmyObj->addChild(batchNode_small);
					pmyObj->set_showb2Body(showb2BodyWireFrame);
					pmyObj->set_showSprite(false);
					for(int k=0;k<nCoveredTile;k++){
						int I=polygonCoveredTileSet[k].i;
						int J=polygonCoveredTileSet[k].j;
						CCSprite*sprite=layer->tileAt(ccp(J,I));
						if(sprite==NULL)continue;
						CCSprite*_sprite=CCSprite::create();
						_sprite->setTexture(sprite->getTexture());
						_sprite->setTextureRect(sprite->getTextureRect());
						_sprite->setAnchorPoint(sprite->getAnchorPoint());
						//求sprite相对于body的坐标
						b2Vec2 bodyPos_inWorld_box2d=pmyObj->pb2Body->GetPosition();
						CCPoint bodyPos_inWorld(bodyPos_inWorld_box2d.x*PTM_RATIO,bodyPos_inWorld_box2d.y*PTM_RATIO);
						CCPoint spritePos_inWorld=sprite->getPosition()+map->getPosition();
						CCPoint offset_spriteRelativeToBody=spritePos_inWorld-bodyPos_inWorld;
						_sprite->setPosition(offset_spriteRelativeToBody);//转化为相对于
						batchNode_small->addChild(_sprite);
					}
					tiledSceneRootNode->addChild(pmyObj);
				}else{//不是边缘块
					if(mat[i][j]){
						CCSprite*sprite=layer->tileAt(ccp(j,i));
						assert(sprite);
						//由于sprite已通过map加入到了场景，所以不能重复添加，只能复制一份再添加
						CCSprite*_sprite=CCSprite::create();
						_sprite->setTexture(sprite->getTexture());
						_sprite->setTextureRect(sprite->getTextureRect());
						_sprite->setAnchorPoint(sprite->getAnchorPoint());
						_sprite->setPosition(sprite->getPosition()+map->getPosition());
						batchNode->addChild(_sprite);
					}
				}

			}
		}
		//map已经没用了，销毁map
		map->removeFromParentAndCleanup(true);
		return tiledSceneRootNode;
	}

};
#endif /* defined(__mybox2dtest__tiledSceneLoader__) */
