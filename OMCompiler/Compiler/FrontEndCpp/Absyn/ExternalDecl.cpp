/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include <ostream>

#include "Util.h"
#include "Expression.h"
#include "ExternalDecl.h"
#include "Subscript.h"

using namespace OpenModelica;
using namespace OpenModelica::Absyn;

extern record_description SCode_ExternalDecl_EXTERNALDECL__desc;

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

MetaModelica::Value ExternalDecl::toSCode() const noexcept
{
  return MetaModelica::Record(0, SCode_ExternalDecl_EXTERNALDECL__desc, {
    _functionName.empty() ? MetaModelica::Option() : MetaModelica::Option(MetaModelica::Value(_functionName)),
    _language.empty() ? MetaModelica::Option() : MetaModelica::Option(MetaModelica::Value(_language)),
    MetaModelica::Option(_outputParam, [](const auto &o) { return o.toAbsyn(); }),
    MetaModelica::List(_args, [](const auto &a) { return a.toAbsyn(); }),
    _annotation.toSCodeOpt()
  });
}

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
