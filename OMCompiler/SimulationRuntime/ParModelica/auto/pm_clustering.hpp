#pragma once
#ifndef id46CF8262_ACA8_41CD_9972EE0E43C8C5E7
#define id46CF8262_ACA8_41CD_9972EE0E43C8C5E7

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
 Mahder.Gebremedhin@liu.se  2014-03-13
*/


#include "pm_cluster_system.hpp"
#include <algorithm>

namespace openmodelica {
namespace parmodelica {



struct concat_clusters {

    template<typename TaskSystemType>
    static void apply(TaskSystemType& task_system,
                        const typename TaskSystemType::ClusterIdType& dest_id,
                        const typename TaskSystemType::ClusterIdType& src_id) {

        typedef typename TaskSystemType::GraphType GraphType;
        typedef typename TaskSystemType::ClusterType ClusterType;
        typedef typename TaskSystemType::adjacency_iterator adjacency_iterator;
        typedef typename TaskSystemType::inv_adjacency_iterator inv_adjacency_iterator;

        GraphType& sys_graph = task_system.sys_graph;

        if(dest_id == src_id)
            return;

        ClusterType& dest = sys_graph[dest_id];
        ClusterType& src = sys_graph[src_id];

        if(dest.level > src.level) {
                std::cout << "trying to add edge : " << dest.level << " -> " << src.level << std::endl;
        }

        // std::cout << "Trying merege "  << dest.index_list << " and " << src.index_list << std::endl;

        typename ClusterType::iterator task_iter;
        for(task_iter = src.begin(); task_iter != src.end(); ++task_iter) {
            dest.add_task(*task_iter);
        }

        adjacency_iterator src_child_iter, src_child_end, curr_src_child_iter;
        boost::tie(src_child_iter, src_child_end) = adjacent_vertices(src_id, sys_graph);
        while (src_child_iter != src_child_end) {

			/*! Increment before erase. Apparently erasing an edge invalidates the vertex iterators in VS.
			  something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
			  (the edge container is in fact a set, but that should matter only if we iterate over ages.
			  well apparently not :) )*/
			curr_src_child_iter = src_child_iter;
			++src_child_iter;

            if(dest_id != *curr_src_child_iter) {
                boost::add_edge(dest_id, *curr_src_child_iter, sys_graph);
            }
            else {
                std::cout << "trying to add edge : " << sys_graph[dest_id].index_list << " -> " << sys_graph[*curr_src_child_iter].index_list << std::endl;
            }
            boost::remove_edge(src_id, *curr_src_child_iter, sys_graph);

        }

        inv_adjacency_iterator src_parent_iter, src_parent_end, curr_src_parent_iter;
        boost::tie(src_parent_iter, src_parent_end) = inv_adjacent_vertices(src_id, sys_graph);
        while (src_parent_iter != src_parent_end) {

			/*! Increment before erase. Apparently erasing an edge invalidates the vertex iterators in VS.
			  something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
			  (the edge container is in fact a set, but that should matter only if we iterate over ages.
			  well apparently not :) )*/
			curr_src_parent_iter = src_parent_iter;
			++src_parent_iter;

            if(*curr_src_parent_iter != dest_id) {
                boost::add_edge(*curr_src_parent_iter, dest_id, sys_graph);
            }
            else {
                std::cout << "trying to add edge : " << sys_graph[*curr_src_parent_iter].index_list << " -> " << sys_graph[dest_id].index_list << std::endl;
            }
            boost::remove_edge(*curr_src_parent_iter, src_id, sys_graph);
        }

		// boost::clear_vertex(src_id, sys_graph);
        boost::remove_vertex(src_id, sys_graph);

    }

};

//struct concat_same_level_clusters {
//
//    template<typename TaskSystemType>
//    static void apply(TaskSystemType& task_system,
//                        const typename TaskSystemType::ClusterIdType& dest_id,
//                        const typename TaskSystemType::ClusterIdType& src_id) {
//
//        typedef typename TaskSystemType::GraphType GraphType;
//        typedef typename TaskSystemType::ClusterType ClusterType;
//        typedef typename TaskSystemType::adjacency_iterator adjacency_iterator;
//        typedef typename TaskSystemType::inv_adjacency_iterator inv_adjacency_iterator;
//
//        GraphType& sys_graph = task_system.sys_graph;
//
//        ClusterType& dest = sys_graph[dest_id];
//        ClusterType& src = sys_graph[src_id];
//
//        typename ClusterType::iterator task_iter;
//        for(task_iter = src.begin(); task_iter != src.end(); ++task_iter) {
//            dest.add_task(*task_iter);
//        }
//
//        adjacency_iterator src_child_iter, src_child_end, curr_src_child_iter;
//        boost::tie(src_child_iter, src_child_end) = adjacent_vertices(src_id, sys_graph);
//		while(src_child_iter != src_child_end) {
//			/*! Increment before erase. Apparently erasing an edge invalidates the vertex iterators in VS.
//			  something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
//			  (the edge container is in fact a set, but that should matter only if we iterate over ages.
//			  well apparently not :) )*/
//			curr_src_child_iter = src_child_iter;
//			++src_child_iter;
//
//			boost::add_edge(dest_id, *curr_src_child_iter, sys_graph);
//            boost::remove_edge(src_id, *curr_src_child_iter, sys_graph);
//		}
//
//        /*for (; src_child_iter != src_child_end; ++src_child_iter) {
//            boost::add_edge(dest_id, *src_child_iter, sys_graph);
//            boost::remove_edge(src_id, *src_child_iter, sys_graph);
//        }*/
//
//        inv_adjacency_iterator src_parent_iter, src_parent_end, curr_src_parent_iter;
//        boost::tie(src_parent_iter, src_parent_end) = inv_adjacent_vertices(src_id, sys_graph);
//
//
//		while(src_parent_iter != src_parent_end) {
//			/*! Increment before erase. Apparently erasing an edge invalidates the vertex iterators in VS.
//			  something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
//			  (the edge container is in fact a set, but that should matter only if we iterate over ages.
//			  well apparently not :) )*/
//			curr_src_parent_iter = src_parent_iter;
//			++src_parent_iter;
//
//			boost::add_edge(*curr_src_parent_iter, dest_id, sys_graph);
//            boost::remove_edge(*curr_src_parent_iter, src_id, sys_graph);
//		}
//
//
//        /*for (; src_parent_iter != src_parent_end; ++src_parent_iter) {
//            boost::add_edge(*src_parent_iter, dest_id, sys_graph);
//            boost::remove_edge(*src_parent_iter, src_id, sys_graph);
//        }*/
//
//		boost::remove_vertex(src_id, sys_graph);
//    }
//
//};

//struct concat_with_parent {
//    static std::string name() {
//        return "concat_with_parent";
//    }
//
//    template<typename TaskSystemType>
//    static void apply(TaskSystemType& task_system,
//                        const typename TaskSystemType::ClusterIdType& parent_id,
//                        const typename TaskSystemType::ClusterIdType& child_id) {
//
//        typedef typename TaskSystemType::GraphType GraphType;
//        typedef typename TaskSystemType::ClusterType ClusterType;
//        typedef typename TaskSystemType::adjacency_iterator adjacency_iterator;
//
//        GraphType& sys_graph = task_system.sys_graph;
//
//        ClusterType& parent = sys_graph[parent_id];
//        ClusterType& child = sys_graph[child_id];
//
//        typename ClusterType::iterator task_iter;
//        for(task_iter = child.begin(); task_iter != child.end(); ++task_iter) {
//            parent.add_task(*task_iter);
//        }
//
//        adjacency_iterator grand_child_iter, grand_child_end, curr_grand_child_iter;
//        boost::tie(grand_child_iter, grand_child_end) = adjacent_vertices(child_id, sys_graph);
//		while(grand_child_iter != grand_child_end) {
//
//			/*! Increment before erase. Apparently erasing an edge invalidates the vertex iterators in VS.
//			  something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
//			  (the edge container is in fact a set, but that should matter only if we iterate over ages.
//			  well apparently not :) )*/
//			curr_grand_child_iter = grand_child_iter;
//			++grand_child_iter;
//
//			boost::add_edge(parent_id, *curr_grand_child_iter, sys_graph);
//            boost::remove_edge(child_id, *curr_grand_child_iter, sys_graph);
//
//		}
//
//
//        boost::remove_edge(parent_id, child_id, sys_graph);
//		// boost::clear_vertex(child_id, sys_graph);
//		boost::remove_vertex(child_id, sys_graph);
//
//    }
//
//};





struct cluster_none {
    static std::string name() {
        return "cluster_none";
    }

