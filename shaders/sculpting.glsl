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
extern Image myTexture;
extern Image myBG;

// DEFINITIONS
float map(in vec3 pos, out vec3 color);
float map(vec3 pos);

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

float sdRoundBox(vec3 p, vec3 b, float r) {
  vec3 q = abs(p) - b + r;
  return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

float sdRoundedCylinder(vec3 p, float ra, float rb, float h) {
  vec2 d = vec2(length(p.xz) - ra + rb, abs(p.y) - h + rb);
  return min(max(d.x, d.y), 0.0) + length(max(d, 0.0)) - rb;
}

// NORMAL
vec3 calculate_normal(in vec3 p) {
  const vec3 eps = vec3(0.001, 0.0, 0.0);

  float dx = map(p + eps.xyy) - map(p - eps.xyy);
  float dy = map(p + eps.yxy) - map(p - eps.yxy);
  float dz = map(p + eps.yyx) - map(p - eps.yyx);

  return normalize(vec3(dx, dy, dz));
}

// SHADOW
float shadow(in vec3 ro, in vec3 rd, float mint, float maxt, float k) {
  float t = mint;
  float res = 1.0;
  for (int i = 0; i < 128 && t < maxt; i++) {
    float h = map(ro + rd * t);
    res = min(res, k * h / t); // soft attenuation
    if (h < 0.001)
      return 0.0;
    t += h;
  }
  return clamp(res, 0.0, 1.0);
}

// OPERATIONS
vec2 smin(float a, float b, float k) {
  k *= 0.5;
  float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
  float d = mix(b, a, h) - k * h * (1.0 - h);
  return vec2(d, h); // h can be used as blend factor
}

// CHECKERED COLOR
vec3 get_checkered_color(in vec3 pos, float scale) {
  float checker = mod(floor(pos.x * scale) + floor(pos.z * scale), 2.0);
  vec3 dark = vec3(0.1);
  vec3 light = vec3(9.0);

  return mix(dark, light, checker);
}

vec3 rotateX(vec3 p, float angle) {
  float c = cos(angle);
  float s = sin(angle);
  return vec3(p.x, c * p.y - s * p.z, s * p.y + c * p.z);
}

vec3 rotateY(vec3 p, float angle) {
  float c = cos(angle);
  float s = sin(angle);
  return vec3(c * p.x + s * p.z, p.y, -s * p.x + c * p.z);
}

vec3 rotateZ(vec3 p, float angle) {
  float c = cos(angle);
  float s = sin(angle);
  return vec3(c * p.x - s * p.y, s * p.x + c * p.y, p.z);
}

vec3 rotateXYZ(vec3 p, vec3 angles) {
  p = rotateX(p, angles.x);
  p = rotateY(p, angles.y);
  p = rotateZ(p, angles.z);
  return p;
}

// MAP
vec2 sphereUV(vec3 p) {
  // Convert xyz → spherical coordinates
  float u = atan(p.z, p.x) / (2.0 * 3.14159) + 0.5;
  float v = asin(p.y) / 3.14159 + 0.5;
  v = 1.0 - v; // flip this bitch
  return vec2(u, v);
}

vec3 get_color(float id, in vec3 pos) {
  // sphere 1
  if (id == 1) {
    vec2 uv = sphereUV(pos);
    vec4 tex = Texel(myTexture, uv);
    tex = pow(tex, vec4(2.2));
    return tex.rgb;
  }

  // floor 3
  if (id == 3.0) {
    return get_checkered_color(pos, 1.0);
  }

  // no id available
  return vec3(1.0);
}

float map(in vec3 pos, out vec3 color) {

  // sphere 1
  vec3 cen1 = vec3(0, 0, -2);
  vec3 p_local = pos - cen1;
  p_local = rotateXYZ(p_local, vec3(0, .5 * iTime, 0));
  vec3 p1 = p_local + cen1;
  float d1 = sdfSphere(p1, cen1, 1);
  vec3 c1 = get_color(1, p_local);

  // floor 3
  float floor = sdfPlane(pos, vec3(0, 1, 0), 1);
  vec3 c_floor = get_color(3, pos);

  // default is floor
  // float dist = floor;
  // color = c_floor;

  float dist = d1;
  color = c1;

  // sphere
  if (d1 < dist) {
    dist = d1;
    color = c1;
  }

  return dist;
}

// overload that ignores color
float map(vec3 pos) {
  vec3 dummy;
  return map(pos, dummy);
}

// RAY MARCHER
// returns color + t (distance)
vec4 march_ray(in vec3 ro, in vec3 rd) {
  // total distance travelled
  float t = 0.0;
  const float NUM_MAX_STEPS = 512;
  const float MIN_HIT_DISTANCE = 0.001;
  const float MAX_TRACE_DISTANCE = 100.0;

  // BUG: id isn't used anymore
  float object_id = -1.0;

  for (int i = 0; i < NUM_MAX_STEPS; i += 1) {
    // current position
    vec3 curr_pos = ro + rd * t;

    // distance to closest
    vec3 object_color = vec3(0);

    float d = map(curr_pos, object_color);

    if (d <= MIN_HIT_DISTANCE) {
      // calculte normal
      vec3 normal = calculate_normal(curr_pos);

      // vec3 object_color = get_color(object_id);

      // vec3 light_pos = vec3(cos(-iTime * 4.0), 0, 0);
      vec3 light_pos = vec3(0., 0, .5);
      vec3 light_dir = normalize(light_pos - curr_pos);
      // vec3 light_color = vec3(1.0, 0.8, 0.6);
      vec3 light_color = vec3(1.0);

      // ambient lighting
      float ambient = 0.1;
      vec3 ambient_color = ambient * light_color;

      // shadow
      float shadow_softness = 32.0;
      float shadow_factor =
          shadow(curr_pos + normal * 0.001, light_dir, 0.001,
                 length(light_pos - curr_pos), shadow_softness);

      // diffuse lighting
      float diffuse = max(dot(normal, light_dir), 0.0);
      vec3 diffuse_color = diffuse * light_color * shadow_factor;

      // specular lighting
      vec3 view_dir = normalize(ro - curr_pos);
      vec3 reflect_dir = reflect(-light_dir, normal);

      float shininess = 32.0;
      float specular_strength = 0.;
      float specular = pow(max(dot(view_dir, reflect_dir), 0.0), shininess) *
                       specular_strength;
      vec3 specular_color = specular * vec3(1.0);

      vec3 color =
          object_color * (ambient_color + diffuse_color) + specular_color;

      // color = color * exp(-0.2 * t);

      return vec4(color, t);
    }

    if (t > MAX_TRACE_DISTANCE) {
      break;
    }

    // updating total distance travelled
    t += d;
  }

  // // background color
  // vec3 bg1 = vec3(1.0, 1.0, 1.0);
  // vec3 bg2 = vec3(0.2, 0.4, 0.8);
  // // vec3 bg1 = rgb(255, 218, 185);
  // // vec3 bg2 = rgb(255, 105, 180);
  // vec3 bg = mix(bg1, bg2, rd.y);
  // return vec4(bg, t);
  return vec4(vec3(0.0), -1.0); // -1.0 means no hit
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
  vec3 camera_position = vec3(0, 0, 3 * abs(sin(iTime * 0.1 + radians(-45))));
  vec3 ro = camera_position;
  float fov = radians(60.0);
  vec3 rd = normalize(vec3(uv * tan(fov * 0.5), -1.0));

  vec4 result = march_ray(ro, rd);
  vec3 color = result.xyz;
  float t = result.w;

  if (t < 0.0) {

    vec2 bg_uv = fragCoord / iResolution.xy;

    vec3 bg = Texel(myBG, bg_uv).rgb;
    fragColor = vec4(bg, 1.0);

    return;
  }

  // // distance fog
  // float fog_density = 0.01;
  // float fog_near = 10.0; // start fading at distance
  // float fog_far = 20.0;  // completely faded by this distance
  // float fog_amount = smoothstep(fog_near, fog_far, t);
  // vec3 fog_color = rgb(255, 215, 230);
  // // vec3 fog_color = rgb(0, 0, 0);

  // color = mix(color, fog_color, fog_amount);

  // gamma correction
  color = pow(color, vec3(1.0 / 2.2));

  fragColor = vec4(color.xyz, 1.0);
}
