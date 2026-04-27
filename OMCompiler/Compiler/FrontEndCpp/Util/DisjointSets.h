/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef DISJOINTSETS_H
#define DISJOINTSETS_H

#include <vector>
#include <unordered_map>

namespace OpenModelica
{
  // This is a disjoint-set data structure using a typical disjoint-set forest.
  // The nodes are stored in an array of integers. The root element of a set is
  // given a negative value that corresponds to its rank (height of the tree),
  // while other elements are given positive values that correspond to the
  // index of their parent in the array. A hash table is used to look up the
  // array index of an entry, and is also used to store the entries.
  template<typename T>
  class DisjointSets
  {
    public:
      // Adds a new unique entry. If the entry might already have been added,
      // use find instead. Returns the index for the new node.
      int add(const T& entry)
      {
        int index = _nodes.size();
        _nodes.push_back(-1);
        _elements.insert({entry, index});
        return index;
      }

      // Adds a new unique entry. If the entry might already have been added,
      // use find instead. Returns the index for the new node.
      int add(T&& entry)
      {
        int index = _nodes.size();
        _nodes.push_back(-1);
        _elements.insert({std::move(entry), index});
        return index;
      }

      // Returns the node index associated with a given entry.
      // If no node exists for the entry then a new one is added.
      int find(const T& entry)
      {
        auto it = _elements.find(entry);

        if (it != _elements.end()) {
          // A node already exists, return its index.
          return it->second;
        } else {
          // A node doesn't already exist, create a new one.
          return add(entry);
        }
      }

      // Returns the index of the root of the tree that a node belongs to.
      int findRoot(int nodeIndex)
      {
        int parent = _nodes[nodeIndex];
        int root_index = nodeIndex;

        // Follow the parent indices until a negative index is found, which indicates a root.
        while (parent >= 0) {
          root_index = parent;
          parent = _nodes[parent];
        }

        // Path compression. Attach each of the traversed nodes directory to the root,
        // to speed up repeated calls.
        parent = _nodes[nodeIndex];
        int idx = nodeIndex;

        while (parent >= 0) {
          _nodes[idx] = root_index;
          idx = parent;
          parent = _nodes[parent];
        }

        return root_index;
      }

      // Returns the set that the given entry belongs to, or adds the entry to
      // a new set if it's not in any set. The set is represented by the root
      // node of the tree.
      int findSet(const T& entry)
      {
        int index = find(entry);
        return findRoot(index);
      }

      // Merges the two sets that the given entries belong to.
      void merge(const T& entry1, const T& entry2)
      {
        merge(findSet(entry1), findSet(entry2));
      }

      // Merges two sets into one. The set indices should point to root nodes,
      // i.e. indices returned by findSet, otherwise the result will be undefined.
      void merge(int set1, int set2)
      {
        if (set1 == set2) return;

        // Assume that the indices actually point to root nodes, in which case
        // the entries in the node array are actually the ranks of the nodes.
        int rank1 = _nodes.at(set1);
        int rank2 = _nodes.at(set2);

        if (rank1 > rank2) {
          // First set is smallest, attach it to the second set.
          _nodes[set2] = set1;
        } else if(rank1 < rank2) {
          // Second set is smallest, attach it to the first set.
          _nodes[set1] = set2;
        } else {
          // Both sets are the same size. Attach the second to the first, and
          // increase the rank of the first one (which means decreasing it,
          // since the rank is stored as a negative number).
          --_nodes[set1];
          _nodes[set2] = set1;
        }
      }

      // Returns all the sets from the disjoint sets structure as an array.
      std::vector<std::vector<T>> extractSets()
      {
        int set_idx = 0;

        // Go through each node and assign a unique set index to each root node.
        // The index is stored as a negative number to mark the node as a root.
        auto nodes = _nodes;
        for (int &i: nodes) {
          if (i < 0) {
            ++set_idx;
            i = -set_idx;
          }
        }

        // Create a value->key table.
        std::vector<const T*> value_table(nodes.size());
        for (const auto &it: _elements) {
          value_table[it.second] = &it.first;
        }

        std::vector<std::vector<T>> sets(set_idx);

        // Use the value->key table to go through the entries in the order that
        // they were added. This is to mimic the original MetaModelica
        // implementation which stored the entries in that order.
        for (std::size_t i = 0; i < value_table.size(); ++i) {
          // Follow the parent indices until the root.
          set_idx = nodes[i];

          while (set_idx >= 0) {
            set_idx = nodes[set_idx];
          }

          // Negate the set index to get the actual index.
          set_idx = -set_idx;
          // Add the entry to the array pointed to by the set index.
          sets[set_idx-1].push_back(*value_table[i]);
        }

        return sets;
      }

    private:
      std::vector<int> _nodes;
      std::unordered_map<T, int> _elements;
  };
}

#endif /* DISJOINTSETS_H */
