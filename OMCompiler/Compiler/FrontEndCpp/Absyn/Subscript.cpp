#include <ostream>

#include "Util.h"
#include "Expression.h"
#include "Subscript.h"

using namespace OpenModelica::Absyn;

Subscript::Subscript(MetaModelica::Record value)
  : _subscript{value.index() == 1 ? std::make_optional<Expression>(value[0]) : std::nullopt}
{

}

Subscript::~Subscript() noexcept = default;

const std::optional<Expression>& Subscript::expression() const noexcept
{
  return _subscript;
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream& os, const Subscript &subscript)
{
  auto &e = subscript.expression();

  if (e) {
    os << *e;
  } else {
    os << ':';
  }

  return os;
}

std::ostream& OpenModelica::Absyn::operator<< (std::ostream& os, const std::vector<Subscript> &subscripts)
{
  if (!subscripts.empty()) {
    os << '[' << Util::printList(subscripts) << ']';
  }

  return os;
}
