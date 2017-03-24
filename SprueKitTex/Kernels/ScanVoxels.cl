
#define EDGE_CT 64

int field_index(const int3 pos)
{ 
    int x = clamp(pos.x, 0, EDGE_CT - 1);
    int y = clamp(pos.y, 0, EDGE_CT - 1);
    int z = clamp(pos.z, 0, EDGE_CT - 1);
    return (z * EDGE_CT * EDGE_CT + y * EDGE_CT + x);
}

#define DENSITY_EDGE_CT 65

int density_index(const int3 pos)
{
    int x = clamp(pos.x, 0, DENSITY_EDGE_CT - 1);
    int y = clamp(pos.y, 0, DENSITY_EDGE_CT - 1);
    int z = clamp(pos.z, 0, DENSITY_EDGE_CT - 1);
    return (z * DENSITY_EDGE_CT * DENSITY_EDGE_CT + y * DENSITY_EDGE_CT + x);
}

// Compute the the states of each leaf voxel
kernel void ScanVoxels(
    global const float* densities,
    global uchar* voxelIndices) // this data is required for generating the mesh
{
    const int x = get_global_id(0);
    const int y = get_global_id(1);
    const int z = get_global_id(2);
    
    if (x > 63 || y > 63 || z > 63)
        return;
    
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
    for (int i = 0; i < 8; ++i)
    {
        const int fieldIdx = density_index(pos + CHILD_OFFSETS[i]);
        if (densities[fieldIdx] < 0)
            corners = corners | (one << i);
    }
    
    voxelIndices[field_index(pos)] = corners;
}

int map_index(const int3 pos, const int dim)
{
    int x = clamp(pos.x, 0, dim - 1);
    int y = clamp(pos.y, 0, dim - 1);
    int z = clamp(pos.z, 0, dim - 1);
    return (z * dim * dim + y * dim + x);
}

// Scans the incoming data and writes for our lower resolution, passes for 32^3 and 16^3 are performed
// The results of this data are used to accelerate octree construction by skipping large groups of nodes
// instead of constructing the octree all the way down to the leaves
// Any cells whose looked up value is 0 or 255 can be skipped (1, 2^3, 4^3, 8^3, 16^3, 32^3, 64^3)
kernel void CalculateOctree(global const uchar* previousData, global uchar* outData, uint dim)
{
    const int x = get_global_id(0);
    const int y = get_global_id(1);
    const int z = get_global_id(2);
    
    if (x > (dim-1) || y > (dim-1) || z > (dim-1))
        return;
        
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
    
    // Where we're at in our 32x32/16x16/8x8 grid
    int3 actualPos = {x,y,z};
    // where the lookup in the other data starts
    int3 pos = {x*2, y*2, z*2};
    uchar retVal = 0;
    for (int i = 0; i < 8; ++i)
    {
        int lookupIndex = map_index(pos + CHILD_OFFSETS[i], dim * 2);
        uchar lookupValue = dataMasks[lookupIndex];
        #ifdef FIRST_PASS
        if (lookupValue != 0 && lookupValue != 255) // does the cell have valid data? First pass cares only about cube edges interesting the volume surface
        #else
        if (lookupValue != 0) // successive passes only care about the 8-bit child mask of the previous pass
        #endif
            retVal = retVal | (1 << i); // write an "active child" mask
    }
    
    int writeIndex = map_index(actualPos, dim);
    outChildMask[writeIndex] = retVal;
}