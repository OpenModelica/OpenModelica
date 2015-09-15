#pragma once
#ifndef id51EE4BD8_93E1_4245_A0B1E55CDC703CF8
#define id51EE4BD8_93E1_4245_A0B1E55CDC703CF8


/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */


/*
 Mahder.Gebremedhin@liu.se  2014-03-07
*/



#include <iostream>

#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/breadth_first_search.hpp>
#include <boost/graph/graph_utility.hpp>

#include "pm_utility.hpp"
#include "pm_timer.hpp"


namespace openmodelica {
namespace parmodelica {


// struct TaskNode {
    // TaskNode() :
    // level(0)
    // , cost(0)
    // {};

    // long task_id;
    // int level;
    // double cost;

    // virtual bool depends_on(const TaskNode&) const = 0;
    // // virtual void execute() const = 0;
// };




template<typename T>
struct TaskCluster :
  public utility::pm_vector<T>
{
    typedef T TaskType;
    typedef typename utility::pm_vector<T>::iterator iterator;
    typedef typename utility::pm_vector<T>::const_iterator const_iterator;

private:
    // TaskCluster& operator=(const TaskCluster& other);

public:
    double cost;
    long level;
    std::string index_list;
    int group;

    TaskCluster()
    {
        cost = 0;
        level = 0;
        index_list = "$";
        group = 0;
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
    }

    bool depends_on(const TaskCluster<TaskType>& other) const {
        bool found = false;
        const_iterator t_iter, o_iter;
        for(t_iter = this->begin(); t_iter != this->end(); ++t_iter) {
            for(o_iter = other.begin(); o_iter != other.end(); ++o_iter) {
                found = t_iter->depends_on(*o_iter);
                if(found)
                    return true;
            }
        }

        return false;
    }


    void execute()
    {
        iterator t_iter;
        for(t_iter = this->begin(); t_iter != this->end(); ++t_iter) {
            t_iter->execute();
        }
    }

    void profile_execute()
    {
        this->cost = 0;
        double elapsed = 0;
        PMTimer task_timer;

        iterator t_iter;
        for(t_iter = this->begin(); t_iter != this->end(); ++t_iter) {
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


    static bool
    cost_comparator(const TaskCluster<TaskType>& lhs,
                    const TaskCluster<TaskType>& rhs) {
        return lhs.cost < rhs.cost;
    }

};


template<typename T>
struct cluster_cost_comparator_by_id
{
    typedef T GraphType;
    typedef typename GraphType::vertex_descriptor ClusterIdType;

    const GraphType& graph;
    cluster_cost_comparator_by_id(const GraphType& g) : graph(g) {}

    bool operator() (const ClusterIdType& lhs, const ClusterIdType& rhs) {
        double lhs_cost = graph[lhs].cost;
        double rhs_cost = graph[rhs].cost;
        if(lhs_cost == rhs_cost) {
            int lhs_degree = out_degree(lhs, graph);
            int rhs_degree = out_degree(rhs, graph);
            // if(lhs_degree == rhs_degree) {

            // }
            return lhs_degree > rhs_degree;
        }
        return lhs_cost > rhs_cost;
    }
};


template<typename T>
struct SameLevelClusterIds :
  public utility::pm_vector<T>
{
    typedef T ClusterIdType;

    double level_cost;

    SameLevelClusterIds() :
      level_cost(0)
    {}

};



template <typename T>
class TaskSystem_v2 : boost::noncopyable {

public:
    typedef T TaskType;
    typedef TaskCluster<TaskType> ClusterType;

    typedef typename boost::adjacency_list<
            boost::setS, boost::listS,
            boost::bidirectionalS, ClusterType
            > GraphType;

    typedef typename GraphType::vertex_descriptor ClusterIdType;
    typedef typename GraphType::vertex_iterator vertex_iterator;
    typedef typename GraphType::adjacency_iterator adjacency_iterator;
    typedef typename GraphType::inv_adjacency_iterator inv_adjacency_iterator;

    typedef typename GraphType::edge_descriptor EdgeIdType;
    typedef typename GraphType::in_edge_iterator in_edge_iterator;
	typedef typename GraphType::out_edge_iterator out_edge_iterator;

    typedef std::list<SameLevelClusterIds<ClusterIdType> > ClusterLevels;

private:
    long node_count;

public:

    std::set<ClusterIdType> active_nodes;
    ClusterLevels clusters_by_level;
    bool levels_valid;
    double total_cost;
    GraphType sys_graph;
    ClusterIdType root_node_id;

    TaskSystem_v2()
    {
        levels_valid = false;
        node_count = 0;
        total_cost = 0;
        root_node_id = boost::add_vertex(sys_graph);
        TaskType& root_node = sys_graph[root_node_id].add_task(TaskType());
        root_node.task_id = -1;
    }

    TaskType& add_node(const TaskType& task)
    {
        ClusterIdType new_clust_id = boost::add_vertex(sys_graph);
        active_nodes.insert(new_clust_id);

        ClusterType& new_clust = sys_graph[new_clust_id];

        TaskType& new_task = new_clust.add_task(task);
        new_task.task_id = node_count;
        ++node_count;

        int parent_count = 0;
        vertex_iterator vert_iter, vert_end;
        boost::tie(vert_iter, vert_end) = vertices(sys_graph);
        /*! skip the root node. */
        ++vert_iter;
        /*! stop just before the new node. */
        --vert_end;
        for ( ; vert_iter != vert_end; ++vert_iter) {
            const ClusterIdType& prev_clust_id = *vert_iter;
            ClusterType& prev_clust = sys_graph[prev_clust_id];

            bool found_dep = new_clust.depends_on(prev_clust);
            if(found_dep) {
                boost::add_edge(prev_clust_id,new_clust_id,sys_graph);
                ++parent_count;
            }
        }

        if(parent_count == 0) {
            boost::add_edge(root_node_id,new_clust_id,sys_graph);
        }

        total_cost += new_task.cost;
        return new_task;

    }

public:

    void concat_same_level_clusters(const ClusterIdType& dest_id, const ClusterIdType& src_id) {

        ClusterType& dest = sys_graph[dest_id];
        ClusterType& src = sys_graph[src_id];

        typename ClusterType::iterator task_iter;
        for(task_iter = src.begin(); task_iter != src.end(); ++task_iter) {
            dest.add_task(*task_iter);
        }

        adjacency_iterator src_child_iter, src_child_end, curr_src_child_iter;
        boost::tie(src_child_iter, src_child_end) = adjacent_vertices(src_id, sys_graph);
		while(src_child_iter != src_child_end) {
			/*! Increment before erase. Apparently erasing an edge invalidates the vertex iterators in VS.
			  something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
			  (the edge container is in fact a set, but that should matter only if we iterate over ages.
			  well apparently not :) )*/
			curr_src_child_iter = src_child_iter;
			++src_child_iter;

			boost::add_edge(dest_id, *curr_src_child_iter, sys_graph);
            boost::remove_edge(src_id, *curr_src_child_iter, sys_graph);
		}

        /*for (; src_child_iter != src_child_end; ++src_child_iter) {
            boost::add_edge(dest_id, *src_child_iter, sys_graph);
            boost::remove_edge(src_id, *src_child_iter, sys_graph);
        }*/

        inv_adjacency_iterator src_parent_iter, src_parent_end, curr_src_parent_iter;
        boost::tie(src_parent_iter, src_parent_end) = inv_adjacent_vertices(src_id, sys_graph);


		while(src_parent_iter != src_parent_end) {
			/*! Increment before erase. Apparently erasing an edge invalidates the vertex iterators in VS.
			  something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
			  (the edge container is in fact a set, but that should matter only if we iterate over ages.
			  well apparently not :) )*/
			curr_src_parent_iter = src_parent_iter;
			++src_parent_iter;

			boost::add_edge(*curr_src_parent_iter, dest_id, sys_graph);
            boost::remove_edge(*curr_src_parent_iter, src_id, sys_graph);
		}


        /*for (; src_parent_iter != src_parent_end; ++src_parent_iter) {
            boost::add_edge(*src_parent_iter, dest_id, sys_graph);
            boost::remove_edge(*src_parent_iter, src_id, sys_graph);
        }*/

		// boost::clear_vertex(src_id, sys_graph);
		boost::remove_vertex(src_id, sys_graph);

    }

    void concat_with_parent(const ClusterIdType& parent_id, const ClusterIdType& child_id) {
        ClusterType& parent = sys_graph[parent_id];
        ClusterType& child = sys_graph[child_id];

        typename ClusterType::iterator task_iter;
        for(task_iter = child.begin(); task_iter != child.end(); ++task_iter) {
            parent.add_task(*task_iter);
        }

        adjacency_iterator grand_child_iter, grand_child_end, curr_grand_child_iter;
        boost::tie(grand_child_iter, grand_child_end) = adjacent_vertices(child_id, sys_graph);
		while(grand_child_iter != grand_child_end) {

			/*! Increment before erase. Apparently erasing an edge invalidates the vertex iterators in VS.
			  something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
			  (the edge container is in fact a set, but that should matter only if we iterate over ages.
			  well apparently not :) )*/
			curr_grand_child_iter = grand_child_iter;
			++grand_child_iter;

			boost::add_edge(parent_id, *curr_grand_child_iter, sys_graph);
            boost::remove_edge(child_id, *curr_grand_child_iter, sys_graph);

		}


        boost::remove_edge(parent_id, child_id, sys_graph);
		// boost::clear_vertex(child_id, sys_graph);
		boost::remove_vertex(child_id, sys_graph);

    }

public:

    void print_leveled_nodes() {

        typedef typename ClusterLevels::value_type SameLevelClusterIdsType;
        int level_number = 0;

        typename ClusterLevels::iterator level_iter = clusters_by_level.begin();
        for( ;level_iter != clusters_by_level.end(); ++level_iter, ++level_number) {
            SameLevelClusterIdsType& current_level = *level_iter;
            std::cout << "Level " << level_number << " : " << current_level.level_cost << " : ";

            typename SameLevelClusterIdsType::iterator clustid_iter = current_level.begin();
            for( ;clustid_iter != current_level.end(); ++clustid_iter) {
                std::cout << sys_graph[*clustid_iter].index_list << ", ";
            }
            std::cout << std::endl;

        }

    }

    struct level_update_visitor : public boost::default_bfs_visitor
    {
        template < typename Vertex, typename Graph >
        void discover_vertex(Vertex u, const Graph & g) const
        {
            std::cout << g[u].index_list << std::endl;
        }
    };

    void update_node_levels2() {
        level_update_visitor vis;
        boost::breadth_first_search(sys_graph, root_node_id, boost::visitor(vis));
    }

    void update_node_levels() {

        typedef typename ClusterLevels::value_type SameLevelClusterIdsType;

        clusters_by_level.clear();

        long critical_path = 0;
        vertex_iterator vert_iter, vert_end;
        boost::tie(vert_iter, vert_end) = vertices(sys_graph);
        /*! skip the root node. */
        ++vert_iter;
        for ( ; vert_iter != vert_end; ++vert_iter) {
            const ClusterIdType& curr_clust_id = *vert_iter;
            ClusterType& curr_clust = sys_graph[curr_clust_id];

            long max_parent_level = 0;

            inv_adjacency_iterator parent_iter, parent_end;
            boost::tie(parent_iter, parent_end) = inv_adjacent_vertices(curr_clust_id, sys_graph);
            for ( ; parent_iter != parent_end; ++parent_iter) {
                const ClusterIdType& curr_parent_id = *parent_iter;
                ClusterType& curr_parent = sys_graph[curr_parent_id];

                max_parent_level = std::max(max_parent_level, curr_parent.level);

            }
            curr_clust.level = max_parent_level + 1;
            critical_path = std::max(curr_clust.level, critical_path);

        }

        clusters_by_level.resize(critical_path + 1);

        typename ClusterLevels::iterator level_iter;
        boost::tie(vert_iter, vert_end) = vertices(sys_graph);
        for ( ; vert_iter != vert_end; ++vert_iter) {
            const ClusterIdType& curr_clust_id = *vert_iter;
            ClusterType& curr_clust = sys_graph[curr_clust_id];


            level_iter = clusters_by_level.begin();
            std::advance(level_iter, curr_clust.level);
            level_iter->push_back(curr_clust_id);
            level_iter->level_cost += curr_clust.cost;
        }


        boost::tie(vert_iter, vert_end) = vertices(sys_graph);
        /*! skip the root node. */
        ++vert_iter;
        for ( ; vert_iter != vert_end; ++vert_iter)
        {
            ClusterIdType& curr_clust_id = *vert_iter;
            ClusterType& curr_clust = sys_graph[curr_clust_id];

            long max_parent_level = 0;

            inv_adjacency_iterator parent_iter, parent_end;
            boost::tie(parent_iter, parent_end) = inv_adjacent_vertices(curr_clust_id, sys_graph);
            for ( ; parent_iter != parent_end; ++parent_iter)
            {
                const ClusterIdType& curr_parent_id = *parent_iter;
                ClusterType& curr_parent = sys_graph[curr_parent_id];

                max_parent_level = std::max(max_parent_level, curr_parent.level);
            }

            if(curr_clust.level != max_parent_level+1)
            {
                std::cerr << curr_clust.level << " vs " << max_parent_level << std::endl;
                std::cerr << curr_clust.index_list << std::endl;
                std::cerr << "level check failure " << std::endl;
                // exit(1);
            }

        }



        this->levels_valid = true;

    }


    void load_from_xml(const std::string& file_name, const std::string& eq_to_read);
    void dump_graphml(const std::string& filename);

};








} // openmodelica
} // parmodelica




#endif // header