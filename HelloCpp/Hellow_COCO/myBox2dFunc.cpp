//
//  myBox2dFunc.cpp
//  mybox2dtest
//
//  Created by apple on 13-7-23.
//
//

#include "myBox2dFunc.h"
b2Vec2 getAveragePoint(const vector<b2Vec2>&b2PointList){//获得均值点
	int npoint=b2PointList.size();
	assert(npoint!=0);
	b2Vec2 c(0,0);//一定要初始化，否则会是随机值
	for(int i=0;i<npoint;i++){
		const b2Vec2&v=b2PointList[i];
		c+=v;
	}
	c*=1.0/npoint;//得到wc
	return c;
}
b2AABB getAABB(b2Shape*shape,const b2Transform&transform){
	b2AABB aabb;
	int32 childIndex = 0;
	shape->ComputeAABB(&aabb, transform, childIndex);  
	return aabb;
}
int getFixtureCount(b2Body*body){
	int count=0;
	for (b2Fixture* f =body->GetFixtureList(); f; f = f->GetNext())
	{
		count++;
	}
	return count;
}
b2Fixture* getFixtureAt_backWards(b2Body*body,int index_backWards){//获得fixtureList中倒数第index个fixture
	//求fixture个数
	//b2Body类有m_fixtureCount成员变量，但没有提供访问接口,所以我们还是自己求吧
	const int fixtureCount=getFixtureCount(body);
	const int index_forwards=fixtureCount-1-index_backWards;
	int i=0;
	for (b2Fixture* f =body->GetFixtureList(); f; f = f->GetNext())
	{
		if(i==index_forwards)return f;
		i++;
	}
	return NULL;

}
b2BodyType bodyTypeStrTobodyTypeValue(string bodyTypeStr){
	if(bodyTypeStr=="staticBody"){
		return b2_staticBody;
	}else if(bodyTypeStr=="kinematicBody"){
		return b2_kinematicBody;
	}else if(bodyTypeStr=="dynamicBody"){
		return b2_dynamicBody;
	}else{
		cout<<"error：未知bodyTypeStr:"<<bodyTypeStr<<endl;
		system("pause");
		exit(0);
	}

}
void splitPolygonShapeWithHoriLine(b2PolygonShape&shape,b2Transform transform,float H_horiLine,
                                   bool&upperShapeGot,bool&lowerShapeGot,
                                   b2PolygonShape&upperShape,b2PolygonShape&lowerShape){//使用水平直线切割shape
    

    //判断是否为polygon shape
    if(shape.GetType()!=b2Shape::e_polygon){
        cout<<"error:shape类型不是e_polygon!"<<endl;
        exit(0);
    }
    //求shape的aabb
    b2AABB aabb;
    {
        int32 childIndex = 0;
        shape.ComputeAABB(&aabb, transform, childIndex);
  //      cout<<"aabb range:"<<aabb.lowerBound.x<<" "<<aabb.upperBound.x<<endl;
    }
    //水平线与shape是否相交
    bool intersect=true;
    //求左交点
    b2Vec2 hitPoint_left;
    bool hit_left;
    const float margin=1.0;
    {
        b2Vec2 p1(aabb.lowerBound.x-margin ,H_horiLine);
        b2Vec2 p2(aabb.upperBound.x+margin,H_horiLine);
        b2RayCastInput input;
        input.p1=p1;
        input.p2=p2;
        input.maxFraction =1;;
        int32 childIndex = 0;
        b2RayCastOutput output;
        hit_left = shape.RayCast(&output, input, transform, childIndex);
        if (hit_left){
            hitPoint_left = input.p1 + output.fraction *(input.p2-input.p1);
        }
    }
    if(hit_left==false)intersect=false;
    //求右交点
    b2Vec2 hitPoint_right;
    bool hit_right;
    if(intersect){
        b2Vec2 p1(aabb.upperBound.x+margin,H_horiLine);
        b2Vec2 p2(aabb.lowerBound.x-margin,H_horiLine);
        b2RayCastInput input;
        input.p1=p1;
        input.p2=p2;
        input.maxFraction = 1;
        int32 childIndex = 0;
        b2RayCastOutput output;
        hit_right = shape.RayCast(&output, input, transform, childIndex);
        if (hit_right){
            hitPoint_right = input.p1 + output.fraction *(input.p2-input.p1);
        }
        if(hit_right==false)intersect=false;
    }//得到intersect
 //   cout<<"hit_left,hit_right:"<<hit_left<<" "<<hit_right<<endl;
    if(intersect==false){//如果不相交
        //判断shape在水平线之上还是之下
        b2Vec2 shapeCentroid_world=b2Mul(transform, shape.m_centroid);//注意要转到世界空间
        if(shapeCentroid_world.y>H_horiLine){//在之上
            upperShape=shape;
            upperShapeGot=true;
            lowerShapeGot=false;
        }else{//在之下
            lowerShape=shape;
            lowerShapeGot=true;
            upperShapeGot=false;
        }
    }else{//如果相交
        //将shape分裂成上下两部分
        vector<b2Vec2> vlist_upper1;
        vector<b2Vec2> vlist_upper2;//辅助
        vector<b2Vec2> vlist_lower1;
        vector<b2Vec2> vlist_lower2;//辅助
        int nv=shape.GetVertexCount();
        bool isUpperVertex=false;//是否为upper节点
        for(int i=0;i<nv;i++){
            b2Vec2 v=shape.GetVertex(i);
            v=b2Mul(transform, v);//转化到世界
            bool isUpperVertex_f=isUpperVertex;
            isUpperVertex=v.y>H_horiLine;
            if(i!=0&&isUpperVertex_f!=isUpperVertex){//如果isUpperVertex发生变化（必须加i!=0的判断，因为首个顶点是绝不可能发生变化的）
                if(isUpperVertex==true){//如果是进入上方
                    //如果vlist_upper1为空，则将v加入到vlist_upper1，否则应加入到vlist_upper2
                    if(vlist_upper1.empty()){//将v加入到vlist_upper1
                        vlist_upper1.push_back(v);
                    }else{//将v加入到vlist_upper2
                        vlist_upper2.push_back(v);
                    }
                }else{//如果是进入下方
                    //如果vlist_lower1为空，则将v加入到vlist_lower1，否则应加入到vlist_lower2
                    if(vlist_lower1.empty()){//将v加入到vlist_lower1
                        vlist_lower1.push_back(v);
                    }else{//将v加入到vlist_lower2
                        vlist_lower2.push_back(v);
                    }
                }
            }else{//如果isUpperVertex没发生变化
                if(isUpperVertex){
                    //如果vlist_upper2为空，则加入到vlist_upper1，如果vlist_upper2不为空，则加入到vlist_upper2
                    if(vlist_upper2.empty()){
                        vlist_upper1.push_back(v);
                    }else{
                        vlist_upper2.push_back(v);
                    }
                }else{
                    //如果vlist_lower2为空，则加入到vlist_lower1，如果vlist_lower2不为空，则加入到vlist_lower2
                    if(vlist_lower2.empty()){
                        vlist_lower1.push_back(v);
                    }else{
                        vlist_lower2.push_back(v);
                    }
                }
            }
        }//得到vlist_upper1,vlist_upper2,vlist_lower1,vlist_lower2
        //vlist_upper=[hitPoint_right,vlist_upper2,vlist_upper1,hitPoint_left]
    //    cout<<(int)vlist_upper1.size()<<" "<<(int)vlist_upper2.size()<<endl;
        vector<b2Vec2> vlist_upper;
        {
            vlist_upper.push_back(hitPoint_right);
            int nv2=(int)vlist_upper2.size();
            for(int i=0;i<nv2;i++){
                vlist_upper.push_back(vlist_upper2[i]);
            }
            int nv1=(int)vlist_upper1.size();
            for(int i=0;i<nv1;i++){
                vlist_upper.push_back(vlist_upper1[i]);
            }
            vlist_upper.push_back(hitPoint_left);
  
        }//得到vlist_upper
        //vlist_lower=[hitPoint_left,vlist_lower2,vlist_lower1,hitPoint_right]
        vector<b2Vec2> vlist_lower;
        {
            vlist_lower.push_back(hitPoint_left);
            int nv2=(int)vlist_lower2.size();
            for(int i=0;i<nv2;i++){
                vlist_lower.push_back(vlist_lower2[i]);
            }
            int nv1=(int)vlist_lower1.size();
            for(int i=0;i<nv1;i++){
                vlist_lower.push_back(vlist_lower1[i]);
            }
            vlist_lower.push_back(hitPoint_right);
        }//得到vlist_lower
   //     cout<<"vlist_upper:"<<(int)vlist_upper.size()<<endl;
   //     cout<<"vlist_lower:"<<(int)vlist_lower.size()<<endl;
        //将vlist_upper和vlist_lower中的坐标均转化为shape局部坐标
        {
            int nv_upper=(int)vlist_upper.size();
            for(int i=0;i<nv_upper;i++){
                vlist_upper[i]=b2MulT(transform, vlist_upper[i]);
            }
            int nv_lower=(int)vlist_lower.size();
            for(int i=0;i<nv_lower;i++){
                vlist_lower[i]=b2MulT(transform, vlist_lower[i]);
            }
        }
        //移除相邻的重合点
        {
            const float eps=0.001;
            int nv_upper=(int)vlist_upper.size();
            for(int i=0;i<nv_upper;i++){
                b2Vec2&v=vlist_upper[i];
                b2Vec2&vf=vlist_upper[(i-1+nv_upper)%nv_upper];
                if(fabsf(v.x-vf.x)<eps&&fabsf(v.y-vf.y)<eps){//v与vf相等
                    //删除v
                    vlist_upper.erase(vlist_upper.begin()+i);
                    i--;//下轮i还在此位置
                    nv_upper--;//不要忘了这句
                }
            }
            int nv_lower=(int)vlist_lower.size();
            for(int i=0;i<nv_lower;i++){
                b2Vec2&v=vlist_lower[i];
                b2Vec2&vf=vlist_lower[(i-1+nv_lower)%nv_lower];
                if(fabsf(v.x-vf.x)<eps&&fabsf(v.y-vf.y)<eps){//v与vf相等
                    //删除v
                    vlist_lower.erase(vlist_lower.begin()+i);
                    i--;//下轮i还在此位置
                    nv_lower--;//不要忘了这句
                }
            }
        }

        //制作返回结果
        if((int)vlist_upper.size()>=3&&(int)vlist_upper.size()<=b2_maxPolygonVertices){
            upperShapeGot=true;
            upperShape.Set(&vlist_upper[0], (int)vlist_upper.size());
        }else{
            upperShapeGot=false;
        }
        if((int)vlist_lower.size()>=3&&(int)vlist_lower.size()<=b2_maxPolygonVertices){
            lowerShapeGot=true;
            lowerShape.Set(&vlist_lower[0], (int)vlist_lower.size());
        }else{
            lowerShapeGot=false;
        }

  

    }
    
}
