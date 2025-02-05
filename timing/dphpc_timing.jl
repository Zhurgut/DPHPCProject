
if !isdefined(Main, :NPBenchManager) include("NPBenchManager.jl") end # for convenience


# macro for timing benchmarks, determines median and 95% confidence interval for median runtime in ms
# need at least 6 measurements to be able to give 95% confidence interval



c_header = open(io->read(io, String), joinpath(@__DIR__, "dphpc_timing.h"))


# adjust the values in dphpc_timing.h!
MIN_RUNS::Int =     parse(Int,     match(r"#define MIN_RUNS\s+(\p{N}+)",  c_header).captures[1])
MAX_RUNS::Int =     parse(Int,     match(r"#define MAX_RUNS\s+(\p{N}+)",  c_header).captures[1])
MAX_TIME::Float64 = parse(Float64, match(r"#define MAX_TIME\s+(\p{Nd}+)", c_header).captures[1])
TIMEOUT::Float64  = parse(Float64, match(r"#define TIMEOUT\s+(\p{Nd}+)", c_header).captures[1])

if !isdefined(@__MODULE__, :PRESETS_TO_RUN)
    global PRESETS_TO_RUN = ["missing", "S"] # defined here for convenience only, otherwise cannot run file with Ctrl+Enter...
    # when doing Alt+Enter just run small versions
    # important not to define it for the case where it is defined in run_benchmarks.jl
end
if !isdefined(@__MODULE__, :PROFILING)
    global PROFILING = false
end
if !isdefined(@__MODULE__, :PROFILING_GPU)
    global PROFILING_GPU = false
end


# generate indeces of lower and upper bounds for 95%-CI
# from the table in https://leboudec.github.io/perfeval/, page 347
lb_reps = [3, 3, 3, 2, 3, 3, 2, 3, 2, 3, 2, 2, 3, 2, 2, 3, 2, 2, 3, 2, 2, 2, 2, 3, 2, 3, 1]
up_reps = [1, 2, 1, 1, 2, 2, 2, 1, 1, 2, 2, 2, 1, 1, 2, 2, 2, 2, 2, 1, 1, 2, 2, 2, 2, 2, 2, 1, 1, 2, 2, 2, 1, 2, 3, 2, 1, 1, 2]
lb_ids = [i for i = 1:27 for j = 1:lb_reps[i]] 
ub_ids = [i for i = 6:44 for j = 1:up_reps[i-5]]

function lb95_idx(n)
    if n ≤ 5 
        return 1
    end
    if n ≤ 70
        return lb_ids[n-5]
    end
    return 0.5n - 0.98√n |> floor |> Int
end

function ub95_idx(n)
    if n ≤ 5
        return n
    end
    if n ≤ 70
        return ub_ids[n-5]
    end
    return 0.5n + 1 + 0.98√n |> ceil |> Int
end
    


# returns the empirical median and a 95% confidence interval for the true median
function median_CI95(measurements)
    sorted = sort(measurements)
    # display(sorted)
    n = length(sorted)
    median_ms = sorted[n ÷ 2 + 1]
    median_lb_ms = sorted[lb95_idx(n)]
    median_ub_ms = sorted[ub95_idx(n)]
    return (median_lb_ms=median_lb_ms, median_ms=median_ms, median_ub_ms=median_ub_ms)
end


time_since(t::Float64) = time() - t
time_since(t::Integer) = time_ns() - t


RESULTS = []


# with reset you can reinitialize the inputs as needed
# expr is the code that is timed

macro dphpc_time(expr)
    return quote
        @dphpc_time(nothing, $(esc(expr)))
    end
end

macro dphpc_time(reset, expr)
    return quote
        @dphpc_time($(esc(reset)), $(esc(expr)), "missing")
    end
end

macro dphpc_time(reset, expr, preset)
    if PROFILING
        return quote
            preset = $(esc(preset))
            if preset ∈ PRESETS_TO_RUN  
                start_time = time() # in seconds
                i = 0
                ProfileView.@profview begin
                    while time_since(start_time) < 5.0 || i < MIN_RUNS
                        if time_since(start_time) > MAX_TIME
                            break
                        end
                        $(esc(reset))
                        $(esc(expr))
                        i += 1
                    end
                end
            end
        end
    elseif PROFILING_GPU
        return quote
            preset = $(esc(preset))
            if preset ∈ PRESETS_TO_RUN  
                $(esc(reset))
                CUDA.@profile $(esc(expr)) # couldnt set it up with external profiler :/
            end
        end
    end
    return quote
        preset = $(esc(preset))
        if preset ∈ PRESETS_TO_RUN     
            measurements_ns = []
            nr_runs = 0
            start_time = time() # in seconds
            for i=1:MIN_RUNS
                $(esc(reset))
                t = time_ns()
                $(esc(expr))
                push!(measurements_ns, time_since(t))
                nr_runs += 1
                if time_since(start_time) > TIMEOUT
                    break
                end
            end
            for i=MIN_RUNS+1:MAX_RUNS
                if time_since(start_time) > MAX_TIME
                    break
                end
                $(esc(reset))
                t = time_ns()
                $(esc(expr))
                push!(measurements_ns, time_since(t))
                nr_runs += 1
            end
            measurements_ms = measurements_ns .* 1e-6
            push!(RESULTS, (nr_runs=nr_runs, median_CI95(measurements_ms)..., preset=$(preset)=="missing" ? missing : $(preset)))
        end
        
    end
end






