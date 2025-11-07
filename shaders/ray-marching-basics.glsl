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

float sdfSphere(in vec3 p, in vec3 c, float r) { return length(p - c) - r; }

// MAP
float map(in vec3 pos) { return sdfSphere(pos, vec3(0, 0, -2), 1.0); }

// RAY MARCHER
vec3 march_ray(in vec3 ro, in vec3 rd) {
  // total distance travelled
  float t = 0.0;
  float NUM_MAX_STEPS = 256;
  float MIN_HIT_DISTANCE = 0.001;
  float MAX_TRACE_DISTANCE = 1000.0;

  for (int i = 0; i < NUM_MAX_STEPS; i += 1) {
    // current position
    vec3 curr_pos = ro + rd * t;

    // distance to closest
    float d = map(curr_pos);

    if (d <= MIN_HIT_DISTANCE) {
      // do calculations adn return color
      return vec3(1, 0, 0);
    }

    if (t > MAX_TRACE_DISTANCE) {
      break;
    }

    // updating total distance travelled
    t += d;
  }

  // background color
  return rgb(255, 255, 255);
}

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
