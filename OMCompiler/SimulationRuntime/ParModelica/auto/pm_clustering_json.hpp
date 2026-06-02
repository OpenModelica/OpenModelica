/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#pragma once
#ifndef id_PARMOD_CLUSTERING_JSON_HPP
#define id_PARMOD_CLUSTERING_JSON_HPP

/*! JSON export/import of the ParModelica auto task graph and clustering, so that
    clustering/optimization can be developed in external tools.

    Everything is keyed by the equation index (Equation::index), which is stable
    across runs and independent of the internal boost vertex ordering.

    Export (one object):
      { "name": ..., "num_threads": K,
        "tasks":        [ {"eq", "level", "cost", "out_degree"}, ... ],
        "dependencies": [ [eq_src, eq_dst], ... ],
        "clusters":     [ {"eqs": [eq, ...]}, ... ] }   // the resulting clustering

    Import:
      { "clusters": [ {"eqs": [eq, ...]}, ... ] }
    Equations not listed become singleton clusters. Importing aborts (fatal) if a
    referenced equation is unknown, an equation is listed twice, or the resulting
    cluster graph would contain a cycle. */

#include "pm_clustering.hpp" // concat_clusters + task-system types

#include "json.hpp"

#include <cstdlib>
#include <fstream>
#include <iostream>
#include <map>
#include <queue>
#include <set>
#include <string>
#include <vector>

