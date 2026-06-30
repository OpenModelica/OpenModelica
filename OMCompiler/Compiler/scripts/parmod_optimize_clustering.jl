#!/usr/bin/env julia
#
# This file is part of OpenModelica.
#
# Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
# c/o Linköpings universitet, Department of Computer and Information Science,
# SE-58183 Linköping, Sweden.
#
# All rights reserved.
#
# THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
# THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
# ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
# RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
# VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
#
# The OpenModelica software and the OSMC (Open Source Modelica Consortium)
# Public License (OSMC-PL) are obtained from OSMC, either from the above
# address, from the URLs:
# http://www.openmodelica.org or
# https://github.com/OpenModelica/ or
# http://www.ida.liu.se/projects/OpenModelica,
# and in the OpenModelica distribution.
#
# GNU AGPL version 3 is obtained from:
# https://www.gnu.org/licenses/licenses.html#GPL
#
# This program is distributed WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
# IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
#
# See the full OSMC Public License conditions for more details.
#
# SPDX-License-Identifier: OSMC-PL-1.8 OR AGPL-3.0-or-later
#
# Optimize a ParModelica auto task-graph clustering with a metaheuristic, then
# write the result back in the format the parmodauto executable imports.
#
# The OpenModelica automatic parallelization (`omc --parmodauto`) can export the
# simulation task graph together with its clustering as JSON, and can import an
# externally produced clustering instead of computing one itself:
#
#     ./<model> -parmodExportTaskGraph=taskgraph.json     # export task graph + clustering
#     ./<model> -parmodImportClustering=clustering.json   # import a clustering and simulate
#
# This script closes that loop. It reads an exported task graph, formulates the
# clustering as an optimization problem and solves it with a metaheuristic from
# MetaheuristicsAlgorithms.jl, then writes a clustering JSON that can be fed back
# in via -parmodImportClustering (optionally launching the simulation directly
# with --run).
#
# Optimization problem (the FixedWidthMinHeight clustering objective from task 2):
#   * Each task is assigned to one of K hardware lanes (K = number of CPU cores).
#   * Tasks that share the same dependency level AND lane form one cluster, so the
#     resulting cluster graph is always acyclic (edges only ever go to a strictly
#     higher level) — importing it can never be rejected for forming a cycle.
#   * Each task's cost is the per-task "cost" estimate from the export (the runtime's
#     estimate; it falls back to 0 when absent).
#   * The objective is the graph HEIGHT: levels run one after another, the lanes
#     within a level run in parallel, so a level takes as long as its busiest lane
#     and the height is the sum over levels of that busiest-lane cost. Minimizing it
#     balances each level's work across the K lanes (shortening the longest path).
#   The metaheuristic searches the lane assignment x in [0,K)^N to minimize height.
#
# JSON schema (keyed by the stable equation index, same as the other parmod tools):
#   { "name": str, "num_threads": int,
#     "tasks":        [ {"eq": int, "level": int, "cost": float, "out_degree": int}, ... ],
#     "dependencies": [ [src_eq, dst_eq], ... ],
#     "clusters":     [ {"eqs": [eq, ...], "lane": int}, ... ] }
# The written file uses this same schema (so the python/Julia visualizers can read
# it too); the executable's importer only consumes clusters[*].eqs.
#
# Usage:
#   julia parmod_optimize_clustering.jl taskgraph.json
#   julia parmod_optimize_clustering.jl --algorithm WOA --iters 500 taskgraph.json
#   julia parmod_optimize_clustering.jl --cores 8 -o clustering.json taskgraph.json
#   julia parmod_optimize_clustering.jl --run --exe ./r_parallel taskgraph.json
#
# Dependencies: JSON, MetaheuristicsAlgorithms. Install once with:
#   julia -e 'using Pkg; Pkg.add("JSON"); \
#             Pkg.add(url="https://github.com/AbdelazimHussien/MetaheuristicsAlgorithms.jl")'

using JSON
using Printf
using Random

