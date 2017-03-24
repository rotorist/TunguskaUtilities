// Kernels for computing the vertices and indices of a naive surface nets grid

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

/// Scan cell layout to determine the need for a vertex
/// Use workgroup functions to simplify the scan of vertex data, this scan requires checking the value to decide what to write
kernel void ScanSurfaceNets_Vertices(
    global const uchar* vertexScanData,     // Data being scanned, CELL_SIZE^3
    global uint* vertexScanResult,          // Results, CELL_SIZE^3
    uint bin_size)
{
    uint lid = get_local_id(0);
    uint binId = get_group_id(0);
    uint group_offset = binId * bin_size;
    uint maxval = 0;
    do
    {
        uint binValue = vertexScanData[group_offset + lid];
        binValue = (binValue != 0 && binValue != 255);
        
        uint prefix_sum = work_group_scan_exclusive_add( binValue );
        vertexScanResult[group_offset + lid] = prefix_sum + maxval;
        maxval += work_group_broadcast( prefix_sum + binValue, get_local_size(0)-1 );
        group_offset += get_local_size(0);
    }
	while(group_offset < (binId+1) * bin_size);
}

/// Scan index buffer 0 and 1 writes to determine what cells need to process.
kernel void ScanSurfaceNets_Indices(
    global const uint* indexScanData,       // Data being scanned, CELL_SIZE^3
    global uint* indexScanResult,           // Results, CELL_SIZE^3
    uint bin_size)
{
    uint lid = get_local_id(0);
    uint binId = get_group_id(0);
    uint group_offset = binId * bin_size;
    uint maxval = 0;
    do
    {
        uint binValue = indexScanData[group_offset + lid];
        uint prefix_sum = work_group_scan_exclusive_add( binValue );
        indexScanResult[group_offset + lid] = prefix_sum + maxval;
        maxval += work_group_broadcast( prefix_sum + binValue, get_local_size(0)-1 );
        group_offset += get_local_size(0);
    }
	while(group_offset < (binId+1) * bin_size);
}

/// Write the collapsed vertex positions and also write the index of each vertex
/// Like a "uniform update"/collapse
kernel void GenerateVertices(
    global const uint* vertexScanResult,    // Results of previous scan of vertex data, CELL_SIZE^3
    global const float4* inVertices,        // vertices calculated previously, CELL_SIZE^3
    global float4* outVertices,             // Size based on previous scan
    global uint* outIndex)                  // CELL_SIZE^3
{
    const int x = get_global_id(0);
    const int y = get_global_id(1);
    const int z = get_global_id(2);
    
    const int inlineIndex = cell_index((int4){ x, y, z, 0 });
    
    const int writeIndex = vertexScanResult[inlineIndex];
    
    if (writeIndex > 0)
    {
        outVertices[writeIndex] = inVertices[inlineIndex].xyzw / inVertices[inlineIndex].w;
        outIndex[writeIndex] = writeIndex;
    }
}

int offset_3d_slab(const float3 p, const float3 size)
{
    return size.x * size.y * (((int)p.z) % 2) + p.y * size.x + p.x;
}

void quad(global uint* outIndices, uint start, bool flip, int ia, int ib, int ic, int id)
{
    outIndices[start * 4] = ia;
    outIndices[start * 4 + 1] = ib;
    outIndices[start * 4 + 2] = ic;
    
    outIndices[start * 4 + 3] = ia;
    outIndices[start * 4 + 4] = ic;
    outIndices[start * 4 + 5] = id;
}


/// Also like a "uniform update"/collapse
kernel void GenerateIndices(
    global const float* densities,                  // Previously calculated density grid, required for some tests
    global const uint* cellVertexPositions,         // Indices of vertex values, CELL_SIZE^3
    global const uint* indexScanResult,             // Results scan of index data
    global uint* outIndices)
{
    const int x = get_global_id(0);
    const int y = get_global_id(1);
    const int z = get_global_id(2);
    
    const int inlineIndex = cell_index((int4){ x, y, z, 0 });
    
    const int basePos = indexScanResult[inlineIndex];
    if (basePos == 0)
        return;
    
    int4 position = {x,y,z,0};
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
    
    const bool flip = density[0] < 0.0f;
    
    float3 dimVec = { EDGE_SIZE, EDGE_SIZE, EDGE_SIZE };
    // same if tests that were used for determining whether to write, unfortunately we need these values again to perform the check correctly
    if (position.y > 0 && position.z > 0 && (density[0] < 0.0f) != (density[1] < 0.0f)) {
        quad(outIndices, basePos, flip,
            cellVertexPositions[offset_3d_slab((float3) { position.x, position.y, position.z }, dimVec)],
            cellVertexPositions[offset_3d_slab((float3) { position.x, position.y, position.z - 1 }, dimVec)],
            cellVertexPositions[offset_3d_slab((float3) { position.x, position.y - 1, position.z - 1 }, dimVec)],
            cellVertexPositions[offset_3d_slab((float3) { position.x, position.y - 1, position.z }, dimVec)]
        );
    }
    if (position.x > 0 && position.z > 0 && (density[0] < 0.0f) != (density[2] < 0.0f)) {
        quad(outIndices, basePos, flip,
            cellVertexPositions[offset_3d_slab((float3) { position.x, position.y, position.z }, dimVec)],
            cellVertexPositions[offset_3d_slab((float3) { position.x - 1, position.y, position.z }, dimVec)],
            cellVertexPositions[offset_3d_slab((float3) { position.x - 1, position.y, position.z - 1 }, dimVec)],
            cellVertexPositions[offset_3d_slab((float3) { position.x, position.y, position.z - 1 }, dimVec)]
        );
    }
    if (position.x > 0 && position.y > 0 && (density[0] < 0.0f) != (density[4] < 0.0f)) {
        quad(outIndices, basePos, flip,
            cellVertexPositions[offset_3d_slab((float3) { position.x, position.y, position.z }, dimVec)],
            cellVertexPositions[offset_3d_slab((float3) { position.x, position.y - 1, position.z }, dimVec)],
            cellVertexPositions[offset_3d_slab((float3) { position.x - 1, position.y - 1, position.z }, dimVec)],
            cellVertexPositions[offset_3d_slab((float3) { position.x - 1, position.y, position.z }, dimVec)]
        );
    }
    
}