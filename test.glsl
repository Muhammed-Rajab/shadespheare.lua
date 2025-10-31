uniform float iTime;
uniform vec4  iMouse;
uniform vec2  iDelta;
uniform vec2  iResolution;

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 sc) {
	vec2 uv = (sc / iResolution) * 2.0 - 1.0;
	vec3 col = vec3(uv.x, sin(iTime), uv.y);
	return vec4(col, 1.0);
}
