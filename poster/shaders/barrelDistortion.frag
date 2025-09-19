// scanline shader

uniform vec2 imageSize;
uniform float power;
uniform int type;

// Credit: https://prideout.net/barrel-distortion
// Modified by Source Kitty to add different types
vec2 Distort(vec2 p)
{
    float theta  = atan(p.y, p.x);
    float radius = length(p);
    radius = pow(radius, power);
    p.x = radius * cos(theta);
    p.y = radius * sin(theta);
    return 0.5 * (p + 1.0);
}

vec4 effect(vec4 color, Image tex, vec2 tc, vec2 sc) {
    vec2 xy = 2.0 * tc - 1.0;
    vec2 uv;
    float d = length(xy);
    if (type == 1){
        if (d < 1.0)
        {
            uv = Distort(xy);
        }
        else
        {
            uv = tc;
        }
    }
    else if (type == 2){
        if (d > 1.0)
        {
            uv = Distort(xy);
        }
        else
        {
            uv = tc;
        }
    }
    else{
        uv = Distort(xy);
    }
    return Texel(tex, uv);
}

// float theta  = atan(p.y, p.x);
// float radius = length(p);
// radius = pow(radius, BarrelPower);
// p.x = radius * cos(theta);
// p.y = radius * sin(theta);
// return 0.5 * (p + 1.0);