# ---------------------------------------------------------------------------
# argument parsing (no external ArgParse dependency)
# ---------------------------------------------------------------------------
function parse_args(argv)
    opts = Dict{String,Any}("algorithm" => "GWO", "pop" => 30, "iters" => 200,
                            "cores" => nothing, "seed" => nothing, "output" => nothing,
                            "run" => false, "exe" => nothing, "simargs" => String[],
                            "input" => nothing)
    i = 1
    while i <= length(argv)
        a = argv[i]
        if a == "--algorithm" || a == "-a"
            i += 1; opts["algorithm"] = argv[i]
        elseif a == "--pop"
            i += 1; opts["pop"] = parse(Int, argv[i])
        elseif a == "--iters"
            i += 1; opts["iters"] = parse(Int, argv[i])
        elseif a == "--cores" || a == "-k"
            i += 1; opts["cores"] = parse(Int, argv[i])
        elseif a == "--seed"
            i += 1; opts["seed"] = parse(Int, argv[i])
        elseif a == "-o" || a == "--output"
            i += 1; opts["output"] = argv[i]
        elseif a == "--run"
            opts["run"] = true
        elseif a == "--exe"
            i += 1; opts["exe"] = argv[i]
        elseif a == "--sim-arg"
            i += 1; push!(opts["simargs"], argv[i])
        elseif a == "-h" || a == "--help"
            println("""
            parmod_optimize_clustering.jl - optimize a ParModelica auto clustering with a
            metaheuristic (MetaheuristicsAlgorithms.jl) and write it back for -parmodImportClustering.

            usage: julia parmod_optimize_clustering.jl [options] TASKGRAPH.json

            options:
              -a, --algorithm NAME   metaheuristic to use (default: GWO), e.g. GWO, WOA, AEO, SSA, ... (99 algorithms)
              --pop N                population size (default: 30)
              --iters N              maximum iterations (default: 200)
              -k, --cores K          number of hardware lanes (default: "num_threads" from the file)
              --seed S               seed the RNG for a reproducible search
              -o, --output FILE      output clustering json (default: <input>.optimized.json)
              --run                  after writing, launch the simulation with -parmodImportClustering
              --exe PATH             simulation executable to run (required with --run)
              --sim-arg ARG          extra argument to pass to the executable (repeatable)
              -h, --help             show this help
            """)
            exit(0)
        elseif startswith(a, "-") && a != "-"
            error("unknown option: $a")
        else
            opts["input"] = a
        end
        i += 1
    end
    opts["input"] === nothing && error("usage: parmod_optimize_clustering.jl [options] TASKGRAPH.json (see --help)")
    opts["run"] && opts["exe"] === nothing && error("--run requires --exe PATH (the simulation executable)")
    return opts
end

# ---------------------------------------------------------------------------
# model
# ---------------------------------------------------------------------------

"Load and minimally validate a parmodauto JSON export."
function load_export(path)
    data = JSON.parsefile(path)
    for k in ("tasks", "dependencies", "clusters")
        haskey(data, k) || error("'$path' is not a parmodauto export: missing '$k'")
    end
    return data
end

"The task graph in a layout convenient for the optimizer (1-based vertices)."
struct TaskModel
    eqs::Vector{Int}             # vertex -> stable equation index
    level::Vector{Int}           # vertex -> dependency level
    cost::Vector{Float64}        # vertex -> cost (out-degree estimate)
    edges::Vector{Tuple{Int,Int}}# (src_vertex, dst_vertex), root excluded
    K::Int                       # number of hardware lanes
    name::String
    num_threads::Int
end

function build_model(data, cores)
    tasks = data["tasks"]
    N = length(tasks)
    eqs   = [Int(t["eq"]) for t in tasks]
    level = [Int(get(t, "level", 0)) for t in tasks]
    cost  = [Float64(get(t, "cost", 0.0)) for t in tasks]
    vid   = Dict(eqs[v] => v for v in 1:N)         # eq -> 1-based vertex
    edges = Tuple{Int,Int}[]
    for dep in data["dependencies"]
        s = get(vid, Int(dep[1]), 0); d = get(vid, Int(dep[2]), 0)
        (s != 0 && d != 0) && push!(edges, (s, d))
    end
    num_threads = Int(get(data, "num_threads", 1))
    K = max(1, cores === nothing ? num_threads : cores)
    name = String(get(data, "name", "model"))
    return TaskModel(eqs, level, cost, edges, K, name, num_threads)
end

# ---------------------------------------------------------------------------
# objective: graph height of a clustering
# ---------------------------------------------------------------------------

"""Group tasks into clusters keyed by (level, lane); returns (cid, nclusters,
lane_of_cluster). Because every cluster lives on a single level and graph edges
always go to a strictly higher level, the contracted cluster graph is acyclic."""
function assign_clusters(model::TaskModel, lane::Vector{Int})
    N = length(lane)
    keymap = Dict{Tuple{Int,Int},Int}()
    cid = Vector{Int}(undef, N)
    clane = Int[]
    for v in 1:N
        key = (model.level[v], lane[v])
        c = get!(() -> (push!(clane, lane[v]); length(clane)), keymap, key)
        cid[v] = c
    end
    return cid, length(clane), clane
end

