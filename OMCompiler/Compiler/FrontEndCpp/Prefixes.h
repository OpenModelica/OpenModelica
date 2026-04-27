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

#ifndef PREFIXES_H
#define PREFIXES_H

#include <string_view>
#include <memory>
#include <optional>
#include <iosfwd>

#include "MetaModelica.h"

extern record_description SCode_Replaceable_REPLACEABLE__desc;
extern record_description SCode_Replaceable_NOT__REPLACEABLE__desc;

extern record_description NFPrefixes_Replaceable_REPLACEABLE__desc;
extern record_description NFPrefixes_Replaceable_NOT__REPLACEABLE__desc;

namespace OpenModelica
{
  class Visibility
  {
    public:
      enum Value
      {
        Public,
        Protected
      };

    public:
      Visibility() = default;
      constexpr Visibility(Value value) noexcept : _value{value} {}
      explicit Visibility(MetaModelica::Value value) noexcept;

      MetaModelica::Value toSCode() const noexcept;

      Value value() const noexcept { return _value; }

      std::string_view str() const noexcept;
      std::string_view unparse() const noexcept;

    private:
      Value _value = Value::Public;
  };

  bool operator== (Visibility vis1, Visibility vis2);
  bool operator!= (Visibility vis1, Visibility vis2);

  std::ostream& operator<< (std::ostream &os, Visibility visibility);

  class Variability
  {
    public:
      enum Value
      {
        Constant,
        StructuralParameter,
        Parameter,
        NonStructuralParameter,
        Discrete,
        ImplicitlyDiscrete,
        Continuous
      };

    public:
      Variability() = default;
      constexpr Variability(Value value) noexcept : _value{value} {}
      explicit Variability(MetaModelica::Value value) noexcept;

      MetaModelica::Value toSCode() const noexcept;
      MetaModelica::Value toNF() const noexcept;

      Value value() const noexcept { return _value; }
      Variability effective() const noexcept;

      std::string_view str() const noexcept;
      std::string_view unparse() const noexcept;

    private:
      Value _value = Value::Continuous;
  };

  bool operator== (Variability var1, Variability var2);
  bool operator!= (Variability var1, Variability var2);
  bool operator<  (Variability var1, Variability var2);
  bool operator<= (Variability var1, Variability var2);
  bool operator>  (Variability var1, Variability var2);
  bool operator>= (Variability var1, Variability var2);

  std::ostream& operator<< (std::ostream &os, Variability variability);

  class Final
  {
    public:
      Final() = default;
      constexpr explicit Final(bool value) noexcept : _value{value} {}
      explicit Final(MetaModelica::Record value);

      MetaModelica::Value toSCode() const noexcept;

      bool isFinal() const noexcept { return _value; }
      explicit operator bool() const noexcept { return _value; }

      std::string_view str() const noexcept;
      std::string_view unparse() const noexcept;

    private:
      bool _value = false;
  };

  std::ostream& operator<< (std::ostream &os, Final fin);

  class Each
  {
    public:
      Each() = default;
      constexpr explicit Each(bool value) noexcept : _value{value} {}
      explicit Each(MetaModelica::Record value);

      MetaModelica::Value toSCode() const noexcept;

      bool isEach() const noexcept { return _value; }
      explicit operator bool() const noexcept { return _value; }

      std::string_view str() const noexcept;
      std::string_view unparse() const noexcept;

    private:
      bool _value = false;
  };

  std::ostream& operator<< (std::ostream &os, Each each);

  class InnerOuter
  {
    public:
      enum Value
      {
        None       = 0,
        Inner      = 1 << 0,
        Outer      = 1 << 1,
        Both       = Inner | Outer
      };

    public:
      InnerOuter() = default;
      constexpr InnerOuter(Value value) noexcept : _value{value} {}
      explicit InnerOuter(MetaModelica::Value value);

      MetaModelica::Value toAbsyn() const noexcept;
      MetaModelica::Value toNF() const noexcept;

      bool isInner() const noexcept { return _value & Inner; }
      bool isOuter() const noexcept { return _value & Outer; }
      bool isOnlyInner() const noexcept { return _value == Inner; }
      bool isOnlyOuter() const noexcept { return _value == Outer; }

      std::string_view str() const noexcept;
      std::string_view unparse() const noexcept;

      friend bool operator== (InnerOuter io1, InnerOuter io2) noexcept;
      friend bool operator!= (InnerOuter io1, InnerOuter io2) noexcept;