	template<typename TaskSystemType>
	static void dump_graph(TaskSystemType& task_system, std::string suffix = "") {
        /*! No op*/
    }

    template<typename TaskSystemType>
    static void apply(TaskSystemType& task_system)
    {
        /*! No op. */
    }
};


struct cluster_merge_level_for_cost {
    static std::string name() {
        return "cluster_merge_level_for_cost";
    }

	template<typename TaskSystemType>
	static void dump_graph(TaskSystemType& task_system, std::string suffix = "") {
        task_system.dump_graphml(cluster_merge_level_for_cost::name()+ "_" + suffix);
    }

    template<typename TaskSystemType>
    static void apply(TaskSystemType& task_system) {

        typedef typename TaskSystemType::GraphType GraphType;
        typedef typename TaskSystemType::ClusterLevels ClusterLevels;
        typedef typename TaskSystemType::ClusterType ClusterType;
        typedef typename TaskSystemType::ClusterIdType ClusterIdType;

        typedef typename ClusterLevels::value_type SameLevelClusterIdsType;

        ClusterLevels& clusters_by_level = task_system.clusters_by_level;
        GraphType& sys_graph = task_system.sys_graph;

        int nr_of_clusters = 8;

        if(task_system.levels_valid == false)
            task_system.update_node_levels();


        typename ClusterLevels::iterator level_iter = clusters_by_level.begin();
        /*! Skip the first level. Which contains only the root node and some invlaidated clusters.*/
        ++level_iter;
        int level_number = 1;
        for( ;level_iter != clusters_by_level.end(); ++level_iter, ++level_number) {
            SameLevelClusterIdsType& current_level = *level_iter;

            /*!Sort the level by cost so that we can pick the nodes that fits the gap easily*/
            // sort in decreasing order
            cluster_cost_comparator_by_id<GraphType> cccbi(sys_graph);
            std::sort(current_level.rbegin(), current_level.rend(), cccbi);

            double target_cost = current_level.total_level_cost/nr_of_clusters;
            if(target_cost < sys_graph[current_level.front()].cost) {
                target_cost = sys_graph[current_level.front()].cost;
            }

            target_cost = std::max(target_cost,0.0);

            int cluster_count = 0;
            typename SameLevelClusterIdsType::iterator clustid_iter = current_level.begin();

            /*! Cluster in to 'n' groups. Anything that doesn't fit in the target cost is handled in the
              next for loop. DO NOT modify the iterator if you are not sure.*/
            for( ;clustid_iter != current_level.end() && cluster_count < nr_of_clusters; ++clustid_iter) {
                ClusterIdType& curr_clust_id = *clustid_iter;
                ClusterType& curr_clust = sys_graph[curr_clust_id];

                /*! cluster is valid*/
                ++cluster_count;

                double gap = target_cost - curr_clust.cost;
                if(gap == 0) {
                    continue;
                }

                typename SameLevelClusterIdsType::iterator othersid_iter = clustid_iter;

                /*! start from the next node.*/
                ++othersid_iter;
                while(othersid_iter != current_level.end()) {
                    ClusterIdType& other_clust_id = *othersid_iter;
                    ClusterType& other_clust = sys_graph[other_clust_id];

                    if(other_clust.cost <= gap) {
                        gap = gap - other_clust.cost;
                        task_system.concat_same_level_clusters(curr_clust_id, other_clust_id);
                        othersid_iter = current_level.erase(othersid_iter);
                    }
                    else {
                        ++othersid_iter;
                    }
                }

            }

            typename SameLevelClusterIdsType::iterator remaining_iter, smallest_clust_iter;
            while(clustid_iter != current_level.end()) {
                smallest_clust_iter = std::min_element(current_level.begin(), current_level.begin() + nr_of_clusters, cccbi);
                task_system.concat_same_level_clusters(*smallest_clust_iter, *clustid_iter);
                clustid_iter = current_level.erase(clustid_iter);
            }

        }

        task_system.levels_valid = false;

    }

};

struct cluster_merge_level_for_bins {
    static std::string name() {
        return "cluster_merge_level_for_bins";
    }

