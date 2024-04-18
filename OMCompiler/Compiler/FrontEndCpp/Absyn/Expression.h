#ifndef ABSYN_EXPRESSION_H
#define ABSYN_EXPRESSION_H

#include <memory>
#include <cstdint>
#include <string>
#include <vector>
#include <iosfwd>

#include "MetaModelica.h"
#include "ComponentRef.h"
#include "Operator.h"
#include "FunctionArgs.h"

namespace OpenModelica::Absyn
{
  class Subscript;

  class Expression
  {
    public:
      class Base
      {
        public:
          virtual ~Base() = default;

          virtual std::unique_ptr<Base> clone() const noexcept = 0;
          virtual MetaModelica::Value toAbsyn() const noexcept = 0;
          virtual void print(std::ostream &os) const noexcept = 0;
      };

    public:
      Expression(MetaModelica::Record value);
      Expression(const Expression &other) noexcept;
      Expression(Expression &&other) = default;
      Expression(const Expression::Base &base) noexcept;

      Expression& operator= (const Expression &other) noexcept;
      Expression& operator= (Expression &&other) = default;

      MetaModelica::Value toAbsyn() const noexcept;

      template<typename T>
      const T& get() const
      {
        return dynamic_cast<const T&>(*_impl.get());
      }

      std::optional<ComponentRef> toCref() const noexcept;

      void print(std::ostream &os) const noexcept;

    private:
      std::unique_ptr<Base> _impl;
  };

  std::ostream& operator<< (std::ostream &os, const Expression &exp) noexcept;

  class Integer : public Expression::Base
  {
    public:
      explicit Integer(MetaModelica::Record value);
      explicit Integer(int64_t value) noexcept;

      int64_t value() const noexcept { return _value; }

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      int64_t _value;
  };

  class Real : public Expression::Base
  {
    public:
      explicit Real(MetaModelica::Record value);
      explicit Real(std::string value) noexcept;

      double value() const noexcept;

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      std::string _value;
  };

  class Boolean : public Expression::Base
  {
    public:
      explicit Boolean(MetaModelica::Record value);
      explicit Boolean(bool value) noexcept;

      bool value() const noexcept { return _value; }

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      bool _value;
  };

  class String : public Expression::Base
  {
    public:
      explicit String(MetaModelica::Record value);
      explicit String(std::string value) noexcept;

      const std::string& value() const noexcept { return _value; }

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      std::string _value;
  };

  class Cref : public Expression::Base
  {
    public:
      explicit Cref(MetaModelica::Record value);
      explicit Cref(ComponentRef cref) noexcept;

      const ComponentRef& cref() const { return _cref; }

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      ComponentRef _cref;
  };

  class Binary : public Expression::Base
  {
    public:
      explicit Binary(MetaModelica::Record value);
      Binary(Expression exp1, Operator op, Expression exp2) noexcept;

      const Expression& exp1() const noexcept { return _exp1; };
      Operator op() const noexcept { return _op; };
      const Expression& exp2() const noexcept { return _exp2; };

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      Expression _exp1;
      Operator _op;
      Expression _exp2;
  };

  class Unary : public Expression::Base
  {
    public:
      explicit Unary(MetaModelica::Record value);
      Unary(Operator op, Expression exp) noexcept;

      Operator op() const noexcept { return _op; }
      const Expression& exp() const noexcept { return _exp; }

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      Operator _op;
      Expression _exp;
  };

  class IfExpression : public Expression::Base
  {
    public:
      explicit IfExpression(MetaModelica::Record value);
      IfExpression(Expression condition, Expression trueBranch, Expression falseBranch) noexcept;

      const Expression& condition() const noexcept { return _condition; }
      const Expression& trueBranch() const noexcept { return _true; }
      const Expression& falseBranch() const noexcept { return _false; }

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      Expression _condition;
      Expression _true;
      Expression _false;
  };

  class Call : public Expression::Base
  {
    public:
      explicit Call(MetaModelica::Record value);
      Call(ComponentRef functionName, FunctionArgs args) noexcept;

      const ComponentRef& name() const noexcept { return _functionName; }
      const FunctionArgs& args() const noexcept { return _args; }

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      ComponentRef _functionName;
      FunctionArgs _args;
  };

  class PartEvalFunction : public Expression::Base
  {
    public:
      explicit PartEvalFunction(MetaModelica::Record value);
      PartEvalFunction(ComponentRef functionName, FunctionArgs args) noexcept;

      const ComponentRef& name() const noexcept { return _functionName; }
      const FunctionArgs& args() const noexcept { return _args; }

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      ComponentRef _functionName;
      FunctionArgs _args;
  };

  class Array : public Expression::Base
  {
    public:
      explicit Array(MetaModelica::Record value);
      Array(std::vector<Expression> elements) noexcept;

      const std::vector<Expression>& elements() const noexcept { return _elements; }

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      std::vector<Expression> _elements;
  };

  class Matrix : public Expression::Base
  {
    public:
      explicit Matrix(MetaModelica::Record value);
      Matrix(std::vector<Array> matrix) noexcept;

      const std::vector<Array>& elements() const noexcept { return _matrix; }

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      std::vector<Array> _matrix;
  };

  class Range : public Expression::Base
  {
    public:
      explicit Range(MetaModelica::Record value);
      Range(Expression start, std::optional<Expression> step, Expression stop) noexcept;


      const Expression& start() const noexcept { return _start; }
      const Expression& stop() const noexcept { return _stop; }
      const std::optional<Expression>& step() const { return _step; }

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      Expression _start;
      std::optional<Expression> _step;
      Expression _stop;
  };

  class Tuple : public Expression::Base
  {
    public:
      explicit Tuple(MetaModelica::Record value);
      Tuple(std::vector<Expression> elements) noexcept;

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      std::vector<Expression> _elements;
  };

  class End : public Expression::Base
  {
    public:
      End() = default;

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;
  };

  class Code : public Expression::Base
  {
    public:
      explicit Code(MetaModelica::Record value);

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      //std::unique_ptr<CodeNode> _code;
  };

  class SubscriptedExp : public Expression::Base
  {
    public:
      explicit SubscriptedExp(MetaModelica::Record value);

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;

    private:
      Expression _exp;
      std::vector<Subscript> _subscripts;
  };

  class Break : public Expression::Base
  {
    public:
      Break() = default;

      std::unique_ptr<Base> clone() const noexcept override;
      MetaModelica::Value toAbsyn() const noexcept override;
      void print(std::ostream &os) const noexcept override;
  };
}

#endif /* ABSYN_EXPRESSION_H */
