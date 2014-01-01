

#ifdef GL_ES
precision mediump float;
#endif

varying vec2 v_texCoord;

uniform sampler2D CC_Texture0;

uniform float myAlpha;

void main() {
    vec4 texColor=texture2D(CC_Texture0, v_texCoord);
    gl_FragColor=vec4(texColor.rgb*2.0,texColor.a*myAlpha);
}

