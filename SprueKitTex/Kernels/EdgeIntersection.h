
#define EDGE_SIZE 65

int field_index(const float3 pos)
{ 
    int x = clamp(pos.x, 0.0f, (float)EDGE_SIZE - 1);
    int y = clamp(pos.y, 0.0f, (float)EDGE_SIZE - 1);
    int z = clamp(pos.z, 0.0f, (float)EDGE_SIZE - 1);
    return (z * EDGE_SIZE * EDGE_SIZE + y * EDGE_SIZE + x);
}

struct EdgeData
{
    float3 normal;
    float distance;
};

//float DensityFunc(float3 pos, const global float* paramData, const global float* transformData)
//{
//    return PaniqQDensity(pos);
//}

#define FIND_EDGE_INFO_INCREMENT 1.0f/16.0f
#define FIND_EDGE_INFO_STEPS 16

kernel void FindEdgeIntersections(
    global float* density,
    global const float* paramData,
    global const float4* transformData,
    //global char* edges,
    global float4* edgeValues)
{
    const int x = get_global_id(0);
    const int y = get_global_id(1);
    const int z = get_global_id(2);
    
    if (x > 64 || y > 64 || z > 64)
        return;

    // Identify our cell
    const float3 pos = { x - 32, y - 32, z - 32 };
    const int index = field_index((float3)(x,y,z));
    const int edgeIndex = index * 3;
    
    const float3 EDGE_POINTS[3] = {
        {1,0,0},
        {0,1,0},
        {0,0,1}
    };

    // Calculate min corner density
    const float lhs = DensityFunc(pos, paramData, transformData);
    
    // For the 3 axis edges find the crossing point and normal
    for (int i = 0; i < 3; ++i)
    {
        const float3 thisPos = pos + EDGE_POINTS[i];
        const float rhs = DensityFunc(thisPos, paramData, transformData);
        
        float minValue = FLT_MAX;
        float currentT = 0.f;
        float t = 0.f;
        for (int j = 0; j <= FIND_EDGE_INFO_STEPS; j++)
        {
            const float3 p = mix(pos, thisPos, currentT);
            const float d = fabs(DensityFunc(p, paramData, transformData));
            if (d < minValue)
            {
                t = currentT;
                minValue = d;
            }
            currentT += FIND_EDGE_INFO_INCREMENT;
        }

        const float3 crossingPosition = mix(pos, thisPos, t);
        
        const float h = 0.001f;
        const float3 xOffset = { h, 0, 0 };
        const float3 yOffset = { 0, h, 0 };
        const float3 zOffset = { 0, 0, h };

        const float dx = DensityFunc(crossingPosition + xOffset, paramData, transformData) - DensityFunc(crossingPosition - xOffset, paramData, transformData);
        const float dy = DensityFunc(crossingPosition + yOffset, paramData, transformData) - DensityFunc(crossingPosition - yOffset, paramData, transformData);
        const float dz = DensityFunc(crossingPosition + zOffset, paramData, transformData) - DensityFunc(crossingPosition - zOffset, paramData, transformData);

        const float3 normal = normalize((float3)(dx, dy, dz));
        
        //edges[edgeIndex + i] = (sign(lhs) != sign(sign(rhs))) ? 1 : 0;
        edgeValues[edgeIndex + i] = (float4)(normal, t);
    }
    
    density[index] = lhs; //store our density for voxel detection
}