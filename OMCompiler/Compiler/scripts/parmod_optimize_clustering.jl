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
# Second optimization problem (--objective merge_across_levels), the search
# version of the runtime's -parmodClustering=merge_across_levels:
#   * Clusters that depend on each other are merged, also across levels. A merge
#     that closes a cycle in the cluster graph is not done.
#   * A cluster is merged as long as it communicates at least as much as it
#     computes: the number of clusters it exchanges values with is not below its
#     number of equations.
#   * The runtime takes the next merge with a fixed rule. Here every dependency has a
#     priority and the merges are tried in that order; the metaheuristic searches
#     the priorities x in [0,1]^E for the clustering with the shortest estimated
#     evaluation time.
#   * The estimate (--estimate bound, the default) is the lower bound
#     max(longest path of cluster costs, total cost / K), without overhead.
#     --estimate schedule is a simulated evaluation: K threads take the clusters
#     that are ready, first come first served, and a cluster takes its cost plus
#     an overhead for the cluster itself and one for every cluster it sends
#     values to (--cluster-overhead, --edge-overhead, in the unit of the task
#     costs).
#     The default overheads were fitted to the C runtime with the flow scheduler
#     and task costs in milliseconds.
#   * With --max-comm-weight W the stop rule gets a weight w, searched in [1, W]: a
#     cluster is merged as long as w * communication >= equations. A larger w gives
#     larger clusters, which pays when the overhead of a cluster is high.
#   * The task costs of an export are one measurement each. --cost-from FILE, given
#     once or more, takes the smallest cost of every task over these exports too.
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
#   julia parmod_optimize_clustering.jl --algorithm Jaya --iters 500 taskgraph.json
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
                            "objective" => "height", "estimate" => "bound",
                            "cluster-overhead" => 1.5e-3, "edge-overhead" => 5.0e-4,
                            "max-comm-weight" => 1.0,
                            "cost-from" => String[],
                            "run" => false, "exe" => nothing, "simargs" => String[],
                            "input" => nothing)
    i = 1
    while i <= length(argv)
        a = argv[i]
        if a == "--algorithm" || a == "-a"
            i += 1; opts["algorithm"] = argv[i]
        elseif a == "--objective"
            i += 1; opts["objective"] = argv[i]
        elseif a == "--estimate"
            i += 1; opts["estimate"] = argv[i]
        elseif a == "--cluster-overhead"
            i += 1; opts["cluster-overhead"] = parse(Float64, argv[i])
        elseif a == "--edge-overhead"
            i += 1; opts["edge-overhead"] = parse(Float64, argv[i])
        elseif a == "--max-comm-weight"
            i += 1; opts["max-comm-weight"] = parse(Float64, argv[i])
        elseif a == "--cost-from"
            i += 1; push!(opts["cost-from"], argv[i])
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
              -a, --algorithm NAME   metaheuristic to use (default: GWO), e.g. GWO, Jaya, AVOA, MPA, ... (99 algorithms)
              --objective NAME       height (default): lanes per level, minimize the graph height;
                                     merge_across_levels: merge dependent clusters of any level
                                     until each communicates less than it computes
              --estimate NAME        for merge_across_levels: bound (default), the lower bound
                                     max(longest path, total cost / K); schedule, a simulated
                                     evaluation on K threads with overhead
              --cluster-overhead X   schedule: time added to every cluster (default: 1.5e-3)
              --edge-overhead X      schedule: time added to a cluster for every cluster it
                                     sends values to (default: 5e-4)
              --max-comm-weight W    also search a weight w in [1, W] of the communication: a
                                     cluster is merged as long as w * communication is not
                                     below its number of equations (default: 1, no search)
              --cost-from FILE       another export of the same model; every task gets its
                                     smallest cost over all exports (repeatable)
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
    opts["objective"] in ("height", "merge_across_levels") ||
        error("unknown objective '$(opts["objective"])': use height or merge_across_levels")
    opts["estimate"] in ("schedule", "bound") ||
        error("unknown estimate '$(opts["estimate"])': use schedule or bound")
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
# objective: merge across levels
# ---------------------------------------------------------------------------

