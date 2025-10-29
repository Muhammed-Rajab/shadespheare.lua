uniform float iTime;
uniform vec2  iResolution;

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 sc) {

    vec2 uv = (sc / iResolution) * 2.0 - 1.0;
    float AR = iResolution.x / iResolution.y;
    uv *= vec2(AR, -1);

    return vec4(uv, 0.0, 1.0 );
}
