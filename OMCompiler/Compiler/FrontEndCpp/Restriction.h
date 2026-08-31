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

#ifndef RESTRICTION_H
#define RESTRICTION_H

#include <bitset>
#include <iosfwd>
#include <string>

#include "MetaModelica.h"
#include "Prefixes.h"

namespace OpenModelica
{
  class Restriction
  {
    public:
      enum class Kind
      {
        Class          = 1 << 0,
        Model          = 1 << 1,
        Package        = 1 << 2,
        Block          = 1 << 3,
        Optimization   = 1 << 4,
        Connector      = 1 << 5,
        Type           = 1 << 6,
        Enumeration    = 1 << 7,
        Clock          = 1 << 8,
        Record         = 1 << 9,
        Operator       = 1 << 10,
        Function       = 1 << 11,
        ExternalObject = 1 << 12,
      };

      enum class Prefix
      {
        None           = 0,
        Expandable     = 1 << 16,
        Pure           = 1 << 17,
        Impure         = 1 << 18,
        External       = 1 << 19,
        Operator       = 1 << 20,
        Constructor    = 1 << 21,
        Parallel       = 1 << 22,
        Kernel         = 1 << 23
      };

    public:
      Restriction(MetaModelica::Record value) noexcept;
      static Restriction Unknown() noexcept           { return {}; }
      static Restriction Class() noexcept             { return Kind::Class; }
      static Restriction Model() noexcept             { return Kind::Model; }
      static Restriction Package() noexcept           { return Kind::Package; }
      static Restriction Block() noexcept             { return Kind::Block; }
      static Restriction Optimization() noexcept      { return Kind::Optimization; }
      static Restriction Connector(bool expandable) noexcept;
      static Restriction Type() noexcept              { return Kind::Type; }
      static Restriction Enumeration() noexcept       { return Kind::Enumeration; }
      static Restriction Clock() noexcept             { return Kind::Clock; }
      static Restriction Record() noexcept            { return Kind::Record; }
      static Restriction Record(bool isOperator, bool isExternal) noexcept;
      static Restriction RecordConstructor() noexcept { return {Prefix::Constructor, Kind::Record}; }
      static Restriction OperatorRecord() noexcept    { return {Prefix::Operator, Kind::Record}; }
      static Restriction ExternalRecord() noexcept    { return {Prefix::External, Kind::Record}; }
      static Restriction Function(Purity purity) noexcept;
      static Restriction ExternalFunction(Purity purity) noexcept;
      static Restriction ParallelFunction() noexcept  { return {Prefix::Parallel, Kind::Function}; }
      static Restriction KernelFunction() noexcept    { return {Prefix::Kernel, Kind::Function}; }
      static Restriction Operator() noexcept          { return Kind::Operator; }
      static Restriction OperatorFunction() noexcept  { return {Prefix::Operator, Kind::Function}; }
      static Restriction ExternalObject() noexcept    { return Kind::ExternalObject; }

      MetaModelica::Value toSCode() const noexcept;
      MetaModelica::Value toNF() const noexcept;

      Kind kind() const noexcept;
      Purity purity() const noexcept;
      bool is(Prefix prefix, Kind kind) const noexcept;
      bool is(Kind kind) const noexcept;
      bool is(Prefix prefix) const noexcept;

      std::string str() const noexcept;

    private:
      // Private so that users can't create their own combinations.
      Restriction() = default;
      Restriction(Prefix prefix, Kind kind) noexcept;
      Restriction(Kind kind) noexcept;
      Restriction(Prefix prefix) noexcept;

    private:
      int _value = 0;
  };

  inline std::ostream& operator<< (std::ostream& out, Restriction restriction) noexcept
  {
    out << restriction.str();
    return out;
  }
}

#endif /* RESTRICTION_H */
