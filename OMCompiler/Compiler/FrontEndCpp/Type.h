#ifndef TYPE_H
#define TYPE_H

#include <string>
#include <vector>
#include <optional>
#include <memory>
//#include "span.hpp"

#include "Dimension.h"
#include "Path.h"

namespace OpenModelica
{
  class InstNode;

  class TypeData
  {
    public:
      virtual ~TypeData() = default;

      virtual std::unique_ptr<TypeData> clone() const = 0;

      virtual bool isScalar() const;
      virtual bool isScalarBuiltin() const;
      virtual bool isArray() const;
      virtual bool isBasic() const;
      virtual bool isNumeric() const;
      virtual bool isConnector() const;
      virtual bool isExpandableConnector() const;
      virtual bool isExternalObject() const;
      virtual bool isRecord() const;
      virtual bool isPolymorphic() const;
      virtual bool isPolymorphicNamed(std::string_view name) const;
  };

  class Type
  {
    public:
      enum Kind
      {
        // Builtin types
        Integer,
        Real,
        String,
        Boolean,
        Enumeration,
        Clock,
        // Special types without extra data
        NoRetCall,
        Unknown,
        Any,
        // Special types with extra data
        Tuple,
        Complex,
        Function,
        MetaBoxed,
        Polymorphic,
        Subscripted,
        ConditionalArray
      };

    public:
      Type(Kind kind);
      Type(const Type &other);
      Type(Type &&other);
      virtual ~Type() = default;

      Type& operator= (Type other);
      Type& operator= (Type &&other);
      friend void swap(Type &first, Type &second) noexcept;

      bool isInteger() const;
      bool isReal() const;
      bool isBoolean() const;
      bool isString() const;
      bool isClock() const;
      bool isEnumeration() const;
      bool isScalar() const;
      bool isBasic() const;
      bool isBasicNumeric() const;
      bool isNumeric() const;
      bool isScalarBuiltin() const;
      bool isDiscrete() const;
      bool isArray() const;
      bool isConditionalArray() const;
      bool isVector() const;
      bool isMatrix() const;
      bool isSquareMatrix() const;
      bool isEmptyArray() const;
      bool isSingleElementArray() const;
      bool isComplex() const;
      bool isConnector() const;
      bool isExpandableConnector() const;
      bool isExternalObject() const;
      bool isRecord() const;
      bool isTuple() const;
      bool isUnknown() const;
      bool isKnown() const;
      bool isPolymorphic() const;
      bool isPolymorphicNamed(std::string_view name) const;

      Type elementType();
      //tcb::span<const Dimension> arrayDims() const;

      std::unique_ptr<Type> unliftArray(size_t n = 1) const;

      std::string typenameString() const;

    private:
      Kind _kind;
      std::vector<Dimension> _dims;
      std::unique_ptr<TypeData> _data;
  };

  void swap(Type &first, Type &second);

  class EnumerationTypeData : public TypeData
  {
    public:
      std::unique_ptr<TypeData> clone() const override;

    private:
      Path _typePath;
      std::vector<std::string> _literals;
  };

  class TupleTypeData : public TypeData
  {
    public:
      std::unique_ptr<TypeData> clone() const override;

    private:
      std::vector<Type> _types;
      std::vector<std::string> _names;
  };

  class ComplexTypeData : public TypeData
  {
    public:
      std::unique_ptr<TypeData> clone() const override;

    private:
      InstNode* _cls;
      // ComplexType _complexTy;
  };

  class FunctionTypeData : public TypeData
  {
    public:
      enum Kind
      {
        FunctionalParameter, // Function parameter of function type.
        FunctionReference,   // Function name used to reference a function.
        FunctionalVariable   // A variable that contains a function reference.
      };

      std::unique_ptr<TypeData> clone() const override;

      bool isBasic() const override;
      bool isScalarBuiltin() const override;

    private:
      //Function* _fn;
      Kind _kind;
  };

  class PolymorphicTypeData : public TypeData
  {
    public:
      std::unique_ptr<TypeData> clone() const override;

      bool isPolymorphic() const override { return true; }
      bool isPolymorphicNamed(std::string_view name) const override { return _name == name; }

    private:
      std::string _name;
  };

  class SubscriptedTypeData : public TypeData
  {
    public:
      std::unique_ptr<TypeData> clone() const override;

    private:
      std::string _name;
      Type _ty;
      std::vector<Type> _subs;
      Type _subscriptedTy;
  };

  class ConditionalArrayData : public TypeData
  {
    public:
      std::unique_ptr<TypeData> clone() const override;

      bool isScalar() const override { return false; }
      bool isArray() const override { return true; }
      bool isNumeric() const override { return _trueType.isNumeric(); }

    private:
      Type _trueType;
      Type _falseType;
      std::optional<bool> _matchedBranch;
  };
}

#endif /* TYPE_H */
