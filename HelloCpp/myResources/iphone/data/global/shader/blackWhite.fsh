

#ifdef GL_ES
precision mediump float; //如果是opengl ES（移动平台），则指定精度全用mediump，这样就不用单独为每个变量指定精度了
#endif

uniform vec4 basicFragColor; 
varying vec2 v_texCoord;

uniform sampler2D CC_Texture0;


void main() {

    //float time = CC_Time[1];
	vec4 texColor = texture2D(CC_Texture0, v_texCoord);
	float gray=0.11*texColor.r+0.59*texColor.g+0.3*texColor.b;
	gl_FragColor = vec4(gray,gray,gray,texColor.a)*basicFragColor;
}

