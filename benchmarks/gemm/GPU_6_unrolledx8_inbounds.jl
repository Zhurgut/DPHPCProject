include("../../timing/dphpc_timing.jl")
include("./validation.jl")

using CUDA 

# eliminate global variables + accumulators + unroll by x8 + inbounds

validation = false

# for validation 
function initialize_matrices_val(N, M, K)
    A = fill(0.5, N, K)
    B = fill(0.7, K, M)
    C = fill(0.3, N, M)
    return CuArray(A), CuArray(B), CuArray(C)
end

function init_matrices(N, M, K)

    A = zeros(Float64, N, K)
    B = zeros(Float64, K, M)
    C = zeros(Float64, N, M)

    A = [(i*j+1) % K / K for i in 1:N, j in 1:K]
    B = [(i*j+1) % M / M for i in 1:K, j in 1:M]
    C = [(i*j+1) % M / M for i in 1:N, j in 1:M]

    return CuArray(A), CuArray(B), CuArray(C)

end

function gemm_kernel(N, M, K, A, B, C)
    i = threadIdx().x + (blockIdx().x - 1) * blockDim().x
    j = threadIdx().y + (blockIdx().y - 1) * blockDim().y

    alpha = 1.5
    beta = 1.2

    if i <= N && j <= M
        @inbounds acc1 = C[i, j] * beta
        acc2 = 0.0

        acc3 = 0.0
        acc4 = 0.0
        acc5 = 0.0
        acc6 = 0.0
        acc7 = 0.0
        acc8 = 0.0
        acc9 = 0.0
        acc10 = 0.0

        # Unroll the loop by 4
        @inbounds for k = 1:8:K-7
            @inbounds acc3 += alpha * A[i, k] * B[k, j]
            @inbounds acc4 += alpha * A[i, k+1] * B[k+1, j]
            @inbounds acc5 += alpha * A[i, k+2] * B[k+2, j]
            @inbounds acc6 += alpha * A[i, k+3] * B[k+3, j]
            @inbounds acc7 += alpha * A[i, k+4] * B[k+4, j]
            @inbounds acc8 += alpha * A[i, k+5] * B[k+5, j]
            @inbounds acc9 += alpha * A[i, k+6] * B[k+6, j]
            @inbounds acc10 += alpha * A[i, k+7] * B[k+7, j]
        end

        # Handle the remaining values
        @inbounds for k = (K - rem(K, 8)) + 1:K
            @inbounds acc2 += alpha * A[i, k] * B[k, j]
        end

        @inbounds C[i, j] = acc1 + acc2 + acc3 + acc4 + acc5 + acc6 + acc7 + acc8 + acc9 + acc10
    end
    nothing
end

function run_gemm_kernel(N, M, K, A, B, C)
    threadsPerBlock = (16, 16)
    numBlocks = ((N - 1) ÷ 16 + 1, (M - 1) ÷ 16 + 1)
    @cuda threads=threadsPerBlock blocks=numBlocks gemm_kernel(N, M, K, A, B, C)
    CUDA.synchronize()
end


function main()

    if validation 

        N, M, K = 30, 40, 50
        A, B, C = initialize_matrices_val(N, M, K)
        run_gemm_kernel(N,M,K,A,B,C)
        C_empty = zeros(Float64, N, M)
        C_cpu = CUDA.copyto!(C_empty, C)  
        is_valid = validate(C_cpu)

        print(is_valid)

        else 

        N, M, K = 1000, 1100, 1200
        @dphpc_time((A, B, C) = init_matrices(N,M,K), run_gemm_kernel(N, M, K, A, B, C), "S")

        N, M, K = 2500, 2750, 3000
        @dphpc_time((A, B, C) = init_matrices(N,M,K), run_gemm_kernel(N, M, K, A, B, C), "M")

        N, M, K = 7000, 7500, 8000
        @dphpc_time((A, B, C) = init_matrices(N,M,K), run_gemm_kernel(N, M, K, A, B, C), "L")

        N, M, K = 2000, 2300, 2600
        @dphpc_time((A, B, C) = init_matrices(N,M,K), run_gemm_kernel(N, M, K, A, B, C), "paper")

        end 

end

main()


