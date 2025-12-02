#ifndef INSTNODETYPE_H
#define INSTNODETYPE_H

#include <memory>
#include <unordered_map>

#include "MetaModelica.h"

namespace OpenModelica
{
  namespace Absyn
  {
    class Element;
  };

  class InstNode;

  class InstNodeType
  {
    public:
      //static std::unique_ptr<InstNodeType> fromAbsyn(Absyn::Element *element, InstNode *parent);

      virtual ~InstNodeType() = default;

      virtual bool isBaseClass() const { return false; }
      virtual bool isUserdefinedClass() const { return false; }
      virtual bool isRootClass() const { return false; }
      virtual bool isDerivedClass() const { return false; }
      virtual bool isTopScope() const { return false; }
      virtual bool isGeneratedInner() const { return false; }
      virtual bool isRedeclared() const { return false; }
      virtual bool isBuiltin() const { return false; }
      virtual bool hasName() const { return false; }

      virtual InstNode* parent() const { return nullptr; }
      virtual InstNode* redeclaredParent() const { return nullptr; }
      virtual InstNode* rootParent() const { return nullptr; }
      virtual InstNode* annotationScope() const { return nullptr; }
      virtual InstNode* derivedParent() const { return nullptr; }

      virtual InstNodeType* derivedType() const { return nullptr; }

      virtual Absyn::Element* definition() const { return nullptr; }

      virtual MetaModelica::Value toMetaModelica() const = 0;
  };

  // A class with no specific characteristics.
  class NormalClassType : public InstNodeType
  {
    public:
      bool isUserdefinedClass() const override { return true; }
      bool hasName() const override { return true; }

      MetaModelica::Value toMetaModelica() const override;
  };

  // A base class extended by another class.
  class BaseClassType : public InstNodeType
  {
    public:
      BaseClassType(InstNode *parent, Absyn::Element *definition)
        : _parent(parent), _definition(definition)
      {
      }

      bool isBaseClass() const override { return true; }
      bool isUserdefinedClass() const override { return true; }
      bool isBuiltin() const override;

      InstNode* parent() const override { return _parent; }
      InstNode* derivedParent() const override { return _parent; }

      Absyn::Element* definition() const override { return _definition; }

      MetaModelica::Value toMetaModelica() const override;

    private:
      InstNode *_parent;
      Absyn::Element *_definition;         // The extends clause definition.
  };

  // A short class definition.
  class DerivedClassType : public InstNodeType
  {
    public:
      DerivedClassType(std::unique_ptr<InstNodeType> ty)
        : _ty{std::move(ty)}
      {
      }

      bool isUserdefinedClass() const override { return true; }
      bool isDerivedClass() const override { return true; }

      InstNode* parent() const override { return _ty ? _ty->parent() : nullptr; }
      InstNode* rootParent() const override { return _ty ? _ty->rootParent() : nullptr; }

      InstNodeType* derivedType() const override { return _ty.get(); }

      MetaModelica::Value toMetaModelica() const override;

    private:
      std::unique_ptr<InstNodeType> _ty; // The base node type not considering that it's a derived class.
  };

  // A builtin class.
  class BuiltinClassType : public InstNodeType
  {
    public:
      bool isBuiltin() const override { return true; }
      bool hasName() const override { return true; }

      MetaModelica::Value toMetaModelica() const override;
  };

  // The unnamed class containing all the top-level classes.
  class TopScopeType : public InstNodeType
  {
    public:
      TopScopeType() = default;
      TopScopeType(std::unique_ptr<InstNode> annotationScope);

      bool isTopScope() const override { return true; }

      void setAnnotationScope(std::unique_ptr<InstNode> annotationScope) const;
      InstNode* annotationScope() const override { return _annotationScope.get(); }

      MetaModelica::Value toMetaModelica() const override;

    private:
      std::unique_ptr<InstNode> _annotationScope;
      std::unordered_map<std::string, std::unique_ptr<InstNode>> _generatedInners;
  };

  // The root of the instance tree, i.e. the class that the instantiation starts from.
  class RootClassType : public InstNodeType
  {
    public:
      RootClassType(InstNode *parent)
        : _parent{parent}
      {
      }

      bool isRootClass() const override { return true; }
      bool hasName() const override { return true; }

      InstNode* parent() const override { return _parent; }
      InstNode* rootParent() const override { return _parent; }

      MetaModelica::Value toMetaModelica() const override;

    private:
      InstNode *_parent;
  };

  // A normal component.
  class NormalComponentType : public InstNodeType
  {
    public:
      MetaModelica::Value toMetaModelica() const override;
  };

  // A redeclared component.
  class RedeclaredComponentType : public InstNodeType
  {
    public:
      RedeclaredComponentType(InstNode *parent)
        : _parent{parent}
      {
      }

      bool isRedeclared() const override { return true; }

      InstNode* parent() const override { return _parent; }
      InstNode* redeclaredParent() const override { return _parent; }

      MetaModelica::Value toMetaModelica() const override;

    private:
      InstNode *_parent;
  };

  // A redeclared class.
  class RedeclaredClassType : public InstNodeType
  {
    public:
      RedeclaredClassType(InstNode *parent, std::unique_ptr<InstNodeType> ty)
        : _parent{parent}, _ty{std::move(ty)}
      {
      }

      bool isUserdefinedClass() const override { return _ty->isUserdefinedClass(); }
      bool isRedeclared() const override { return true; }
      bool hasName() const override { return true; }

      InstNode* parent() const override { return _parent; }

      MetaModelica::Value toMetaModelica() const override;

    private:
      InstNode *_parent;
      std::unique_ptr<InstNodeType> _ty;
  };

  // A generated inner element due to a missing outer.
  class GeneratedInnerType : public InstNodeType
  {
    public:
      bool isGeneratedInner() const override { return true; }

      MetaModelica::Value toMetaModelica() const override;
  };

  // An implicit scope that's ignored when e.g. constructing a scope path.
  // Not used by implicit scope nodes since those have no node type (they're
  // implicitly implicit), but by e.g. the annotation scope.
  class ImplicitScopeType : public InstNodeType
  {
    public:
      MetaModelica::Value toMetaModelica() const override;
  };
}

#endif /* INSTNODETYPE_H */
