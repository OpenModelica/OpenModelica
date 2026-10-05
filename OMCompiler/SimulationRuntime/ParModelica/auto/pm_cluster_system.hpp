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
#ifndef id51EE4BD8_93E1_4245_A0B1E55CDC703CF8
#define id51EE4BD8_93E1_4245_A0B1E55CDC703CF8

/*
 Mahder.Gebremedhin@liu.se  2014-03-07
*/

#include <iostream>
#include <fstream>
#include <map>
#include <queue>
#include <tuple>

#include "pm_graph.hpp"
#include "pm_timer.hpp"
#include "pm_utility.hpp"

namespace openmodelica { namespace parmodelica {

struct TaskNode {
    TaskNode() : level(0), cost(0){}
    virtual ~TaskNode() {}

    long   task_id;
    int    level;
    double cost;

    virtual bool depends_on(const TaskNode&) const = 0;
    virtual void execute() = 0;
};

template <typename T>
struct TaskCluster : public utility::pm_vector<T> {
    typedef T                                              TaskType;
    typedef typename utility::pm_vector<T>::iterator       iterator;
    typedef typename utility::pm_vector<T>::const_iterator const_iterator;

  private:
    // TaskCluster& operator=(const TaskCluster& other);

  public:
    double      cost;
    long        level;
    std::string index_list;
    int         group;
    int         lane; /*!< hardware lane (0..K-1) assigned by lane-based clustering
                           (cluster_fixed_width_min_height); -1 if not lane-assigned. */

    TaskCluster() {
        cost = 0;
        level = 0;
        index_list = "$";
        group = 0;
        lane = -1;
    }

    TaskType& add_task(const TaskType& task) {
        this->push_back(task);
        cost += task.cost;
        std::ostringstream os;
        os << "," << task.index;
        index_list += os.str();
        return this->back();
    }

    void clear_cluster() {
        this->clear();
        this->cost = 0;
        this->index_list = "$";
    }

    bool depends_on(const TaskCluster<TaskType>& other) const {
        bool           found = false;
        const_iterator t_iter, o_iter;
        for (t_iter = this->begin(); t_iter != this->end(); ++t_iter) {
            for (o_iter = other.begin(); o_iter != other.end(); ++o_iter) {
                found = t_iter->depends_on(*o_iter);
                if (found)
                    return true;
            }
        }

        return false;
    }

    void execute() {
        iterator t_iter;
        for (t_iter = this->begin(); t_iter != this->end(); ++t_iter) {
            t_iter->execute();
        }
    }

    void profile_execute() {
        this->cost = 0;
        double  elapsed = 0;
        PMTimer task_timer;

        iterator t_iter;
        for (t_iter = this->begin(); t_iter != this->end(); ++t_iter) {
            task_timer.start_timer();
            t_iter->execute();
            task_timer.stop_timer();
            elapsed = task_timer.get_elapsed_time();
            // if(elapsed == 0)
            // t_iter->cost = 0.0005;
            // else
            t_iter->cost = elapsed;

            this->cost += t_iter->cost;

            task_timer.reset_timer();
        }
    }

    static bool cost_comparator(const TaskCluster<TaskType>& lhs, const TaskCluster<TaskType>& rhs) {
        return lhs.cost < rhs.cost;
    }
};

template <typename T>
struct cluster_cost_comparator_by_id {
    typedef T                                     GraphType;
    typedef typename GraphType::vertex_descriptor ClusterIdType;

    const GraphType& graph;
    cluster_cost_comparator_by_id(const GraphType& g) : graph(g) {}

    bool operator()(const ClusterIdType& lhs, const ClusterIdType& rhs) {
        double lhs_cost = graph[lhs].cost;
        double rhs_cost = graph[rhs].cost;
        if (lhs_cost == rhs_cost) {
            int lhs_degree = out_degree(lhs, graph);
            int rhs_degree = out_degree(rhs, graph);
            // if(lhs_degree == rhs_degree) {

            // }
            return lhs_degree < rhs_degree;
        }
        return lhs_cost < rhs_cost;
    }
};

template <typename T>
struct SameLevelClusterIds : public utility::pm_vector<T> {
    typedef T ClusterIdType;

    double total_level_cost;

    SameLevelClusterIds() : total_level_cost(0) {}
};

template <typename T>
class TaskSystem_v2 {

  public:
    typedef T                     TaskType;
    typedef TaskCluster<TaskType> ClusterType;

    typedef DiGraph<ClusterType> GraphType;

    typedef typename GraphType::vertex_descriptor      ClusterIdType;
    typedef typename GraphType::vertex_iterator        vertex_iterator;
    typedef typename GraphType::adjacency_iterator     adjacency_iterator;
    typedef typename GraphType::inv_adjacency_iterator inv_adjacency_iterator;