"The clusters of a partition and the clusters each one exchanges values with."
struct ClusterGraph
    cl::Vector{Int}                # vertex -> cluster
    members::Vector{Vector{Int}}   # cluster -> vertices, empty once merged away
    succ::Vector{Set{Int}}
    pred::Vector{Set{Int}}
    label::Vector{Int}             # topological numbering: label[a] < label[b] for a -> b
end

"One cluster per task. Fails when the task graph has a cycle."
function ClusterGraph(model::TaskModel)
    N = length(model.eqs)
    g = ClusterGraph(collect(1:N), [[v] for v in 1:N], [Set{Int}() for _ in 1:N],
                     [Set{Int}() for _ in 1:N], zeros(Int, N))
    for (s, d) in model.edges
        push!(g.succ[s], d); push!(g.pred[d], s)
    end
    indeg = [length(g.pred[v]) for v in 1:N]
    ready = [v for v in 1:N if indeg[v] == 0]
    next = 0
    while !isempty(ready)
        v = pop!(ready)
        g.label[v] = (next += 1)
        for w in g.succ[v]
            (indeg[w] -= 1) == 0 && push!(ready, w)
        end
    end
    next == N || error("the task graph has a cycle")
    return g
end

"Does the cluster communicate, weighted by w, at least as much as it computes?"
needs_merge(g::ClusterGraph, c::Int, w::Float64) =
    w * (length(g.succ[c]) + length(g.pred[c])) >= length(g.members[c])

"Is b reached from a by more than the edge a -> b? Then merging them closes a cycle."
function other_path(g::ClusterGraph, a::Int, b::Int)
    seen = Set{Int}()
    stack = Int[]
    for x in g.succ[a]
        if x != b && g.label[x] < g.label[b]
            push!(seen, x); push!(stack, x)
        end
    end
    while !isempty(stack)
        x = pop!(stack)
        for y in g.succ[x]
            y == b && return true
            if g.label[y] < g.label[b] && !(y in seen)
                push!(seen, y); push!(stack, y)
            end
        end
    end
    return false
end

"Merge the clusters of an edge a -> b that has no other path from a to b."
function merge!(g::ClusterGraph, a::Int, b::Int)
    s, o = min(a, b), max(a, b)
    merged_label = g.label[b]
    for v in g.members[o]
        g.cl[v] = s
    end
    append!(g.members[s], g.members[o]); empty!(g.members[o])
    for x in g.succ[o]
        delete!(g.pred[x], o)
        x != s && (push!(g.succ[s], x); push!(g.pred[x], s))
    end
    for x in g.pred[o]
        delete!(g.succ[x], o)
        x != s && (push!(g.pred[s], x); push!(g.succ[x], s))
    end
    empty!(g.succ[o]); empty!(g.pred[o])
    # the merged cluster takes the later label; move the clusters after it up
    g.label[s] = merged_label
    stack = [s]
    while !isempty(stack)
        x = pop!(stack)
        for y in g.succ[x]
            if g.label[y] <= g.label[x]
                g.label[y] = g.label[x] + 1; push!(stack, y)
            end
        end
    end
    return s
end

"""Decode a search position, one priority per dependency, into a clustering: the
dependencies are taken by decreasing priority and the two clusters of one are
merged when one of them still communicates at least as much as it computes and
the merge closes no cycle. With a `max_weight` above 1 the position has one more
entry, the weight of the communication in that rule. A merge can make another one possible, so the list is
walked until nothing changes."""
function merge_by_priority(model::TaskModel, x, max_weight::Float64 = 1.0)
    g = ClusterGraph(model)
    E = length(model.edges)
    w = max_weight > 1.0 ? 1.0 + clamp(Float64(x[E + 1]), 0.0, 1.0) * (max_weight - 1.0) : 1.0
    order = sortperm([Float64(x[i]) for i in 1:length(model.edges)]; rev = true)
    merged = true
    while merged
        merged = false
        for e in order
            a = g.cl[model.edges[e][1]]; b = g.cl[model.edges[e][2]]
            a == b && continue
            (needs_merge(g, a, w) || needs_merge(g, b, w)) || continue
            other_path(g, a, b) && continue
            merge!(g, a, b)
            merged = true
        end
    end
    return g.cl
