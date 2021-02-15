#define MAX_STEPS 1000
#define MAX_DIST 200.
#define SURF_DIST .001
#define TAU 6.283185

const float bandHeight = .5;
const float doubleBH = bandHeight * 2.;
const float squareBH = bandHeight * bandHeight;

const float pinMinHeight = 0.;
const float pinMaxHeight = 2.;
const float tolerance = .01;

const vec2 pinAngle=vec2(sin(.5), cos(.5));
const float pinBottomRadius = 2.;
const float pinTopRadius = 1.0;
const float pinSpacing = 2.;
const vec2 pinA = vec2(-pinSpacing,0);
const vec4 pinABottom = vec4(.0, 0., -1., pinMinHeight);
const vec4 pinATop = vec4(.0, 0., 1., pinMaxHeight);
const vec3 pinAScale = vec3(
    pinMinHeight,
    (pinMaxHeight-pinMinHeight)/(pinTopRadius-pinBottomRadius),
    pinBottomRadius
);

const vec4 b_pln = vec4(.0, 0., 1., 10.);
const vec4 b_pln_ref = vec4(.0, 0., 1., 9.0);

float sdPlane(vec3 p, vec4 pln){
    return dot(p,pln.xyz) - pln.w;
}

mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}


float sdCone( vec3 p, vec2 c, float h )
{
  float q = length(p.xz);
  return max(dot(c.xy,vec2(q,p.y)),-h-p.y);
}

float smin(float a, float b, float k) {
    float h = clamp(.5  + .5 * (b - a) / k, .0, 1.);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float sdBands(vec3 p) {
    float val = mod(p.z, doubleBH);
    val -= bandHeight;
    val = sqrt(squareBH - val * val);
    return -val;
}

float sdGyroid(vec3 p, float scale) {
    p *= scale;
    float d = dot(sin(p), cos(p.yzx) );
    // float d = abs(dot(sin(p), cos(p.yzx) ) + THICKNESS) ;
    // float d = abs(dot(sin(p), cos(p.yzx))+bias)-thickness;
    // d += 3.0;
    d *= .3333;
	return d;
}

float sdCookie(vec3 p) {
    float d_b=sdPlane(p, pinABottom);
    float d_t=sdPlane(p, pinATop);
    float d_g=sdGyroid(p, 5.);
    return min(min(d_b, d_g), d_t);
}

float GetDist(vec3 p) {
    // return sdCookie(p);
    return sdCone(p, pinAngle, pinMaxHeight);
}

float RayMarch(vec3 ro, vec3 rd) {
    float d0 = 0.;

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d0;
        float dS = GetDist(p) * .1;
        d0 += dS;

        if (d0 > MAX_DIST || dS < SURF_DIST) break;
    }

    return d0;
}
vec3 GetNormal(vec3 p) {
	float d = GetDist(p);
    vec2 e = vec2(.01, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx)
    );
    
    return -normalize(n);
    // return abs(normalize(n) );
}

vec3 R(vec2 uv, vec3 p, vec3 l, float z, vec3 up) {
    vec3 f = normalize(l-p),
        r = normalize(cross(up, f)),
        u = cross(f,r),
        c = p+f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i-p);
    return d;
}

float GetLight(vec3 p) {
    vec3 lightPos = vec3(0,0,0);
    vec3 l = normalize(lightPos - p);
    vec3 n = GetNormal(p);

    float dif = clamp( dot(n, l) * .5 + .5, .0, 1.);
    float d = RayMarch(p + n * SURF_DIST * 2., l);
    if (p.y < .01 && d < length(lightPos - p)) dif *= .5;

    return dif;
}

vec3 R(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l - p),
        r = normalize(cross(vec3(0, 1, 0), f)),
        u = cross(f, r),
        c = p + f * z,
        i = c + uv.x * r + uv.y * u,
        d = normalize(i - p);
    return d;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = (fragCoord - .5 * iResolution.xy) / iResolution.y;
    vec2 m = iMouse.xy/ iResolution.xy;

    // vec3 col = vec3(GetNormal(fragCoord) );

    vec3 ro = vec3(10., 0, 0.);
    ro.yz *= Rot(-m.y + .4);
    ro.xz *= Rot(5.3 + m.x * TAU);

    vec3 rd = R(uv, ro, vec3(0), .58);

    float d = RayMarch(ro, rd);
    vec3 p = ro + d*rd;
    
    vec3 n = vec3(.5) - GetNormal(p) * .5;

    fragColor = vec4(n, 1.);
}