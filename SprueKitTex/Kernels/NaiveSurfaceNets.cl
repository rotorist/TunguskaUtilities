// Calculates the vertex position for naive surface nets

#define EDGE_SIZE 65
#define CELL_SIZE 64

int vertex_index(const int4 pos)
{ 
    int x = clamp(pos.x, 0, EDGE_SIZE - 1);
    int y = clamp(pos.y, 0, EDGE_SIZE - 1);
    int z = clamp(pos.z, 0, EDGE_SIZE - 1);
    return (z * EDGE_SIZE * EDGE_SIZE + y * EDGE_SIZE + x);
}

int cell_index(const int4 pos)
{
    int x = clamp(pos.x, 0, CELL_SIZE - 1);
    int y = clamp(pos.y, 0, CELL_SIZE - 1);
    int z = clamp(pos.z, 0, CELL_SIZE - 1);
    return (z * CELL_SIZE * CELL_SIZE + y * CELL_SIZE + x);
}

// Process an edge
float4 do_edge(float va, float vb, int axis, float3 pt)
{
    if (va < 0.0f == vb < 0.0f)
        return (float4){0,0,0,0};
    
    float value = va / (va - vb);
    if (axis == 0)
        return (float4){pt.x + value, pt.y, pt.z, 1.0f };
    else if (axis == 1)
        return (float4){pt.x, pt.y + value, pt.z, 1.0f };
    else
        return (float4){pt.x, pt.y, pt.z + value, 1.0f };
}

/// Takes a (DIM+1)^3 density field and computes the vertex positions in the cells using naive surface nets
kernel void CalculateVertexPositions(
    global const float* densities,      /* Density data received from the "BasicDensityCalculation.cl" kernel */
    global float4* positions,           /* contains the calculated mass-point vertex position */
    global uchar* writtenMask           /* Contains the 8bit corners mask */
)
{
    const int x = get_global_id(0);
    const int y = get_global_id(1);
    const int z = get_global_id(2);
    if (x > CELL_SIZE || y > CELL_SIZE || z > CELL_SIZE)
        return;
        
    int4 position = {x,y,z,1};
    const float density[8] = {
                        densities[vertex_index(position)],
                        densities[vertex_index(position + (int4){1, 0, 0, 0})],
                        densities[vertex_index(position + (int4){0, 1, 0, 0})],
                        densities[vertex_index(position + (int4){1, 1, 0, 0})],
                        densities[vertex_index(position + (int4){0, 0, 1, 0})],
                        densities[vertex_index(position + (int4){1, 0, 1, 0})],
                        densities[vertex_index(position + (int4){0, 1, 1, 0})],
                        densities[vertex_index(position + (int4){1, 1, 1, 0})]
                    };
                    
    const int layout = ((density[0] < 0.0f) << 0) |
                        ((density[1] < 0.0f) << 1) |
                        ((density[2] < 0.0f) << 2) |
                        ((density[3] < 0.0f) << 3) |
                        ((density[4] < 0.0f) << 4) |
                        ((density[5] < 0.0f) << 5) |
                        ((density[6] < 0.0f) << 6) |
                        ((density[7] < 0.0f) << 7);
                    
    float4 vertPos = { 0.0f, 0.0f, 0.0f, 0.0f };
    vertPos += do_edge(density[0], density[1], 0, (float3){ x, y, z});
    vertPos += do_edge(density[2], density[3], 0, (float3){ x, y + 1, z});
    vertPos += do_edge(density[4], density[5], 0, (float3){ x, y, z + 1});
    vertPos += do_edge(density[6], density[7], 0, (float3){ x, y + 1, z + 1});
    vertPos += do_edge(density[0], density[2], 1, (float3){ x, y, z});
    vertPos += do_edge(density[1], density[3], 1, (float3){ x + 1, y, z});
    vertPos += do_edge(density[4], density[6], 1, (float3){ x, y, z + 1});
    vertPos += do_edge(density[5], density[7], 1, (float3){ x + 1, y, z + 1});
    vertPos += do_edge(density[0], density[4], 2, (float3){ x, y, z});
    vertPos += do_edge(density[1], density[5], 2, (float3){ x + 1, y, z});
    vertPos += do_edge(density[2], density[6], 2, (float3){ x, y + 1, z});
    vertPos += do_edge(density[3], density[7], 2, (float3){ x + 1, y + 1, z });
 
    const int writeIndex = cell_index(position);
    // positions[writeIndex] = (float4){ x, y, z, 1 }; // Blocky-MineCraft style
    positions[writeIndex] = vertPos;
    writtenMask[writeIndex] = layout;
    
    // Could perform 3 if tests for the need to output indices and output a uint of 1 to later run a scan on for indices, always outputs 2 triangles so there's really no need for any serious counting
    // Vertex count could be scanned off of the "writtenMask" any value that isn't 0 or 255 is a 1 in a prefix sum
}