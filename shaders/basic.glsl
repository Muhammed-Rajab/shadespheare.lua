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

void mainImage(out vec4 fragColor, in vec2 fragCoord) {

  vec2 uv = (fragCoord / iResolution.xy) * 2.0 - 1.0;

  fragColor = vec4(uv, 0.0, 1.0);
}
