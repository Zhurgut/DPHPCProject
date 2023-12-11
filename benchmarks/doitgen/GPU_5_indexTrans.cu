#include "utils.h"

#define ASSERT 1
#define THREADS 16


__global__ void kernel_doitgen(int nr, int nq, int np,
      double *A,
      double *C4,
      double *sum) {

    // Very bad performance - optimization replace writing to sum with temporary variable
    int r = blockIdx.x * blockDim.x + threadIdx.x;
    int q = blockIdx.y * blockDim.y + threadIdx.y;

    if (q < nr && r < nq) {
        for(int p = 0; p < np; p++) {
            double tempSum = 0.0;
            for (int s = 0; s < np; s++) {
                tempSum += A[q * nq * np + r * np + s] * C4[s * np + p];
            }
            sum[q * nq * np + r * np + p] = tempSum;
        }
        for (int p = 0; p < np; p++) {
            A[q * nq * np + r * np + p] = sum[q * nq * np + r * np + p];
        }
    }
}


void run_doitgen_gpu(int nr, int nq, int np,
      double *A,
      double *C4,
      double *sum) {

    dim3 threadsPerBlock(THREADS, THREADS);
    dim3 numBlocks(CEIL_DIV(nq, THREADS), CEIL_DIV(nr, THREADS));
    kernel_doitgen<<<numBlocks,threadsPerBlock>>>(nr, nq, np, A, C4, sum);
    cudaDeviceSynchronize();
}


int main(int argc, char** argv) {

    int nr = NR_S; int nq = NQ_S; int np = NP_S;
    run_bm(nr, nq, np, "S", run_doitgen_gpu, ASSERT);
    
    nr = NR_M; nq = NQ_M; np = NP_M;
    run_bm(nr, nq, np, "M", run_doitgen_gpu, ASSERT);

    nr = NR_L; nq = NQ_L; np = NP_L;
    run_bm(nr, nq, np, "L", run_doitgen_gpu, ASSERT);

    nr = NR_PAPER; nq = NQ_PAPER; np = NP_PAPER;
    run_bm(nr, nq, np, "paper", run_doitgen_gpu, ASSERT);

    return 0;
}
