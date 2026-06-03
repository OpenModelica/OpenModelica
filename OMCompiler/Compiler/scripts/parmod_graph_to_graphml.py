#!/usr/bin/env python3
# This file belongs to the OpenModelica Run-Time System.
# SPDX-License-Identifier: BSD-3-Clause OR OSMC-PL-1.8 OR AGPL-3.0-or-later
"""Convert a ParModelica auto task-graph / clustering JSON export to GraphML.

The OpenModelica automatic parallelization (``omc --parmodauto``) can export the
simulation task graph together with its clustering as JSON:

    # single snapshot of the final task graph + clustering
    ./<model> -parmodDumpTaskGraph=taskgraph.json

    # one before/after snapshot per clustering optimization:
    #   stages.00.initial.json, stages.01.<opt>.json, stages.02.<opt>.json, ...
    ./<model> -parmodDumpStages=stages

This program reads such a JSON file (the schema is the same for both) and writes
a GraphML file that can be opened in Gephi, yEd, Cytoscape, or read back with
networkx for visualization.

Two views are available (``--mode``):

  * ``tasks``    (default) one node per equation/task; edges are the data
                 dependencies; every node carries its ``cluster`` index and a
                 per-cluster ``color`` so a viewer shows the clustering by
                 coloring the fine-grained graph.
  * ``clusters``          one node per cluster (the contracted graph); a cluster
                 edge exists when any task in one cluster depends on a task in
                 another. Node ``size``/``total_cost`` summarize the cluster.
  * ``lanes``             one yEd group node ("swimlane") per cluster with its
                 tasks nested inside; lanes stack vertically, tasks flow left to
                 right by dependency level. Always yEd-styled (group nodes).
  * ``both``              write the tasks and clusters files.

JSON schema (keyed by the stable equation index):

    { "name": str, "num_threads": int,
      "tasks":        [ {"eq": int, "level": int, "cost": float, "out_degree": int}, ... ],
      "dependencies": [ [src_eq, dst_eq], ... ],
      "clusters":     [ {"eqs": [eq, ...]}, ... ],
      "stage": int, "stage_name": str }       # only present in -parmodDumpStages snapshots

Output is plain GraphML; no third-party packages are required.

Examples:
    python3 parmod_graph_to_graphml.py taskgraph.json
    python3 parmod_graph_to_graphml.py --mode both stages.02.cluster_merge_level_for_bins.json
    python3 parmod_graph_to_graphml.py --mode lanes taskgraph.json          # one lane per cluster
    python3 parmod_graph_to_graphml.py --hardware-lanes taskgraph.json      # K = num_threads lanes
    python3 parmod_graph_to_graphml.py stages.*.json      # batch convert a whole series
"""

import argparse
import colorsys
import json
import os
import sys
from xml.sax.saxutils import escape, quoteattr


def load_export(path):
    """Load and minimally validate a parmodauto JSON export."""
    with open(path, "r") as f:
        data = json.load(f)
    for key in ("tasks", "dependencies", "clusters"):
        if key not in data:
            raise ValueError(
                "'%s' does not look like a parmodauto export: missing '%s' key" % (path, key)
            )
    return data


def cluster_of_eq(data):
    """Map each equation index to the index of the cluster that contains it."""
    mapping = {}
    for cidx, cluster in enumerate(data["clusters"]):
        for eq in cluster["eqs"]:
            mapping[eq] = cidx
    return mapping


