#include "../../timing/dphpc_timing.h"

#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>

#define ASSERT 1

// grid has to be square
void init_arrays(int n, double A[n][n], double B[n][n])
{
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            A[i][j] = ((double) i * (j + 2) + 2) / n;
            B[i][j] = ((double) i * (j + 3) + 3) / n;
        }
    }
}

void print_arrays(int n, double A[n][n], double B[n][n])
{   
    puts("matrix A:");
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            printf("%.2f ", A[i][j]);
        }
        printf("\n");
    }
    
    puts("\nmatrix B:");
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            printf("%.2f ", B[i][j]);
        }
        printf("\n");
    }
}

void print_array(int n, double A[n][n])
{   
    puts("matrix A:");
    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < n; j++)
        {
            printf("%.2f ", A[i][j]);
        }
        printf("\n");
    }
}

void kernel_j2d(int tsteps, int n, double A[n][n], double B[n][n])
{
    // iterate for tsteps steps
    for (int t = 0; t < tsteps; t++)
    {
        for (int i = 1; i < (n - 1); i++)
        {
            for (int j = 1; j < (n - 1); j++)
            {
                B[i][j] = 0.2 * (A[i][j] + A[i][j-1] + A[i][j+1] + A[i+1][j] + A[i-1][j]); // mean (sum/5) of -|- w/ Aij in centre
            }
        }
        for (int i = 1; i < (n - 1); i++)
        {
            for (int j = 1; j < (n - 1); j++)
            {
                A[i][j] = 0.2 * (B[i][j] + B[i][j-1] + B[i][j+1] + B[i+1][j] + B[i-1][j]);
            }
        }
    }
}

void run_bm(int tsteps, int n, const char* preset)
{    
    double (*A)[n][n] = malloc(sizeof(*A));
    double (*B)[n][n] = malloc(sizeof(*B));

    init_arrays(n, *A, *B);
    
    if (ASSERT)
    {
        print_array(n, *A);
    }
    
    kernel_j2d(tsteps, n, *A, *B);
    
    if (ASSERT)
    {
        //print_arrays(n, *A, *B);
        print_array(n, *A);
    }

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



// int main(int argc, char** argv)
// {
//     run_bm(50, 150, "S");   // steps 50, n 150
//     // run_bm(80, 350, "M");   // steps 80, n 350
//     // run_bm(200, 700, "L");   // steps 200, n 700
//     // run_bm(500, 1400, "test"); // steps 500, n 1400, testing purposes
//     // run_bm(1000, 2800, "paper");  // steps 1000, n 2800
  
//     return 0;
// }

