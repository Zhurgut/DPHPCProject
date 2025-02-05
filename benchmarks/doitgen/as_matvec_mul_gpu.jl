
include("./utils.jl")
using LinearAlgebra: mul!

ASSERT = true

# different from the one defined in utils
function localreset(A, C4, nr, nq, np)
    A_gpu = CuArray(A)
    C4_gpu = CuArray(C4)

    # actually here its ok
    sum = CUDA.fill(0.0, np)
    CUDA.synchronize()
    return A_gpu, C4_gpu, sum
end


function doitgen_gpu!(nr, nq, np, A, C4, sum)

    CUDA.@sync blocking=true doitgen_kernel(nr, nq, np, A, C4, sum)

end



function doitgen_kernel(nr, nq, np, A, C4, sum)
    for r in 1:nr
        for q in 1:nq
            @view(A[r, q, :]) .= transpose(C4) * @view(A[r, q, :])
        end
    end
    return A
end

function main()

    benchmark_sizes = NPBenchManager.get_parameters("doitgen")
    
    nr,nq,np = benchmark_sizes["S"] |> values |> collect
    A, C4 = init_array(nr, nq, np)
    A_gpu, C4_gpu, sum = localreset(A, C4, nr, nq, np)
    res = @dphpc_time((A_gpu, C4_gpu, sum) = localreset(A, C4, nr, nq, np), doitgen_gpu!(nr, nq, np, A_gpu, C4_gpu, sum), "S")
    if ASSERT && res != nothing
        result_A = CUDA.copyto!(Array{Float64}(undef, nr, nq, np), A_gpu)
        assert_naive(result_A, nr, nq, np)
    end
    

    nr,nq,np = benchmark_sizes["M"] |> values |> collect
    A, C4 = init_array(nr, nq, np)
    A_gpu, C4_gpu, sum = localreset(A, C4, nr, nq, np)
    res = @dphpc_time((A_gpu, C4_gpu, sum) = localreset(A, C4, nr, nq, np), doitgen_gpu!(nr, nq, np, A_gpu, C4_gpu, sum), "M")
    if ASSERT && res != nothing
        result_A = CUDA.copyto!(Array{Float64}(undef, nr, nq, np), A_gpu)
        assert_naive(result_A, nr, nq, np)
    end


    nr,nq,np = benchmark_sizes["L"] |> values |> collect
    A, C4 = init_array(nr, nq, np)
    A_gpu, C4_gpu, sum = localreset(A, C4, nr, nq, np)
    res = @dphpc_time((A_gpu, C4_gpu, sum) = localreset(A, C4, nr, nq, np), doitgen_gpu!(nr, nq, np, A_gpu, C4_gpu, sum), "L")
    if ASSERT && res != nothing
        result_A = CUDA.copyto!(Array{Float64}(undef, nr, nq, np), A_gpu)
        assert_naive(result_A, nr, nq, np)
    end


    nr,nq,np = benchmark_sizes["paper"] |> values |> collect
    A, C4 = init_array(nr, nq, np)
    A_gpu, C4_gpu, sum = localreset(A, C4, nr, nq, np)
    res = @dphpc_time((A_gpu, C4_gpu, sum) = localreset(A, C4, nr, nq, np), doitgen_gpu!(nr, nq, np, A_gpu, C4_gpu, sum), "paper")
    if ASSERT && res != nothing
        result_A = CUDA.copyto!(Array{Float64}(undef, nr, nq, np), A_gpu)
        assert_naive(result_A, nr, nq, np)
    end
end

main()