	template<typename TaskSystemType>
	static void dump_graph(TaskSystemType& task_system, std::string suffix = "") {
        task_system.dump_graphml(cluster_merge_level_for_bins::name()+ "_" + suffix);
    }

    template<typename TaskSystemType>
    static void apply(TaskSystemType& task_system) {

        typedef typename TaskSystemType::GraphType GraphType;
        typedef typename TaskSystemType::ClusterLevels ClusterLevels;
        // typedef typename TaskSystemType::ClusterType ClusterType;
        // typedef typename TaskSystemType::ClusterIdType ClusterIdType;

        typedef typename ClusterLevels::value_type SameLevelClusterIdsType;

        ClusterLevels& clusters_by_level = task_system.clusters_by_level;
        GraphType& sys_graph = task_system.sys_graph;

        int nr_of_clusters = NUM_THREADS*2;

        if(task_system.levels_valid == false)
            task_system.update_node_levels();


        typename ClusterLevels::iterator level_iter = clusters_by_level.begin();
        /*! Skip the first level. Which contains only the root node and some invlaidated clusters.*/
        ++level_iter;
        int level_number = 1;
        for( ;level_iter != clusters_by_level.end(); ++level_iter, ++level_number) {
            SameLevelClusterIdsType& current_level = *level_iter;

            if(current_level.size() <= nr_of_clusters)
                continue;

            /*!Sort the level by cost so that we can pick the nodes that fits the gap easily*/
            // sort in decreasing order
            cluster_cost_comparator_by_id<GraphType> cccbi(sys_graph);
            std::sort(current_level.rbegin(), current_level.rend(), cccbi);

            // std::cout << "current level {";
            // for(auto& c: current_level)
                // std::cout << sys_graph[c].cost << ",";
            // std::cout << "}" << std::endl;

            typename SameLevelClusterIdsType::iterator smallest_clust_iter, clustid_iter, end_of_accepted;

            // Accept the first n clusters as merged tasks
            end_of_accepted = current_level.begin();
            std::advance(end_of_accepted, nr_of_clusters);
            // std::cout << "will start at: " << std::distance(current_level.begin(), end_of_accepted) << ": "<< sys_graph[*end_of_accepted].cost << std::endl;

            // iterate through the rest and merge with the smallest currently
            clustid_iter = end_of_accepted;
            while(clustid_iter != current_level.end()) {
                // std::cout << "current level {";
                // for(auto& c: current_level)
                    // std::cout << sys_graph[c].cost << ",";
                // std::cout << "}" << std::endl;

                smallest_clust_iter = std::min_element(current_level.begin(), end_of_accepted, cccbi);
                // std::cout << "smallest is " << std::distance(current_level.begin(), smallest_clust_iter) << ": "<< sys_graph[*smallest_clust_iter].cost << std::endl;
                task_system.concat_same_level_clusters(*smallest_clust_iter, *clustid_iter);
                clustid_iter = current_level.erase(clustid_iter);
            }

            // std::cout << "current level {";
            // for(auto& c: current_level)
                // std::cout << sys_graph[c].cost << ",";
            // std::cout << "}" << std::endl;

        }

        task_system.levels_valid = false;

    }

};


struct cluster_merge_common {
    static std::string name() {
        return "cluster_merge_common";
    }

