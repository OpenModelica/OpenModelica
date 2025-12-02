#ifndef ABSYN_ELEMENT_H
#define ABSYN_ELEMENT_H

#include <memory>
#include <iosfwd>

#include "MetaModelica.h"
#include "SourceInfo.h"
#include "Prefixes.h"

namespace OpenModelica::Absyn
{
  struct ElementVisitor;

  class Element
  {
    public:
      static constexpr int IMPORT = 0;
      static constexpr int EXTENDS = 1;
      static constexpr int CLASS = 2;
      static constexpr int COMPONENT = 3;
      static constexpr int DEFINEUNIT = 4;

    public:
      static std::unique_ptr<Element> fromSCode(MetaModelica::Record value);
      virtual ~Element();

      virtual std::unique_ptr<Element> clone() const noexcept = 0;
      friend void swap(Element &first, Element &second) noexcept;
      virtual MetaModelica::Value toSCode() const noexcept = 0;

      virtual void apply(ElementVisitor &visitor) = 0;

      const SourceInfo& info() const noexcept { return _info; }

      virtual void print(std::ostream &os, Each each = Each()) const noexcept = 0;

    protected:
      Element(SourceInfo info);

    private:
      SourceInfo _info;
  };

  std::ostream& operator<< (std::ostream &os, const Element &element) noexcept;
}

#endif /* ABSYN_ELEMENT_H */
