#version 120
uniform sampler2D iChannel0;

void main()
{
	int x = int(gl_TexCoord[0].x * 512);
	int y = int(gl_TexCoord[0].y * 448);
	vec2 uv = vec2(gl_TexCoord[0].x - mod(x, 2) / 512, gl_TexCoord[0].y + mod(y + 1, 2) / 448);
	vec4 c = texture2D(iChannel0, uv);
	gl_FragColor = c;
}