float function_example(float a, float b)
{
    return a + b;
}

__kernel void TestKernel(__global float* a, __global float* b, __global float* c)
{
    unsigned int i = get_global_id(0);

    //c[i] = a[i] + b[i];
    c[i] = function_example(a[i], b[i]);
}