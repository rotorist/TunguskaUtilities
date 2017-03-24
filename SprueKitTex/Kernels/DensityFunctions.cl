// TODO: Add OpenCL kernel code here.

#define MATRIX_SIZE 3
#define SprueMin(a, b) (((a) < (b)) ? (a) : (b))
#define SprueMax(a, b) (((a) > (b)) ? (a) : (b))
#define MaxElem(a) (max(a.x, max(a.y, a.z)))

float3 MatrixMul(float3 pos, const global float4* transforms, int* shapeIndex)
{
    float4 f4 = { pos.x, pos.y, pos.z, 1.0f };
    int idx = (*shapeIndex)++;
    return (float3) { dot(transforms[idx * 3], f4), dot(transforms[idx * 3 + 1], f4), dot(transforms[idx * 3 + 2], f4) };
}

float length2(float3 a)
{ 
    return a.x * a.x + a.y * a.y + a.z * a.z;
}


float3 ClosestPoint(float3 a, float3 b, float3 point)
{ 
    float3 dir = b - a;
    return a + clamp(dot(point - a, dir) / length2(dir), 0.0f, 1.0f) * dir;
}

float SphereDensity(float3 pos, const global float* data, const global float4* transforms, int* paramIndex, int* shapeIndex)
{ 
    pos = MatrixMul(pos, transforms, shapeIndex);
    const float radius = data[(*paramIndex)];
    (*paramIndex) = (*paramIndex) + 1;
    // TODO
    return length(pos) - radius;
}


float BoxDensity(float3 pos, const global float* data, const global float4* transforms, int* paramIndex, int* shapeIndex)
{ 
    pos = MatrixMul(pos, transforms, shapeIndex);
    const float xDim = data[(*paramIndex)++]/2.0f;
    const float yDim = data[(*paramIndex)++]/2.0f;
    const float zDim = data[(*paramIndex)++]/2.0f;

    float3 d = fabs(pos) - (float3){ xDim, yDim, zDim };
    //d -= float3 { xDim, yDim, zDim };
    return SprueMin(MaxElem(d), 0.0f) + length(max(d, (float3){ 0,0,0 }));
}

float RoundedBoxDensity(float3 pos, const global float* data, const global float4* transforms, int* paramIndex, int* shapeIndex)
{
    pos = MatrixMul(pos, transforms, shapeIndex);
    const float xDim = data[(*paramIndex)++]/2.0f;
    const float yDim = data[(*paramIndex)++]/2.0f;
    const float zDim = data[(*paramIndex)++]/2.0f;
    const float rounding = data[(*paramIndex)++];
    
    float3 d = fabs(pos) - (float3){ xDim, yDim, zDim };
    return SprueMin(MaxElem(d), 0.0f) + length(max(d, (float3){0,0,0})) - rounding;
}

float ConeDensity(float3 p, const global float* data, const global float4* transforms, int* paramIndex, int* shapeIndex)
{
    p = MatrixMul(p, transforms, shapeIndex);
    const float c = data[*paramIndex];// / 2.0f;
    *paramIndex = *paramIndex + 1;
    
    const float r = data[*paramIndex];
    *paramIndex = *paramIndex + 1;
    
    float d = length((float2)(p.x, p.z)) - r * (1.0f - (c + p.y) / (c + c));
    d = max(d, -p.y - c);
    d = max(d, p.y - c);
    return d;
}

float EllipsoidDensity(float3 p, const global float* data, const global float4* transforms, int* paramIndex, int* shapeIndex)
{ 
    p = MatrixMul(p, transforms, shapeIndex);
    const float paramX = data[(*paramIndex)++];
    const float paramY = data[(*paramIndex)++];
    const float paramZ = data[(*paramIndex)++];
    return (length(p / (float3){paramX,paramY, paramZ}) - 1.0f) * min(min(paramX,paramY),paramZ);
}


float CylinderDensity(float3 p, const global float* data, const global float4* transforms, int* paramIndex, int* shapeIndex)
{ 
    p = MatrixMul(p, transforms, shapeIndex);
    const float radius = data[(*paramIndex)++];
    const float height = data[(*paramIndex)++];

    float4 pt = { p.x, p.z, 0, 0 };
    float d = length(pt) - radius;
    return max(d, fabs(p.y) - height);
}

float CapsuleDensity(float3 p, const global float* data, const global float4* transforms, int* paramIndex, int* shapeIndex)
{ 
    p = MatrixMul(p, transforms, shapeIndex);
    float3 a = { 0.0f, 0.0f, data[(*paramIndex)++] / 2.0f };
    float3 b = { 0.0f, 0.0f, -a.z };
    float3 nearest = ClosestPoint(a, b, p);
    return length(p - nearest) - data[(*paramIndex)++];
}

