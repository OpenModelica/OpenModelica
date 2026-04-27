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

#ifndef MMAVLTREE_H
#define MMAVLTREE_H

#include <ostream>
#include <string>
#include <algorithm>

#include "MetaModelica.h"

#define DEFINE_MM_AVL_TREE_TYPE(name, mm_type, comp_func) \
  extern record_description mm_type##_NODE__desc; \
  extern record_description mm_type##_LEAF__desc; \
  extern record_description mm_type##_EMPTY__desc; \
  using name = OpenModelica::MetaModelica::AvlTree<mm_type##_NODE__desc, mm_type##_LEAF__desc, mm_type##_EMPTY__desc, comp_func>;

namespace OpenModelica
{
  namespace MetaModelica
  {
    template<record_description& NodeDesc, record_description& LeafDesc, record_description& EmptyDesc, auto ComparisonFunc>
    class AvlTree
    {
      private:
        static constexpr int NODE = 0;
        static constexpr int LEAF = 1;
        static constexpr int EMPTY = 2;

        static constexpr int KEY = 0;
        static constexpr int VALUE = 1;
        static constexpr int HEIGHT = 2;
        static constexpr int LEFT = 3;
        static constexpr int RIGHT = 4;

      public:
        AvlTree()
          : _value(makeEmpty())
        {
        }

        AvlTree(MetaModelica::Record value)
          : _value{value}
        {
        }

        operator Value() const noexcept { return _value; }

        void add(Value key, Value value)
        {
          _value = add(_value, key, value);
        }

        template<typename FoldFunc>
        void apply(FoldFunc f) const
        {
          apply(_value, f);
        }

        static std::string treeString(Record tree)
        {
          switch (tree.index()) {
            case NODE:
              return treeString2(tree[LEFT], true, "") +
                     nodeString(tree) + '\n' +
                     treeString2(tree[RIGHT], false, "");

            case LEAF:
              return nodeString(tree);

            default:
              return "EMPTY()";
          }
        }

      private:
        Record add(Record tree, Value key, Value value)
        {
          int key_comp;

          switch (tree.index()) {
            case NODE:
              key_comp = ComparisonFunc(key, tree[KEY]);

              if (key_comp < 0) {
                // Replace left branch.
                tree.set(LEFT, add(tree[LEFT], key, value));
                tree = balance(tree);
              } else if (key_comp > 0) {
                // Replace right branch.
                tree.set(RIGHT, add(tree[RIGHT], key, value));
                tree = balance(tree);
              } else {
                // Replace the existing value.
                tree.set(VALUE, value);
              }
              break;

            case LEAF:
              key_comp = ComparisonFunc(key, tree[KEY]);

              if (key_comp < 0) {
                // Replace left branch.
                tree = makeNode(tree[KEY], tree[VALUE], 2, makeLeaf(key, value), makeEmpty());
                tree = balance(tree);
              } else if (key_comp > 0) {
                // Replace right branch.
                tree = makeNode(tree[KEY], tree[VALUE], 2, makeEmpty(), makeLeaf(key, value));
                tree = balance(tree);
              } else {
                // Replace the existing value.
                tree.set(VALUE, value);
              }
              break;

            case EMPTY:
              tree = makeLeaf(key, value);
              break;
          }

          return tree;
        }

        static Record balance(Record tree)
        {
          Record left = tree[LEFT];
          Record right = tree[RIGHT];
          auto lh = height(left);
          auto rh = height(right);
          auto diff = lh - rh;

          if (diff < -1) {
            if (calculateBalance(right) > 0) {
              tree.set(RIGHT, rotateRight(right));
            }
            tree = rotateLeft(tree);
          } else if (diff > 1) {
            if (calculateBalance(left) < 0) {
              tree.set(LEFT, rotateLeft(left));
            }
            tree = rotateRight(tree);
          } else {
            tree.set(HEIGHT, Value{static_cast<int64_t>(std::max(lh, rh) + 1)});
          }

          return tree;
        }

