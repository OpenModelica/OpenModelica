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
#include "Util/IndirectForwardIterator.h"

namespace OpenModelica::Absyn
{
  class Class;
  class ExternalDecl;
  class Equation;
  class Algorithm;
  struct ClassDefVisitor;

  class ClassDef
  {
    public:
      static std::unique_ptr<ClassDef> fromSCode(MetaModelica::Record value);
      virtual ~ClassDef();

      virtual std::unique_ptr<ClassDef> clone() const noexcept = 0;
      virtual MetaModelica::Value toSCode() const noexcept = 0;

      virtual void apply(ClassDefVisitor &visitor) const = 0;

      virtual void print(std::ostream &os, const Class &parent) const noexcept = 0;
      virtual void printBody(std::ostream &os) const noexcept = 0;

    protected:
      ClassDef() = default;
      ClassDef(const ClassDef &other) = default;
      ClassDef(ClassDef &&other) = default;
      ClassDef& operator= (const ClassDef &other) = default;
      ClassDef& operator= (ClassDef &&other) = default;
  };

  class ClassParts : public ClassDef
  {
    public:
      using ElementList = std::vector<std::unique_ptr<Element>>;
      using ElementIterator = Util::IndirectForwardIterator<ElementList::iterator>;
      using ElementConstIterator = Util::IndirectForwardIterator<ElementList::const_iterator>;

    public:
      ClassParts();
      ClassParts(std::vector<std::unique_ptr<Element>> elements);
      ClassParts(MetaModelica::Record value);
      ClassParts(const ClassParts &other) noexcept;
      ClassParts(ClassParts &&other) = default;
      ~ClassParts();

      ClassParts& operator= (ClassParts other) noexcept;
      ClassParts& operator= (ClassParts &&other) = default;
      friend void swap(ClassParts &first, ClassParts &second) noexcept;

      std::unique_ptr<ClassDef> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void apply(ClassDefVisitor &visitor) const override;
      void print(std::ostream &os, const Class &parent) const noexcept override;
      void printBody(std::ostream &os) const noexcept override;

      ElementIterator elementsBegin();
      ElementConstIterator elementsBegin() const;
      ElementIterator elementsEnd();
      ElementConstIterator elementsEnd() const;

    private:
      std::vector<std::unique_ptr<Element>> _elements;
      std::vector<Equation> _equations;
      std::vector<Equation> _initialEquations;
      std::vector<Algorithm> _algorithms;
      std::vector<Algorithm> _initialAlgorithms;
      //std::vector<ConstraintSection> _constraints;
      //std::vector<NamedArg> _classAttributes;
      std::unique_ptr<ExternalDecl> _externalDecl;
  };

  class ClassExtends : public ClassDef
  {
    public:
      ClassExtends(MetaModelica::Record value);
      ClassExtends(const ClassExtends &other) noexcept;
      ClassExtends(ClassExtends &&other) = default;
      ~ClassExtends();

      ClassExtends& operator= (ClassExtends other) noexcept;
      ClassExtends& operator= (ClassExtends &&other) = default;
      friend void swap(ClassExtends &first, ClassExtends &second) noexcept;

      std::unique_ptr<ClassDef> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void apply(ClassDefVisitor &visitor) const override;
      void print(std::ostream &os, const Class &parent) const noexcept override;
      void printBody(std::ostream &os) const noexcept override;

    private:
      Modifier _modifier;
      std::unique_ptr<ClassDef> _composition; // TODO: Inherit ClassParts instead?
  };

  class Derived : public ClassDef
  {
    public:
      Derived(MetaModelica::Record value);

      std::unique_ptr<ClassDef> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void apply(ClassDefVisitor &visitor) const override;
      void print(std::ostream &os, const Class &parent) const noexcept override;
      void printBody(std::ostream &os) const noexcept override;

    private:
      TypeSpec _typeSpec;
      Modifier _modifier;
      ElementAttributes _attributes;
  };

  class Enumeration : public ClassDef
  {
    public:
      using EnumLiteral = std::pair<std::string, Comment>;

    public:
      Enumeration(MetaModelica::Record value);

      std::unique_ptr<ClassDef> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void apply(ClassDefVisitor &visitor) const override;
      void print(std::ostream &os, const Class &parent) const noexcept override;
      void printBody(std::ostream &os) const noexcept override;

    private:
      std::vector<EnumLiteral> _literals;
  };

  class Overload : public ClassDef
  {
    public:
      Overload(MetaModelica::Record value);

      std::unique_ptr<ClassDef> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void apply(ClassDefVisitor &visitor) const override;
      void print(std::ostream &os, const Class &parent) const noexcept override;
      void printBody(std::ostream &os) const noexcept override;

    private:
      std::vector<Path> _paths;
  };

  class PartialDerivative : public ClassDef
  {
    public:
      PartialDerivative(MetaModelica::Record value);

      std::unique_ptr<ClassDef> clone() const noexcept override;
      MetaModelica::Value toSCode() const noexcept override;
      void apply(ClassDefVisitor &visitor) const override;
      void print(std::ostream &os, const Class &parent) const noexcept override;
      void printBody(std::ostream &os) const noexcept override;

    private:
      Path _functionPath;
      std::vector<std::string> _derivedVariables;
  };

  struct ClassDefVisitor
  {
    virtual void visit(const ClassDef &) {};
    virtual void visit(const ClassParts &def)         { visit(static_cast<const ClassDef&>(def)); }
    virtual void visit(const ClassExtends &def)       { visit(static_cast<const ClassDef&>(def)); }
    virtual void visit(const Derived &def)            { visit(static_cast<const ClassDef&>(def)); }
    virtual void visit(const Enumeration &def)        { visit(static_cast<const ClassDef&>(def)); }
    virtual void visit(const Overload &def)           { visit(static_cast<const ClassDef&>(def)); }
    virtual void visit(const PartialDerivative &def)  { visit(static_cast<const ClassDef&>(def)); }
  };
}

#endif /* ABSYN_CLASSDEF_H */