float PlaneDensity(float3 p, const global float* data, const global float4* transforms, int* paramIndex, int* shapeIndex)
{
    p = MatrixMul(p, transforms, shapeIndex);
    return dot(p, (float3){ data[(*paramIndex)++], data[(*paramIndex)++], data[(*paramIndex)++] }) + data[(*paramIndex)++];
}

float TorusDensity(float3 p, const global float* data, const global float4* transforms, int* paramindex, int* shapeIndex)
{ 
    p = MatrixMul(p, transforms, shapeIndex);
    float4 q = { length((float4){ p.x, p.z, 0, 0 }) - data[(*paramindex)++], p.y, 0, 0 };
    return length(q) - data[(*paramindex)++];
}

float2 octahedron(float3 p, float r) {
  float3 o = (fabs(p)/sqrt(3.f));
  float s = (o.x+o.y+o.z);
  return (float2)((s-(r*(2.f/sqrt(3.f)))),1.f);
}
 
float3 opTwist(float3 p) {
  float t = 3.f;
  float c = cos((t*p.y));
  float s = sin((t*p.y));
  float2 mp = { c * p.x - s * p.z, s * p.x + c * p.z };
  float3 q = (float3)(mp.x, mp.y, p.y);
  return q;
}
 
float PaniqQDensity(float3 p) {
  p = opTwist(p);
  //p = p * 0.1f;
  float2 o = octahedron(p,15.0f);
  float m = min(o.x, o.y);
  return m;
  //return max(m, (10.0f-length(p)));
}

float tangle(float3 p)
{
    p = p * 0.1f;
	float a = p.x * p.x * p.x * p.x;
	float b = -5.f * (p.x * p.x);
	float c = p.y * p.y * p.y * p.y;
	float d = -5.f * (p.y * p.y);
	float e = p.z * p.z * p.z * p.z;
	float f = -5.f * (p.z * p.z);
	float g = 11.8f;
	return a + b + c + d + e + f + g;
}

float CSGAdd(float lhs, float rhs)
{ 
    return min(lhs, rhs);
}

float CSGSubtract(float lhs, float rhs)
{ 
    return max(lhs, -rhs);
}

float CSGIntersect(float lhs, float rhs)
{ 
    return max(lhs, rhs);
}

float EvaluateShape(float3 p, const global float* data, const global float4* transforms, int* paramIndex, int* shapeIndex)
{
    uint shapeID = data[*paramIndex];
    (*paramIndex)++;
    
    switch (shapeID)
    {
    case 0: // Sphere
        return SphereDensity(p, data, transforms, paramIndex, shapeIndex);
    case 1: // Box
        return BoxDensity(p, data, transforms, paramIndex, shapeIndex);
    case 2: // rounded box
        break;
    case 3: // Capsule
        return CapsuleDensity(p, data, transforms, paramIndex, shapeIndex);
    case 4: // Cylinder
        return CylinderDensity(p, data, transforms, paramIndex, shapeIndex);
    case 5: // Cone
        return ConeDensity(p, data, transforms, paramIndex, shapeIndex);
    case 6: // Plane
        return PlaneDensity(p, data, transforms, paramIndex, shapeIndex);
    case 7: // Ellipsoid
        return EllipsoidDensity(p, data, transforms, paramIndex, shapeIndex);
    case 8: // Torus
        return TorusDensity(p, data, transforms, paramIndex, shapeIndex);
    case 9: // Reserved space for super ellipsoid ... if the patent ever goes away
        return 1000.0f;
    case 10: // Reserved space for Segment
        break;
    case 11: // Reserved space for Catmul-Rom spline
        break;
    }
    return 1000.0f;
}

float EvaluateGraph(float curDensity, float3 p, const global float* data, const global float4* transforms, int* paramIndex, int* shapeIndex)
{
    uint command = data[*paramIndex];
    (*paramIndex)++;
    
    // Todo: consider a stack, Blist won't actually work
    while (command != 0)
    {
        float density = EvaluateShape(p, data, transforms, paramIndex, shapeIndex);
        
        switch (command)
        {
        case 0:
            return curDensity;
        case 1:
            curDensity = CSGAdd(curDensity, density);
            break;
        case 2:
            curDensity = CSGSubtract(curDensity, density);
            break;
        case 3:
            curDensity = CSGIntersect(curDensity, density);
            break;
        }
        
        command = data[*paramIndex];
    }
    
    return curDensity;
}

float EvaluateDensity(float3 p, const global float* data, const global float4* transforms, int* paramIndex, int* shapeIndex)
{
    float density = EvaluateShape(p, data, transforms, paramIndex, shapeIndex);
    return EvaluateGraph(density, p, data, transforms, paramIndex, shapeIndex);
}