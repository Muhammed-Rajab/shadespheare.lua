uniform float iTime;
uniform vec2  iResolution;
uniform vec4  iMouse;
uniform vec2  iDelta;

float sdfSphere(in vec3 p, in vec3 c, float r){
  return length(p - c) - r;
}

vec3 ray_march(in vec3 ro, in vec3 rd){
  float total_distance_travelled = 0.0;
  const int NUMBER_OF_STEPS  = 32;
  const float MINIMUM_HIT_DISTANCE = 0.001;
  const float MAXIMUM_TRACE_DISTANCE = 1000.0;

  for (int i = 0; i <  NUMBER_OF_STEPS; ++i){

    vec3 current_position = ro + total_distance_travelled * rd;

    float distance_to_closest = sdfSphere(current_position, vec3(0.0), 0.3);

    if (distance_to_closest < MINIMUM_HIT_DISTANCE) {
      return vec3(1.0, 0.0, 0.0);
    }

    if (total_distance_travelled > MAXIMUM_TRACE_DISTANCE){
      break;
    }

    total_distance_travelled += distance_to_closest;
  }

  return vec3(0.0);
}

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 sc) {

  // uv coordinate setup
  vec2 uv = (sc / iResolution) * 2.0 - 1.0;
  float AR = iResolution.x / iResolution.y;
  uv *= vec2(AR, -1);

  // mouse coordinate setup
  vec2 mouse = (iMouse.xy / iResolution) * 2.0 - 1.0;
  mouse *= vec2(AR, -1);

  // camera setup
  vec3 camera_position = vec3(0.0, 0.0, -5.0);
  vec3 ro = camera_position;
  vec3 rd = vec3(uv, 1.0);


  vec3 col = ray_march(ro, rd);

  return vec4(col, 1.0);
}