    private:
      Value _value = Value::None;
  };

  bool operator== (InnerOuter io1, InnerOuter io2) noexcept;
  bool operator!= (InnerOuter io1, InnerOuter io2) noexcept;

  std::ostream& operator<< (std::ostream &os, InnerOuter io);

  class Redeclare
  {
    public:
      Redeclare() = default;
      constexpr explicit Redeclare(bool value) noexcept : _value{value} {}
      explicit Redeclare(MetaModelica::Record value);

      MetaModelica::Value toSCode() const noexcept;

      bool isRedeclare() const noexcept { return _value; }
      explicit operator bool() const noexcept { return _value; }

      std::string_view str() const noexcept;
      std::string_view unparse() const noexcept;

    private:
      bool _value = false;
  };

  std::ostream& operator<< (std::ostream &os, Redeclare redeclare);

  template<typename ConstrainingClass>
  class Replaceable
  {
      static constexpr int REPLACEABLE = 0;
      static constexpr int NOT_REPLACEABLE = 1;

    public:
      Replaceable() = default;
      constexpr explicit Replaceable(bool value) : _value{value} {}

      explicit Replaceable(MetaModelica::Record value)
        : _value{value.index() == REPLACEABLE},
          _cc{_value ? value[0].mapPointer<ConstrainingClass>() : nullptr}
      {

      }

      Replaceable(const Replaceable &other)
        : _value{other._value},
          _cc{other._cc ? std::make_unique<ConstrainingClass>(*other._cc) : nullptr}
      {

      }

      Replaceable(Replaceable &&other) = default;

      Replaceable& operator= (Replaceable other)
      {
        other.swap(*this);
        return *this;
      }

      void swap(Replaceable<ConstrainingClass> &other)
      {
        using std::swap;
        swap(_value, other._value);
        swap(_cc, other._cc);
      }

      MetaModelica::Value toSCode() const noexcept
      {
        if (isReplaceable()) {
          return MetaModelica::Record{REPLACEABLE, SCode_Replaceable_REPLACEABLE__desc, {
            _cc ? MetaModelica::Option{_cc->toSCode()} : MetaModelica::Option{}
          }};
        }

        return MetaModelica::Record{NOT_REPLACEABLE, SCode_Replaceable_NOT__REPLACEABLE__desc};
      }

      MetaModelica::Value toNF() const
      {
        if (isReplaceable()) {
          return MetaModelica::Record{REPLACEABLE, NFPrefixes_Replaceable_REPLACEABLE__desc, {
            _cc ? MetaModelica::Option{_cc->toNF()} : MetaModelica::Option{}
          }};
        }

        return MetaModelica::Record{NOT_REPLACEABLE, NFPrefixes_Replaceable_NOT__REPLACEABLE__desc};
      }

      bool isReplaceable() const noexcept { return _value; }
      explicit operator bool() const noexcept { return _value; }

      const ConstrainingClass* constrainingClass() const noexcept { return _cc.get(); }

      std::string_view str() const noexcept
      {
        return _value ? "replaceable" : "";
      }

      std::string_view unparse() const noexcept
      {
        return _value ? "replaceable " : "";
      }

    private:
      bool _value = false;
      std::unique_ptr<ConstrainingClass> _cc;
  };

  class Encapsulated
  {
    public:
      Encapsulated() = default;
      constexpr explicit Encapsulated(bool value) noexcept : _value{value} {}
      explicit Encapsulated(MetaModelica::Record value);

      MetaModelica::Value toSCode() const noexcept;

      bool isEncapsulated() const noexcept { return _value; }
      explicit operator bool() const noexcept { return _value; }

      std::string_view str() const noexcept;
      std::string_view unparse() const noexcept;

    private:
      bool _value = false;
  };

  std::ostream& operator<< (std::ostream &os, Encapsulated encapsulated);

  class Partial
  {
    public:
      Partial() = default;
      constexpr explicit Partial(bool value) : _value{value} {}
      explicit Partial(MetaModelica::Record value);

      MetaModelica::Value toSCode() const noexcept;

      bool isPartial() const noexcept { return _value; }
      explicit operator bool() const noexcept { return _value; }

      std::string_view str() const noexcept;
      std::string_view unparse() const noexcept;

    private:
      bool _value = false;
  };

  std::ostream& operator<< (std::ostream &os, Partial partial);

  class Purity
  {
    public:
      enum Value
      {
        None,
        Pure,
        Impure
      };