	template<typename TaskSystemType>
	static void dump_graph(TaskSystemType& task_system, std::string suffix = "") {
        task_system.dump_graphml(cluster_merge_common::name()+ "_" + suffix);
    }

    template<typename TaskSystemType>
    static int concat_children_recursive(TaskSystemType& task_system,
                                            const typename TaskSystemType::ClusterIdType& curr_clust_id) {

        typedef typename TaskSystemType::GraphType GraphType;
        typedef typename TaskSystemType::ClusterType ClusterType;
        typedef typename TaskSystemType::ClusterIdType ClusterIdType;
        typedef typename TaskSystemType::adjacency_iterator adjacency_iterator;
		// typedef typename TaskSystemType::out_edge_iterator out_edge_iterator;

        GraphType& sys_graph = task_system.sys_graph;

        ClusterType& curr_clust = sys_graph[curr_clust_id];

        double target_cost = 20;

        int nr_of_parents;
        adjacency_iterator child_iter, child_end, next_child_iter;
        boost::tie(child_iter, child_end) = adjacent_vertices(curr_clust_id, sys_graph);

        std::vector<ClusterIdType> child_ids;
        for ( ; child_iter != child_end; ++child_iter) {
            const ClusterIdType& curr_child_id = *child_iter;

            nr_of_parents = in_degree(curr_child_id, sys_graph);
            if(nr_of_parents == 1)
                child_ids.push_back(curr_child_id);
        }

            // sort in decreasing order
        cluster_cost_comparator_by_id<GraphType> cccbi(sys_graph);
        std::sort(child_ids.rbegin(), child_ids.rend(), cccbi);

        typename std::vector<ClusterIdType>::iterator id_iter = child_ids.begin();
        for ( ; id_iter != child_ids.end(); ++id_iter) {
            const ClusterIdType& curr_child_id = *id_iter;
            ClusterType& curr_child = sys_graph[curr_child_id];

            double gap = target_cost - curr_child.cost;
            if(gap < 0.005) {
                continue;
            }


            typename std::vector<ClusterIdType>::iterator othersid_iter = id_iter;
            /*! start from the next node.*/
            ++othersid_iter;
            while(othersid_iter != child_ids.end()) {
                ClusterIdType& other_child_id = *othersid_iter;
                ClusterType& other_child = sys_graph[other_child_id];

                if(other_child.cost <= gap) {
                    gap = gap - other_child.cost;
                    task_system.concat_same_level_clusters(curr_child_id, other_child_id);
                    othersid_iter = child_ids.erase(othersid_iter);
                }
                else {
                    ++othersid_iter;
                }
            }



        }


		adjacency_iterator curr_child_iter;
        boost::tie(child_iter, child_end) = adjacent_vertices(curr_clust_id, sys_graph);
		while(child_iter != child_end) {

			/*! Increment before concat. Apparently erasing an edge invalidates the vertex iterators in VS.
			  something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
			  (the edge container is in fact a set, but that should matter only if we iterate over ages.
			  well apparently not :) )*/
			curr_child_iter = child_iter;
			++child_iter;


			const ClusterIdType& curr_child_id = *curr_child_iter;
            ClusterType& curr_child = sys_graph[curr_child_id];

            nr_of_parents = concat_children_recursive(task_system, curr_child_id);
            if(nr_of_parents == 1) {
                if(curr_clust.cost + curr_child.cost < target_cost) {
                    task_system.concat_with_parent(curr_clust_id, curr_child_id);
				}
            }

		}


        return in_degree(curr_clust_id, sys_graph);

    }