"""Graph HEIGHT for a lane assignment: levels execute sequentially, lanes within a
level execute in parallel, so a level costs its busiest lane and the height is the
sum of those over all levels. This is the value the optimizer minimizes."""
function makespan(model::TaskModel, lane::Vector{Int})
    bylevel = Dict{Int,Dict{Int,Float64}}()
    for v in 1:length(lane)
        d = get!(() -> Dict{Int,Float64}(), bylevel, model.level[v])
        d[lane[v]] = get(d, lane[v], 0.0) + model.cost[v]
    end
    h = 0.0
    for (_, d) in bylevel
        h += maximum(values(d))
    end
    return h
end

"""Lane-independent reference heights: the serial height (everything on one lane =
total work) and the lower bound reachable with unlimited lanes (sum over levels of
the single most expensive task)."""
function reference_heights(model::TaskModel)
    work = Dict{Int,Float64}()
    crit = Dict{Int,Float64}()
    for v in 1:length(model.eqs)
        L = model.level[v]
        work[L] = get(work, L, 0.0) + model.cost[v]
        crit[L] = max(get(crit, L, 0.0), model.cost[v])
    end
    return sum(values(work); init = 0.0), sum(values(crit); init = 0.0)
end

"""Height of the clustering already stored in the export, using each cluster's own
hardware lane. Returns nothing when the export carries no lane assignment (every
"lane" is -1, e.g. the default clustering), since then there is nothing to compare."""
function input_height(model::TaskModel, data)
    eq2lane = Dict{Int,Int}()
    for c in data["clusters"]
        l = Int(get(c, "lane", -1))
        l < 0 && return nothing
        for e in c["eqs"]
            eq2lane[Int(e)] = l
        end
    end
    isempty(eq2lane) && return nothing
    lane = [get(eq2lane, model.eqs[v], 0) for v in 1:length(model.eqs)]
    return makespan(model, lane)
end

"""Decode a continuous search position into integer lane assignments. The float is
clamped to [0, K-1] *before* flooring, so positions that an algorithm pushed far
outside the bounds (many do not enforce them) still map to a valid lane instead of
overflowing Int conversion."""
decode_lanes(model::TaskModel, x) =
    [clamp(floor(Int, clamp(Float64(x[i]), 0.0, Float64(model.K - 1))), 0, model.K - 1)
     for i in 1:length(x)]

"The objective the metaheuristic minimizes."
function make_objective(model::TaskModel)
    return function (x::AbstractVector)
        return makespan(model, decode_lanes(model, x))
    end
end

# ---------------------------------------------------------------------------
# metaheuristic driver (robust to the two argument orders in the package)
# ---------------------------------------------------------------------------

"Look up the algorithm function by name inside MetaheuristicsAlgorithms. The
binding is read through invokelatest because the module is imported at run time."
function resolve_algorithm(MH, name)
    sym = Symbol(name)
    Base.invokelatest(isdefined, MH, sym) ||
        error("unknown algorithm '$name'. It must be defined by " *
              "MetaheuristicsAlgorithms.jl (e.g. GWO, WOA, AEO, SSA).")
    return Base.invokelatest(getfield, MH, sym)
end

"""Call the algorithm. The package has shipped two signatures across versions;
try the documented `alg(objfun, lb, ub, npop, max_iter)` first and fall back to
`alg(npop, max_iter, lb, ub, dim, objfun)`. The call goes through invokelatest
because the package is imported at run time (otherwise Julia >= 1.12 rejects the
freshly defined method with a "too new for this world" error)."""
function call_algorithm(alg, objfun, lb, ub, npop, iters)
    try
        return Base.invokelatest(alg, objfun, lb, ub, npop, iters)
    catch e
        # Only retry with the other signature when the failure is "no such method
        # on alg itself"; a MethodError thrown from deep inside the algorithm is a
        # bug in that algorithm and should surface as-is, not be masked.
        (e isa MethodError && e.f === alg) || rethrow()
        return Base.invokelatest(alg, npop, iters, lb, ub, length(lb), objfun)
    end
end

"Pull the best position vector out of whatever struct/tuple the algorithm returns.
Properties are read through invokelatest (the result type is defined at run time)."
function best_position(res)
    for f in (:bestX, :BestX, :bestPosition, :best_x, :gbest, :x, :position)
        Base.invokelatest(hasproperty, res, f) && return Base.invokelatest(getproperty, res, f)
    end
    res isa Tuple && length(res) >= 2 && return res[2]
    error("could not find the best position in a result of type $(typeof(res))")
end

