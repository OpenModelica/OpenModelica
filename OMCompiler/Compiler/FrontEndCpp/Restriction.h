#ifndef RESTRICTION_H
#define RESTRICTION_H

#include <bitset>
#include <iosfwd>

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
      static Restriction RecordConstructor() noexcept { return {Prefix::Constructor, Kind::Record}; }
      static Restriction OperatorRecord() noexcept    { return {Prefix::Operator, Kind::Record}; }
      static Restriction Function(Purity purity) noexcept;
      static Restriction ExternalFunction(Purity purity) noexcept;
      static Restriction ParallelFunction() noexcept  { return {Prefix::Parallel, Kind::Function}; }
      static Restriction KernelFunction() noexcept    { return {Prefix::Kernel, Kind::Function}; }
      static Restriction Operator() noexcept          { return Kind::Operator; }
      static Restriction OperatorFunction() noexcept  { return {Prefix::Operator, Kind::Function}; }
      static Restriction ExternalObject() noexcept    { return Kind::ExternalObject; }

      MetaModelica::Value toSCode() const noexcept;

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
