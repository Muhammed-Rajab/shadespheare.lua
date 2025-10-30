uniform float iTime;
uniform vec2  iResolution;
uniform vec4  iMouse;
uniform vec2  iDelta;

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 sc) {

  // uv coordinate setup
  vec2 uv = (sc / iResolution) * 2.0 - 1.0;
  float AR = iResolution.x / iResolution.y;
  uv *= vec2(AR, -1);

  // mouse coordinate setup
  vec2 mouse = (iMouse.xy / iResolution) * 2.0 - 1.0;
  mouse *= vec2(AR, -1);

  uv.x = sin(uv.x + iTime);
  uv.y += 1.25;


  vec3 col = vec3(uv.x, 0.0, uv.y);
  return vec4(col, 1.0);
}