    template<typename TaskSystemType>
    static void apply(TaskSystemType& task_system) {

        typedef typename TaskSystemType::GraphType GraphType;
        typedef typename TaskSystemType::ClusterIdType ClusterIdType;
        typedef typename TaskSystemType::adjacency_iterator adjacency_iterator;

        GraphType& sys_graph = task_system.sys_graph;
        const ClusterIdType& root_node_id = task_system.root_node_id;

        adjacency_iterator child_iter, child_end;
        boost::tie(child_iter, child_end) = adjacent_vertices(root_node_id, sys_graph);

        for ( ; child_iter != child_end; ++child_iter) {
            const ClusterIdType& curr_child_id = *child_iter;
            concat_children_recursive(task_system, curr_child_id);

        }

        task_system.levels_valid = false;

    }

};


struct cluster_merge_single_parent {
    static std::string name() {
        return "cluster_merge_single_parent";
    }

	template<typename TaskSystemType>
	static void dump_graph(TaskSystemType& task_system, std::string suffix = "") {
        task_system.dump_graphml(cluster_merge_single_parent::name()+ "_" + suffix);
    }

    template<typename TaskSystemType>
    static void apply(TaskSystemType& task_system) {

        typedef typename TaskSystemType::GraphType GraphType;
        typedef typename TaskSystemType::ClusterType ClusterType;
        typedef typename TaskSystemType::ClusterIdType ClusterIdType;
        typedef typename TaskSystemType::vertex_iterator vertex_iterator;
        typedef typename TaskSystemType::adjacency_iterator adjacency_iterator;

        GraphType& sys_graph = task_system.sys_graph;

        vertex_iterator vert_iter, vert_end;
        boost::tie(vert_iter, vert_end) = vertices(sys_graph);
        /*! skip the root node. */
        ++vert_iter;
        for ( ; vert_iter != vert_end; ++vert_iter) {
            const ClusterIdType& curr_clust_id = *vert_iter;
            ClusterType& curr_clust = sys_graph[curr_clust_id];

            if(!curr_clust.is_valid()) {
                continue;
            }

            adjacency_iterator child_iter, child_end, curr_child_iter;
            boost::tie(child_iter, child_end) = adjacent_vertices(curr_clust_id, sys_graph);
            while (child_iter != child_end) {
				/*! Increment before concat. Apparently erasing an edge invalidates the vertex iterators in VS.
				  something is going on inside boost that I don't know yet. Or VS is just being VS as ususal.
				  (the edge container is in fact a set, but that should matter only if we iterate over ages.
				  well apparently not :) )*/
				curr_child_iter = child_iter;
				++child_iter;

                const ClusterIdType& curr_child_id = *curr_child_iter;
                // ClusterType& curr_child = sys_graph[curr_child_id];

                int nr_parents = in_degree(curr_child_id, sys_graph);
                if(nr_parents == 1) {
                    task_system.concat_with_parent(curr_clust_id, curr_child_id);
                }
            }

        }

        task_system.levels_valid = false;

    }

};


struct cluster_merge_level_parents {
    static std::string name() {
        return "cluster_merge_level_parents";
    }