    typedef std::vector<SameLevelClusterIds<ClusterIdType>> ClusterLevels;

  private:
    long node_count;

  public:
    std::string name;

    size_t max_num_threads;

    ClusterLevels clusters_by_level;
    bool          levels_valid;
    double        total_cost;

    GraphType     sys_graph;
    ClusterIdType root_node_id;

    TaskSystem_v2(const std::string& in_name, size_t mnt) {
        max_num_threads = mnt;
        name = in_name;
        levels_valid = false;
        node_count = 0;
        total_cost = 0;

        // add a new cluster for root node.
        root_node_id = add_vertex(sys_graph);
        // add an empty task to the root node.
        TaskType& root_node = sys_graph[root_node_id].add_task(TaskType());
        root_node.task_id = -1;
    }

    TaskSystem_v2(const TaskSystem_v2& other) {
        this->name = other.name;
        this->max_num_threads = other.max_num_threads;
        this->node_count = other.node_count;

        this->clusters_by_level = other.clusters_by_level;

        this->levels_valid = other.levels_valid;
        this->total_cost = other.total_cost;

        this->sys_graph = other.sys_graph;
        vertex_iterator vert_iter, vert_end;
        std::tie(vert_iter, vert_end) = vertices(this->sys_graph);
        this->root_node_id = *vert_iter;
    }

    TaskSystem_v2& operator=(const TaskSystem_v2& other) {

        this->name = other.name;
        this->max_num_threads = other.max_num_threads;
        this->node_count = other.node_count;

        this->clusters_by_level = other.clusters_by_level;

        this->levels_valid = other.levels_valid;
        this->total_cost = other.total_cost;

        this->sys_graph = other.sys_graph;

        vertex_iterator vert_iter, vert_end;
        std::tie(vert_iter, vert_end) = vertices(this->sys_graph);
        this->root_node_id = *vert_iter;

        return *this;
    }

    TaskType& add_node(const TaskType& task) {
        ClusterIdType new_clust_id = add_vertex(sys_graph);

        ClusterType& new_clust = sys_graph[new_clust_id];

        TaskType& new_task = new_clust.add_task(task);
        new_task.task_id = node_count;
        ++node_count;

        int             parent_count = 0;
        vertex_iterator vert_iter, vert_end;
        std::tie(vert_iter, vert_end) = vertices(sys_graph);
        /*! skip the root node. */
        ++vert_iter;
        /*! stop just before the new node. */
        --vert_end;
        for (; vert_iter != vert_end; ++vert_iter) {
            const ClusterIdType& prev_clust_id = *vert_iter;
            ClusterType&         prev_clust = sys_graph[prev_clust_id];

            bool found_dep = new_clust.depends_on(prev_clust);
            if (found_dep) {
                add_edge(prev_clust_id, new_clust_id, sys_graph);
                ++parent_count;
            }
        }

        if (parent_count == 0) {
            add_edge(root_node_id, new_clust_id, sys_graph);
        }

        total_cost += new_task.cost;
        return new_task;
    }

  public:
    void concat_same_level_clusters(const ClusterIdType& dest_id, const ClusterIdType& src_id) {

        ClusterType& dest = sys_graph[dest_id];
        ClusterType& src = sys_graph[src_id];

        typename ClusterType::iterator task_iter;
        for (task_iter = src.begin(); task_iter != src.end(); ++task_iter) {
            dest.add_task(*task_iter);
        }

        adjacency_iterator src_child_iter, src_child_end, curr_src_child_iter;
        std::tie(src_child_iter, src_child_end) = adjacent_vertices(src_id, sys_graph);
        while (src_child_iter != src_child_end) {
            /*! Increment before erase. Apparently erasing an edge invalidates the vertex iterators in VS.
              something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
              (the edge container is in fact a set, but that should matter only if we iterate over ages.
              well apparently not :) )*/
            curr_src_child_iter = src_child_iter;
            ++src_child_iter;

            add_edge(dest_id, *curr_src_child_iter, sys_graph);
            remove_edge(src_id, *curr_src_child_iter, sys_graph);
        }

        /*for (; src_child_iter != src_child_end; ++src_child_iter) {
            add_edge(dest_id, *src_child_iter, sys_graph);
            remove_edge(src_id, *src_child_iter, sys_graph);
        }*/

        inv_adjacency_iterator src_parent_iter, src_parent_end, curr_src_parent_iter;
        std::tie(src_parent_iter, src_parent_end) = inv_adjacent_vertices(src_id, sys_graph);

        while (src_parent_iter != src_parent_end) {
            /*! Increment before erase. Apparently erasing an edge invalidates the vertex iterators in VS.
              something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
              (the edge container is in fact a set, but that should matter only if we iterate over ages.
              well apparently not :) )*/
            curr_src_parent_iter = src_parent_iter;
            ++src_parent_iter;

            add_edge(*curr_src_parent_iter, dest_id, sys_graph);
            remove_edge(*curr_src_parent_iter, src_id, sys_graph);
        }

        /*for (; src_parent_iter != src_parent_end; ++src_parent_iter) {
            add_edge(*src_parent_iter, dest_id, sys_graph);
            remove_edge(*src_parent_iter, src_id, sys_graph);
        }*/

        // clear_vertex(src_id, sys_graph);
        remove_vertex(src_id, sys_graph);
    }

