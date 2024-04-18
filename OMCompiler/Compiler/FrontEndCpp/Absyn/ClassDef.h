#ifndef ABSYN_CLASSDEF_H
#define ABSYN_CLASSDEF_H

#include <memory>
#include <vector>
#include <iosfwd>

#include "MetaModelica.h"
#include "TypeSpec.h"
#include "Element.h"
#include "Modifier.h"
#include "ElementAttributes.h"
#include "Comment.h"

namespace OpenModelica::Absyn
{
  class Class;
  class ExternalDecl;
  class Equation;
  class Algorithm;

  class ClassDef
  {
    public:
      class Base
      {
        public:
          virtual ~Base() = default;

          virtual std::unique_ptr<Base> clone() const noexcept = 0;
          virtual MetaModelica::Value toSCode() const noexcept = 0;
          virtual void print(std::ostream &os, const Class &parent) const noexcept = 0;
          virtual void printBody(std::ostream &os) const noexcept = 0;
      };

    public:
      ClassDef(MetaModelica::Record value);
      ClassDef(const ClassDef &other) noexcept;
      ClassDef(ClassDef &&other) = default;

      ClassDef& operator= (const ClassDef &other) noexcept;
      ClassDef& operator= (ClassDef &&other) = default;

      MetaModelica::Value toSCode() const noexcept;

      void print(std::ostream &os, const Class &parent) const noexcept;
      void printBody(std::ostream &os) const noexcept;

    private:
      std::unique_ptr<Base> _impl;
  };

  class Parts : public ClassDef::Base
  {
    public:
      Parts(MetaModelica::Record value);
      Parts(const Parts &other) noexcept;
      Parts(Parts &&other) = default;
      ~Parts();

      Parts& operator= (Parts other) noexcept;
      Parts& operator= (Parts &&other) = default;
      void swap(Parts &parts) noexcept;

      std::unique_ptr<ClassDef::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os, const Class &parent) const noexcept override;
      void printBody(std::ostream &os) const noexcept override;

    private:
      std::vector<Element> _elements;
      std::vector<Equation> _equations;
      std::vector<Equation> _initialEquations;
      std::vector<Algorithm> _algorithms;
      std::vector<Algorithm> _initialAlgorithms;
      //std::vector<ConstraintSection> _constraints;
      //std::vector<NamedArg> _classAttributes;
      std::unique_ptr<ExternalDecl> _externalDecl;
  };

  class ClassExtends : public ClassDef::Base
  {
    public:
      ClassExtends(MetaModelica::Record value);

      std::unique_ptr<ClassDef::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os, const Class &parent) const noexcept override;
      void printBody(std::ostream &os) const noexcept override;

    private:
      Modifier _modifier;
      ClassDef _composition;
  };

  class Derived : public ClassDef::Base
  {
    public:
      Derived(MetaModelica::Record value);

      std::unique_ptr<ClassDef::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os, const Class &parent) const noexcept override;
      void printBody(std::ostream &os) const noexcept override;

    private:
      TypeSpec _typeSpec;
      Modifier _modifier;
      ElementAttributes _attributes;
  };

  class Enumeration : public ClassDef::Base
  {
    public:
      using EnumLiteral = std::pair<std::string, Comment>;

    public:
      Enumeration(MetaModelica::Record value);

      std::unique_ptr<ClassDef::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os, const Class &parent) const noexcept override;
      void printBody(std::ostream &os) const noexcept override;

    private:
      std::vector<EnumLiteral> _literals;
  };

  class Overload : public ClassDef::Base
  {
    public:
      Overload(MetaModelica::Record value);

      std::unique_ptr<ClassDef::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os, const Class &parent) const noexcept override;
      void printBody(std::ostream &os) const noexcept override;

    private:
      std::vector<Path> _paths;
  };

  class PartialDerivative : public ClassDef::Base
  {
    public:
      PartialDerivative(MetaModelica::Record value);

      std::unique_ptr<ClassDef::Base> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void print(std::ostream &os, const Class &parent) const noexcept override;
      void printBody(std::ostream &os) const noexcept override;

    private:
      Path _functionPath;
      std::vector<std::string> _derivedVariables;
  };
}

#endif /* ABSYN_CLASSDEF_H */
