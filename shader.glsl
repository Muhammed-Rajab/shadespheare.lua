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

    vec3  c = vec3(mouse.xy, 0);
    float r = 0.25 * abs(sin(iTime * 2.0));
    // float r = 0.25;
    float d = length(vec3(uv, 0.0) - c) - r;

    if (d >= r) {
      return vec4(1.0);
    }
    return vec4(0.0);
}