        static int64_t height(Record tree)
        {
          switch (tree.index()) {
            case NODE: return tree[HEIGHT].toInt();
            case LEAF: return 1;
            default:   return 0;
          }
        }

        static int64_t calculateBalance(Record tree)
        {
          return tree.index() == NODE ? height(tree[LEFT]) - height(tree[RIGHT]) : 0;
        }

        static Record updateNodeHeight(Record tree)
        {
          int64_t h = std::max(height(tree[RIGHT]), height(tree[LEFT])) + 1;
          tree.set(HEIGHT, Value{h});
          return tree;
        }

        static Record rotateLeft(Record tree)
        {
          if (tree.index() == NODE) {
            Record right = tree[RIGHT];
            Record left = tree[LEFT];

            if (right.index() == NODE) {
              tree.set(RIGHT, right[LEFT]);
              updateNodeHeight(tree);
              right.set(LEFT, tree);
              tree = updateNodeHeight(right);
            } else if (right.index() == LEAF) {
              if (left.index() == EMPTY) {
                tree = makeLeaf(tree[KEY], tree[VALUE]);
              } else {
                tree.set(RIGHT, makeEmpty());
                updateNodeHeight(tree);
              }
              tree = makeNode(right[KEY], right[VALUE], 2, tree, makeEmpty());
            }
          }

          return tree;
        }

        static Record rotateRight(Record tree)
        {
          if (tree.index() == NODE) {
            Record right = tree[RIGHT];
            Record left = tree[LEFT];

            if (left.index() == NODE) {
              tree.set(LEFT, left[RIGHT]);
              updateNodeHeight(tree);
              left.set(RIGHT, tree);
              tree = updateNodeHeight(left);
            } else if (left.index() == LEAF) {
              if (right.index() == EMPTY) {
                tree = makeLeaf(tree[KEY], tree[VALUE]);
              } else {
                tree.set(LEFT, makeEmpty());
                updateNodeHeight(tree);
              }
              tree = makeNode(left[KEY], left[VALUE], 2, makeEmpty(), tree);
            }
          }

          return tree;
        }

        static Record makeNode(Value key, Value value, int64_t height, Value left, Value right)
        {
          return Record(NODE, NodeDesc, {key, value, Value{height}, left, right});
        }

        static Record makeLeaf(Value key, Value value)
        {
          return Record(LEAF, LeafDesc, {key, value});
        }

        static Record makeEmpty()
        {
          return Record(EMPTY, EmptyDesc, {});
        }

        template<typename FoldFunc>
        static void apply(Record tree, FoldFunc f)
        {
          switch (tree.index()) {
            case NODE:
              apply(tree[LEFT], f);
              f(tree[KEY], tree[VALUE]);
              apply(tree[RIGHT], f);
              break;

            case LEAF:
              f(tree[KEY], tree[VALUE]);
              break;
          }
        }

        static std::string treeString2(Record tree, bool isLeft, std::string indent)
        {
          if (tree.index() == NODE) {
            return treeString2(tree[LEFT], true, indent + (isLeft ? "     " : " │   ")) +
                   indent + (isLeft ? " ┌" : " └") + "────" +
                   nodeString(tree) + "\n" +
                   treeString2(tree[RIGHT], false, indent + (isLeft ? " │   " : "     "));
          } else if (tree.index() == LEAF) {
            return indent + (isLeft ? " ┌" : " └") + "────" + nodeString(tree) + "\n";
          }

          return "";
        }

        static std::string nodeString(Record node)
        {
          return '(' + node[KEY].toString() + ')';
        }

      private:
        Record _value;
    };

    template<record_description& NodeDesc, record_description& LeafDesc, record_description& EmptyDesc, auto ComparisonFunc>
    std::ostream& operator<< (std::ostream &os, AvlTree<NodeDesc, LeafDesc, EmptyDesc, ComparisonFunc> tree) noexcept
    {
      os << tree.treeString(Record{tree});
      return os;
    }
  }
}

#endif /* MMAVLTREE_H */