    void concat_with_parent(const ClusterIdType& parent_id, const ClusterIdType& child_id) {
        ClusterType& parent = sys_graph[parent_id];
        ClusterType& child = sys_graph[child_id];

        typename ClusterType::iterator task_iter;
        for (task_iter = child.begin(); task_iter != child.end(); ++task_iter) {
            parent.add_task(*task_iter);
        }

        adjacency_iterator grand_child_iter, grand_child_end, curr_grand_child_iter;
        std::tie(grand_child_iter, grand_child_end) = adjacent_vertices(child_id, sys_graph);
        while (grand_child_iter != grand_child_end) {

            /*! Increment before erase. Apparently erasing an edge invalidates the vertex iterators in VS.
              something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
              (the edge container is in fact a set, but that should matter only if we iterate over ages.
              well apparently not :) )*/
            curr_grand_child_iter = grand_child_iter;
            ++grand_child_iter;

            add_edge(parent_id, *curr_grand_child_iter, sys_graph);
            remove_edge(child_id, *curr_grand_child_iter, sys_graph);
        }

        remove_edge(parent_id, child_id, sys_graph);
        // clear_vertex(child_id, sys_graph);
        remove_vertex(child_id, sys_graph);
    }

  public:
    void print_leveled_nodes() {

        typedef typename ClusterLevels::value_type SameLevelClusterIdsType;
        int                                        level_number = 0;

        typename ClusterLevels::iterator level_iter = clusters_by_level.begin();
        for (; level_iter != clusters_by_level.end(); ++level_iter, ++level_number) {
            SameLevelClusterIdsType& current_level = *level_iter;
            std::cout << "Level " << level_number << " : " << current_level.total_level_cost << " : ";

            typename SameLevelClusterIdsType::iterator clustid_iter = current_level.begin();
            for (; clustid_iter != current_level.end(); ++clustid_iter) {
                std::cout << sys_graph[*clustid_iter].index_list << ", ";
            }
            std::cout << std::endl;
        }
    }

    /*! Print the clusters in breadth-first order. */
    void update_node_levels2() {
        std::set<ClusterIdType>   discovered;
        std::queue<ClusterIdType> queue;
        discovered.insert(root_node_id);
        queue.push(root_node_id);
        while (!queue.empty()) {
            ClusterIdType curr_clust_id = queue.front();
            queue.pop();
            std::cout << sys_graph[curr_clust_id].index_list << std::endl;
            adjacency_iterator child_iter, child_end;
            for (std::tie(child_iter, child_end) = adjacent_vertices(curr_clust_id, sys_graph); child_iter != child_end;
                 ++child_iter) {
                if (discovered.insert(*child_iter).second)
                    queue.push(*child_iter);
            }
        }
    }

