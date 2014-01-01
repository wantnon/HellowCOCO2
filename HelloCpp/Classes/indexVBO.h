
#include <iostream>
using namespace std;
#include "cocos2d.h"
using namespace cocos2d;
#include "simpleClasses.h"
class CindexVBO :public CCObject
{
public:
	GLuint posBuffer ;
    GLuint texCoordBuffer ;
    GLuint indexBuffer ;
	int m_indexArrayLen;
	int m_posArrayLen;
	int m_texCoordArrayLen;
	CindexVBO(){
		posBuffer=0 ;
		texCoordBuffer=0 ;
		indexBuffer=0 ;
		m_indexArrayLen=0;
	    m_posArrayLen=0;
	    m_texCoordArrayLen=0;
	}
	virtual ~CindexVBO(){
		glDeleteBuffers(1, &posBuffer) ;
		glDeleteBuffers(1, &texCoordBuffer) ;
		glDeleteBuffers(1, &indexBuffer) ;
        
	}
	static void enableAttribArrays(){
		glEnableVertexAttribArray(kCCVertexAttrib_Position);
		glEnableVertexAttribArray(kCCVertexAttrib_TexCoords);
	}
	static void bindTexture(GLenum textureAttachPoint,GLuint texture){
		glActiveTexture(textureAttachPoint) ;
        ccGLBindTexture2D(texture) ;
	}
	void genBuffers(){
		if(posBuffer==0)glGenBuffers(1, &posBuffer);
		if(texCoordBuffer==0)glGenBuffers(1, &texCoordBuffer);
		if(indexBuffer==0)glGenBuffers(1, &indexBuffer);
	}
	void submitPos(const float posArray[],const int posArrayLen,GLenum usage){
		m_posArrayLen=posArrayLen;
		glBindBuffer(GL_ARRAY_BUFFER, posBuffer);
		glBufferData(GL_ARRAY_BUFFER, m_posArrayLen*sizeof(float), posArray, usage);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
	}
	void submitTexCoord(const float texCoordArray[],const int texCoordArrayLen,GLenum usage){
		m_texCoordArrayLen=texCoordArrayLen;
	    glBindBuffer(GL_ARRAY_BUFFER, texCoordBuffer);
		glBufferData(GL_ARRAY_BUFFER, m_texCoordArrayLen*sizeof(float), texCoordArray, usage);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
	}
	void submitIndex(const short indexArray[],const int indexArrayLen,GLenum usage){
		m_indexArrayLen=indexArrayLen;
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, m_indexArrayLen*sizeof(short), indexArray, usage);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	}
    void submitPos(const vector<Cv2> &pointList,GLenum usage){
		m_posArrayLen=((int)pointList.size())*2;
		glBindBuffer(GL_ARRAY_BUFFER, posBuffer);
		glBufferData(GL_ARRAY_BUFFER, sizeof(float)*m_posArrayLen, &pointList.front(), usage);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
	}
	void submitTexCoord(const vector<Cv2> &texCoordList,GLenum usage){
		m_texCoordArrayLen=((int)texCoordList.size())*2;
	    glBindBuffer(GL_ARRAY_BUFFER, texCoordBuffer);
		glBufferData(GL_ARRAY_BUFFER, sizeof(float)*m_texCoordArrayLen, &texCoordList.front(), usage);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
	}
	void submitIndex(const vector<CIDTriangle> &IDtriList,GLenum usage){//CIDTriangle's element must use short type
		m_indexArrayLen=((int)IDtriList.size())*3;
        if(m_indexArrayLen==0)return;
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(short)*m_indexArrayLen, &IDtriList.front(), usage);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	}
    void submitIndex(const vector<CIDLine> &IDlineList,GLenum usage){//CIDLine's element must use short type
		m_indexArrayLen=((int)IDlineList.size())*2;
        if(m_indexArrayLen==0)return;
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(short)*m_indexArrayLen, &IDlineList.front(), usage);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	}
	void setPointers(){
		//set position format
		glBindBuffer(GL_ARRAY_BUFFER, posBuffer);
		glVertexAttribPointer(kCCVertexAttrib_Position, 2, GL_FLOAT, GL_FALSE, 2*sizeof(float), 0);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
		//set texCoord format
		glBindBuffer(GL_ARRAY_BUFFER, texCoordBuffer);
		glVertexAttribPointer(kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, 2*sizeof(float), 0);
		glBindBuffer(GL_ARRAY_BUFFER, 0);
	}
	void draw(GLenum mode){
        if(m_indexArrayLen==0)return;
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
        //the third parameter of glDrawElements must be GL_UNSIGNED_SHORT or GL_UNSIGNED_BYTE
        //or there will be OpenGL error 0x0500
        //http://blog.csdn.net/zhucde/article/details/3547442
        //http://www.khronos.org/opengles/sdk/docs/man/xhtml/glDrawElements.xml
        //http://www.opengl.org/wiki/OpenGL_Error
        //here we use GL_UNSIGNED_SHORT
        glDrawElements(mode, m_indexArrayLen, GL_UNSIGNED_SHORT, 0) ;
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	}
    
};