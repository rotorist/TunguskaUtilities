
#define VOXEL_CT 64

int voxel_index(const int3 pos)
{ 
    int x = clamp(pos.x, 0, VOXEL_CT - 1);
    int y = clamp(pos.y, 0, VOXEL_CT - 1);
    int z = clamp(pos.z, 0, VOXEL_CT - 1);
    return (z * VOXEL_CT * VOXEL_CT + y * VOXEL_CT + x);
}

#define VOXEL_EDGE_CT 65

int edge_index(const int3 pos)
{
    int x = clamp(pos.x, 0, VOXEL_EDGE_CT - 1);
    int y = clamp(pos.y, 0, VOXEL_EDGE_CT - 1);
    int z = clamp(pos.z, 0, VOXEL_EDGE_CT - 1);
    return (z * VOXEL_EDGE_CT * VOXEL_EDGE_CT + y * VOXEL_EDGE_CT + x);
}

const int3 EDGE_POINTS[4] = {
    {0,0,0},
    {1,0,0},
    {0,1,0},
    {0,0,1}
};

const int EDGE_BITS[8] = {
    // pos -> +0 0 0
    // pos -> +0 0 1
    // pos -> +0 1 0
    // pos -> +0 1 1
    // pos -> +1 0 0
    // pos -> +1 0 1
    // pos -> +1 1 0
    // pos -> +1 1 1
};

// -1 in which axes we need to check
const int8 CORNER_AXES[24] = {
     0,  1,  2,     // 0
    -1, -1,  2,     // 1
     0,  1, -1,     // 2
     0, -1, -1,     // 3
    -1,  1,  2,     // 4
    -1,  1, -1,     // 5
    -1, -1,  2,     // 6
    -1, -1, -1      // 7
};

struct EdgeData
{
    float3 normal;
    float distance;
};

// Compute the the states of each leaf voxel
kernel void ScanVoxels(
    global const int8* edgeUsage,
    global const EdgeData* edgeValues,
    global int* voxelIndices)
{
    const int x = get_global_id(0);
    const int y = get_global_id(1);
    const int z = get_global_id(2);
    
    const int3 CHILD_OFFSETS[8] = {
        { 0, 0, 0},
        { 0, 0, 1},
        { 0, 1, 0},
        { 0, 1, 1},
        { 1, 0, 0},
        { 1, 0, 1},
        { 1, 1, 0},
        { 1, 1, 1}
    };
    
    int3 pos = {x, y, z};
    int corners = 0;
    const int one = 1;
    const int voxelIndex = voxel_index(pos);
    const int edgeOffset = 0;
    
    for (int i = 0; i < 12; ++i)
    {
        
    }
    
    // check our three local edges
    int currentEdge = edge_index(pos) * 3;
    for (int i = 0; i < 3; ++i)
    {
        // is this edge used?
        if (edgeUsage[currentEdge + i])
        {
        }
    }
    
    currentEdge = edge_index(pos + {
    
    for (int i = 0; i < 8; ++i)
    {
        const int fieldIdx = edge_index(pos + CHILD_OFFSETS[i]);
        if (densities[fieldIdx] < 0.0f)
            corners = corners | (one << i);
    }
    
    voxelIndices[voxelIndex] = corners;
}