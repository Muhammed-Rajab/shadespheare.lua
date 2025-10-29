// uniform float iTime;
// uniform vec2  iResolution;
//
// vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 sc) {
//
//     // uv coordinate setup
//     vec2 uv = (sc / iResolution) * 2.0 - 1.0;
//     float AR = iResolution.x / iResolution.y;
//     uv *= vec2(AR, -1);
//
//     return vec4(uv.xy, 0.0, 1.0 );
// }
//

uniform float iTime;
uniform vec2  iResolution;

vec4 effect(vec4 color, Image tex, vec2 tex_coords, vec2 sc) {
    // normalized coordinates
    vec2 uv = (sc / iResolution.xy) * 2.0 - 1.0;
    uv.x *= iResolution.x / iResolution.y;

    // plasma pattern
    float v = 0.0;
    v += sin(uv.x * 4.0 + iTime);
    v += sin((uv.y + iTime) * 3.0);
    v += sin((uv.x + uv.y + iTime) * 4.0);
    v += cos(length(uv) * 4.0 - iTime * 2.0);

    // normalize to 0–1
    v = v / 4.0;

    // create a fun color palette
    vec3 col = 0.5 + 0.5 * cos(6.2831 * (v + vec3(.0, 0.33, 0.7)));

    return vec4(col, 1.0);
}