	template<typename TaskSystemType>
	static void dump_graph(TaskSystemType& task_system, std::string suffix = "") {
        task_system.dump_graphml(cluster_merge_level_parents::name()+ "_" + suffix);
    }

    template<typename TaskSystemType>
    static void apply(TaskSystemType& task_system) {

        typedef typename TaskSystemType::GraphType GraphType;
        typedef typename TaskSystemType::ClusterLevels ClusterLevels;
        typedef typename TaskSystemType::ClusterType ClusterType;
        typedef typename TaskSystemType::ClusterIdType ClusterIdType;
        typedef typename TaskSystemType::inv_adjacency_iterator inv_adjacency_iterator;
        typedef typename ClusterLevels::value_type SameLevelClusterIdsType;

        GraphType& sys_graph = task_system.sys_graph;
        ClusterLevels& clusters_by_level = task_system.clusters_by_level;


        if(task_system.levels_valid == false)
            task_system.update_node_levels();


        typename ClusterLevels::iterator level_iter = clusters_by_level.begin();
        /*! Skip the first level. Which contains only the root node and some invlaidated clusters.*/
        ++level_iter;
        /*! Skip the second level as well. All nodes here have root as parent.*/
        ++level_iter;

        int level_number = 2;
        for( ;level_iter != clusters_by_level.end(); ++level_iter, ++level_number) {
            SameLevelClusterIdsType& current_level = *level_iter;

            typename SameLevelClusterIdsType::iterator clustid_iter = current_level.begin();
            for( ;clustid_iter != current_level.end(); ++clustid_iter) {
                ClusterIdType& curr_clust_id = *clustid_iter;
                ClusterType& curr_clust = sys_graph[curr_clust_id];

                if(!curr_clust.is_valid()) {
                    continue;
                }

                if(in_degree(curr_clust_id, sys_graph) == 1) {
                    continue;
                }

                std::vector<ClusterIdType> parent_ids;
                inv_adjacency_iterator parent_iter, parent_end;
                boost::tie(parent_iter, parent_end) = inv_adjacent_vertices(curr_clust_id, sys_graph);
                const ClusterIdType& main_parent_id = *parent_iter;
                ClusterType& main_parent = sys_graph[main_parent_id];

                /*! start from the second parent.*/
                parent_iter++;
                for ( ; parent_iter != parent_end; ++parent_iter) {
                    const ClusterIdType& other_parent_id = *parent_iter;
                    ClusterType& other_parent = sys_graph[other_parent_id];
                    /*! Don't merge different level parents for now.*/
                    if(other_parent.level == main_parent.level)
                        parent_ids.push_back(*parent_iter);
                }

                typename std::vector<ClusterIdType>::iterator id_iter;
                for(id_iter = parent_ids.begin(); id_iter != parent_ids.end(); ++id_iter) {
                    task_system.concat_same_level_clusters(main_parent_id, *id_iter);
                }




            }

        }


        task_system.levels_valid = false;

    }

};


struct cluster_merge_connected_for_cost {
    static std::string name() {
        return "cluster_merge_connected_for_cost";
    }

