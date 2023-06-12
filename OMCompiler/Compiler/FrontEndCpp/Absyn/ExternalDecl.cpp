#include <ostream>

#include "Util.h"
#include "Expression.h"
#include "ExternalDecl.h"
#include "Subscript.h"

using namespace OpenModelica::Absyn;

ExternalDecl::ExternalDecl(MetaModelica::Record value)
  : _functionName{value[0].toOptional<std::string>().value_or("")},
    _language{value[1].toOptional<std::string>().value_or("")},
    _outputParam{value[2].mapOptional<ComponentRef>()},
    _annotation{value[4].mapOptionalOrDefault<Annotation>()}
{
  for (auto arg: value[3].toList()) {
    _args.emplace_back(arg);
  }
}

ExternalDecl::~ExternalDecl() = default;

std::ostream& OpenModelica::Absyn::operator<< (std::ostream& os, const ExternalDecl &externalDecl) noexcept
{
  os << "external";
  if (!externalDecl.language().empty()) os << ' ' << '"' << externalDecl.language() << '"';
  if (externalDecl.outputParam()) os << ' ' << *externalDecl.outputParam() << " =";
  if (!externalDecl.functionName().empty()) {
    os << ' ' << externalDecl.functionName() << '(' << Util::printList(externalDecl.args()) << ')';
  }
  externalDecl.annotation().print(os, " ");
  return os;
}
