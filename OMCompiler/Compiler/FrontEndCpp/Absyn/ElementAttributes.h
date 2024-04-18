#ifndef ABSYN_ELEMENTATTRIBUTES_H
#define ABSYN_ELEMENTATTRIBUTES_H

#include <vector>
#include <iosfwd>

#include "MetaModelica.h"
#include "Prefixes.h"
#include "Subscript.h"

namespace OpenModelica::Absyn
{
  class ElementAttributes
  {
    public:
      explicit ElementAttributes(MetaModelica::Record value);

      MetaModelica::Value toSCode() const noexcept;

      const std::vector<Subscript>& arrayDims() const noexcept { return _arrayDims; }
      ConnectorType connectorType() const noexcept { return _connectorType; }
      Parallelism parallelism() const noexcept { return _parallelism; }
      Variability variability() const noexcept { return _variability; }
      Direction direction() const noexcept { return _direction; }
      Field field() const noexcept { return _field; }

    private:
      std::vector<Subscript> _arrayDims;
      ConnectorType _connectorType;
      Parallelism _parallelism;
      Variability _variability;
      Direction _direction;
      Field _field;
  };

  std::ostream& operator<< (std::ostream &os, const ElementAttributes &attrs) noexcept;
}

#endif /* ABSYN_ELEMENTATTRIBUTES_H */