	template<typename TaskSystemType>
	static void dump_graph(TaskSystemType& task_system, std::string suffix = "") {
        task_system.dump_graphml(cluster_merge_connected_for_cost::name()+ "_" + suffix);
    }

    template<typename TaskSystemType>
    static void find_connected(TaskSystemType& task_system,
                            const typename TaskSystemType::ClusterIdType& curr_clust_id,
                            std::list<typename TaskSystemType::ClusterIdType>& connected_comps, int nr_of_connected) {

        typedef typename TaskSystemType::GraphType GraphType;
        typedef typename TaskSystemType::ClusterType ClusterType;
        typedef typename TaskSystemType::ClusterIdType ClusterIdType;
        typedef typename TaskSystemType::inv_adjacency_iterator inv_adjacency_iterator;
        typedef typename TaskSystemType::adjacency_iterator adjacency_iterator;

        GraphType& sys_graph = task_system.sys_graph;

        ClusterType& curr_clust = sys_graph[curr_clust_id];
        if(!curr_clust.is_valid())
            return;

        inv_adjacency_iterator parent_iter, parent_end;
        boost::tie(parent_iter, parent_end) = inv_adjacent_vertices(curr_clust_id, sys_graph);

        for ( ; parent_iter != parent_end; ++parent_iter) {
            const ClusterIdType& curr_parent_id = *parent_iter;
            // ClusterType& curr_parent = sys_graph[curr_parent_id];

            find_connected(task_system, curr_parent_id, connected_comps, nr_of_connected);
        }


        if(curr_clust.group != 0)
            std::cout << "Already visited node " << curr_clust.index_list << std::endl;
        else {
            connected_comps.push_back(curr_clust_id);
            curr_clust.group = nr_of_connected;
            curr_clust.valid = false;
        }

        adjacency_iterator child_iter, child_end;
        boost::tie(child_iter, child_end) = adjacent_vertices(curr_clust_id, sys_graph);

        for ( ; child_iter != child_end; ++child_iter) {
            const ClusterIdType& curr_child_id = *child_iter;
            // ClusterType& curr_child = sys_graph[curr_child_id];

            find_connected(task_system, curr_child_id, connected_comps, nr_of_connected);
        }

    }

