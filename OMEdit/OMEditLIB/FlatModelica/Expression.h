#ifndef EXPRESSION_H
#define EXPRESSION_H

#include <memory>
#include <string>
#include <ostream>
#include <functional>
#include <vector>

#include <QString>

namespace FlatModelica
{
  class ExpressionBase;

  /*!
   * \class FlatModelica::Expression
   * \brief Represents a flat Modelica expression.
   *
   * This class can be used to parse and evaluate flat Modelica expressions.
   * It supports most of Modelica's builtin operators and functions, though the
   * operators are only implemented for literal values so expressions should be
   * evaluated before using them.
   *
   * Using the default constructor will create an Expression that contains no
   * value, the only methods allowed on such Expressions are the isXXX methods
   * (like isNull()), toString/toQString, and assignment operators.
   *
   * Since Flat Modelica expression contain no type information and the result
   * files only store double values all variables are evaluated to Real
   * expression. This class is therefore more permissive than regular Modelica
   * when type casting, and evaluating an expression might result in a Real when
   * e.g. a Boolean was expected (so e.g.  isNumber or isBooleanish should
   * usually be used rather than isInteger or isBoolean when checking the type
   * of an evaluated Expression).
   *
   * Also since there's no type information methods like isInteger will only
   * return true for an actual Integer expression, not for an expression whose
   * type is Integer (like an Integer variable).
   */
  class Expression
  {
    public:
      using VariableEvaluator = std::function<double(std::string cref_name)>;

    public:
      Expression();
      explicit Expression(int value);
      explicit Expression(int64_t value);
      explicit Expression(double value);
      explicit Expression(bool value);
      explicit Expression(std::string value);
      explicit Expression(const QString &value);
      explicit Expression(const char *value);
      explicit Expression(std::vector<Expression> elements);
      explicit Expression(std::unique_ptr<ExpressionBase> value);

      ~Expression();

      Expression(const Expression &other);
      Expression& operator= (const Expression &other) noexcept;
      Expression(Expression &&other);
      Expression& operator= (Expression &&other) noexcept;

      static Expression parse(std::string str);
      static Expression parse(const QString &str);

      Expression evaluate(const VariableEvaluator &var_eval) const;

      bool isNull() const;
      bool isLiteral() const;
      bool isInteger() const;
      bool isReal() const;
      bool isNumber() const;
      bool isBoolean() const;
      bool isBooleanish() const;
      bool isString() const;
      bool isArray() const;
      bool isCall() const;
      bool isCall(const std::string &name) const;

      size_t ndims() const;
      size_t size() const;
      size_t size(size_t dimension) const;

      int64_t intValue() const;
      double realValue() const;
      bool boolValue() const;
      std::string stringValue() const;
      QString QStringValue() const;
      QString functionName() const;

      std::string toString() const;
      QString toQString() const;

      const std::vector<Expression>& elements() const;
      const std::vector<Expression>& args() const;
      const Expression& arg(size_t index) const;
      void setArg(size_t index, const Expression &e);

      Expression& operator+= (const Expression &other);
      Expression& operator-= (const Expression &other);
      Expression& operator*= (const Expression &other);
      Expression& operator/= (const Expression &other);
      Expression& operator^= (const Expression &other);

      static Expression addEw(const Expression &e1, const Expression &e2);
      static Expression subEw(const Expression &e1, const Expression &e2);
      static Expression mulEw(const Expression &e1, const Expression &e2);
      static Expression divEw(const Expression &e1, const Expression &e2);
      static Expression powEw(const Expression &e1, const Expression &e2);

      Expression operator- () const;
      Expression operator! () const;

      friend Expression operator&& (const Expression &e1, const Expression &e2);
      friend Expression operator|| (const Expression &e1, const Expression &e2);

      friend bool operator== (const Expression &e1, const Expression &e2);
      friend bool operator!= (const Expression &e1, const Expression &e2);
      friend bool operator< (const Expression &e1, const Expression &e2);
      friend bool operator<= (const Expression &e1, const Expression &e2);
      friend bool operator> (const Expression &e1, const Expression &e2);
      friend bool operator>= (const Expression &e1, const Expression &e2);

      friend std::ostream& operator<< (std::ostream &os, const Expression &e);

    private:
      std::unique_ptr<ExpressionBase> _value;
  };

  Expression operator+ (Expression lhs, const Expression &rhs);
  Expression operator- (Expression lhs, const Expression &rhs);
  Expression operator* (Expression lhs, const Expression &rhs);
  Expression operator/ (Expression lhs, const Expression &rhs);
  Expression operator^ (Expression lhs, const Expression &rhs);
}

#endif /* EXPRESSION_H */
