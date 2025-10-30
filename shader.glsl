uniform float iTime;
uniform vec2  iResolution;

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 sc) {

    // uv coordinate setup
    vec2 uv = (sc / iResolution) * 2.0 - 1.0;
    float AR = iResolution.x / iResolution.y;
    uv *= vec2(AR, -1);

    vec3  c = vec3(0, 0, 0);
    float r = 0.25 * abs(sin(iTime * 2.0));
    float d = length(vec3(uv, 0.0) - c) - r;

    if (d >= r) {
      return vec4(1.0);
    }
    return vec4(0.0);
}
