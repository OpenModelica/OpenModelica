#ifndef PREFIXES_H
#define PREFIXES_H

#include <string_view>
#include <memory>
#include <optional>
#include <iosfwd>

#include "MetaModelica.h"

extern record_description SCode_Replaceable_REPLACEABLE__desc;
extern record_description SCode_Replaceable_NOT__REPLACEABLE__desc;

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
      explicit Visibility(MetaModelica::Record value) noexcept;

      MetaModelica::Value toSCode() const noexcept;

      Value value() const noexcept { return _value; }

      std::string_view str() const noexcept;
      std::string_view unparse() const noexcept;

    private:
      Value _value = Value::Public;
  };

  bool operator== (Visibility vis1, Visibility vis2);
  bool operator!= (Visibility vis1, Visibility vis2);

  std::ostream& operator<< (std::ostream &os, Visibility visibility) noexcept;

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
      explicit Variability(MetaModelica::Record value) noexcept;

      MetaModelica::Value toSCode() const noexcept;

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
      explicit InnerOuter(MetaModelica::Record value);

      MetaModelica::Value toAbsyn() const noexcept;

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

      Replaceable& operator= (Replaceable &&other) = default;

      void swap(Replaceable<ConstrainingClass> &other)
      {
        std::swap(_value, other._value);
        std::swap(_cc, other._cc);
      }

      MetaModelica::Value toSCode() const noexcept
      {
        if (isReplaceable()) {
          return MetaModelica::Record(REPLACEABLE, SCode_Replaceable_REPLACEABLE__desc, {
            _cc ? MetaModelica::Option(_cc->toSCode()) : MetaModelica::Option()
          });
        }

        return MetaModelica::Record(NOT_REPLACEABLE, SCode_Replaceable_NOT__REPLACEABLE__desc);
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
      explicit ConnectorType(MetaModelica::Record value);

      MetaModelica::Value toSCode() const noexcept;

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
      int _value = 0;
  };

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
      explicit Parallelism(MetaModelica::Record value);

      MetaModelica::Value toSCode() const noexcept;

      Value value() const noexcept { return _value; }

      std::string_view str() const noexcept;
      std::string_view unparse() const noexcept;

    private:
      Value _value = Value::None;
  };

  bool operator== (Parallelism par1, Parallelism par2) noexcept;
  bool operator!= (Parallelism par1, Parallelism par2) noexcept;

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
      explicit Direction(MetaModelica::Record value);

      MetaModelica::Value toAbsyn() const noexcept;

      Value value() const noexcept { return _value; }

      static std::optional<Direction> merge(Direction outer, Direction inner, bool allowSame = false);

      std::string_view str() const noexcept;
      std::string_view unparse() const noexcept;

    private:
      Value _value = Value::None;
  };

  bool operator== (Direction dir1, Direction dir2) noexcept;
  bool operator!= (Direction dir1, Direction dir2) noexcept;

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
}

#endif /* PREFIXES_H */
