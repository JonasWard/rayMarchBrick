#define MAX_STEPS 1000
#define MAX_DIST 200.
#define SURF_DIST .001
#define TAU 6.283185
#define GLOBALSCALE .4

const float bandHeight = .02;
const float doubleBH = bandHeight * 2.;
const float squareBH = bandHeight * bandHeight;

const float pinSpacing = 2.;
const float pinHeight = 3.;
const float tolerance = .01;
const float pinBottomR = .2;
const float pinTopR = .1;

const float brickL = 2.;
const float brickW = 1.;
const float brickH = 2.;

const vec3 pinAStart = vec3(-.5*pinSpacing,-.5*brickL,0);
const vec3 pinAEnd = vec3(-.5*pinSpacing,pinHeight-.5*brickL,0);
const vec3 pinBStart = vec3(.5*pinSpacing,-.5*brickL,0);
const vec3 pinBEnd = vec3(.5*pinSpacing,pinHeight-.5*brickL,0);

const vec2 cylinderA = vec2(-.5*brickL,0);
const vec2 cylinderB = vec2(.5*brickL,0);

const vec4 planeMain = vec4(0.,0.,1.,0);
const vec4 planeSecA = vec4(-1.0,0.,0.,.5*brickL);
const vec4 planeSecB = vec4(1.0,0.,0.,.5*brickL);

const vec4 planeBottom = vec4(0.,-1.,0.,.5*brickH);
const vec4 planeTop = vec4(0.,1.,0,.5*brickH);

const vec4 b_pln = vec4(.0, 0., 1., 10.);
const vec4 b_pln_ref = vec4(.0, 0., 1., 9.0);

const float backgroundD = 50.;
const vec3 backgroundColor = vec3(0.07058823529411765, 0.0392156862745098, 0.5607843137254902);
const vec3 objColor = vec3(0.6627450980392157, 0.06666666666666667, 0.00392156862745098);

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

float sdLine(vec2 p, vec2 a, vec2 b) {
    float d=distance(a, b);
    float l2 = d*d;
    if(l2 == 0.0) return d;
    
    vec2 b_a = b-a;
    float t = clamp(dot(p - a, b_a) / l2, 0., 1.);
    vec2 j = a + t * (b_a);
    
    return distance(p, j);
}

float sdLine(vec3 p, vec2 a, vec2 b) {
    return sdLine(p.xz, a, b);
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
    float val = mod(p.y, doubleBH);
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

float sdCappedCone(vec3 p, vec3 a, vec3 b, float ra, float rb)
{
    float rba  = rb-ra;
    float baba = dot(b-a,b-a);
    float papa = dot(p-a,p-a);
    float paba = dot(p-a,b-a)/baba;
    float x = sqrt( papa - paba*paba*baba );
    float cax = max(0.0,x-((paba<0.5)?ra:rb));
    float cay = abs(paba-0.5)-0.5;
    float k = rba*rba + baba;
    float f = clamp( (rba*(x-ra)+paba*baba)/k, 0.0, 1.0 );
    float cbx = x-ra - f*rba;
    float cby = paba - f;
    float s = (cbx < 0.0 && cay < 0.0) ? -1.0 : 1.0;
    return s*sqrt( min(cax*cax + cay*cay*baba,
                       cbx*cbx + cby*cby*baba) );
}

float sdCookie(vec3 p) {
    // float d_m=abs(sdPlane(p, planeMain))-brickW;
    // // float d_m=sdPlane(p, planeMain);
    // float d_sa=sdPlane(p, planeSecA);
    // float d_sb=sdPlane(p, planeSecB);

    // // float d=d_m;
    // float d=intersectSDF(intersectSDF(d_m, d_sa), d_sb);

    // float d_ca=sdCylinder(p, cylinderA, brickW);
    // float d_cb=sdCylinder(p, cylinderB, brickW);

    // d=unionSDF(unionSDF(d, d_ca), d_cb);
    float d=sdLine(p, cylinderA, cylinderB)-brickW;

    float d_g=.3*sdGyroid(p, .3*sdGyroid(p, 20.));
    d+=d_g;
    d=differenceSDF(d, d);

    float d_t=sdPlane(p, planeTop);
    float d_b=sdPlane(p, planeBottom);

    d=intersectSDF(intersectSDF(d, d_t), d_b);

    return d;
}

float GetDist(vec3 p) {
    // return sdCookie(p);
    p*=GLOBALSCALE;
    float d=sdCookie(p);
    d=unionSDF(sdCappedCone(p, pinAStart, pinAEnd, pinBottomR, pinTopR), d);
    d=unionSDF(sdCappedCone(p, pinBStart, pinBEnd, pinBottomR, pinTopR), d);

    d+=sdBands(p);
    return d*GLOBALSCALE;
}

float RayMarch(vec3 ro, vec3 rd) {
    float d0 = 0.;

    for (int i = 0; i < MAX_STEPS; i++) {
        vec3 p = ro + rd * d0;
        float dS = GetDist(p);
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
    vec2 m = 4.*iMouse.xy/ iResolution.xy;

    vec3 ro = vec3(10., -5., 0.);
    ro.yx *= Rot(-m.y*2.);
    ro.xz *= Rot(-m.x*2.);
    // ro.xz *= Rot(5.3 + m.x * TAU);

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