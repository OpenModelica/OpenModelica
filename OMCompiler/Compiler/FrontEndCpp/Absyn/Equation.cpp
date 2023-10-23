#include <cassert>
#include <ostream>

#include "Util.h"
#include "Equation.h"

constexpr int EQ_IF = 0;
constexpr int EQ_EQUALS = 1;
constexpr int EQ_PDE = 2;
constexpr int EQ_CONNECT = 3;
constexpr int EQ_FOR = 4;
constexpr int EQ_WHEN = 5;
constexpr int EQ_ASSERT = 6;
constexpr int EQ_TERMINATE = 7;
constexpr int EQ_REINIT = 8;
constexpr int EQ_NORETCALL = 9;

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

Equation::Base::Base(Comment comment, SourceInfo info)
  : _comment{std::move(comment)}, _info{std::move(info)}
{

}

std::unique_ptr<Equation::Base> eq_from_mm(MetaModelica::Record value)
{
  switch (value.index()) {
    case EQ_IF:        return std::make_unique<IfEquation>(value);
    case EQ_EQUALS:    return std::make_unique<EqualityEquation>(value);
    case EQ_CONNECT:   return std::make_unique<ConnectEquation>(value);
    case EQ_FOR:       return std::make_unique<ForEquation>(value);
    case EQ_WHEN:      return std::make_unique<WhenEquation>(value);
    case EQ_ASSERT:    return std::make_unique<AssertEquation>(value);
    case EQ_TERMINATE: return std::make_unique<TerminateEquation>(value);
    case EQ_REINIT:    return std::make_unique<ReinitEquation>(value);
    case EQ_NORETCALL: return std::make_unique<CallEquation>(value);
  }

  throw std::runtime_error("Unimplemented Equation index " + std::to_string(value.index()));
}

Equation::Equation(MetaModelica::Record value)
  : _impl{eq_from_mm(value)}
{

}

Equation::Equation(const Equation &other) noexcept
  : _impl{other._impl->clone()}
{

}

Equation& Equation::operator= (const Equation &other) noexcept
{
  _impl = other._impl->clone();
  return *this;
}

void Equation::print(std::ostream &os, std::string_view indent) const noexcept
{
  os << indent;
  _impl->print(os);
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream &os, const Equation &eq) noexcept
{
  eq.print(os);
  return os;
}

EqualityEquation::EqualityEquation(MetaModelica::Record value)
  : Base(Comment{value[2]}, SourceInfo{value[3]}),
    _lhs{value[0]},
    _rhs{value[1]}
{

}

std::unique_ptr<Equation::Base> EqualityEquation::clone() const noexcept
{
  return std::make_unique<EqualityEquation>(*this);
}

void EqualityEquation::print(std::ostream &os) const noexcept
{
  os << _lhs << " = " << _rhs << _comment;
}

IfEquation::IfEquation(MetaModelica::Record value)
  : Base(Comment{value[3]}, SourceInfo{value[4]})
{
  auto conditions = value[0].toList();
  auto branches = value[1].toList();
  assert(conditions.size() == branches.size());

  auto branch_iter = branches.begin();
  for (auto cond: conditions) {
    _branches.emplace_back(cond, branch_iter->mapVector<Equation>());
    ++branch_iter;
  }

  _else = value[2].mapVector<Equation>();
}

std::unique_ptr<Equation::Base> IfEquation::clone() const noexcept
{
  return std::make_unique<IfEquation>(*this);
}

void IfEquation::print(std::ostream &os) const noexcept
{
  bool first = true;

  for (auto &branch: _branches) {
    if (first) {
      first = false;
    } else {
      os << "else";
    }

    os << "if " << branch.first << " then\n";
    for (auto &eq: branch.second) os << "  " << eq << ";\n";
  }

  if (!_else.empty()) {
    os << "else\n";
    for (auto &eq: _else) os << "  " << eq << ";\n";
  }

  os << "end if";
}

