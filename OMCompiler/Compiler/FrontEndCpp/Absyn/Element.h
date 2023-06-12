#ifndef ABSYN_ELEMENT_H
#define ABSYN_ELEMENT_H

#include <memory>
#include <iosfwd>

#include "MetaModelica.h"
#include "SourceInfo.h"
#include "Prefixes.h"

namespace OpenModelica::Absyn
{
  class Element
  {
    public:
      class Base
      {
        public:
          Base(SourceInfo info);
          virtual ~Base() = default;

          const SourceInfo& info() const noexcept { return _info; }

          virtual std::unique_ptr<Base> clone() const noexcept = 0;
          virtual void print(std::ostream &os, Each each = Each()) const noexcept = 0;

        protected:
          SourceInfo _info;
      };

    public:
      Element(MetaModelica::Record value);
      Element(const Element &element) noexcept;
      Element(Element &&other) = default;

      Element& operator= (const Element &other) noexcept;
      Element& operator= (Element &&other) = default;

      const SourceInfo& info() const noexcept { return _impl->info(); }

      void print(std::ostream &os, Each each = Each()) const noexcept;

    private:
      std::unique_ptr<Base> _impl;

  };

  std::ostream& operator<< (std::ostream &os, const Element &element) noexcept;
}

#endif /* ABSYN_ELEMENT_H */
