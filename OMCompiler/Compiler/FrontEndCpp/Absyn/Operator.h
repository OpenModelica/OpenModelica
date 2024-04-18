#ifndef ABSYN_OPERATOR_H
#define ABSYN_OPERATOR_H

#include <string_view>
#include <iosfwd>

#include "MetaModelica.h"

namespace OpenModelica::Absyn
{
  class Operator
  {
    public:
      enum Value
      {
        Add,
        Sub,
        Mul,
        Div,
        Pow,
        UnaryPlus,
        UnaryMinus,
        AddEw,
        SubEw,
        MulEw,
        DivEw,
        PowEw,
        UnaryPlusEw,
        UnaryMinusEw,
        And,
        Or,
        Not,
        Less,
        LessEq,
        Greater,
        GreaterEq,
        Equal,
        NotEqual
      };

    public:
      explicit Operator(MetaModelica::Record value);

      MetaModelica::Value toAbsyn() const noexcept;

      bool isArithmetic() const noexcept;
      bool isLogical() const noexcept;
      bool isRelational() const noexcept;

      std::string_view symbol() const noexcept;
      std::string_view spacedSymbol() const noexcept;

    private:
      Value _value;
  };

  inline std::ostream& operator<< (std::ostream &os, Operator op) noexcept
  {
    os << op.symbol();
    return os;
  }
}

#endif /* ABSYN_OPERATOR_H */
