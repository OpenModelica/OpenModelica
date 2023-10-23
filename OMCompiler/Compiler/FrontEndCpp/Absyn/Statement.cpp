#include <cassert>
#include <ostream>

#include "Util.h"
#include "Statement.h"

constexpr int ALG_ASSIGN = 0;
constexpr int ALG_IF = 1;
constexpr int ALG_FOR = 2;
constexpr int ALG_PARFOR = 3;
constexpr int ALG_WHILE = 4;
constexpr int ALG_WHEN_A = 5;
constexpr int ALG_ASSERT = 6;
constexpr int ALG_TERMINATE = 7;
constexpr int ALG_REINIT = 8;
constexpr int ALG_NORETCALL = 9;
constexpr int ALG_RETURN = 10;
constexpr int ALG_BREAK = 11;

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

Statement::Base::Base(Comment comment, SourceInfo info)
  : _comment{std::move(comment)}, _info{std::move(info)}
{

}

std::unique_ptr<Statement::Base> stmt_from_mm(MetaModelica::Record value)
{
  switch (value.index()) {
    case ALG_ASSIGN:    return std::make_unique<AssignmentStatement>(value);
    case ALG_IF:        return std::make_unique<IfStatement>(value);
    case ALG_FOR:       return std::make_unique<ForStatement>(value, false);
    case ALG_PARFOR:    return std::make_unique<ForStatement>(value, true);
    case ALG_WHILE:     return std::make_unique<WhileStatement>(value);
    case ALG_WHEN_A:    return std::make_unique<WhenStatement>(value);
    case ALG_ASSERT:    return std::make_unique<AssertStatement>(value);
    case ALG_TERMINATE: return std::make_unique<TerminateStatement>(value);
    case ALG_REINIT:    return std::make_unique<ReinitStatement>(value);
    case ALG_NORETCALL: return std::make_unique<CallStatement>(value);
    case ALG_RETURN:    return std::make_unique<ReturnStatement>(value);
    case ALG_BREAK:     return std::make_unique<BreakStatement>(value);
  }

  throw std::runtime_error("Unimplemented Statement index " + std::to_string(value.index()));
}

Statement::Statement(MetaModelica::Record value)
  : _impl{stmt_from_mm(value)}
{

}

Statement::Statement(const Statement &other) noexcept
  : _impl{other._impl->clone()}
{

}

Statement& Statement::operator= (const Statement &other) noexcept
{
  _impl = other._impl->clone();
  return *this;
}

void Statement::print(std::ostream &os, std::string_view indent) const noexcept
{
  os << indent;
  _impl->print(os);
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream &os, const Statement &stmt) noexcept
{
  stmt.print(os);
  return os;
}

AssignmentStatement::AssignmentStatement(MetaModelica::Record value)
  : Base(Comment{value[2]}, SourceInfo{value[3]}),
    _lhs{value[0]},
    _rhs{value[1]}
{

}

std::unique_ptr<Statement::Base> AssignmentStatement::clone() const noexcept
{
  return std::make_unique<AssignmentStatement>(*this);
}

void AssignmentStatement::print(std::ostream &os) const noexcept
{
  os << _lhs << " := " << _rhs;
}

IfStatement::IfStatement(MetaModelica::Record value)
  : Base(Comment{value[4]}, SourceInfo{value[5]})
{
  _branches.emplace_back(value[0], value[1].mapVector<Statement>());

  for (auto e: value[2].toList()) {
    auto branch = e.toTuple();
    _branches.emplace_back(branch[0], branch[1].mapVector<Statement>());
  }

  _else = value[3].mapVector<Statement>();
}

std::unique_ptr<Statement::Base> IfStatement::clone() const noexcept
{
  return std::make_unique<IfStatement>(*this);
}

void IfStatement::print(std::ostream &os) const noexcept
{
  bool first = true;

  for (auto &branch: _branches) {
    if (first) {
      first = false;
    } else {
      os << "else";
    }

    os << "if " << branch.first << " then\n";
    for (auto &stmt: branch.second) os << "  " << stmt << ";\n";
  }

  if (!_else.empty()) {
    os << "else\n";
    for (auto &stmt: _else) os << "  " << stmt << ";\n";
  }

  os << "end if";
}

ForStatement::ForStatement(MetaModelica::Record value, bool parallel)
  : Base(Comment{value[3]}, SourceInfo{value[4]}),
    _iterator{value[0].toString()},
    _range{value[1].mapOptional<Expression>()},
    _body{value[2].mapVector<Statement>()},
    _parallel{parallel}
{

}

