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
# Display a ParModelica auto task-graph / clustering JSON export with GraphPlot.jl.
#
# The OpenModelica automatic parallelization (`omc --parmodauto`) can export the
# simulation task graph together with its clustering as JSON:
#
#     ./<model> -parmodExportTaskGraph=taskgraph.json          # final task graph + clustering
#     ./<model> -parmodDumpStages=stages                     # one snapshot per optimization
#
# This script reads such a file and renders it (SVG by default, PNG with --png)
# using GraphPlot.jl, laying tasks out left-to-right by dependency level and
# coloring them by cluster.
#
# JSON schema (keyed by the stable equation index):
#   { "name": str, "num_threads": int,
#     "tasks":        [ {"eq": int, "level": int, "cost": float, "out_degree": int}, ... ],
#     "dependencies": [ [src_eq, dst_eq], ... ],
#     "clusters":     [ {"eqs": [eq, ...], "lane": int}, ... ] }   # "lane": real core, -1 if none
#
# Views (--mode):
#   tasks    (default) one node per equation, colored by cluster; label "eq (level)".
#   clusters            the contracted graph, one node per cluster.
#   lanes               one node per equation, banded vertically by hardware lane
#                       (core) and colored by cluster; uses the real "lane" from the
#                       export when present, otherwise reconstructs it by load balancing.
#
# Usage:
#   julia parmod_graph_plot.jl taskgraph.json
#   julia parmod_graph_plot.jl --mode clusters taskgraph.json
#   julia parmod_graph_plot.jl --mode lanes --png taskgraph.json
#
# Dependencies: JSON, Graphs, GraphPlot, Colors, Compose (and Cairo+Fontconfig for --png).
# Install once with:
#   julia -e 'using Pkg; Pkg.add(["JSON","Graphs","GraphPlot","Colors","Compose"])'

using JSON
using Graphs
using GraphPlot
using Colors
using Compose
using Printf

# ---------------------------------------------------------------------------
# argument parsing (no external ArgParse dependency)
# ---------------------------------------------------------------------------
function parse_args(argv)
    opts = Dict{String,Any}("mode" => "tasks", "output" => nothing,
                            "png" => false, "input" => nothing)
    i = 1
    while i <= length(argv)
        a = argv[i]
        if a == "--mode"
            i += 1; opts["mode"] = argv[i]
        elseif a == "-o" || a == "--output"
            i += 1; opts["output"] = argv[i]
        elseif a == "--hardware-lanes"
            opts["mode"] = "lanes"
        elseif a == "--png"
            opts["png"] = true
        elseif a == "-h" || a == "--help"
            println("""
            parmod_graph_plot.jl - render a ParModelica auto task-graph/clustering
            JSON export (from -parmodExportTaskGraph / -parmodDumpStages) with GraphPlot.jl.

            usage: julia parmod_graph_plot.jl [options] JSON

            options:
              --mode tasks|clusters|lanes   view to render (default: tasks)
              --hardware-lanes              alias for --mode lanes (K = num_threads core lanes)
              --png                         render PNG instead of SVG (needs Cairo, Fontconfig)
              -o, --output FILE             output path (default: derived from the input name)
              -h, --help                    show this help
            """)
            exit(0)
        elseif startswith(a, "-")
            error("unknown option: $a")
        else
            opts["input"] = a
        end
        i += 1
    end
    opts["input"] === nothing && error("usage: parmod_graph_plot.jl [--mode tasks|clusters|lanes] [--png] [-o FILE] JSON")
    opts["mode"] in ("tasks", "clusters", "lanes") || error("--mode must be tasks, clusters or lanes")
    return opts
end

# ---------------------------------------------------------------------------
# helpers
# ---------------------------------------------------------------------------

"Load and minimally validate a parmodauto JSON export."
function load_export(path)
    data = JSON.parsefile(path)
    for k in ("tasks", "dependencies", "clusters")
        haskey(data, k) || error("'$path' is not a parmodauto export: missing '$k'")
    end
    return data
end

"eq index -> 0-based cluster index that contains it."
function cluster_of_eq(data)
    m = Dict{Int,Int}()
    for (ci, c) in enumerate(data["clusters"])
        for e in c["eqs"]
            m[Int(e)] = ci - 1
        end
    end
    return m
end

"n visually distinct fill colors."
palette(n) = n <= 0 ? RGB{Float64}[] :
    distinguishable_colors(n, [RGB(0.95, 0.95, 0.95)], dropseed = true)