def palette(n):
    """Return n visually distinct '#rrggbb' colors (evenly spaced hues)."""
    if n <= 0:
        return []
    colors = []
    for i in range(n):
        h = (i / float(n)) % 1.0
        # vary saturation/value a little so neighbours differ even for many clusters
        s = 0.55 + 0.25 * ((i % 2))
        v = 0.95 - 0.20 * ((i // 2) % 2)
        r, g, b = colorsys.hsv_to_rgb(h, s, v)
        colors.append("#%02x%02x%02x" % (int(r * 255), int(g * 255), int(b * 255)))
    return colors


# ---------------------------------------------------------------------------
# tiny GraphML writer (no dependencies)
# ---------------------------------------------------------------------------

class GraphMLWriter:
    """Builds a GraphML document. Key types: int, long, float, double, string."""

    def __init__(self):
        self._keys = []          # (kid, domain, name, gtype)
        self._key_id = {}        # (domain, name) -> kid
        self._nodes = []         # (nid, [(kid, value), ...], gfx|None, group|None)
        self._edges = []         # (eid, src, dst, [(kid, value), ...], gfx|None)
        self._graph_data = []    # (kid, value)
        self._groups = []        # (gid, group_gfx) ; yEd group/lane nodes (yed output only)

    def key(self, domain, name, gtype):
        ident = (domain, name)
        if ident not in self._key_id:
            kid = "d%d" % len(self._keys)
            self._key_id[ident] = kid
            self._keys.append((kid, domain, name, gtype))
        return self._key_id[ident]

    def graph_data(self, domain_name_type_value):
        for name, gtype, value in domain_name_type_value:
            if value is None:
                continue
            self._graph_data.append((self.key("graph", name, gtype), value))

    def group(self, gid, gfx):
        """Register a yEd group node (a collapsible box / lane). Child nodes are
        attached with node(..., group=gid). Only affects yEd output."""
        self._groups.append((gid, gfx))

    def node(self, nid, attrs, gfx=None, group=None):
        """gfx: optional dict {label, fill, shape, x, y, w, h} for yEd rendering.
        group: id of a registered group() this node is nested in (yEd output)."""
        data = [(self.key("node", n, t), v) for (n, t, v) in attrs if v is not None]
        self._nodes.append((nid, data, gfx, group))

    def edge(self, eid, src, dst, attrs=(), gfx=None):
        """gfx: optional dict {color, width} for yEd rendering."""
        data = [(self.key("edge", n, t), v) for (n, t, v) in attrs if v is not None]
        self._edges.append((eid, src, dst, data, gfx))

    @staticmethod
    def _fmt(value):
        if isinstance(value, bool):
            return "true" if value else "false"
        return escape(str(value))

    @staticmethod
    def _node_gfx_xml(gfx, indent):
        g = {"label": "", "fill": "#cccccc", "shape": "ellipse",
             "x": 0.0, "y": 0.0, "w": 60.0, "h": 30.0,
             "align": "center", "fontsize": 11, "fontstyle": "plain"}
        g.update({k: v for k, v in gfx.items() if v is not None})
        pad = " " * indent
        return [
            '%s<data key="dng">' % pad,
            '%s  <y:ShapeNode>' % pad,
            '%s    <y:Geometry height="%s" width="%s" x="%s" y="%s"/>'
            % (pad, g["h"], g["w"], g["x"], g["y"]),
            '%s    <y:Fill color="%s" transparent="false"/>' % (pad, escape(str(g["fill"]))),
            '%s    <y:BorderStyle color="#000000" raised="false" type="line" width="1.0"/>' % pad,
            '%s    <y:NodeLabel alignment="%s" autoSizePolicy="content"'
            ' fontSize="%s" fontStyle="%s" modelName="internal" modelPosition="c"'
            ' textColor="#000000" visible="true">%s</y:NodeLabel>'
            % (pad, escape(str(g["align"])), g["fontsize"], escape(str(g["fontstyle"])),
               escape(str(g["label"]))),
            '%s    <y:Shape type="%s"/>' % (pad, escape(str(g["shape"]))),
            '%s  </y:ShapeNode>' % pad,
            '%s</data>' % pad,
        ]

    @staticmethod
    def _edge_gfx_xml(gfx, indent):
        g = {"color": "#000000", "width": "1.0"}
        g.update({k: v for k, v in gfx.items() if v is not None})
        pad = " " * indent
        return [
            '%s<data key="deg">' % pad,
            '%s  <y:PolyLineEdge>' % pad,
            '%s    <y:LineStyle color="%s" type="line" width="%s"/>'
            % (pad, escape(str(g["color"])), g["width"]),
            '%s    <y:Arrows source="none" target="standard"/>' % pad,
            '%s  </y:PolyLineEdge>' % pad,
            '%s</data>' % pad,
        ]

    @classmethod
    def _group_gfx_xml(cls, gfx, indent):
        """yEd group node (ProxyAutoBoundsNode with an open + a closed realizer)."""
        g = {"label": "", "fill": "#f5f5f5", "header": "#ebebeb",
             "x": 0.0, "y": 0.0, "w": 200.0, "h": 120.0}
        g.update({k: v for k, v in gfx.items() if v is not None})
        pad = " " * indent

        def realizer(closed, w, h):
            state = 'closed="%s" innerGraphDisplayEnabled="false"' % ("true" if closed else "false")
            return [
                '  <y:GroupNode>',
                '    <y:Geometry height="%s" width="%s" x="%s" y="%s"/>' % (h, w, g["x"], g["y"]),
                '    <y:Fill color="%s" transparent="false"/>' % escape(str(g["fill"])),
                '    <y:BorderStyle color="#000000" type="dashed" width="1.0"/>',
                '    <y:NodeLabel alignment="right" autoSizePolicy="node_width"'
                ' backgroundColor="%s" fontSize="12" fontStyle="bold" modelName="internal"'
                ' modelPosition="t" textColor="#000000" visible="true">%s</y:NodeLabel>'
                % (escape(str(g["header"])), escape(str(g["label"]))),
                '    <y:Shape type="roundrectangle"/>',
                '    <y:State %s/>' % state,
                '    <y:Insets bottom="20" left="20" right="20" top="28"/>',
                '    <y:BorderInsets bottom="0" left="0" right="0" top="0"/>',
                '  </y:GroupNode>',
            ]
        lines = ['<data key="dng">', '  <y:ProxyAutoBoundsNode>', '    <y:Realizers active="0">']
        lines += ["      " + ln for ln in realizer(False, g["w"], g["h"])]
        lines += ["      " + ln for ln in realizer(True, 130.0, 50.0)]
        lines += ['    </y:Realizers>', '  </y:ProxyAutoBoundsNode>', '</data>']
        return [pad + ln for ln in lines]

    def _node_xml(self, nid, data, gfx, yed, indent):
        """Emit a leaf <node> (with optional yEd ShapeNode graphics)."""
        pad = " " * indent
        body = ['%s  <data key=%s>%s</data>' % (pad, quoteattr(kid), self._fmt(value))
                for kid, value in data]
        if yed and gfx is not None:
            body += self._node_gfx_xml(gfx, indent + 2)
        if body:
            return ['%s<node id=%s>' % (pad, quoteattr(nid))] + body + ['%s</node>' % pad]
        return ['%s<node id=%s/>' % (pad, quoteattr(nid))]

    def dumps(self, graph_id="G", edgedefault="directed", yed=False):
        out = ['<?xml version="1.0" encoding="UTF-8"?>']
        out.append('<graphml xmlns="http://graphml.graphdrawing.org/xmlns"')
        out.append('         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"')
        if yed:
            out.append('         xmlns:y="http://www.yworks.com/xml/graphml"')
            out.append('         xmlns:yed="http://www.yworks.com/xml/yed/3"')
        out.append('         xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns'
                   ' http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">')
        for kid, domain, name, gtype in self._keys:
            out.append('  <key id=%s for=%s attr.name=%s attr.type=%s/>'
                       % (quoteattr(kid), quoteattr(domain), quoteattr(name), quoteattr(gtype)))
        if yed:
            # yFiles graphics keys (no attr.name/attr.type; carry the visual data)
            out.append('  <key id="dng" for="node" yfiles.type="nodegraphics"/>')
            out.append('  <key id="deg" for="edge" yfiles.type="edgegraphics"/>')
        out.append('  <graph id=%s edgedefault=%s>' % (quoteattr(graph_id), quoteattr(edgedefault)))
        for kid, value in self._graph_data:
            out.append('    <data key=%s>%s</data>' % (quoteattr(kid), self._fmt(value)))

        use_groups = yed and bool(self._groups)
        if use_groups:
            members = {}  # gid -> [(nid, data, gfx), ...]
            ungrouped = []
            for nid, data, gfx, group in self._nodes:
                if group is not None:
                    members.setdefault(group, []).append((nid, data, gfx))
                else:
                    ungrouped.append((nid, data, gfx))
            for gid, ggfx in self._groups:
                out.append('    <node id=%s yfiles.foldertype="group">' % quoteattr(gid))
                out.extend(self._group_gfx_xml(ggfx, 6))
                out.append('      <graph edgedefault=%s id="%s:">'
                           % (quoteattr(edgedefault), gid))
                for nid, data, gfx in members.get(gid, []):
                    out.extend(self._node_xml(nid, data, gfx, yed, 8))
                out.append('      </graph>')
                out.append('    </node>')
            for nid, data, gfx in ungrouped:
                out.extend(self._node_xml(nid, data, gfx, yed, 4))
        else:
            for nid, data, gfx, group in self._nodes:
                out.extend(self._node_xml(nid, data, gfx, yed, 4))

        for eid, src, dst, data, gfx in self._edges:
            body = ['      <data key=%s>%s</data>' % (quoteattr(kid), self._fmt(value))
                    for kid, value in data]
            if yed and gfx is not None:
                body += self._edge_gfx_xml(gfx, 6)
            if body:
                out.append('    <edge id=%s source=%s target=%s>'
                           % (quoteattr(eid), quoteattr(src), quoteattr(dst)))
                out.extend(body)
                out.append('    </edge>')
            else:
                out.append('    <edge id=%s source=%s target=%s/>'
                           % (quoteattr(eid), quoteattr(src), quoteattr(dst)))
        out.append('  </graph>')
        out.append('</graphml>')
        return "\n".join(out) + "\n"


def _common_graph_data(w, data, mode):
    w.graph_data([
        ("name", "string", data.get("name")),
        ("num_threads", "int", data.get("num_threads")),
        ("num_clusters", "int", len(data["clusters"])),
        ("num_tasks", "int", len(data["tasks"])),
        ("stage", "int", data.get("stage")),
        ("stage_name", "string", data.get("stage_name")),
        ("view", "string", mode),
    ])


# layout spacing (yEd coordinates; level = column, in pixels)
_X_SPACING = 220.0
_Y_SPACING = 70.0

# GraphML/yEd "int" is a 32-bit signed integer. Equation indices are 'long' in the
# runtime; if any value exceeds the 32-bit range we must NOT declare it as int or
# yEd silently truncates it (the very warning this tool avoids). Fall back to string.
_INT32_MIN = -2147483648
_INT32_MAX = 2147483647


def _fits_int32(values):
    return all(v is None or (_INT32_MIN <= int(v) <= _INT32_MAX) for v in values)


def _eq_type(eqs, what="equation index"):
    """Pick a yEd-safe attr.type for equation indices: 'int' if they all fit in
    32 bits, else 'string' (avoids silent overflow/truncation in yEd)."""
    if _fits_int32(eqs):
        return "int"
    sys.stderr.write("warning: some %s values exceed 32-bit int range; "
                     "emitting them as 'string' so yEd does not truncate them\n" % what)
    return "string"


def _layered_positions(node_levels):
    """node_levels: list of (node_id, level). Returns id -> (x, y), laid out
    left-to-right by level so the longest dependency path reads as graph width
    (matches how the clustering minimizes graph 'height')."""
    by_level = {}
    for nid, lvl in node_levels:
        by_level.setdefault(int(lvl) if lvl is not None else 0, []).append(nid)
    pos = {}
    for lvl in sorted(by_level):
        col = by_level[lvl]
        y0 = -(len(col) - 1) * _Y_SPACING / 2.0  # center each column vertically
        for i, nid in enumerate(col):
            pos[nid] = (lvl * _X_SPACING, y0 + i * _Y_SPACING)
    return pos


def _task_label(eq, level):
    """Node caption: 'equation (level)', or just the equation if level is unknown."""
    return "%d (%s)" % (eq, level) if level is not None else "%d" % eq


# what the encoding means, per view -- shown as a legend box in the yEd output
_LEGEND_ROWS = {
    "tasks": [
        "Node = one equation (task).",
        "Node label:  equation_number (level_number)",
        "  level = depth in the dependency graph (1 = runs first).",
        "Node color = the cluster the task was merged into.",
        "Arrow A → B = B depends on A (A runs before B).",
        "  grey arrow = same cluster,  dark arrow = across clusters.",
        "Left → right = increasing level (the graph 'height').",
    ],
    "clusters": [
        "Node = one cluster (a group of equations run as a unit).",
        "Node label:  c<index> (<number of equations>)",
        "Node size grows with the equation count.",
        "Arrow A → B = some task in B depends on a task in A.",
        "  edge thickness = number of cross-cluster dependencies.",
        "Left → right = increasing level.",
    ],
    "lanes": [
        "Each box (swimlane) = one cluster; nested nodes are its tasks.",
        "Node label:  equation_number (level_number)",
        "Node color = cluster.   Lanes stack top-to-bottom.",
        "Within a lane, left → right = increasing level (1 = first).",
        "Arrow A → B = B depends on A;  red = crosses lanes.",
    ],
    "lanes_hw": [
        "Each box (swimlane) = one hardware lane / core.",
        "Clusters are packed onto K = num_threads lanes.",
        "Node label:  equation_number (level_number)",
        "Node color = cluster (so you see clusters within a core).",
        "Within a lane, left → right = increasing level (1 = first).",
        "Arrow A → B = B depends on A;  red = crosses lanes.",
    ],
}


def _add_legend(w, data, view, minx, miny):
    """Add a free-standing legend box (yEd) to the left of the graph explaining
    what the nodes, labels, colors and edges mean."""
    rows = list(_LEGEND_ROWS.get(view, []))
    title = "Legend - %s" % data.get("name", "task graph")
    sub = {"tasks": "task graph", "clusters": "cluster graph",
           "lanes": "cluster swimlanes", "lanes_hw": "hardware-lane swimlanes"}.get(view, view)
    body = title + "\n(" + sub + ")\n\n" + "\n".join(rows)
    longest = max([len(title)] + [len(r) for r in rows] + [1])
    width = max(360.0, longest * 6.6 + 24.0)
    height = 30.0 + 18.0 * (len(rows) + 2)
    w.node("__legend__", [("kind", "string", "legend")],
           gfx={"label": body, "fill": "#fffbe0", "shape": "rectangle",
                "x": minx - width - 60.0, "y": miny,
                "w": width, "h": height,
                "align": "left", "fontsize": 12})


def build_tasks_graphml(data, legend=False):
    """One node per task (equation), colored by its cluster."""
    w = GraphMLWriter()
    _common_graph_data(w, data, "tasks")

    eq2cluster = cluster_of_eq(data)
    colors = palette(len(data["clusters"]))
    pos = _layered_positions([(t["eq"], t.get("level", 0)) for t in data["tasks"]])
    eq_type = _eq_type([t["eq"] for t in data["tasks"]])

    known = set()
    for t in data["tasks"]:
        eq = t["eq"]
        known.add(eq)
        cidx = eq2cluster.get(eq, -1)
        color = colors[cidx] if 0 <= cidx < len(colors) else "#cccccc"
        x, y = pos.get(eq, (0.0, 0.0))
        label = _task_label(eq, t.get("level"))
        w.node("eq%d" % eq, [
            ("eq", eq_type, eq),
            ("level", "int", t.get("level")),
            ("cost", "double", t.get("cost")),
            ("out_degree", "int", t.get("out_degree")),
            ("cluster", "int", cidx),
            ("color", "string", color),
            ("label", "string", label),
        ], gfx={"label": label, "fill": color, "shape": "ellipse",
                "x": x, "y": y, "w": 70.0, "h": 30.0})

    dropped = 0
    for i, dep in enumerate(data["dependencies"]):
        src, dst = dep[0], dep[1]
        if src not in known or dst not in known:
            dropped += 1
            continue
        same = eq2cluster.get(src) == eq2cluster.get(dst)
        w.edge("e%d" % i, "eq%d" % src, "eq%d" % dst, [
            ("intra_cluster", "boolean", bool(same)),
        ], gfx={"color": "#999999" if same else "#333333"})
    if dropped:
        sys.stderr.write("warning: dropped %d dependency edge(s) referencing unknown tasks\n" % dropped)
    if legend and pos:
        xs = [p[0] for p in pos.values()]
        ys = [p[1] for p in pos.values()]
        _add_legend(w, data, "tasks", min(xs), min(ys))
    return w


def build_clusters_graphml(data, legend=False):
    """One node per cluster (the contracted graph)."""
    w = GraphMLWriter()
    _common_graph_data(w, data, "clusters")

    eq2cluster = cluster_of_eq(data)
    task_by_eq = {t["eq"]: t for t in data["tasks"]}
    colors = palette(len(data["clusters"]))

    min_levels = []
    for cidx, cluster in enumerate(data["clusters"]):
        levels = [task_by_eq[e].get("level") for e in cluster["eqs"]
                  if e in task_by_eq and task_by_eq[e].get("level") is not None]
        min_levels.append((("c%d" % cidx), min(levels) if levels else 0))
    pos = _layered_positions(min_levels)

    for cidx, cluster in enumerate(data["clusters"]):
        eqs = cluster["eqs"]
        costs = [task_by_eq[e].get("cost", 0.0) for e in eqs if e in task_by_eq]
        levels = [task_by_eq[e].get("level") for e in eqs if e in task_by_eq and task_by_eq[e].get("level") is not None]
        eqs_str = " ".join(str(e) for e in eqs)
        color = colors[cidx] if cidx < len(colors) else "#cccccc"
        x, y = pos.get("c%d" % cidx, (0.0, 0.0))
        # scale node size a little with the number of equations it holds
        side = 40.0 + 8.0 * min(len(eqs), 12)
        w.node("c%d" % cidx, [
            ("cluster", "int", cidx),
            ("size", "int", len(eqs)),
            ("total_cost", "double", sum(costs) if costs else 0.0),
            ("min_level", "int", min(levels) if levels else None),
            ("max_level", "int", max(levels) if levels else None),
            ("color", "string", color),
            ("eqs", "string", eqs_str),
            ("label", "string", "c%d (%d eqs)" % (cidx, len(eqs))),
        ], gfx={"label": "c%d\n%d eqs" % (cidx, len(eqs)), "fill": color,
                "shape": "roundrectangle", "x": x, "y": y, "w": side, "h": side})

    # contract dependencies: weight = number of inter-cluster task dependencies
    weight = {}
    for dep in data["dependencies"]:
        ca = eq2cluster.get(dep[0])
        cb = eq2cluster.get(dep[1])
        if ca is None or cb is None or ca == cb:
            continue
        weight[(ca, cb)] = weight.get((ca, cb), 0) + 1
    for i, ((ca, cb), wt) in enumerate(sorted(weight.items())):
        w.edge("e%d" % i, "c%d" % ca, "c%d" % cb, [("weight", "int", wt)],
               gfx={"width": "%.1f" % (1.0 + min(wt, 8))})
    if legend and pos:
        xs = [p[0] for p in pos.values()]
        ys = [p[1] for p in pos.values()]
        _add_legend(w, data, "clusters", min(xs), min(ys))
    return w


_LANE_HEIGHT = 150.0   # vertical band per cluster/lane
_LANE_NODE_DY = 38.0   # vertical spacing between tasks sharing a level within a lane


def _cluster_cost(data):
    """Per-cluster cost = sum of its task costs (fallback: number of equations)."""
    task_by_eq = {t["eq"]: t for t in data["tasks"]}
    costs = []
    for cluster in data["clusters"]:
        c = sum((task_by_eq.get(e, {}).get("cost") or 0.0) for e in cluster["eqs"])
        costs.append(c if c > 0 else float(len(cluster["eqs"])))
    return costs


def _hardware_lane_assignment(data):
    """Map each cluster to a hardware lane (core). Returns (cluster_index -> lane,
    K, real). If the export carries a real per-cluster "lane" (>= 0) — as produced
    by cluster_fixed_width_min_height in the runtime — that exact assignment is
    used (real=True). Otherwise the clusters are packed onto K = num_threads lanes
    with greedy longest-processing-time load balancing (real=False, a best-effort
    reconstruction, since the dynamic TBB schedulers have no static mapping)."""
    clusters = data["clusters"]
    runtime_lanes = [c.get("lane", -1) for c in clusters]
    if clusters and all(l is not None and l >= 0 for l in runtime_lanes):
        K = max(int(data.get("num_threads") or 1), max(runtime_lanes) + 1)
        return {i: runtime_lanes[i] for i in range(len(clusters))}, K, True

    K = max(1, int(data.get("num_threads") or 1))
    costs = _cluster_cost(data)
    order = sorted(range(len(clusters)), key=lambda c: -costs[c])  # heaviest first
    load = [0.0] * K
    lane = {}
    for cidx in order:
        l = min(range(K), key=lambda i: load[i])  # least-loaded lane
        lane[cidx] = l
        load[l] += costs[cidx]
    return lane, K, False


def build_lanes_graphml(data, hardware=False, legend=False):
    """Swimlane view (yEd group nodes). Each lane is a group node with task nodes
    nested inside; lanes stack vertically and within a lane tasks flow left-to-right
    by dependency level. Tasks are always colored by their cluster.

    hardware=False: one lane per cluster.
    hardware=True : K = num_threads lanes (the hardware cores); clusters are packed
                    onto the lanes by load balancing, so you see the parallel
                    execution lanes while the cluster coloring is still visible."""
    w = GraphMLWriter()
    _common_graph_data(w, data, "lanes")
    all_xy = []

    eq2cluster = cluster_of_eq(data)
    task_by_eq = {t["eq"]: t for t in data["tasks"]}
    colors = palette(len(data["clusters"]))
    eq_type = _eq_type([t["eq"] for t in data["tasks"]])

    # Define the lanes (groups). Each: (lane_id, label, header_color, [eqs]).
    lanes = []
    if hardware:
        lane_of, K, real = _hardware_lane_assignment(data)
        w.graph_data([("lane_source", "string",
                       "runtime" if real else "reconstructed-load-balanced")])
        if not real:
            sys.stderr.write("note: export carries no per-cluster lane (clustering is not "
                             "fixed_width_min_height); reconstructing hardware lanes by "
                             "load balancing\n")
        lane_eqs = {l: [] for l in range(K)}
        lane_nclust = {l: 0 for l in range(K)}
        for cidx, cluster in enumerate(data["clusters"]):
            lane_eqs[lane_of[cidx]].extend(cluster["eqs"])
            lane_nclust[lane_of[cidx]] += 1
        lane_hdr = palette(K)
        for l in range(K):
            if not lane_eqs[l]:
                continue  # idle core (more lanes than clusters): skip empty lane
            lanes.append(("lane%d" % l,
                          "hardware lane %d / %d  (%d clusters, %d eqs)"
                          % (l, K, lane_nclust[l], len(lane_eqs[l])),
                          lane_hdr[l], lane_eqs[l]))
    else:
        for cidx, cluster in enumerate(data["clusters"]):
            lanes.append(("lane%d" % cidx,
                          "cluster c%d  (%d eqs)" % (cidx, len(cluster["eqs"])),
                          colors[cidx] if cidx < len(colors) else "#cccccc",
                          cluster["eqs"]))

    known = set()
    for band, (gid, label, header, eqs) in enumerate(lanes):
        lane_top = band * _LANE_HEIGHT
        # layout this lane's tasks: x by level, stack tasks sharing a level
        per_level = {}
        placed = []
        for eq in sorted(eqs, key=lambda e: (task_by_eq.get(e, {}).get("level", 0) or 0, e)):
            lvl = int(task_by_eq.get(eq, {}).get("level", 0) or 0)
            slot = per_level.get(lvl, 0)
            per_level[lvl] = slot + 1
            x = lvl * _X_SPACING
            y = lane_top + 34.0 + slot * _LANE_NODE_DY  # 34px leaves room for the lane label
            placed.append((eq, x, y))
            all_xy.append((x, y))
        xs = [p[1] for p in placed] or [0.0]
        pad = 30.0
        w.group(gid, {
            "label": label, "fill": "#fbfbfb", "header": header,
            "x": min(xs) - pad, "y": lane_top,
            "w": (max(xs) - min(xs)) + 2 * pad + 60.0,
            "h": _LANE_HEIGHT - 12.0,
        })
        for eq, x, y in placed:
            known.add(eq)
            t = task_by_eq.get(eq, {"eq": eq})
            cidx = eq2cluster.get(eq, -1)
            color = colors[cidx] if 0 <= cidx < len(colors) else "#cccccc"
            label = _task_label(eq, t.get("level"))
            w.node("eq%d" % eq, [
                ("eq", eq_type, eq),
                ("level", "int", t.get("level")),
                ("cost", "double", t.get("cost")),
                ("out_degree", "int", t.get("out_degree")),
                ("cluster", "int", cidx),
                ("color", "string", color),
                ("label", "string", label),
            ], gfx={"label": label, "fill": color, "shape": "ellipse",
                    "x": x, "y": y, "w": 70.0, "h": 30.0}, group=gid)

    dropped = 0
    for i, dep in enumerate(data["dependencies"]):
        src, dst = dep[0], dep[1]
        if src not in known or dst not in known:
            dropped += 1
            continue
        same = eq2cluster.get(src) == eq2cluster.get(dst)
        w.edge("e%d" % i, "eq%d" % src, "eq%d" % dst, [
            ("intra_cluster", "boolean", bool(same)),
        ], gfx={"color": "#bbbbbb" if same else "#cc3333",
                "width": "1.0" if same else "2.0"})
    if dropped:
        sys.stderr.write("warning: dropped %d dependency edge(s) referencing unknown tasks\n" % dropped)
    if legend and all_xy:
        minx = min(p[0] for p in all_xy)
        miny = min(p[1] for p in all_xy)
        _add_legend(w, data, "lanes_hw" if hardware else "lanes", minx, miny)
    return w


def derive_output(in_path, mode, suffix_for_mode):
    base = in_path
    if base.lower().endswith(".json"):
        base = base[:-len(".json")]
    return base + suffix_for_mode[mode]


_BUILDERS = {"tasks": build_tasks_graphml, "clusters": build_clusters_graphml,
             "lanes": build_lanes_graphml}
_SUFFIX = {"tasks": ".graphml", "clusters": ".clusters.graphml", "lanes": ".lanes.graphml"}


def convert_one(in_path, mode, out_path=None, yed=False, hardware=False, legend=True):
    data = load_export(in_path)

    modes = ["tasks", "clusters"] if mode == "both" else [mode]
    written = []
    for m in modes:
        use_yed = yed or (m == "lanes")  # lanes are group nodes -> only meaningful in yEd
        add_legend = legend and use_yed   # the legend is a yEd-styled box
        if m == "lanes":
            doc = build_lanes_graphml(data, hardware=hardware, legend=add_legend)
            n_lanes = (min(max(1, int(data.get("num_threads") or 1)), len(data["clusters"]))
                       if hardware else len(data["clusters"]))
            extra = " in %d %slanes" % (n_lanes, "hardware " if hardware else "")
            n_nodes = len(data["tasks"])
        else:
            doc = _BUILDERS[m](data, legend=add_legend)
            n_nodes = len(data["clusters"]) if m == "clusters" else len(data["tasks"])
            extra = ""
        target = out_path if (out_path and mode != "both") else derive_output(in_path, m, _SUFFIX)
        with open(target, "w") as f:
            f.write(doc.dumps(yed=use_yed))
        print("Wrote %s (%s view: %d nodes%s%s)"
              % (target, m, n_nodes, extra, ", yEd-styled" if use_yed else ""))
        written.append(target)
    return written


def main(argv=None):
    p = argparse.ArgumentParser(
        description="Convert a ParModelica auto task-graph/clustering JSON export to GraphML.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    p.add_argument("inputs", nargs="+", metavar="JSON",
                   help="parmodauto JSON export(s) (-parmodDumpTaskGraph / -parmodDumpStages output)")
    p.add_argument("--mode", choices=["tasks", "clusters", "lanes", "both"], default="tasks",
                   help="which view to emit (default: tasks). 'lanes' groups each cluster "
                        "into a yEd swimlane (group node) with its tasks nested inside")
    p.add_argument("-o", "--output", metavar="GRAPHML",
                   help="output file (only with a single input and --mode != both; "
                        "otherwise the name is derived from each input)")
    p.add_argument("--yed", action="store_true",
                   help="emit yWorks/yEd-flavored GraphML: colored shape nodes, labels, "
                        "and level-based coordinates so the graph opens already laid out in yEd")
    p.add_argument("--hardware-lanes", action="store_true",
                   help="in lanes mode, use K = num_threads hardware lanes (cores) instead of "
                        "one lane per cluster; clusters are packed onto the lanes by load "
                        "balancing (implies --mode lanes)")
    p.add_argument("--no-legend", dest="legend", action="store_false",
                   help="do not add the explanatory legend box to the yEd output")
    args = p.parse_args(argv)

    if args.hardware_lanes and args.mode != "lanes":
        if args.mode != "tasks":  # tasks is the silent default; warn only on a real override
            sys.stderr.write("note: --hardware-lanes implies --mode lanes\n")
        args.mode = "lanes"

    if args.output and (len(args.inputs) > 1 or args.mode == "both"):
        p.error("-o/--output cannot be combined with multiple inputs or --mode both")

    rc = 0
    for in_path in args.inputs:
        try:
            convert_one(in_path, args.mode, args.output, yed=args.yed,
                        hardware=args.hardware_lanes, legend=args.legend)
        except (OSError, ValueError, json.JSONDecodeError) as e:
            sys.stderr.write("error: %s: %s\n" % (in_path, e))
            rc = 1
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
