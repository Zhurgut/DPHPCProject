include("../../timing/dphpc_timing.jl")
using Serialization

ASSERT = true

function init_graph(n)
    tmp = 0
    graph = zeros(Int, n, n)
    for i in 0:n-1
        for j in 0:n-1
            graph[i+1, j+1] = i * j % 7 + 1
            tmp = (i + j) % 13 == 0 || (i + j) % 7 == 0 || (i + j) % 11 == 0 ? 1 : 0
            if tmp == 0
                graph[i+1, j+1] = 999
            end
        end
    end
    return graph
end


function floyd_warshall(n, graph)

    for k in 1:n
        for i in 1:n
            # @views graph[i, 1:n] .= min.(graph[i, 1:n], graph[i, k] .+ graph[k, 1:n])

            gki = graph[k, i]
            @views graph[1:k, i] .= min.(graph[1:k, k] .+ gki, graph[1:k, i])
            gki = graph[k, i]
            @views graph[k+1:n, i] .= min.(graph[k+1:n, k] .+ gki, graph[k+1:n, i])
        end
    end

    return graph
end


function floyd_warshall_naive(n)
    graph = init_graph(n)

    for k in 1:n
        for i in 1:n
            for j in 1:n
                graph[i, j] = min(graph[i, j], graph[i, k] + graph[k, j])
                # Optimization column major
                #graph[j, i] = min(graph[j, i], graph[j, k] + graph[k, i])
            end
        end
    end

    return graph
end

function assert_correctness(graph, n)
    graph_test = floyd_warshall_naive(n)
    @assert isequal(graph, graph_test)
end

function main()

    benchmarks = NPBenchManager.get_parameters("floyd_warshall")

    n = (benchmarks["S"] |> values |> collect)[1]
    graph = init_graph(n)
    floyd_warshall(n, graph)
    assert_correctness(graph, n)
    
    @dphpc_time(graph = init_graph(n),floyd_warshall(n, graph),"S")

    

    n = (benchmarks["M"] |> values |> collect)[1]
    graph = init_graph(n)
    @dphpc_time(graph = init_graph(n),floyd_warshall(n, graph),"M")

    n = (benchmarks["L"] |> values |> collect)[1]
    graph = init_graph(n)
    @dphpc_time(graph = init_graph(n),floyd_warshall(n, graph),"L")

    n = (benchmarks["paper"] |> values |> collect)[1]
    graph = init_graph(n)
    @dphpc_time(graph = init_graph(n),floyd_warshall(n, graph),"paper")

end

main()