std::unique_ptr<Statement::Base> ForStatement::clone() const noexcept
{
  return std::make_unique<ForStatement>(*this);
}

void ForStatement::print(std::ostream &os) const noexcept
{
  os << "for " << _iterator;
  if (_range) os << " in " << *_range;
  os << " loop\n";

  for (auto &eq: _body) os << "  " << eq << ";\n";

  os << "end for";
}

WhileStatement::WhileStatement(MetaModelica::Record value)
  : Base(Comment{value[2]}, SourceInfo{value[3]}),
    _condition{value[0]},
    _body{value[1].mapVector<Statement>()}
{

}

std::unique_ptr<Statement::Base> WhileStatement::clone() const noexcept
{
  return std::make_unique<WhileStatement>(*this);
}

void WhileStatement::print(std::ostream &os) const noexcept
{
  os << "while " << _condition << " loop\n";

  for (auto &s: _body) {
    s.print(os, "  ");
    os << ";\n";
  }

  os << "end while";
}

WhenStatement::WhenStatement(MetaModelica::Record value)
  : Base(Comment{value[1]}, SourceInfo{value[2]})
{
  for (auto e: value[0].toList()) {
    auto branch = e.toTuple();
    _branches.emplace_back(branch[0], branch[1].mapVector<Statement>());
  }
}

std::unique_ptr<Statement::Base> WhenStatement::clone() const noexcept
{
  return std::make_unique<WhenStatement>(*this);
}

void WhenStatement::print(std::ostream &os) const noexcept
{
  bool first = true;

  for (auto &branch: _branches) {
    if (first) {
      first = false;
    } else {
      os << "else";
    }

    os << "when " << branch.first << " then\n";
    for (auto &stmt: branch.second) os << stmt << ";\n";
  }

  os << "end when";
}

AssertStatement::AssertStatement(MetaModelica::Record value)
  : Base(Comment{value[3]}, SourceInfo{value[4]}),
    _condition{value[0]},
    _message{value[1]},
    _level{value[2]}
{

}

std::unique_ptr<Statement::Base> AssertStatement::clone() const noexcept
{
  return std::make_unique<AssertStatement>(*this);
}

void AssertStatement::print(std::ostream &os) const noexcept
{
  os << "assert(" << _condition << ", " << _message << ", " << _level << ')';
}

TerminateStatement::TerminateStatement(MetaModelica::Record value)
  : Base(Comment{value[1]}, SourceInfo{value[2]}),
    _message{value[0]}
{

}

std::unique_ptr<Statement::Base> TerminateStatement::clone() const noexcept
{
  return std::make_unique<TerminateStatement>(*this);
}

void TerminateStatement::print(std::ostream &os) const noexcept
{
  os << "terminate(" << _message << ')';
}

ReinitStatement::ReinitStatement(MetaModelica::Record value)
  : Base(Comment{value[2]}, SourceInfo{value[3]}),
    _variable{value[0]},
    _exp{value[1]}
{

}

std::unique_ptr<Statement::Base> ReinitStatement::clone() const noexcept
{
  return std::make_unique<ReinitStatement>(*this);
}

void ReinitStatement::print(std::ostream &os) const noexcept
{
  os << "reinit(" << _variable << ", " << _exp << ')';
}

CallStatement::CallStatement(MetaModelica::Record value)
  : Base(Comment{value[1]}, SourceInfo{value[2]}),
    _callExp{value[0]}
{

}

std::unique_ptr<Statement::Base> CallStatement::clone() const noexcept
{
  return std::make_unique<CallStatement>(*this);
}

void CallStatement::print(std::ostream &os) const noexcept
{
  os << _callExp;
}

ReturnStatement::ReturnStatement(MetaModelica::Record value)
  : Base(Comment{value[0]}, SourceInfo{value[1]})
{

}

std::unique_ptr<Statement::Base> ReturnStatement::clone() const noexcept
{
  return std::make_unique<ReturnStatement>(*this);
}

void ReturnStatement::print(std::ostream &os) const noexcept
{
  os << "return";
}

BreakStatement::BreakStatement(MetaModelica::Record value)
  : Base(Comment{value[0]}, SourceInfo{value[1]})
{

}

std::unique_ptr<Statement::Base> BreakStatement::clone() const noexcept
{
  return std::make_unique<BreakStatement>(*this);
}

void BreakStatement::print(std::ostream &os) const noexcept
{
  os << "break";
}
