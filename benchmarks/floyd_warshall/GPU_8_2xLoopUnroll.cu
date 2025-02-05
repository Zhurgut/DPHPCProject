/* DOES NOT RESOLVE RACE CONDITION - BUGGY

#include "utils.h"

#define ASSERT 1


__global__ void kernel_floyd_warshall(int n, int *graph) {

  int tmp, tmp1;
  int j = blockIdx.x * blockDim.x + threadIdx.x;
  int i = blockIdx.y * blockDim.y + threadIdx.y;

  if (i < n && j < n) {
    for (int k = 0; k < n-1; k+=2){
      tmp = graph[i * n + k] + graph[k * n + j];
      tmp1 = graph[i * n + k + 1] + graph[(k + 1) * n + j];
      if (tmp > tmp1) tmp = tmp1;

      if (tmp < graph[i * n + j]) {
        graph[i * n + j] = tmp;
      }
    }
    tmp = graph[i * n + (n - 1)] + graph[(n - 1) * n + j];
    if (tmp < graph[i * n + j]) {
      graph[i * n + j] = tmp;
    }
  }
}


void run_floyd_warshall_gpu(int n, int *graph) {
  
  dim3 threadsPerBlock(16, 16);
  dim3 numBlocks(n / 16 + 1, n / 16 + 1);
  kernel_floyd_warshall<<<numBlocks,threadsPerBlock>>>(n, graph);
  cudaDeviceSynchronize();
}


int main(int argc, char** argv) {
  
  run_bm(N_S, "S", run_floyd_warshall_gpu, ASSERT);
  run_bm(N_M, "M", run_floyd_warshall_gpu, ASSERT);
  run_bm(N_L, "L", run_floyd_warshall_gpu, ASSERT);
  run_bm(N_PAPER, "paper", run_floyd_warshall_gpu, ASSERT);
  
  return 0;
}
*/