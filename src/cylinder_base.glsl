#define MAX_STEPS 1000
#define MAX_DIST 200.
#define SURF_DIST .001
#define TAU 6.283185

const float bandHeight = .5;
const float doubleBH = bandHeight * 2.;
const float squareBH = bandHeight * bandHeight;

const float pinSpacing = 5.;
const float pinMinHeight = 0.;
const float pinMaxHeight = .12;
const float tolerance = .01;

const float brickL = .2;
const float brickW = .1;

const vec2 cylinderA = vec2(-.5*brickL,0);
const vec2 cylinderB = vec2(.5*brickL,0);

const vec4 planeMain = vec4(0.,1.,0.,0);
const vec4 planeSecA = vec4(-1.0,0.,0.,.5*brickL);
const vec4 planeSecB = vec4(1.0,0.,0.,.5*brickL);

const vec4 planeBottom = vec4(0.,0.,-1.,pinMinHeight);
const vec4 planeTop = vec4(0.,0.,1.,pinMaxHeight);

const vec4 b_pln = vec4(.0, 0., 1., 10.);
const vec4 b_pln_ref = vec4(.0, 0., 1., 9.0);

const float backgroundD = 50.;
const vec3 backgroundColor = vec3(0.07058823529411765, 0.0392156862745098, 0.5607843137254902);

float intersectSDF(float distA, float distB) {
    return max(distA, distB);
}
 
float unionSDF(float distA, float distB) {
    return min(distA, distB);
}
 
float differenceSDF(float distA, float distB) {
    return max(distA, -distB);
}

float sdPlane(vec3 p, vec4 pln){
    return dot(p,pln.xyz) - pln.w;
}

mat2 Rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

float sdCylinder( vec3 p, vec2 c, float th )
{
  return length(p.xz-c.xy)-th;
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
    float d_m=abs(sdPlane(p, planeMain))-brickW;
    float d_sa=sdPlane(p, planeSecA);
    float d_sb=sdPlane(p, planeSecB);

    float d=d_m;
    // float d=intersectSDF(intersectSDF(d_m, d_sa), d_sb);

    float d_ca=sdCylinder(p, cylinderA, brickW);
    float d_cb=sdCylinder(p, cylinderB, brickW);

    // d=unionSDF(unionSDF(d, d_ca), d_cb);

    float d_t=sdPlane(p, planeTop);
    float d_b=sdPlane(p, planeBottom);

    // d=intersectSDF(intersectSDF(d, d_t), d_b);

    return d;
}

float GetDist(vec3 p) {
    // return sdCookie(p);
    return sdCookie(p);
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
    ro.yz *= Rot(-m.z + .4);
    ro.xz *= Rot(5.3 + m.x * TAU);

    vec3 rd = R(uv, ro, vec3(0), .58);

    float d = RayMarch(ro, rd);
    vec3 n;
    if (d < backgroundD) {
        vec3 p = ro + d*rd;
        n = vec3(.5) - GetNormal(p) * .5;
    } else {
        n = backgroundColor;
    }
    

    fragColor = vec4(n, 1.);
}