end

"""A clustering, given as vertex -> cluster, measured: (clusters, clusters that
communicate at least as much as they compute, longest path of cluster costs).
The path is Inf when the cluster graph has a cycle."""
function clustering_stats(model::TaskModel, cost::Vector{Float64}, cl::Vector{Int})
    ids = Dict{Int,Int}()
    cid = [get!(ids, c, length(ids) + 1) for c in cl]
    nC = length(ids)
    ccost = zeros(Float64, nC); ops = zeros(Int, nC)
    for v in 1:length(cid)
        ccost[cid[v]] += cost[v]; ops[cid[v]] += 1
    end
    succ = [Set{Int}() for _ in 1:nC]; pred = [Set{Int}() for _ in 1:nC]
    for (s, d) in model.edges
        a = cid[s]; b = cid[d]
        a != b && (push!(succ[a], b); push!(pred[b], a))
    end
    violations = count(c -> length(succ[c]) + length(pred[c]) >= ops[c], 1:nC)
    indeg = [length(pred[c]) for c in 1:nC]
    ready = [c for c in 1:nC if indeg[c] == 0]
    finish = zeros(Float64, nC)
    visited = 0; height = 0.0
    while !isempty(ready)
        c = pop!(ready)
        visited += 1
        finish[c] += ccost[c]
        height = max(height, finish[c])
        for d in succ[c]
            finish[d] = max(finish[d], finish[c])
            (indeg[d] -= 1) == 0 && push!(ready, d)
        end
    end
    return (nC = nC, violations = violations, height = (visited == nC ? height : Inf), cid = cid,
            ccost = ccost, succ = succ, npred = [length(pred[c]) for c in 1:nC])
end

"How the time of one evaluation is estimated: the name and the two overheads of the schedule."
struct Estimate
    name::String
    cluster_overhead::Float64
    edge_overhead::Float64
end

"""Time of one evaluation on K threads, simulated: a free thread takes the cluster
that became ready first, and a cluster takes its cost, the cluster overhead and
the edge overhead for every cluster it sends values to."""
function schedule_time(st, K::Int, est::Estimate)
    nC = st.nC
    wait = copy(st.npred)
    queue = [c for c in 1:nC if wait[c] == 0]
    head = 1
    running = Tuple{Float64,Int}[]
    t = 0.0
    while head <= length(queue) || !isempty(running)
        while head <= length(queue) && length(running) < K
            c = queue[head]; head += 1
            push!(running, (t + st.ccost[c] + est.cluster_overhead + est.edge_overhead * length(st.succ[c]), c))
        end
        i = argmin(running)
        t, c = running[i]
        deleteat!(running, i)
        for d in st.succ[c]
            (wait[d] -= 1) == 0 && push!(queue, d)
        end
    end
    return t
end

"Estimated time of one evaluation of a clustering; Inf when its cluster graph has a cycle."
function estimated_time(model::TaskModel, total, st, est::Estimate)
    isinf(st.height) && return Inf
    est.name == "bound" && return max(st.height, total / model.K)
    return schedule_time(st, model.K, est)
end

"Every task's smallest cost over the export and the other exports of the same model."
function robust_costs(model::TaskModel, paths)
    cost = copy(model.cost)
    vid = Dict(model.eqs[v] => v for v in 1:length(model.eqs))
    for path in paths
        for t in load_export(path)["tasks"]
            v = get(vid, Int(t["eq"]), 0)
            v == 0 && error("'$path' has equation $(t["eq"]), which the task graph does not have")
            c = Float64(get(t, "cost", 0.0))
            cost[v] = cost[v] == 0.0 ? c : (c == 0.0 ? cost[v] : min(cost[v], c))
        end
    end
    return cost
