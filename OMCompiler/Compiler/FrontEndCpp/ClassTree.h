#ifndef CLASSTREE_H
#define CLASSTREE_H

#include <string>
#include <vector>
#include <unordered_map>

#include "Absyn/AbsynFwd.h"

namespace OpenModelica
{
  class InstNode;

  class ClassTree
  {
    public:
      enum class State
      {
        Partial,      // Allows lookup of local classes and imported elements.
        Expanded,     // Lookup table has all elements, but elements have now
                      // yet been added to the arrays.
        Instantiated, // Allows lookup of both local and inherited elements.
        Flat
      };

    public:
      //ClassTree(const std::vector<Absyn::Element*> &elements, bool isClassExtends, InstNode *parent);
      ClassTree(const Absyn::ClassParts &definition, bool isClassExtends, InstNode *parent);
      //ClassTree(const std::vector<Absyn::Enumeration::EnumLiteral> &literals, const Type &enumType,
      //          const InstNode &enumClass);
      //ClassTree(const std::vector<InstNode> fields, const InstNode &out);
      ~ClassTree();

      void add(Absyn::Class &cls);
      void add(Absyn::Component &comp);
      void add(Absyn::Extends &ext);
      void add(Absyn::Import &imp);

      void expand();
      void instantiate();

    private:
      enum class EntryType
      {
        Class,
        Component,
        Import
      };

      struct Entry
      {
        EntryType type;
        size_t index;

        Entry offset(size_t classOffset, size_t componentOffset) const;
      };

      enum class DuplicateType
      {
        Duplicate,
        Redeclare,
        Entry
      };

      struct Duplicate
      {
        Duplicate(DuplicateType type, Entry entry);
        Duplicate(Entry kept, Entry duplicate);

        DuplicateType type;
        Entry entry;
        InstNode *node = nullptr;
        std::vector<Duplicate> children;
      };

      using LookupTable = std::unordered_map<std::string, Entry>;
      using DuplicateTable = std::unordered_map<std::string, Duplicate>;

    private:
      void addLocalName(const std::string &name, Entry entry, const InstNode &node);
      void addInheritedName(const std::string &name, Entry entry);
      void countInheritedElements(size_t &classCount, size_t &componentCount) const;
      void expandExtends(const InstNode &extends, size_t classOffset, size_t componentOffset);

    private:
      InstNode *_parent;
      State _state;
      LookupTable _table;
      std::vector<std::unique_ptr<InstNode>> _classes;
      std::vector<std::unique_ptr<InstNode>> _components;
      std::vector<int> _localComponents;
      std::vector<std::unique_ptr<InstNode>> _extends;
      //std::vector<Import> _imports;
      DuplicateTable _duplicates;
  };
}

#endif /* CLASSTREE_H */
