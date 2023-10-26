#include <ostream>

#include "Util.h"
#include "Subscript.h"
#include "Expression.h"

constexpr int INTEGER = 0;
constexpr int REAL = 1;
constexpr int CREF = 2;
constexpr int STRING = 3;
constexpr int BOOL = 4;
constexpr int BINARY = 5;
constexpr int UNARY = 6;
constexpr int LBINARY = 7;
constexpr int LUNARY = 8;
constexpr int RELATION = 9;
constexpr int IFEXP = 10;
constexpr int CALL = 11;
constexpr int PARTEVALFUNCTION = 12;
constexpr int ARRAY = 13;
constexpr int MATRIX = 14;
constexpr int RANGE = 15;
constexpr int TUPLE = 16;
constexpr int END = 17;
constexpr int CODE = 18;
constexpr int EXPRESSIONCOMMENT = 24;
constexpr int SUBSCRIPTED_EXP = 25;
constexpr int BREAK = 26;

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

std::unique_ptr<Expression::Base> exp_from_mm(MetaModelica::Record value)
{
  switch (value.index()) {
    case INTEGER:           return std::make_unique<Integer>(value);
    case REAL:              return std::make_unique<Real>(value);
    case CREF:              return std::make_unique<Cref>(value);
    case STRING:            return std::make_unique<String>(value);
    case BOOL:              return std::make_unique<Boolean>(value);
    case BINARY:            return std::make_unique<Binary>(value);
    case UNARY:             return std::make_unique<Unary>(value);
    case LBINARY:           return std::make_unique<Binary>(value);
    case LUNARY:            return std::make_unique<Unary>(value);
    case RELATION:          return std::make_unique<Binary>(value);
    case IFEXP:             return std::make_unique<IfExpression>(value);
    case CALL:              return std::make_unique<Call>(value);
    case PARTEVALFUNCTION:  return std::make_unique<PartEvalFunction>(value);
    case ARRAY:             return std::make_unique<Array>(value);
    case MATRIX:            return std::make_unique<Matrix>(value);
    case RANGE:             return std::make_unique<Range>(value);
    case TUPLE:             return std::make_unique<Tuple>(value);
    case END:               return std::make_unique<End>();
    case EXPRESSIONCOMMENT: return exp_from_mm(value[1]);
    case SUBSCRIPTED_EXP:   return std::make_unique<SubscriptedExp>(value);
    case BREAK:             return std::make_unique<Break>();
  }

  throw std::runtime_error("Unimplemented Expression index " + std::to_string(value.index()));
}

Expression::Expression(MetaModelica::Record value)
  : _impl{exp_from_mm(value)}
{

}

Expression::Expression(const Expression &other) noexcept
  : _impl{other._impl->clone()}
{

}

Expression::Expression(const Expression::Base &base) noexcept
  : _impl{base.clone()}
{

}

Expression& Expression::operator= (const Expression &other) noexcept
{
  _impl = other._impl->clone();
  return *this;
}

void Expression::print(std::ostream &os) const noexcept
{
  _impl->print(os);
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream &os, const Expression &exp) noexcept
{
  exp.print(os);
  return os;
}

Integer::Integer(int64_t value) noexcept
  : _value{value}
{

}

Integer::Integer(MetaModelica::Record value)
  : _value{value[0].toInt()}
{

}

std::unique_ptr<Expression::Base> Integer::clone() const noexcept
{
  return std::make_unique<Integer>(*this);
}

void Integer::print(std::ostream &os) const noexcept
{
  os << _value;
}

Real::Real(std::string value) noexcept
  : _value{std::move(value)}
{

}

Real::Real(MetaModelica::Record value)
  : _value{value[0].toString()}
{

}

double Real::value() const noexcept
{
  return std::stod(_value);
}

std::unique_ptr<Expression::Base> Real::clone() const noexcept
{
  return std::make_unique<Real>(*this);
}

void Real::print(std::ostream &os) const noexcept
{
  os << _value;
}

Boolean::Boolean(bool value) noexcept
  : _value{value}
{

}

Boolean::Boolean(MetaModelica::Record value)
  : _value{value[0].toBool()}
{

}

std::unique_ptr<Expression::Base> Boolean::clone() const noexcept
{
  return std::make_unique<Boolean>(*this);
}

void Boolean::print(std::ostream &os) const noexcept
{
  os << (_value ? "true" : "false");
}

String::String(std::string value) noexcept
  : _value{std::move(value)}
{

}

String::String(MetaModelica::Record value)
  : _value{value[0].toString()}
{

}

std::unique_ptr<Expression::Base> String::clone() const noexcept
{
  return std::make_unique<String>(*this);
}

void String::print(std::ostream &os) const noexcept
{
  os << '"' << _value << '"';
}

Cref::Cref(MetaModelica::Record value)
  : _cref{value[0]}
{

}

Cref::Cref(ComponentRef cref) noexcept
  : _cref{std::move(cref)}
{

}

std::unique_ptr<Expression::Base> Cref::clone() const noexcept
{
  return std::make_unique<Cref>(*this);
}

void Cref::print(std::ostream &os) const noexcept
{
  os << _cref;
}

Binary::Binary(MetaModelica::Record value)
  : _exp1{value[0]},
    _op{value[1]},
    _exp2{value[2]}
{

}

std::unique_ptr<Expression::Base> Binary::clone() const noexcept
{
  return std::make_unique<Binary>(*this);
}