    void update_node_levels() {

        /* compute the level of each node*/
        long            critical_path = 0;
        vertex_iterator vert_iter, vert_end;
        std::tie(vert_iter, vert_end) = vertices(sys_graph);
        /*! skip the root node. */
        ++vert_iter;
        for (; vert_iter != vert_end; ++vert_iter) {
            const ClusterIdType& curr_clust_id = *vert_iter;
            ClusterType&         curr_clust = sys_graph[curr_clust_id];

            long max_parent_level = 0;

            inv_adjacency_iterator parent_iter, parent_end;
            std::tie(parent_iter, parent_end) = inv_adjacent_vertices(curr_clust_id, sys_graph);
            for (; parent_iter != parent_end; ++parent_iter) {
                const ClusterIdType& curr_parent_id = *parent_iter;
                ClusterType&         curr_parent = sys_graph[curr_parent_id];

                max_parent_level = std::max(max_parent_level, curr_parent.level);
            }
            curr_clust.level = max_parent_level + 1;
            critical_path = std::max(curr_clust.level, critical_path);
        }

        // Check the levels are correct. Paranoia!
        std::tie(vert_iter, vert_end) = vertices(sys_graph);
        /*! skip the root node. */
        ++vert_iter;
        for (; vert_iter != vert_end; ++vert_iter) {
            ClusterIdType& curr_clust_id = *vert_iter;
            ClusterType&   curr_clust = sys_graph[curr_clust_id];

            long max_parent_level = 0;

            inv_adjacency_iterator parent_iter, parent_end;
            std::tie(parent_iter, parent_end) = inv_adjacent_vertices(curr_clust_id, sys_graph);
            for (; parent_iter != parent_end; ++parent_iter) {
                const ClusterIdType& curr_parent_id = *parent_iter;
                ClusterType&         curr_parent = sys_graph[curr_parent_id];

                max_parent_level = std::max(max_parent_level, curr_parent.level);
            }

            if (curr_clust.level != max_parent_level + 1) {
                std::cerr << curr_clust.level << " vs " << max_parent_level << std::endl;
                std::cerr << curr_clust.index_list << std::endl;
                std::cerr << "level check failure " << std::endl;
                // exit(1);
            }
        }

        // create a list of nodes per level
        // Collect nodes of the same level in to a vector and add it to the list of levels
        clusters_by_level.clear();
        clusters_by_level.resize(critical_path + 1);
        typedef typename ClusterLevels::value_type SameLevelClusterIdsType;

        typename ClusterLevels::iterator level_iter;
        std::tie(vert_iter, vert_end) = vertices(sys_graph);
        for (; vert_iter != vert_end; ++vert_iter) {
            const ClusterIdType& curr_clust_id = *vert_iter;
            ClusterType&         curr_clust = sys_graph[curr_clust_id];

            // find the entry in the level list for the current node. its level defines where it goes
            SameLevelClusterIdsType& my_level = clusters_by_level[curr_clust.level];
            // std::advance(level_iter, curr_clust.level);

            // Add it to the vector of nodes of that level.
            my_level.push_back(curr_clust_id);
            my_level.total_level_cost += curr_clust.cost;
        }

        this->levels_valid = true;
    }

    void dump_graphml(const std::string& suffix) {

        if (levels_valid == false)
            update_node_levels();

        std::string   out_filename = this->name + "_" + suffix + ".graphml";
        std::ofstream outfileml(out_filename.c_str());

        std::map<ClusterIdType, size_t> clust_index;
        vertex_iterator                 vert_iter, vert_end;
        for (std::tie(vert_iter, vert_end) = vertices(sys_graph); vert_iter != vert_end; ++vert_iter) {
            size_t index = clust_index.size();
            clust_index[*vert_iter] = index;
        }

        outfileml << "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
                  << "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\""
                  << " xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\""
                  << " xsi:schemaLocation=\"http://graphml.graphdrawing.org/xmlns"
                  << " http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd\">\n"
                  << "  <key id=\"key0\" for=\"node\" attr.name=\"cost\" attr.type=\"double\" />\n"
                  << "  <key id=\"key1\" for=\"node\" attr.name=\"index\" attr.type=\"string\" />\n"
                  << "  <key id=\"key2\" for=\"node\" attr.name=\"level\" attr.type=\"long\" />\n"
                  << "  <graph id=\"G\" edgedefault=\"directed\" parse.nodeids=\"canonical\""
                  << " parse.edgeids=\"canonical\" parse.order=\"nodesfirst\">\n";
        for (std::tie(vert_iter, vert_end) = vertices(sys_graph); vert_iter != vert_end; ++vert_iter) {
            const ClusterType& clust = sys_graph[*vert_iter];
            outfileml << "    <node id=\"n" << clust_index[*vert_iter] << "\">\n"
                      << "      <data key=\"key0\">" << clust.cost << "</data>\n"
                      << "      <data key=\"key1\">" << clust.index_list << "</data>\n"
                      << "      <data key=\"key2\">" << clust.level << "</data>\n"
                      << "    </node>\n";
        }
        size_t edge_count = 0;
        for (std::tie(vert_iter, vert_end) = vertices(sys_graph); vert_iter != vert_end; ++vert_iter) {
            adjacency_iterator child_iter, child_end;
            for (std::tie(child_iter, child_end) = adjacent_vertices(*vert_iter, sys_graph); child_iter != child_end;
                 ++child_iter) {
                outfileml << "    <edge id=\"e" << edge_count++ << "\" source=\"n" << clust_index[*vert_iter]
                          << "\" target=\"n" << clust_index[*child_iter] << "\">\n"
                          << "    </edge>\n";
            }
        }
        outfileml << "  </graph>\n"
                  << "</graphml>\n";
    }
};

}} // namespace openmodelica::parmodelica

#endif // header
