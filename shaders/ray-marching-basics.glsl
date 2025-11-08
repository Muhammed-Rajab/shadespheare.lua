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

// DEFINITIONS
vec2 map(in vec3 pos);
vec3 calculate_norma(in vec3 p);

// HELPERS
vec3 rgb(float r, float g, float b) { return vec3(r, g, b) / 255; }
vec4 invert(in vec4 color) {
  vec4 temp_color = vec4(1.0) - color;
  temp_color.w = 1.0;
  return temp_color;
}

// SDFs
float sdfSphere(in vec3 p, in vec3 c, float r) { return length(p - c) - r; }

float sdfPlane(in vec3 p, in vec3 n, float h) {
  // h = height along normal
  return dot(p, n) + h;
}

// NORMAL
vec3 calculate_normal(in vec3 p) {
  const vec3 eps = vec3(0.001, 0.0, 0.0);

  float dx = map(p + eps.xyy).x - map(p - eps.xyy).x;
  float dy = map(p + eps.yxy).x - map(p - eps.yxy).x;
  float dz = map(p + eps.yyx).x - map(p - eps.yyx).x;

  return normalize(vec3(dx, dy, dz));
}

// SHADOW
float soft_shadow(in vec3 ro, in vec3 rd, float mint, float maxt, float w) {
  float res = 1.0;
  float ph = 1e20;
  float t = mint;
  for (int i = 0; i < 256 && t < maxt; i++) {
    float h = map(ro + rd * t).x;
    if (h < 0.001)
      return 0.0;
    float y = h * h / (2.0 * ph);
    float d = sqrt(h * h - y * y);
    res = min(res, d / (w * max(0.0, t - y)));
    ph = h;
    t += h;
  }
  return res;
}

// MAP
vec3 get_color(float id) {

  // sphere 0
  if (id == 0.0) {
    return vec3(1.0, 0, 0);
  }

  // sphere 1
  if (id == 1.0) {
    return vec3(0, 1.0, 0);
  }

  // sphere 2
  if (id == 2.0) {
    return vec3(0, 0, 1.0);
  }

  // floor 3
  if (id == 3.0) {
    return vec3(0.5);
  }

  // no id available
  return vec3(1.0);
}

vec2 map(in vec3 pos) {

  // sphere 0
  float d0 = sdfSphere(pos, vec3(0, 0, -2), 1.0);

  // sphere 1
  float d1 = sdfSphere(pos, vec3(-1.25, 0, -2), .75);

  // sphere 2
  float d2 = sdfSphere(pos, vec3(1.25, 0, -2), .75);

  // floor 3
  float d3 = sdfPlane(pos, vec3(0, 1, 0), 1);

  // find closest
  float id = 0.0;
  float dist = d0;

  if (d1 < dist) {
    dist = d1;
    id = 1.0;
  }
  if (d2 < dist) {
    dist = d2;
    id = 2.0;
  }
  if (d3 < dist) {
    dist = d3;
    id = 3.0;
  }

  return vec2(dist, id);
}

// RAY MARCHER
vec3 march_ray(in vec3 ro, in vec3 rd) {
  // total distance travelled
  float t = 0.0;
  const float NUM_MAX_STEPS = 512;
  const float MIN_HIT_DISTANCE = 0.001;
  const float MAX_TRACE_DISTANCE = 500.0;

  float object_id = -1.0;

  for (int i = 0; i < NUM_MAX_STEPS; i += 1) {
    // current position
    vec3 curr_pos = ro + rd * t;

    // distance to closest
    vec2 hit_info = map(curr_pos);
    float d = hit_info.x;
    object_id = hit_info.y;

    if (d <= MIN_HIT_DISTANCE) {
      // calculte normal
      vec3 normal = calculate_normal(curr_pos);

      vec3 object_color = get_color(object_id);

      // vec3 light_pos = vec3(cos(-iTime * 4.0), sin(-iTime * 4.0) + 1, 0);
      vec3 light_pos = vec3(1, 1, 0);
      vec3 light_dir = normalize(light_pos - curr_pos);
      // vec3 light_color = vec3(1.0, 0.8, 0.6);
      vec3 light_color = vec3(1.0);

      // ambient lighting
      float ambient = 0.1;
      vec3 ambient_color = ambient * light_color;

      // diffuse lighting
      float diffuse = max(dot(normal, light_dir), 0.0);
      vec3 diffuse_color = diffuse * light_color;

      // specular lighting
      vec3 view_dir = normalize(ro - curr_pos);
      vec3 reflect_dir = reflect(-light_dir, normal);

      float shininess = 32.0;
      float specular_strength = 1.0;
      float specular = pow(max(dot(view_dir, reflect_dir), 0.0), shininess) *
                       specular_strength;
      vec3 specular_color = specular * vec3(1.0);

      if (object_id == 3.0) { // floor
        float scale = 1.0;    // squares per unit
        float checker =
            mod(floor(curr_pos.x * scale) + floor(curr_pos.z * scale), 2.0);
        object_color *= 0.3 + 0.7 * checker; // alternate dark/light squares
      }

      vec3 color =
          object_color * (ambient_color + diffuse_color) + specular_color;

      return color;
    }

    if (t > MAX_TRACE_DISTANCE) {
      break;
    }

    // updating total distance travelled
    t += d;
  }

  // background color
  vec3 bg1 = vec3(1.0, 1.0, 1.0);
  vec3 bg2 = vec3(0.2, 0.4, 0.8);
  return mix(bg1, bg2, rd.y);
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
  vec3 camera_position = vec3(0 * sin(iTime), 0, 1);
  vec3 ro = camera_position;
  float fov = radians(60.0);
  vec3 rd = normalize(vec3(uv * tan(fov * 0.5), -1.0));

  fragColor = vec4(march_ray(ro, rd), 1.0);
}