function best_fitness(res)
    for f in (:bestF, :BestF, :bestFitness, :best_f, :gbestFitness, :f, :fitness)
        Base.invokelatest(hasproperty, res, f) && return Base.invokelatest(getproperty, res, f)
    end
    res isa Tuple && length(res) >= 1 && return res[1]
    return nothing
end

# ---------------------------------------------------------------------------
# output
# ---------------------------------------------------------------------------

"Build the export-schema dict for a clustering given vertex->cluster id and lanes."
function clustering_dict(model::TaskModel, data, cid::Vector{Int}, nC::Int, clane)
    eqs = [Int[] for _ in 1:nC]
    for v in 1:length(cid)
        push!(eqs[cid[v]], model.eqs[v])
    end
    clusters = [Dict("eqs" => eqs[c],
                     "lane" => (clane === nothing ? -1 : clane[c])) for c in 1:nC]
    return Dict("name" => model.name,
                "num_threads" => model.K,
                "tasks" => data["tasks"],
                "dependencies" => data["dependencies"],
                "clusters" => clusters)
end

function lane_loads(model::TaskModel, lane::Vector{Int})
    load = zeros(Float64, model.K)
    for v in 1:length(lane)
        load[lane[v] + 1] += model.cost[v]
    end
    return load
end

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
function main(argv)
    opts = parse_args(argv)
    opts["seed"] !== nothing && Random.seed!(opts["seed"])

    data = load_export(opts["input"])
    model = build_model(data, opts["cores"])
    N = length(model.eqs)
    N == 0 && error("the task graph has no tasks")

    println("Loaded $(model.name): $N tasks, $(length(model.edges)) dependencies, " *
            "$(model.K) lanes (cores).")

    # reference heights and the baseline clustering already in the file
    serial_h, lb_h = reference_heights(model)
    @printf("Reference height: %.3f serial (1 lane)  ..  %.3f lower bound (unlimited lanes)\n",
            serial_h, lb_h)
    base_h = input_height(model, data)
    base_h !== nothing && @printf("Imported clustering height (its own lanes): %.3f\n", base_h)

    # load the optimizer lazily so --help and the baseline work without the package
    local MH
    try
        @eval import MetaheuristicsAlgorithms
        MH = MetaheuristicsAlgorithms
    catch e
        error("could not load MetaheuristicsAlgorithms.jl ($e).\n" *
              "Install it once with:\n" *
              "    julia -e 'using Pkg; Pkg.add(url=\"https://github.com/AbdelazimHussien/MetaheuristicsAlgorithms.jl\")'")
    end

    objfun = make_objective(model)
    lb = zeros(Float64, N)
    ub = fill(Float64(model.K), N)            # decode floors, so K maps to lane K-1
    alg = resolve_algorithm(MH, opts["algorithm"])

    @printf("Optimizing with %s (pop=%d, iters=%d) ...\n",
            opts["algorithm"], opts["pop"], opts["iters"])
    res = call_algorithm(alg, objfun, lb, ub, opts["pop"], opts["iters"])

    bestx = best_position(res)
    lane = decode_lanes(model, bestx)
    cid, nC, clane = assign_clusters(model, lane)
    opt_h = makespan(model, lane)
    reported = best_fitness(res)

    @printf("Optimized clustering: %d clusters, height = %.3f", nC, opt_h)
    reported !== nothing && @printf(" (algorithm reported %.3f)", Float64(reported))
    println()
    opt_h > 0 && @printf("Speedup vs. serial: %.2fx  (%.1f%% height reduction)\n",
                         serial_h / opt_h, 100 * (serial_h - opt_h) / serial_h)
    if base_h !== nothing && base_h > 0
        @printf("Improvement vs. imported clustering: %.1f%%\n", 100 * (base_h - opt_h) / base_h)
    end
    loads = lane_loads(model, lane)
    @printf("Per-lane total cost: [%s]  (max %.3f, min %.3f)\n",
            join((@sprintf("%.1f", l) for l in loads), ", "), maximum(loads), minimum(loads))

    out = opts["output"]
    if out === nothing
        base = endswith(lowercase(opts["input"]), ".json") ? opts["input"][1:end-5] : opts["input"]
        out = base * ".optimized.json"
    end
    open(out, "w") do f
        JSON.print(f, clustering_dict(model, data, cid, nC, clane), 2)
    end
    println("Wrote clustering to $out")

    if opts["run"]
        cmd = `$(opts["exe"]) -parmodImportClustering=$out $(opts["simargs"])`
        println("Running: $cmd")
        run(cmd)
    else
        println("Re-run the simulation with this clustering via:")
        println("    <model_executable> -parmodImportClustering=$out")
    end
end

main(ARGS)
