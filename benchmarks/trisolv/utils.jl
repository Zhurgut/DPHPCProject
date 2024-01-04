using Statistics
using CUDA
using LinearAlgebra

include("../../timing/dphpc_timing.jl")

function initialize(N)
    # L = [((i + N - j + 1) * 2 / N) for i in 1:N, j in 1:N]
    L = zeros(N, N)
    @inbounds for j=1:N, i=1:N
        L[i, j] = 2 * (i + N - j + 1)
    end
    L *= (1/N)

    x = zeros(N)
    b = collect(0:N-1)

    return CuArray.((L, x, b))
end

benchmark_sizes = Dict(
    "S"     => 2000, 
    "M"     => 5000, 
    "L"     => 14000, 
    "paper" => 16000, 
    "dev"   => 4, 
)


function is_valid(L, x, b)
    # display(LowerTriangular(L))
    # display(x)
    # display(LowerTriangular(L)*x)
    # display(b)
    println(norm(LowerTriangular(L)*x - b))
    return norm(LowerTriangular(L)*x - b) < 1e-2 # naive_gpu has relatively large norm...
end


function main()
    val_N = 500
    L, x, b = initialize(val_N)
    kernel(L, x, b)

    if is_valid(L, x, b)
        
        N = 20 # warmup
        @dphpc_time(data = initialize(N), kernel(data...))

        for (preset, dims) in benchmark_sizes
            N = dims
    
            @dphpc_time(data = initialize(N), kernel(data...), preset)
        end
    else 
        println("VALIDATION FAILED")
    end
end