void Binary::print(std::ostream &os) const noexcept
{
  os << _exp1 << _op.spacedSymbol() << _exp2;
}

Unary::Unary(MetaModelica::Record value)
  : _op{value[0]},
    _exp{value[1]}
{

}

std::unique_ptr<Expression::Base> Unary::clone() const noexcept
{
  return std::make_unique<Unary>(*this);
}

void Unary::print(std::ostream &os) const noexcept
{
  os << _op.spacedSymbol() << _exp;
}

IfExpression::IfExpression(MetaModelica::Record value)
  : _condition{value[0]},
    _true{value[1]},
    _false{value[2]}
{
  auto branches = value[3].toList();

  if (!branches.empty()) {
    auto v = branches.mapVector<MetaModelica::Value>();

    for (auto it = v.rbegin(); it != v.rend(); ++it) {
      auto branch = it->toTuple();
      _false = IfExpression(Expression{branch[0]}, Expression{branch[1]}, std::move(_false));
    }
  }
}

IfExpression::IfExpression(Expression condition, Expression trueBranch, Expression falseBranch) noexcept
  : _condition{std::move(condition)},
    _true{std::move(trueBranch)},
    _false{std::move(falseBranch)}
{

}

std::unique_ptr<Expression::Base> IfExpression::clone() const noexcept
{
  return std::make_unique<IfExpression>(*this);
}

void IfExpression::print(std::ostream &os) const noexcept
{
  os << "if " << _condition << " then " << _true << " else " << _false;
}

Call::Call(MetaModelica::Record value)
  : _functionName{value[0]},
    _args{value[1]}
{

}

std::unique_ptr<Expression::Base> Call::clone() const noexcept
{
  return std::make_unique<Call>(*this);
}

void Call::print(std::ostream &os) const noexcept
{
  os << _functionName << '(' << _args << ')';
}

PartEvalFunction::PartEvalFunction(MetaModelica::Record value)
  : _functionName{value[0]},
    _args{value[1]}
{

}

std::unique_ptr<Expression::Base> PartEvalFunction::clone() const noexcept
{
  return std::make_unique<PartEvalFunction>(*this);
}

void PartEvalFunction::print(std::ostream &os) const noexcept
{
  os << "function " << _functionName << '(' << _args << ')';
}

Array::Array(MetaModelica::Record value)
{
  for (auto e: value[0].toList()) {
    _elements.emplace_back(e);
  }
}

Array::Array(std::vector<Expression> elements) noexcept
  : _elements(std::move(elements))
{

}

std::unique_ptr<Expression::Base> Array::clone() const noexcept
{
  return std::make_unique<Array>(*this);
}

void Array::print(std::ostream &os) const noexcept
{
  os << '{' << Util::printList(_elements) << '}';
}

Matrix::Matrix(MetaModelica::Record value)
{
  for (auto row: value[0].toList()) {
    std::vector<Expression> arr;
    for (auto e: row.toList()) {
      arr.emplace_back(e);
    }
    _matrix.emplace_back(std::move(arr));
  }
}

std::unique_ptr<Expression::Base> Matrix::clone() const noexcept
{
  return std::make_unique<Matrix>(*this);
}

void Matrix::print(std::ostream &os) const noexcept
{
  os << '[';

  bool first = true;
  for (auto &row: _matrix) {
    if (first) {
      first = false;
    } else {
      os << "; ";
    }

    os << Util::printList(row.elements());
  }
  os << ']';
}

Range::Range(MetaModelica::Record value)
  : _start{value[0]},
    _step{value[1].mapOptional<Expression>()},
    _stop{value[2]}
{

}

std::unique_ptr<Expression::Base> Range::clone() const noexcept
{
  return std::make_unique<Range>(*this);
}

void Range::print(std::ostream &os) const noexcept
{
  os << _start << ':';
  if (_step) os << *_step << ':';
  os << _stop;
}

Tuple::Tuple(MetaModelica::Record value)
{
  for (auto e: value[0].toList()) {
    _elements.emplace_back(e);
  }
}

std::unique_ptr<Expression::Base> Tuple::clone() const noexcept
{
  return std::make_unique<Tuple>(*this);
}

void Tuple::print(std::ostream &os) const noexcept
{
  os << '(';
  os << Util::printList(_elements);
  os << ')';
}

std::unique_ptr<Expression::Base> End::clone() const noexcept
{
  return std::make_unique<End>(*this);
}

void End::print(std::ostream &os) const noexcept
{
  os << "end";
}

Code::Code(MetaModelica::Record value)
{

}

std::unique_ptr<Expression::Base> Code::clone() const noexcept
{
  return std::make_unique<Code>(*this);
}

void Code::print(std::ostream &os) const noexcept
{
  os << "$CODE";
}

SubscriptedExp::SubscriptedExp(MetaModelica::Record value)
  : _exp{value[0]},
    _subscripts{value[1].mapVector<Subscript>()}
{

}

std::unique_ptr<Expression::Base> SubscriptedExp::clone() const noexcept
{
  return std::make_unique<SubscriptedExp>(*this);
}

void SubscriptedExp::print(std::ostream &os) const noexcept
{
  os << _exp << '[' << Util::printList(_subscripts) << ']';
}

std::unique_ptr<Expression::Base> Break::clone() const noexcept
{
  return std::make_unique<Break>(*this);
}

void Break::print(std::ostream &os) const noexcept
{
  os << "break";
}