namespace openmodelica { namespace parmodelica {

inline void parmod_json_fatal(const std::string& message) {
    utility::error("Fatal") << message << std::endl;
    std::exit(1);
}

/*! Capture the fine-grained task graph (call before clustering, while every vertex
    is a single task). */
template <typename TaskSystemType>
void collect_task_graph_json(TaskSystemType& task_system, nlohmann::json& out) {

    typedef typename TaskSystemType::GraphType          GraphType;
    typedef typename TaskSystemType::ClusterType        ClusterType;
    typedef typename TaskSystemType::ClusterIdType      ClusterIdType;
    typedef typename TaskSystemType::vertex_iterator    vertex_iterator;
    typedef typename TaskSystemType::adjacency_iterator adjacency_iterator;

    GraphType&          sys_graph = task_system.sys_graph;
    const ClusterIdType root_id = task_system.root_node_id;

    if (task_system.levels_valid == false)
        task_system.update_node_levels();

    out["name"] = task_system.name;
    out["num_threads"] = (int)task_system.max_num_threads;

    nlohmann::json tasks = nlohmann::json::array();
    nlohmann::json deps = nlohmann::json::array();

    vertex_iterator vi, ve;
    for (boost::tie(vi, ve) = vertices(sys_graph); vi != ve; ++vi) {
        if (*vi == root_id)
            continue;
        ClusterType& clust = sys_graph[*vi];
        const long   eq = clust.front().index;

        nlohmann::json t;
        t["eq"] = eq;
        t["level"] = (int)clust.level;
        t["cost"] = clust.cost;
        t["out_degree"] = (int)out_degree(*vi, sys_graph);
        tasks.push_back(t);

        adjacency_iterator ci, ce;
        for (boost::tie(ci, ce) = adjacent_vertices(*vi, sys_graph); ci != ce; ++ci) {
            if (*ci == root_id)
                continue;
            deps.push_back(nlohmann::json::array({eq, sys_graph[*ci].front().index}));
        }
    }

    out["tasks"] = tasks;
    out["dependencies"] = deps;
}

/*! Capture the current clustering (call after clustering): each vertex's equations. */
template <typename TaskSystemType>
void collect_clusters_json(TaskSystemType& task_system, nlohmann::json& out) {

    typedef typename TaskSystemType::GraphType       GraphType;
    typedef typename TaskSystemType::ClusterType     ClusterType;
    typedef typename TaskSystemType::ClusterIdType   ClusterIdType;
    typedef typename TaskSystemType::vertex_iterator vertex_iterator;

    GraphType&          sys_graph = task_system.sys_graph;
    const ClusterIdType root_id = task_system.root_node_id;

    nlohmann::json clusters = nlohmann::json::array();

    vertex_iterator vi, ve;
    for (boost::tie(vi, ve) = vertices(sys_graph); vi != ve; ++vi) {
        if (*vi == root_id)
            continue;
        ClusterType&   clust = sys_graph[*vi];
        nlohmann::json eqs = nlohmann::json::array();
        for (typename ClusterType::iterator it = clust.begin(); it != clust.end(); ++it)
            eqs.push_back(it->index);
        nlohmann::json cl;
        cl["eqs"] = eqs;
        clusters.push_back(cl);
    }

    out["clusters"] = clusters;
}

inline void write_json_file(const std::string& path, const nlohmann::json& j) {
    std::ofstream f(path.c_str());
    if (!f.is_open()) {
        parmod_json_fatal("Could not open '" + path + "' for writing the parmodauto task graph.");
    }
    f << j.dump(2) << std::endl;
    std::cout << "Exported parmodauto task graph to " << path << std::endl;
}

/*! Apply an externally produced clustering. Aborts (fatal) on an invalid clustering. */
template <typename TaskSystemType>
void import_clustering_json(TaskSystemType& task_system, const std::string& path) {

    typedef typename TaskSystemType::GraphType          GraphType;
    typedef typename TaskSystemType::ClusterIdType      ClusterIdType;
    typedef typename TaskSystemType::vertex_iterator    vertex_iterator;
    typedef typename TaskSystemType::adjacency_iterator adjacency_iterator;

    std::ifstream f(path.c_str());
    if (!f.is_open())
        parmod_json_fatal("Could not open clustering json '" + path + "'.");

    nlohmann::json j;
    try {
        f >> j;
    }
    catch (const std::exception& e) {
        parmod_json_fatal("Could not parse clustering json '" + path + "': " + e.what());
    }
    if (!j.contains("clusters"))
        parmod_json_fatal("Clustering json '" + path + "' has no 'clusters' array.");

    GraphType&          sys_graph = task_system.sys_graph;
    const ClusterIdType root_id = task_system.root_node_id;

    if (task_system.levels_valid == false)
        task_system.update_node_levels();

    /* eq index -> vertex (the graph is still single-task at this point) */
    std::map<long, ClusterIdType> eq_to_vid;
    vertex_iterator               vi, ve;
    for (boost::tie(vi, ve) = vertices(sys_graph); vi != ve; ++vi) {
        if (*vi == root_id)
            continue;
        eq_to_vid[sys_graph[*vi].front().index] = *vi;
    }

    /* parse clusters into eq -> cluster id, and cluster id -> eqs */
    std::map<long, int>             eq_to_cluster;
    std::vector<std::vector<long> > cluster_eqs;
    for (nlohmann::json::iterator c = j["clusters"].begin(); c != j["clusters"].end(); ++c) {
        std::vector<long> eqs;
        for (nlohmann::json::iterator e = (*c)["eqs"].begin(); e != (*c)["eqs"].end(); ++e) {
            const long eq = e->get<long>();
            if (eq_to_vid.find(eq) == eq_to_vid.end())
                parmod_json_fatal("Imported clustering references unknown equation " + std::to_string(eq) + ".");
            if (eq_to_cluster.find(eq) != eq_to_cluster.end())
                parmod_json_fatal("Imported clustering assigns equation " + std::to_string(eq) +
                                  " to more than one cluster.");
            eq_to_cluster[eq] = (int)cluster_eqs.size();
            eqs.push_back(eq);
        }
        if (!eqs.empty())
            cluster_eqs.push_back(eqs);
    }

    /* equations not listed become singleton clusters */
    for (typename std::map<long, ClusterIdType>::iterator it = eq_to_vid.begin(); it != eq_to_vid.end(); ++it) {
        if (eq_to_cluster.find(it->first) == eq_to_cluster.end()) {
            eq_to_cluster[it->first] = (int)cluster_eqs.size();
            cluster_eqs.push_back(std::vector<long>(1, it->first));
        }
    }

    const int num_clusters = (int)cluster_eqs.size();

    /* build the induced cluster graph and check it is acyclic (Kahn) */
    std::vector<std::set<int> > succ(num_clusters);
    for (boost::tie(vi, ve) = vertices(sys_graph); vi != ve; ++vi) {
        if (*vi == root_id)
            continue;
        const int          ca = eq_to_cluster[sys_graph[*vi].front().index];
        adjacency_iterator ci, ce;
        for (boost::tie(ci, ce) = adjacent_vertices(*vi, sys_graph); ci != ce; ++ci) {
            if (*ci == root_id)
                continue;
            const int cb = eq_to_cluster[sys_graph[*ci].front().index];
            if (ca != cb)
                succ[ca].insert(cb);
        }
    }
    std::vector<int> indeg(num_clusters, 0);
    for (int a = 0; a < num_clusters; ++a)
        for (std::set<int>::iterator b = succ[a].begin(); b != succ[a].end(); ++b)
            ++indeg[*b];
    std::queue<int> ready;
    for (int a = 0; a < num_clusters; ++a)
        if (indeg[a] == 0)
            ready.push(a);
    int visited = 0;
    while (!ready.empty()) {
        const int a = ready.front();
        ready.pop();
        ++visited;
        for (std::set<int>::iterator b = succ[a].begin(); b != succ[a].end(); ++b)
            if (--indeg[*b] == 0)
                ready.push(*b);
    }
    if (visited != num_clusters)
        parmod_json_fatal("Imported clustering forms a cycle in the cluster graph; aborting.");

    /* realize: merge each cluster's vertices into a representative. Choose the
       lowest-level member as the representative so merges keep edges pointing
       forward (and avoid concat diagnostics). */
    for (int c = 0; c < num_clusters; ++c) {
        std::vector<long>& eqs = cluster_eqs[c];
        if (eqs.size() <= 1)
            continue;
        ClusterIdType rep = eq_to_vid[eqs[0]];
        long          rep_level = sys_graph[rep].level;
        for (size_t k = 1; k < eqs.size(); ++k) {
            const ClusterIdType v = eq_to_vid[eqs[k]];
            if (sys_graph[v].level < rep_level) {
                rep = v;
                rep_level = sys_graph[v].level;
            }
        }
        for (size_t k = 0; k < eqs.size(); ++k) {
            const ClusterIdType v = eq_to_vid[eqs[k]];
            if (v != rep)
                concat_clusters::apply(task_system, rep, v);
        }
    }

    task_system.levels_valid = false;
    std::cout << "Imported parmodauto clustering (" << num_clusters << " clusters) from " << path << std::endl;
}

}} // namespace openmodelica::parmodelica

#endif // header
