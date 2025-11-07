void mainImage(out vec4 fragColor, in vec2 fragCoord);

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 sc) {

  // color place holder to pass into mainImage
  vec4 col = vec4(0, 0, 0, 1);

  // now it is shadertoy compatible, lol
  mainImage(col, sc.xy);

  return col;
}

/**********-------------------------------
 * YOUR CODE STARTS HERE
 *------------------------------**********/
uniform float iTime;
uniform vec4 iMouse;
uniform vec2 iDelta;
uniform vec3 iResolution;

// HELPERS
vec3 rgb(float r, float g, float b) { return vec3(r, g, b) / 255; }

// MAP

// RAY MARCHER
vec3 march_ray(in vec3 ro, in vec3 rd) { return vec3(1.0, 0, 0); }

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  // aspect ratio
  float AR = iResolution.x / iResolution.y;

  // uv setup
  vec2 uv = (fragCoord / iResolution.xy) * 2.0 - 1.0;
  uv *= vec2(AR, -1);

  // mouse setup
  vec2 mouse = (iMouse.xy / iResolution.xy) * 2.0 - 1.0;
  mouse *= vec2(AR, -1);

  // camera setup
  vec3 camera_position = vec3(0, 0, 0);
  vec3 ro = camera_position;
  vec3 rd = vec3(uv, -1.0);

  fragColor = vec4(march_ray(ro, rd), 1.0);
}
