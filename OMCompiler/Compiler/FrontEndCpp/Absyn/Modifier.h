#ifndef ABSYN_MODIFIER_H
#define ABSYN_MODIFIER_H

#include <vector>
#include <utility>
#include <string>
#include <memory>
#include <optional>
#include <string_view>
#include <iosfwd>

#include "MetaModelica.h"
#include "Prefixes.h"
#include "Element.h"
#include "Expression.h"
#include "SourceInfo.h"

namespace OpenModelica::Absyn
{
  class Modifier
  {
    public:
      using SubMod = std::pair<std::string, Modifier>;

      class Base
      {
public:
          virtual ~Base() = default;

          virtual MetaModelica::Value toSCode() const noexcept = 0;

          virtual bool isFinal() const noexcept = 0;
          virtual bool isEach() const noexcept = 0;

          virtual const Expression* binding() const noexcept { return nullptr; }
          virtual const Modifier::SubMod* lookupSubMod(std::string_view /*name*/) const noexcept { return nullptr; }

          virtual std::unique_ptr<Base> clone() const noexcept = 0;
          virtual void print(std::ostream &os, std::string_view name) const noexcept = 0;
      };

    public:
      Modifier() = default;
      Modifier(MetaModelica::Record value);
      Modifier(Final finalPrefix, Each eachPrefix, std::vector<SubMod> subMods,
        std::optional<Expression> binding, const SourceInfo &info) noexcept;
      Modifier(Final finalPrefix, Each eachPrefix, std::unique_ptr<Element> element) noexcept;
      Modifier(const Modifier &other) noexcept;
      Modifier(Modifier &&other) = default;

      Modifier& operator= (const Modifier &other) noexcept;
      Modifier& operator= (Modifier &&other) = default;

      MetaModelica::Value toSCode() const noexcept;

      bool isEmpty() const noexcept;
      bool isFinal() const noexcept;
      bool isEach() const noexcept;
      const SourceInfo& info() const noexcept;

      const Expression* binding() const noexcept;
      //bool hasBooleanNamed(std::string_view name) const;

      void print(std::ostream &os, std::string_view name = "") const noexcept;

    private:
      std::unique_ptr<Base> _value;
  };

  std::ostream& operator<< (std::ostream &os, const Modifier &modifier) noexcept;

  class BindingModifier : public Modifier::Base
  {
    public:
      BindingModifier(MetaModelica::Record value);
      BindingModifier(Final finalPrefix, Each eachPrefix, std::vector<Modifier::SubMod> subMods,
          std::optional<Expression> binding, const SourceInfo &info) noexcept;

      MetaModelica::Value toSCode() const noexcept override;

      bool isFinal() const noexcept override { return _final.isFinal(); }
      bool isEach() const noexcept override { return _each.isEach(); }

      const Expression* binding() const noexcept override { return _binding ? &*_binding : nullptr; }
      const Modifier::SubMod* lookupSubMod(std::string_view name) const noexcept override;

      std::unique_ptr<Base> clone() const noexcept override;
      void print(std::ostream &os, std::string_view name) const noexcept override;

    private:
      Final _final;
      Each _each;
      std::vector<Modifier::SubMod> _subMods;
      std::optional<Expression> _binding;
      std::optional<std::string> _comment;
      SourceInfo _info;
  };

  class RedeclareModifier : public Modifier::Base
  {
    public:
      RedeclareModifier(MetaModelica::Record value);
      RedeclareModifier(Final isFinal, Each isEach, std::unique_ptr<Element> element) noexcept;
      RedeclareModifier(const RedeclareModifier &other) noexcept;
      RedeclareModifier(RedeclareModifier &&other) noexcept = default;

      MetaModelica::Value toSCode() const noexcept override;

      bool isFinal() const noexcept override { return _final.isFinal(); }
      bool isEach() const noexcept override { return _each.isEach(); }

      const Element& redeclareElement() const noexcept { return *_element; }

      std::unique_ptr<Base> clone() const noexcept override;
      void print(std::ostream &os, std::string_view name) const noexcept override;

    private:
      Final _final;
      Each _each;
      std::unique_ptr<Element> _element;
  };
}

#endif /* ABSYN_MODIFIER_H */