    public:
      Purity() = default;
      constexpr Purity(Value value) noexcept : _value{value} {}
      explicit Purity(MetaModelica::Record value);

      MetaModelica::Value toAbsyn() const noexcept;

      Value value() const noexcept { return _value; }

      std::string_view str() const noexcept;
      std::string_view unparse() const noexcept;

    private:
      Value _value = Value::None;
  };

  bool operator== (Purity pur1, Purity pur2) noexcept;
  bool operator!= (Purity pur1, Purity pur2) noexcept;
  // pur1 is less pure than pur2 if pur1 is impure and pur2 is not.
  bool operator<  (Purity pur1, Purity pur2) noexcept;

  std::ostream& operator<< (std::ostream &os, Purity purity);

  class ConnectorType
  {
    public:
      enum Value
      {
        None               = 0,
        Potential          = 1 << 0, // A connector element without a prefix.
        Flow               = 1 << 1, // A connector element with flow prefix.
        Stream             = 1 << 2, // A connector element with stream prefix.
        PotentiallyPresent = 1 << 3, // An element declared inside an expandable connector.
        Virtual            = 1 << 4, // A virtual connector used in a connetion.
        Connector          = 1 << 5, // A non-expandable connector that contains elements.
        Expandable         = 1 << 6  // An expandable connector.
      };

    public:
      ConnectorType() = default;
      constexpr ConnectorType(Value value) noexcept : _value{value} {}
      explicit ConnectorType(MetaModelica::Value value);

      MetaModelica::Value toSCode() const noexcept;
      MetaModelica::Value toNF() const noexcept;

      bool isPotential() const noexcept;
      bool isFlow() const noexcept;
      bool isStream() const noexcept;
      bool isFlowOrStream() const noexcept;
      bool isConnector() const noexcept;
      bool isConnectorType() const noexcept;
      bool isExpandable() const noexcept;
      bool isUndeclared() const noexcept;
      bool isVirtual() const noexcept;
      bool isPotentiallyPresent() const noexcept;

      static std::optional<ConnectorType> merge(ConnectorType outer, ConnectorType inner) noexcept;

      std::string_view str() const noexcept;
      std::string debugStr() const noexcept;
      std::string_view unparse() const noexcept;

    private:
      int64_t _value = 0;
  };

  std::ostream& operator<< (std::ostream &os, ConnectorType cty);

  class Parallelism
  {
    public:
      enum Value
      {
        None,
        Global,
        Local
      };

    public:
      Parallelism() = default;
      constexpr Parallelism(Value value) noexcept : _value{value} {}
      explicit Parallelism(MetaModelica::Value value);

      MetaModelica::Value toSCode() const noexcept;
      MetaModelica::Value toNF() const noexcept;

      Value value() const noexcept { return _value; }

      std::string_view str() const noexcept;
      std::string_view unparse() const noexcept;

    private:
      Value _value = Value::None;
  };

  bool operator== (Parallelism par1, Parallelism par2) noexcept;
  bool operator!= (Parallelism par1, Parallelism par2) noexcept;

  std::ostream& operator<< (std::ostream &os, Parallelism par);

  class Direction
  {
    public:
      enum Value
      {
        None,
        Input,
        Output,
      };

    public:
      Direction() = default;
      constexpr Direction(Value value) noexcept : _value{value} {}
      explicit Direction(MetaModelica::Value value);

      MetaModelica::Value toAbsyn() const noexcept;
      MetaModelica::Value toNF() const noexcept;

      Value value() const noexcept { return _value; }

      static std::optional<Direction> merge(Direction outer, Direction inner, bool allowSame = false);

      std::string_view str() const noexcept;
      std::string_view unparse() const noexcept;

    private:
      Value _value = Value::None;
  };

  bool operator== (Direction dir1, Direction dir2) noexcept;
  bool operator!= (Direction dir1, Direction dir2) noexcept;

  std::ostream& operator<< (std::ostream &os, Direction direction);

  class Field
  {
    public:
      Field() = default;
      constexpr explicit Field(bool value) : _value{value} {}
      explicit Field(MetaModelica::Record value);

      MetaModelica::Value toAbsyn() const noexcept;

      bool isField() const noexcept { return _value; }
      explicit operator bool() const noexcept { return _value; }

      std::string_view str() const noexcept;
      std::string_view unparse() const noexcept;

    private:
      bool _value = false;
  };

  std::ostream& operator<< (std::ostream &os, Field field);
}

#endif /* PREFIXES_H */
