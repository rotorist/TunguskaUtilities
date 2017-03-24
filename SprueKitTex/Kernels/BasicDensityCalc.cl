// This code expects to be combined with other code for a "DensityFunc" before being compiled.

#define VERTEX_SIZE 65

int vertex_index(const int4 pos)
{ 
    int x = clamp(pos.x, 0, VERTEX_SIZE - 1);
    int y = clamp(pos.y, 0, VERTEX_SIZE - 1);
    int z = clamp(pos.z, 0, VERTEX_SIZE - 1);
    return (z * VERTEX_SIZE * VERTEX_SIZE + y * VERTEX_SIZE + x);
}

// Signature for density function
//      float DensityFunc(float3 pos, const global float* paramData, const global float* transformData)


// This kernel fills a grid of density values based on the density function
kernel void GenerateDefaultField(
    //const int4 offset,
    global float* densities,
    global const float* shapeData,
    global const float4* transforms)
{
    const int x = get_global_id(0);
    const int y = get_global_id(1);
    const int z = get_global_id(2);
    
    if (x > VERTEX_SIZE || y > VERTEX_SIZE || z > VERTEX_SIZE)
        return;
    
    float3 world_pos = {x, y, z };
    // density function comes from elsewhere
    const float density = DensityFunc(world_pos, shapeData, transforms);
    
    const int4 local_pos = { x, y, z, 0 };
    const int index = vertex_index(local_pos);
    
    densities[index] = density;
}