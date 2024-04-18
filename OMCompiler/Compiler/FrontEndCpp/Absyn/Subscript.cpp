#include <ostream>

#include "Util.h"
#include "Expression.h"
#include "Subscript.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

constexpr int NOSUB = 0;
constexpr int SUBSCRIPT = 1;

extern record_description Absyn_Subscript_NOSUB__desc;
extern record_description Absyn_Subscript_SUBSCRIPT__desc;

Subscript::Subscript(MetaModelica::Record value)
  : _subscript{value.index() == SUBSCRIPT ? std::make_optional<Expression>(value[0]) : std::nullopt}
{

}

Subscript::~Subscript() noexcept = default;

MetaModelica::Value Subscript::toAbsyn() const noexcept
{
  if (_subscript) {
    return MetaModelica::Record(SUBSCRIPT, Absyn_Subscript_SUBSCRIPT__desc, {_subscript->toAbsyn()});
  }

  return MetaModelica::Record(NOSUB, Absyn_Subscript_NOSUB__desc);
}

MetaModelica::Value Subscript::toAbsynList(const std::vector<Subscript> &subs) noexcept
{
  return MetaModelica::List(subs, [](const auto &s) { return s.toAbsyn(); });
}

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