"""Embed a CSS color-scheme rule into an SVG so viewers that honor
`prefers-color-scheme` (web browsers, the VS Code SVG preview, ...) paint a
theme-matched backdrop instead of a transparency checkerboard: white in light
mode, near-black in dark mode. Viewers that ignore it just keep the transparent
background. Node/label/edge colors are already legible on either backdrop."""
function inject_theme_css(path)
    s = read(path, String)
    m = findfirst("<svg", s)
    m === nothing && return
    gt = findnext(==('>'), s, last(m))
    gt === nothing && return
    style = """

    <style type="text/css"><![CDATA[
      svg { background: #ffffff; color-scheme: light dark; }
      @media (prefers-color-scheme: dark) { svg { background: #1e1e1e; } }
    ]]></style>"""
    write(path, s[1:gt] * style * s[gt+1:end])
end

"Perceived luminance of a color (0 dark .. 1 light)."
luminance(c) = 0.299 * red(c) + 0.587 * green(c) + 0.114 * blue(c)

"A label/border color that contrasts with the node's own fill, so each node and
its label stay legible on ANY page background (light or dark mode)."
contrast_color(c) = luminance(c) > 0.55 ? colorant"black" : colorant"white"

"Lay nodes out left->right by level; returns (locs_x, locs_y) for ids 1..N given a
per-id level. Nodes sharing a level are spread (and centered) vertically."
function layered_positions(levels::Vector{Int})
    bylevel = Dict{Int,Vector{Int}}()
    for (v, lvl) in enumerate(levels)
        push!(get!(bylevel, lvl, Int[]), v)
    end
    N = length(levels)
    xs = zeros(Float64, N); ys = zeros(Float64, N)
    for lvl in sort(collect(keys(bylevel)))
        col = bylevel[lvl]
        y0 = -(length(col) - 1) / 2.0
        for (i, v) in enumerate(col)
            xs[v] = Float64(lvl)
            ys[v] = y0 + (i - 1)
        end
    end
    return xs, ys
end

"Per-cluster cost = sum of task costs (fallback: equation count)."
function cluster_costs(data)
    tcost = Dict{Int,Float64}()
    for t in data["tasks"]
        tcost[Int(t["eq"])] = Float64(get(t, "cost", 0.0))
    end
    costs = Float64[]
    for c in data["clusters"]
        s = sum(get(tcost, Int(e), 0.0) for e in c["eqs"]; init = 0.0)
        push!(costs, s > 0 ? s : Float64(length(c["eqs"])))
    end
    return costs
end

"""Map each cluster to a hardware lane. Uses the real per-cluster "lane" (>= 0)
from the export when every cluster has one; otherwise packs clusters onto
K = num_threads lanes by greedy longest-processing-time load balancing.
Returns (cluster_index(0-based) -> lane, K, real::Bool)."""
function hardware_lane_assignment(data)
    clusters = data["clusters"]
    runtime = [Int(get(c, "lane", -1)) for c in clusters]
    if !isempty(clusters) && all(>=(0), runtime)
        K = max(Int(get(data, "num_threads", 1)), maximum(runtime) + 1)
        return Dict(i - 1 => runtime[i] for i in 1:length(clusters)), K, true
    end
    K = max(1, Int(get(data, "num_threads", 1)))
    costs = cluster_costs(data)
    order = sortperm(costs; rev = true)           # heaviest first
    load = zeros(Float64, K)
    lane = Dict{Int,Int}()
    for ci in order
        l = argmin(load)                          # least-loaded lane (1-based)
        lane[ci - 1] = l - 1
        load[l] += costs[ci]
    end
    return lane, K, false
end

# ---------------------------------------------------------------------------
# views
# ---------------------------------------------------------------------------

