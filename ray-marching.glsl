uniform float iTime;
uniform vec2  iResolution;
uniform vec4  iMouse;
uniform vec2  iDelta;

float sdfSphere(in vec3 p, in vec3 c, float r){
  return length(p - c) - r;
}

float map(in vec3 p) {

  float displacement_0 = sin(5.0 * p.x + iTime) * sin(5.0 * p.y - iTime) * sin(5.0 * p.z + iTime) * 0.25;
  float sphere_0 = sdfSphere(p, vec3(0.0, 0.0, -2), 1.0) + displacement_0;

  return sphere_0;
}

vec3 calculate_normal(in vec3 p)
{
    const vec3 small_step = vec3(0.001, 0.0, 0.0);

    float gradient_x = map(p + small_step.xyy) - map(p - small_step.xyy);
    float gradient_y = map(p + small_step.yxy) - map(p - small_step.yxy);
    float gradient_z = map(p + small_step.yyx) - map(p - small_step.yyx);

    vec3 normal = vec3(gradient_x, gradient_y, gradient_z);

    return normalize(normal);
}

vec3 rgb(float r, float g, float b) {
  return vec3(r, g, b) / 255;
}


vec3 ray_march(in vec3 ro, in vec3 rd) {
    float total_distance_travelled = 0.0;
    float NUM_MAX_STEPS = 128;
    float MIN_HIT_DISTANCE = 0.001;
    float MAX_TRACE_DISTANCE = 1000.0;

    for (int  i = 0; i < NUM_MAX_STEPS; i += 1) {

      vec3 current_pos = ro + total_distance_travelled * rd;


      float distance_to_closest = map(current_pos);

      if (distance_to_closest <= MIN_HIT_DISTANCE) {


        vec3 normal = calculate_normal(current_pos);

        vec3 light_pos = vec3(0, 3, -2);
        vec3 dir_to_light = normalize(current_pos - light_pos);

        float diff_intensity = max(0.0, dot(normal, dir_to_light));

        // return (normal * 0.5 + 0.5) * diff_intensity;

        return rgb(255, 105, 180) * diff_intensity;

      }

      if (total_distance_travelled >  MAX_TRACE_DISTANCE) {
        break;
      }

      total_distance_travelled += distance_to_closest;

    }

    return vec3(1.0, 0.922, 0.816);
}

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 sc) {

  // uv coordinate setup
  vec2 uv = (sc / iResolution) * 2.0 - 1.0;
  float AR = iResolution.x / iResolution.y;
  uv *= vec2(AR, 1);

  // mouse coordinate setup
  vec2 mouse = (iMouse.xy / iResolution) * 2.0 - 1.0;
  mouse *= vec2(AR, 1);

  // camera setup
  vec3 camera_position = vec3(0.0, 0.0, 0.0);
  vec3 ro = camera_position;
  vec3 rd = vec3(uv, -1.0);

  vec3 col = ray_march(ro, rd);

  return vec4(col, 1.0);
}