end

"The clustering stored in the export as vertex -> cluster; unlisted tasks are alone."
function input_clusters(model::TaskModel, data)
    eq2c = Dict{Int,Int}()
    for (c, cluster) in enumerate(data["clusters"]), e in cluster["eqs"]
        eq2c[Int(e)] = c
    end
    n = length(data["clusters"])
    return [get(eq2c, model.eqs[v], n + v) for v in 1:length(model.eqs)]
end

function print_stats(what, model, total, st, est::Estimate)
    if isinf(st.height)
        @printf("%s: %d clusters, the cluster graph has a cycle\n", what, st.nC)
    else
        t = estimated_time(model, total, st, est)
        @printf("%s: %d clusters, %d communicate at least as much as they compute, estimated time %.6g (speedup %.2fx)\n",
                what, st.nC, st.violations, t, total / t)
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
              "MetaheuristicsAlgorithms.jl (e.g. GWO, Jaya, AVOA, MPA).")
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

    if opts["objective"] == "merge_across_levels"
        isempty(model.edges) && error("the task graph has no dependencies, there is nothing to merge")
        # without measured costs every equation counts the same
        cost = robust_costs(model, opts["cost-from"])
        all(==(0.0), cost) && (cost = ones(Float64, N))
        total = sum(cost)
        est = Estimate(opts["estimate"], opts["cluster-overhead"], opts["edge-overhead"])
        print_stats("Clustering in the file", model, total,
                    clustering_stats(model, cost, input_clusters(model, data)), est)

        maxw = opts["max-comm-weight"]
        MH = load_metaheuristics()
        objfun = function (x::AbstractVector)
            st = clustering_stats(model, cost, merge_by_priority(model, x, maxw))
            return estimated_time(model, total, st, est) + st.violations * total
        end
        E = length(model.edges) + (maxw > 1.0 ? 1 : 0)
        alg = resolve_algorithm(MH, opts["algorithm"])
        @printf("Optimizing the merge order with %s (pop=%d, iters=%d) ...\n",
                opts["algorithm"], opts["pop"], opts["iters"])
        res = call_algorithm(alg, objfun, zeros(Float64, E), ones(Float64, E), opts["pop"], opts["iters"])

        st = clustering_stats(model, cost, merge_by_priority(model, best_position(res), maxw))
        print_stats("Optimized clustering", model, total, st, est)
        write_and_run(opts, clustering_dict(model, data, st.cid, st.nC, nothing))
        return
    end

    # reference heights and the baseline clustering already in the file
    serial_h, lb_h = reference_heights(model)
    @printf("Reference height: %.3f serial (1 lane)  ..  %.3f lower bound (unlimited lanes)\n",
            serial_h, lb_h)
    base_h = input_height(model, data)
    base_h !== nothing && @printf("Imported clustering height (its own lanes): %.3f\n", base_h)

    MH = load_metaheuristics()
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

    write_and_run(opts, clustering_dict(model, data, cid, nC, clane))
end

"Load the optimizer lazily so --help and the baseline work without the package."
function load_metaheuristics()
    try
        @eval import MetaheuristicsAlgorithms
        return Base.invokelatest(getfield, @__MODULE__, :MetaheuristicsAlgorithms)
    catch e
        error("could not load MetaheuristicsAlgorithms.jl ($e).\n" *
              "Install it once with:\n" *
              "    julia -e 'using Pkg; Pkg.add(url=\"https://github.com/AbdelazimHussien/MetaheuristicsAlgorithms.jl\")'")
    end
end

function write_and_run(opts, clustering)
    out = opts["output"]
    if out === nothing
        base = endswith(lowercase(opts["input"]), ".json") ? opts["input"][1:end-5] : opts["input"]
        out = base * ".optimized.json"
    end
    open(out, "w") do f
        JSON.print(f, clustering, 2)
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