"Build the tasks/lanes graph. lanes=true bands nodes vertically by hardware lane."
function build_task_plot(data; lanes::Bool=false)
    tasks = data["tasks"]
    N = length(tasks)
    eq_of = [Int(t["eq"]) for t in tasks]
    vid = Dict(eq_of[v] => v for v in 1:N)            # eq -> 1-based vertex
    eq2c = cluster_of_eq(data)
    nclusters = length(data["clusters"])
    cols = palette(nclusters)

    g = SimpleDiGraph(N)
    for dep in data["dependencies"]
        s = get(vid, Int(dep[1]), 0); d = get(vid, Int(dep[2]), 0)
        (s != 0 && d != 0) && add_edge!(g, s, d)
    end

    levels = [Int(get(t, "level", 0)) for t in tasks]
    labels = [@sprintf("%d (%d)", eq_of[v], levels[v]) for v in 1:N]
    nodefillc = [cols[eq2c[eq_of[v]] + 1] for v in 1:N]

    if lanes
        lane_of, K, real = hardware_lane_assignment(data)
        @info (real ? "using real per-cluster lanes from the export" :
                      "no per-cluster lane in export; reconstructing lanes by load balancing")
        # x by level, y by lane band (lane 0 on top)
        locs_x = Float64.(levels)
        locs_y = [Float64(lane_of[eq2c[eq_of[v]]]) for v in 1:N]
        # spread nodes that collide at the same (level, lane)
        seen = Dict{Tuple{Int,Int},Int}()
        for v in 1:N
            key = (Int(levels[v]), Int(locs_y[v]))
            k = get(seen, key, 0); seen[key] = k + 1
            locs_y[v] = locs_y[v] + 0.18 * k
        end
        title = "$(get(data,"name","model")) — $K hardware lanes (lane = core, color = cluster)"
    else
        locs_x, locs_y = layered_positions(levels)
        title = "$(get(data,"name","model")) — task graph (color = cluster, label = eq (level))"
    end
    return g, locs_x, locs_y, labels, nodefillc, title
end

"Build the contracted cluster graph."
function build_cluster_plot(data)
    clusters = data["clusters"]
    n = length(clusters)
    cols = palette(n)
    tlevel = Dict{Int,Int}()
    for t in data["tasks"]; tlevel[Int(t["eq"])] = Int(get(t, "level", 0)); end
    eq2c = cluster_of_eq(data)

    g = SimpleDiGraph(n)
    seen = Set{Tuple{Int,Int}}()
    for dep in data["dependencies"]
        ca = get(eq2c, Int(dep[1]), -1); cb = get(eq2c, Int(dep[2]), -1)
        if ca >= 0 && cb >= 0 && ca != cb && !((ca, cb) in seen)
            push!(seen, (ca, cb)); add_edge!(g, ca + 1, cb + 1)
        end
    end

    minlvl = [isempty(c["eqs"]) ? 0 : minimum(get(tlevel, Int(e), 0) for e in c["eqs"]) for c in clusters]
    locs_x, locs_y = layered_positions(minlvl)
    labels = [@sprintf("c%d (%d)", ci - 1, length(clusters[ci]["eqs"])) for ci in 1:n]
    nodefillc = [cols[ci] for ci in 1:n]
    title = "$(get(data,"name","model")) — cluster graph (label = c<idx> (n eqs))"
    return g, locs_x, locs_y, labels, nodefillc, title
end

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
function main(argv)
    opts = parse_args(argv)
    data = load_export(opts["input"])

    if opts["mode"] == "clusters"
        g, lx, ly, labels, fillc, title = build_cluster_plot(data)
        suffix = ".clusters"
    else
        g, lx, ly, labels, fillc, title = build_task_plot(data; lanes = (opts["mode"] == "lanes"))
        suffix = opts["mode"] == "lanes" ? ".lanes" : ""
    end

    println(title)
    # Per-node label + border colors chosen from each node's own fill luminance, so
    # nodes and labels read on a white page AND a dark page (dark fills get a white
    # label and a white outline; light fills get black). Edges use a mid-gray that
    # is visible on both. The canvas is left transparent so it adopts the viewer's
    # background instead of forcing white.
    labelc = [contrast_color(c) for c in fillc]
    plot = gplot(g, lx, ly;
                 nodelabel = labels,
                 nodefillc = fillc,
                 nodelabelc = labelc,
                 nodestrokec = labelc,
                 nodestrokelw = 0.8,
                 nodelabelsize = 0.6,
                 NODESIZE = 0.025,
                 EDGELINEWIDTH = 0.3,
                 arrowlengthfrac = nv(g) > 0 && is_directed(g) ? 0.03 : 0.0,
                 edgestrokec = colorant"gray")

    out = opts["output"]
    if out === nothing
        base = endswith(lowercase(opts["input"]), ".json") ? opts["input"][1:end-5] : opts["input"]
        out = base * suffix * (opts["png"] ? ".png" : ".svg")
    end

    # size the canvas with the graph so labels stay legible
    side = clamp(round(Int, 2 + sqrt(max(nv(g), 1))), 12, 60)
    if opts["png"]
        @eval using Cairo, Fontconfig   # only needed for PNG
        draw(PNG(out, (side)Compose.cm, (side)Compose.cm), plot)
    else
        draw(SVG(out, (side)Compose.cm, (side)Compose.cm), plot)
        inject_theme_css(out)           # theme-matched backdrop for browser / VS Code preview
    end
    println("Wrote $out  ($(nv(g)) nodes, $(ne(g)) edges)")
end

main(ARGS)
