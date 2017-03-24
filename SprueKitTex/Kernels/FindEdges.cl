
#define EDGE_SIZE 64

int field_index(const int3 pos)
{ 
    int x = clamp(pos.x, 0, EDGE_SIZE - 1);
    int y = clamp(pos.y, 0, EDGE_SIZE - 1);
    int z = clamp(pos.z, 0, EDGE_SIZE - 1);
    return (z * EDGE_SIZE * EDGE_SIZE + y * EDGE_SIZE + x);
}

const int3 EDGE_POINTS[4] = {
    {0,0,0},
    {1,0,0},
    {0,1,0},
    {0,0,1}
};

struct EdgeData
{
    float3 Normal;
    float Distance;
};

kernel void FindEdges(
    global const float* density,
    global int8* edges)
{
    const int x = get_global_id(0);
    const int y = get_global_id(1);
    const int z = get_global_id(2);

    const int3 pos = { x, y, z };
    const int index = field_index(pos);
    const int edgeIndex = index * 3;
    
    const float DENSITIES[4] = {
        density[field_index(pos + (int3){0, 0, 0})],
        density[field_index(pos + (int3){1, 0, 0})],
        density[field_index(pos + (int3){0, 1, 0})],
        density[field_index(pos + (int3){0, 0, 1})]
    };
    
    for (int i = 0; i < 3; ++i)
    {
        const int e = i + 1;
        const int signChange = (sign(DENSITIES[0]) != sign(DENSITIES[e])) ? 1.0f : 0.0f;
        edges[edgeIndex + i] = signChange;
    }
}