    template<typename TaskSystemType>
    static void apply(TaskSystemType& task_system) {

        typedef typename TaskSystemType::GraphType GraphType;
        typedef typename TaskSystemType::ClusterType ClusterType;
        typedef typename TaskSystemType::ClusterIdType ClusterIdType;
        typedef typename TaskSystemType::adjacency_iterator adjacency_iterator;

        GraphType& sys_graph = task_system.sys_graph;
        ClusterIdType& root_node_id = task_system.root_node_id;

        adjacency_iterator top_iter, top_end;
        boost::tie(top_iter, top_end) = adjacent_vertices(root_node_id, sys_graph);
        sys_graph[root_node_id].valid = false;


        std::vector< std::list<ClusterIdType> > connected_comps_list;
        int nr_of_connected = 0;
        for ( ; top_iter != top_end; ++top_iter) {
            const ClusterIdType& curr_top_id = *top_iter;
            ClusterType& curr_top = sys_graph[curr_top_id];

            if(!curr_top.is_valid())
                continue;

            curr_top.valid = false;
            ++nr_of_connected;

            connected_comps_list.push_back(std::list<ClusterIdType>());
            std::list<ClusterIdType>& connected_comps = connected_comps_list.back();
            connected_comps.push_back(curr_top_id);
            if(curr_top.group != 0)
                std::cout << "Top Already visited node " << curr_top.index_list << std::endl;

            curr_top.group = nr_of_connected;

            adjacency_iterator child_iter, child_end;
            boost::tie(child_iter, child_end) = adjacent_vertices(curr_top_id, sys_graph);

            for ( ; child_iter != child_end; ++child_iter) {
                const ClusterIdType& curr_child_id = *child_iter;
                // const ClusterType& curr_child = sys_graph[curr_child_id];

                find_connected(task_system, curr_child_id, connected_comps, nr_of_connected);
            }


            typename std::list<ClusterIdType>::iterator iter = connected_comps.begin();
            for( ; iter != connected_comps.end(); ++iter) {
                const ClusterIdType& curr_clust_id = *iter;
                ClusterType& curr_clust = sys_graph[curr_clust_id];
                // curr_clust.valid = true;

                std::cout << curr_clust.index_list << ", ";
            }
            std::cout << std::endl;

        }

        sys_graph[root_node_id].valid = true;

        double target_cost = 2000;
        typename std::vector< std::list<ClusterIdType> >::iterator list_iter;
        list_iter = connected_comps_list.begin();
        for( ; list_iter != connected_comps_list.end(); ++list_iter) {
            std::list<ClusterIdType>& connected_comps = *list_iter;
            typename std::list<ClusterIdType>::iterator iter = connected_comps.begin();
            ClusterIdType main_clust_id = *iter;
            sys_graph[main_clust_id].valid = true;

            ++iter;
            long prev_level = sys_graph[main_clust_id].level;
            for( ; iter != connected_comps.end(); ++iter) {
                const ClusterIdType& curr_clust_id = *iter;
                ClusterType& curr_clust = sys_graph[curr_clust_id];
                curr_clust.valid = true;

                if( (sys_graph[main_clust_id].cost + curr_clust.cost <= target_cost) &&
                    (prev_level <= curr_clust.level) ) {
                    std::cout << "Merging " << sys_graph[main_clust_id].index_list << " " << curr_clust.index_list << std::endl;
                    prev_level = curr_clust.level;
                    concat_clusters::apply(task_system, main_clust_id, curr_clust_id);
                }
                else {
                    std::cout << "Chainging main " << sys_graph[main_clust_id].index_list << " " << sys_graph[main_clust_id].level << " ";
                    std::cout << curr_clust.index_list << " " << curr_clust.level << " = " << sys_graph[main_clust_id].cost + curr_clust.cost << std::endl;
                    main_clust_id = curr_clust_id;
                    prev_level = curr_clust.level;
                    std::cout << "New main " << sys_graph[main_clust_id].index_list << std::endl;
                }

            }
        }
        task_system.levels_valid = true;
        task_system.update_node_levels2();


        std::cout << "Done connected : " << connected_comps_list.size() << std::endl;

    }

};



} // openmodelica
} // parmodelica

#endif // header