ConnectEquation::ConnectEquation(MetaModelica::Record value)
  : Base(Comment{value[2]}, SourceInfo{value[3]}),
    _lhs{Cref{ComponentRef{value[0]}}},
    _rhs{Cref{ComponentRef{value[1]}}}
{

}

std::unique_ptr<Equation::Base> ConnectEquation::clone() const noexcept
{
  return std::make_unique<ConnectEquation>(*this);
}

void ConnectEquation::print(std::ostream &os) const noexcept
{
  os << "connect(" << _lhs << ", " << _rhs << ')';
}

ForEquation::ForEquation(MetaModelica::Record value)
  : Base(Comment{value[3]}, SourceInfo{value[4]}),
    _iterator{value[0].toString()},
    _range{value[1].mapOptional<Expression>()},
    _body{value[2].mapVector<Equation>()}
{

}

std::unique_ptr<Equation::Base> ForEquation::clone() const noexcept
{
  return std::make_unique<ForEquation>(*this);
}

void ForEquation::print(std::ostream &os) const noexcept
{
  os << "for " << _iterator;
  if (_range) os << " in " << *_range;
  os << " loop\n";

  for (auto &eq: _body) os << "  " << eq << ";\n";

  os << "end for";
}

WhenEquation::WhenEquation(MetaModelica::Record value)
  : Base(Comment{value[3]}, SourceInfo{value[4]})
{
  _branches.emplace_back(value[0], value[1].mapVector<Equation>());

  for (auto e: value[2].toList()) {
    auto branch = e.toTuple();
    _branches.emplace_back(branch[0], branch[1].mapVector<Equation>());
  }
}

std::unique_ptr<Equation::Base> WhenEquation::clone() const noexcept
{
  return std::make_unique<WhenEquation>(*this);
}

void WhenEquation::print(std::ostream &os) const noexcept
{
  bool first = true;

  for (auto &branch: _branches) {
    if (first) {
      first = false;
    } else {
      os << "else";
    }

    os << "when " << branch.first << " then\n";
    for (auto &eq: branch.second) os << eq << ";\n";
  }

  os << "end when";
}

AssertEquation::AssertEquation(MetaModelica::Record value)
  : Base(Comment{value[3]}, SourceInfo{value[4]}),
    _condition{value[0]},
    _message{value[1]},
    _level{value[2]}
{

}

std::unique_ptr<Equation::Base> AssertEquation::clone() const noexcept
{
  return std::make_unique<AssertEquation>(*this);
}

void AssertEquation::print(std::ostream &os) const noexcept
{
  os << "assert(" << _condition << ", " << _message << ", " << _level << ')';
}

TerminateEquation::TerminateEquation(MetaModelica::Record value)
  : Base(Comment{value[1]}, SourceInfo{value[2]}),
    _message{value[0]}
{

}

std::unique_ptr<Equation::Base> TerminateEquation::clone() const noexcept
{
  return std::make_unique<TerminateEquation>(*this);
}

void TerminateEquation::print(std::ostream &os) const noexcept
{
  os << "terminate(" << _message << ')';
}

ReinitEquation::ReinitEquation(MetaModelica::Record value)
  : Base(Comment{value[2]}, SourceInfo{value[3]}),
    _variable{value[0]},
    _exp{value[1]}
{

}

std::unique_ptr<Equation::Base> ReinitEquation::clone() const noexcept
{
  return std::make_unique<ReinitEquation>(*this);
}

void ReinitEquation::print(std::ostream &os) const noexcept
{
  os << "reinit(" << _variable << ", " << _exp << ')';
}

CallEquation::CallEquation(MetaModelica::Record value)
  : Base(Comment{value[1]}, SourceInfo{value[2]}),
    _callExp{value[0]}
{

}

std::unique_ptr<Equation::Base> CallEquation::clone() const noexcept
{
  return std::make_unique<CallEquation>(*this);
}

void CallEquation::print(std::ostream &os) const noexcept
{
  os << _callExp;
}
