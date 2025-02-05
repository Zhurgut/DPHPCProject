#include "../../timing/dphpc_timing.h"

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>

#define ASSERT 0

__global__ void kernel_j2d(int n, double *A, double *B)
{

    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;
    
    if (i > 0 && i < (n - 1) && j > 0 && j < (n - 1))
    {
        B[i * n + j] = 0.2 * (A[i * n + j] + A[i * n + (j - 1)] + A[i * n + (j + 1)] + A[(i + 1) * n + j] + A[(i - 1) * n + j]);
    }
        
}

void init_arrays(int n, double *A, double *B)
{
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            A[i * n + j] = ((double) i * (j + 2) + 2) / n;
            B[i * n + j] = ((double) i * (j + 3) + 3) / n;
        }
    }
}

void print_array(int n, double *A)
{   
    puts("matrix A:");
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            printf("%.2f ", A[i * n + j]);
        }
        printf("\n");
    }
}

void print_arrays(int n, double *A, double *B)
{   
    puts("matrix A:");
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            printf("%.2f ", A[i * n + j]);
        }
        printf("\n");
    }
    
    puts("\nmatrix B:");
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            printf("%.2f ", B[i * n + j]);
        }
        printf("\n");
    }
}


void run_kernel_j2d(int tsteps, int n, double *A, double *B)
{   
    dim3 threadsPerBlock(16, 16);   // threads per block: 256
    dim3 numBlocks((n + threadsPerBlock.x - 1) / threadsPerBlock.x, (n + threadsPerBlock.y - 1) / threadsPerBlock.y);
    for (int t = 0; t < tsteps; t++)
    {
        kernel_j2d<<<numBlocks,threadsPerBlock>>>(n, A, B);
        kernel_j2d<<<numBlocks,threadsPerBlock>>>(n, B, A);
    }
    cudaDeviceSynchronize();
}

void reset(int n, double *A, double *A_d, double *B, double *B_d)
{
    cudaMemcpy((void *) A_d, (void *) A, sizeof(*A) * n * n, cudaMemcpyHostToDevice);
    cudaMemcpy((void *) B_d, (void *) B, sizeof(*B) * n * n, cudaMemcpyHostToDevice);
}

void run_bm(int tsteps, int n, const char* preset)
{
    double *A = (double *) malloc(sizeof(*A) * n * n);
    double *B = (double *) malloc(sizeof(*B) * n * n);
    init_arrays(n, A, B);

    double *A_d, *B_d;
    cudaMalloc((void **) &A_d, sizeof(*A) * n * n);
    cudaMalloc((void **) &B_d, sizeof(*B) * n * n);

    cudaMemcpy((void *) A_d, (void *) A, sizeof(*A) * n * n, cudaMemcpyHostToDevice);
    cudaMemcpy((void *) B_d, (void *) B, sizeof(*B) * n * n, cudaMemcpyHostToDevice);

    dphpc_time3(
        reset(n, A, A_d, B, B_d),
        run_kernel_j2d(tsteps, n, A_d, B_d),
        preset
    );  // TODO: since data is never copied back from gpu in the runs, does it actually execute?
    
    if (ASSERT && strcmp(preset, "S") == 0)
    {
        cudaMemcpy((void *) A, (void *) A_d, sizeof(*A) * n * n, cudaMemcpyDeviceToHost); // read output back
        print_array(n, A);
    }

    cudaFree((void *) A_d);
    cudaFree((void *) B_d);

    free((void *) A);
    free((void *) B);
}

#include "_parameters.h"
int main(int argc, char** argv)
{   
    const char *presets[] = {"S", "M", "L", "paper"};

    for (int i = 0; i < 4; i++) {
        const char* preset = presets[i];
        int tsteps = get_params(preset)[0];
        int n      = get_params(preset)[1];
        run_bm(tsteps, n, preset);
    }


    //run_bm(500, 1400, "missing"); // in-between for testing
  
    return 0;
}
