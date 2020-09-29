
attribute vec4 position;
attribute vec2 inputTextureCoordinate;

varying vec2 textureCoordinate;

void main()
{
    vec4 p = position;
    p.x = -p.x;
    gl_Position = p;
    textureCoordinate = inputTextureCoordinate;
}
