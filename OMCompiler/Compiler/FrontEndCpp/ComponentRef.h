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

#ifndef COMPONENTREF_H
#define COMPONENTREF_H

#include <iosfwd>

#include "MetaModelica.h"

#include "Subscript.h"
#include "Type.h"

namespace OpenModelica
{
  class InstNode;

  class ComponentRef
  {
    public:
      enum class Origin
      {
        Absyn,   // From an Absyn cref.
        Scope,   // From prefixing the cref with its scope.
        Iterator // From an iterator.
      };

      struct Part
      {
        Part(MetaModelica::Record value);
        Part(InstNode *node, std::vector<Subscript> subscripts, Type ty, Origin origin)
          : node{node}, subscripts{std::move(subscripts)}, ty{std::move(ty)}, origin{origin} {}

        const std::string& name() const;
        std::string str() const;

        InstNode *node;
        std::vector<Subscript> subscripts;
        Type ty;
        Origin origin;

        static inline const std::string wildcard = "_";
      };

      using PartList = std::vector<Part>;
      using PartIterator = PartList::iterator;
      using PartConstIterator = PartList::const_iterator;

    public:
      ComponentRef();
      ComponentRef(std::vector<Part> parts);
      explicit ComponentRef(MetaModelica::Record value);
      ~ComponentRef();

      MetaModelica::Value toNF() const;

      void pushBack(Part part);
      void emplaceBack(InstNode *node, std::vector<Subscript> subscripts, Type ty, Origin origin = Origin::Scope);
      void popBack();

      const Part& front() const { return _parts.front(); }
      const Part& back() const { return _parts.back(); }

      PartIterator begin() noexcept { return _parts.begin(); }
      PartIterator end() noexcept { return _parts.end(); }
      PartConstIterator begin() const noexcept { return _parts.begin(); }
      PartConstIterator end() const noexcept  { return _parts.end(); }
      PartConstIterator cbegin() noexcept { return _parts.cbegin(); }
      PartConstIterator cend() const noexcept { return _parts.cend(); }

      std::string str() const;
      std::size_t hash() const noexcept;

    private:
      std::vector<Part> _parts;
  };

  void swap(ComponentRef::Part &first, ComponentRef::Part &second) noexcept;

  bool operator== (const ComponentRef::Part &part1, const ComponentRef::Part &part2) noexcept;
  bool operator== (const ComponentRef &cref1, const ComponentRef &cref2) noexcept;

  std::ostream& operator<< (std::ostream &os, const ComponentRef::Part &part);
  std::ostream& operator<< (std::ostream &os, const ComponentRef &cref);
}

template<>
struct std::hash<OpenModelica::ComponentRef>
{
  std::size_t operator() (const OpenModelica::ComponentRef &cref) const noexcept
  {
    return cref.hash();
  }
};

#endif /* COMPONENTREF_H */
