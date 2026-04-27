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

#ifndef CLASSTREE_H
#define CLASSTREE_H

#include <string>
#include <vector>
#include <unordered_map>

#include "Absyn/AbsynFwd.h"
#include "MetaModelica.h"

namespace OpenModelica
{
  class InstNode;
  class Import;

  class ClassTree
  {
    public:
      enum class State
      {
        Partial,      // Allows lookup of local classes and imported elements.
        Expanded,     // Lookup table has all elements, but elements have not
                      // yet been added to the arrays.
        Instantiated, // Allows lookup of both local and inherited elements.
        Flat
      };

    public:
      ClassTree();
      ClassTree(MetaModelica::Record value);
      //ClassTree(const std::vector<Absyn::Element*> &elements, bool isClassExtends, InstNode *parent);
      ClassTree(const Absyn::ClassParts &definition, bool isClassExtends, InstNode *parent);
      //ClassTree(const std::vector<Absyn::Enumeration::EnumLiteral> &literals, const Type &enumType,
      //          const InstNode &enumClass);
      //ClassTree(const std::vector<InstNode> fields, const InstNode &out);
      ClassTree(const ClassTree &other);
      ClassTree(ClassTree &&other) noexcept;
      ~ClassTree();

      ClassTree& operator=(ClassTree other);
      friend void swap(ClassTree &first, ClassTree &second) noexcept;

      void add(Absyn::Class &cls);
      void add(Absyn::Component &comp);
      void add(Absyn::Extends &ext);
      void add(Absyn::Import &imp);
      bool add(std::unique_ptr<InstNode> node);

      // TODO: Encapsulate better.
      std::vector<std::unique_ptr<InstNode>>& components() { return _components; }

      void expand();
      void instantiate();

      MetaModelica::Record toNF() const;

    public:
      enum class EntryType
      {
        Class,
        Component,
        Import
      };

      struct Entry
      {
        Entry(EntryType type, size_t index);
        Entry(MetaModelica::Record value);

        operator MetaModelica::Value() const noexcept;
        Entry offset(size_t classOffset, size_t componentOffset) const;

        EntryType type;
        size_t index;
      };

      enum class DuplicateType
      {
        Duplicate,
        Redeclare,
        Entry
      };

      struct Duplicate
      {
        Duplicate(DuplicateType type, Entry entry);
        Duplicate(Entry kept, Entry duplicate);

        DuplicateType type;
        Entry entry;
        InstNode *node = nullptr;
        std::vector<Duplicate> children;
      };

    public:
      using LookupTable = std::unordered_map<std::string, Entry>;
      using DuplicateTable = std::unordered_map<std::string, Duplicate>;

    private:
      void addLocalName(const std::string &name, Entry entry, const InstNode &node);
      void addInheritedName(const std::string &name, Entry entry);
      void countInheritedElements(size_t &classCount, size_t &componentCount) const;
      void expandExtends(const InstNode &extends, size_t classOffset, size_t componentOffset);

    private:
      InstNode *_parent;
      State _state = State::Partial;
      LookupTable _table;
      // TODO: Use pointers in the lookup table and just store local elements here?
      std::vector<std::unique_ptr<InstNode>> _classes;
      std::vector<std::unique_ptr<InstNode>> _components;
      std::vector<int64_t> _localComponents;
      std::vector<std::unique_ptr<InstNode>> _extends;
      std::vector<Import> _imports;
      DuplicateTable _duplicates;

      mutable std::optional<MetaModelica::Record> _mmCache;
  };

  void swap(ClassTree &first, ClassTree &second) noexcept;
}

#endif /* CLASSTREE_H */
