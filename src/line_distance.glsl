#define squv *= iResolution.x/iResolution.y;
/*
float map( float a, float a1, float a2, float b1, float b2 ) {
    return (a - a1) / (a2 - a1) * (b2 - b1) + b1;
}
*/

float dline( vec2 p, vec2 a, vec2 b ) {
    
    //vec2 mx = mix(a, b, clamp( map(p.x, a.x, b.x, 0., 1.), 0., 1. ) );
    //vec2 my = mix(a, b, clamp( map(p.y, a.y, b.y, 0., 1.), 0., 1. ) );
    
    //return min(distance(mx, p),distance(my, p));
    
    
    //v2
    //float den = distance(a, b);
    //float num = abs( (b.y-a.y)*p.x - (b.x-a.x)*p.y + b.x*a.y - b.y*a.x );
    
    //float d = num / den;
    
    //return d;
    
    //v3
    
    /*
https://stackoverflow.com/questions/849211/shortest-distance-between-a-point-and-a-line-segment
float minimum_distance(vec2 v, vec2 w, vec2 p) {
  // Return minimum distance between line segment vw and point p
  const float l2 = length_squared(v, w);  // i.e. |w-v|^2 -  avoid a sqrt
  if (l2 == 0.0) return distance(p, v);   // v == w case
  // Consider the line extending the segment, parameterized as v + t (w - v).
  // We find projection of point p onto the line. 
  // It falls where t = [(p-v) . (w-v)] / |w-v|^2
  // We clamp t from [0,1] to handle points outside the segment vw.
  const float t = max(0, min(1, dot(p - v, w - v) / l2));
  const vec2 projection = v + t * (w - v);  // Projection falls on the segment
  return distance(p, projection);
}

	*/
    
    vec2 v = a, w = b;
    
    float l2 = pow(distance(w, v), 2.);
    if(l2 == 0.0) return distance(p, v);
    
    float t = clamp(dot(p - v, w - v) / l2, 0., 1.);
    vec2 j = v + t * (w - v);
    
    return distance(p, j);
    
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = fragCoord/iResolution.xy;
    vec2 mo = iMouse.xy / iResolution.xy;
    
    mo.x squv uv.x squv

    // Time varying pixel color
    ///vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));
    vec3 col = vec3(pow(sin(dline( uv, vec2(0.1), mo )*64.)/2.+0.5, 0.09));

    // Output to screen
    fragColor = vec4(col,1.0);
}