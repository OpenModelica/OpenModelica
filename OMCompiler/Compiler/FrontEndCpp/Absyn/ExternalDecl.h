#ifndef ABSYN_EXTERNALDECL_H
#define ABSYN_EXTERNALDECL_H

#include <string>
#include <optional>
#include <vector>
#include <memory>
#include <iosfwd>

#include "MetaModelica.h"
#include "Annotation.h"
#include "ComponentRef.h"

namespace OpenModelica::Absyn
{
  class Expression;

  class ExternalDecl
  {
    public:
      ExternalDecl(MetaModelica::Record value);
      ~ExternalDecl();

      MetaModelica::Value toSCode() const noexcept;

      const std::string& functionName() const noexcept { return _functionName; }
      const std::string& language() const noexcept { return _language; }
      const std::optional<ComponentRef>& outputParam() const noexcept { return _outputParam; }
      const std::vector<Expression>& args() const noexcept { return _args; }
      const Annotation& annotation() const noexcept { return _annotation; }

    private:
      std::string _functionName;
      std::string _language;
      std::optional<ComponentRef> _outputParam;
      std::vector<Expression> _args;
      Annotation _annotation;
  };

  std::ostream& operator<< (std::ostream& os, const ExternalDecl &externalDecl) noexcept;
}

#endif /* ABSYN_EXTERNALDECL_H */
