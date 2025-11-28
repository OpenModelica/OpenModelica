#include "MMAvlTree.h"
#include "Absyn/ElementVisitor.h"
#include "ClassNode.h"
#include "Class.h"
#include "Import.h"
#include "ClassTree.h"

using namespace OpenModelica;

extern record_description NFClassTree_ClassTree_PARTIAL__TREE__desc;
extern record_description NFClassTree_ClassTree_EXPANDED__TREE__desc;
extern record_description NFClassTree_ClassTree_INSTANTIATED__TREE__desc;
extern record_description NFClassTree_ClassTree_FLAT__TREE__desc;
extern record_description NFClassTree_ClassTree_EMPTY__TREE__desc;

constexpr int PARTIAL_TREE = 0;
constexpr int EXPANDED_TREE = 1;
constexpr int INSTANTIATED_TREE = 2;
constexpr int FLAT_TREE = 3;
constexpr int EMPTY_TREE = 4;

extern record_description NFLookupTree_Entry_CLASS__desc;
extern record_description NFLookupTree_Entry_COMPONENT__desc;
extern record_description NFLookupTree_Entry_IMPORT__desc;

constexpr int CLASS_ENTRY = 0;
constexpr int COMPONENT_ENTRY = 1;
constexpr int IMPORT_ENTRY = 2;

int compareClassTreeKeys(MetaModelica::Value key1, MetaModelica::Value key2)
{
  return key1.toStringView().compare(key2.toStringView());
}

DEFINE_MM_AVL_TREE_TYPE(LookupTree, NFLookupTree_Tree, compareClassTreeKeys);
DEFINE_MM_AVL_TREE_TYPE(DuplicateTree, NFDuplicateTree_Tree, compareClassTreeKeys);

ClassTree::Entry::operator MetaModelica::Value() const noexcept
{
  int idx = 0;
  record_description *desc = nullptr;

  switch (type) {
    case EntryType::Class:
      idx = CLASS_ENTRY;
      desc = &NFLookupTree_Entry_CLASS__desc;
      break;
    case EntryType::Component:
      idx = COMPONENT_ENTRY;
      desc = &NFLookupTree_Entry_COMPONENT__desc;
      break;
    case EntryType::Import:
      idx = IMPORT_ENTRY;
      desc = &NFLookupTree_Entry_IMPORT__desc;
      break;
  }

  return MetaModelica::Record(idx, *desc, {MetaModelica::Value(static_cast<int64_t>(index + 1))});
}

ClassTree::Entry ClassTree::Entry::offset(size_t classOffset, size_t componentOffset) const
{
  auto idx = index;

  switch (type) {
    case EntryType::Class:     idx += classOffset;     break;
    case EntryType::Component: idx += componentOffset; break;
    default: break;
  }

  return {type, idx};
}

ClassTree::Duplicate::Duplicate(DuplicateType type, Entry entry)
  : type{type}, entry{entry}
{

}

ClassTree::Duplicate::Duplicate(Entry kept, Entry duplicate)
  : type{DuplicateType::Duplicate}, entry{kept}
{
  children.emplace_back(DuplicateType::Entry, duplicate);
}

ClassTree::ClassTree(const Absyn::ClassParts &definition, bool isClassExtends, InstNode *parent)
  : _parent{parent}, _state{State::Partial}
{
  // If the class is a class extends, reserve space for the extends.
  if (isClassExtends) {
    _extends.emplace_back(nullptr);
    //_components.emplace_back(std::make_unique<InstNode>(1));
  }

  // Use a visitor to add the elements to the tree. Imports are not added
  // immediately but saved for later.
  struct InitTreeVisitor : public Absyn::ElementVisitor
  {
    InitTreeVisitor(ClassTree &tree) : tree{tree} { }

    void visit(Absyn::Class &cls) override      { tree.add(cls); }
    void visit(Absyn::Component &comp) override { tree.add(comp); }
    void visit(Absyn::Extends &ext) override    { tree.add(ext); }
    void visit(Absyn::Import &imp) override     { imports.push_back(&imp); }

    ClassTree &tree;
    std::vector<Absyn::Import*> imports;
  };

  InitTreeVisitor visitor(*this);

  auto end = definition.elementsEnd();
  for (auto it = definition.elementsBegin(); it != end; ++it) {
    it->apply(visitor);
  }
  //for (auto &elem: elements) {
  //  elem->apply(visitor);
  //}

  // Add all the imports that were collected.
  // TODO:
  //for (auto &imp: visitor.imports) {
  //   If unqualified:
  //     Import.instQualified(...)
  //   else
  //     add Import.UNRESOLVED_IMPORT()
  //}
}

ClassTree::~ClassTree() = default;

void ClassTree::add(Absyn::Class &cls)
{
  auto cls_node = std::make_unique<ClassNode>(&cls, _parent);
  addLocalName(cls.name(), Entry{EntryType::Class, _classes.size()}, *cls_node);
  _classes.push_back(std::move(cls_node));

  // If the class is an element redeclare, add an entry in the duplicate tree so
  // we can check later that it actually redeclares something.
  //if (cls.isElementRedeclare() || cls.isClassExtends()) {
  //  TODO: dups := NFDuplicateTree.add(dups, e.name, NFDuplicateTree.newRedeclare(lentry));
  //}
}

void ClassTree::add(Absyn::Component &/*comp*/)
{
  // A component, add it to the component array but don't add an entry in the
  // lookup tree. We need to preserve the component's order, but won't know
  // their actual indices until we've expanded the extends. We don't really need
  // to be able to look up components until after that happens, so we add them
  // to the lookup tree later instead.

  //_components.push_back(std::make_unique<InstNode>(&comp));
}

void ClassTree::add(Absyn::Extends &/*ext*/)
{
  // An extends clause, add it to the list of extends, and also add a reference
  // in the component array so we can preserve the order of components.

  //_components.push_back(std::make_unique<InstNode>(_extends.size()));
  //_extends.push_back(std::make_unique<InstNode>(&ext, _parent));
}

void ClassTree::add(Absyn::Import &/*imp*/)
{
  // TODO
}

// This function adds all local and inherited class and component names to the
// lookup tree. Note that only their names are added, the elements themselves
// are added to their respective arrays by the instantiation function below.
void ClassTree::expand()
{
  size_t cls_idx = _classes.size();
  size_t comp_idx = 0;
  std::vector<size_t> ext_cls_idxs, ext_comp_idxs;

  // Since we now know the names of both local and inherited components we can
  // add them to the lookup tree. First we add the local components' names, to
  // be able to catch duplicate local elements easier.
  for (auto &c: _components)
  {
    auto ref_index = c->refIndex();

    if (ref_index < 0) {
      // A component. Add its name to the lookup tree.
      auto entry = Entry{EntryType::Component, comp_idx};
      addLocalName(c->name(), entry, *c);

      // If the component is an element redeclare, add an entry in the duplicate
      // tree so we can check later that it actually redeclares something.
      if (c->isRedeclare()) {
        // TODO: dups := DuplicateTree.add(dups, c->name(), DuplicateTree.newRedeclare(entry));
      }

      ++comp_idx;
    } else {
      // An extends node. Save the index so we know where to start adding components later,
      // and increment the index with the number of components it contains.
      ext_cls_idxs.emplace_back(cls_idx - 1);
      ext_comp_idxs.emplace_back(comp_idx - 1);
      _extends[ref_index]->getClass()->classTree()->countInheritedElements(cls_idx, comp_idx);
    }
  }

  // Checking whether inherited duplicate elements are identical is hard to do
  // correctly at this point. So we just detect them and store their indices in
  // the class tree for now, and check them for identicalness later on instead.
  // TODO: dups_ptr := Mutable.create(dups);

  // Add the names of inherited components and classes to the lookup tree.
  for (size_t i = 0; i < _extends.size(); ++i) {
    // Use the component indices we saved earlier to add the required elements
    // from the extends nodes to the lookup tree.
    expandExtends(*_extends[i], ext_cls_idxs[i], ext_comp_idxs[i] /*, dups_ptr*/);
  }

  _state = State::Expanded;
}

// This function instantiates an expanded tree. clsNode is the class to be
// instantiated, while instance is the instance the clsNode belongs to. instance
// is usually the component which has the class as its type. In some cases the
// class itself is the instance, like for the top-level model that's being
// instantiated or packages used for lookup. Because the actual instance of
// clsNode will then be the cloned clsNode created by this function it's not
// possible to send in the correct instance in that case, so setting the
// instance to a nullptr is interpreted by this function to mean that the
// instance should be set to the cloned clsNode.
void ClassTree::instantiate()
{

}

MetaModelica::Record ClassTree::toNF() const
{
  LookupTree ltree;
  for (auto &e: _table) {
    ltree.add(MetaModelica::Value{e.first}, e.second);
  }

  switch (_state) {
    case State::Partial:
      return MetaModelica::Record{PARTIAL_TREE, NFClassTree_ClassTree_PARTIAL__TREE__desc, {
        ltree,
        MetaModelica::Array{_classes, [](auto &c) { return c->toMetaModelica(); }},
        MetaModelica::Array{_components, [](auto &c) { return c->toMetaModelica(); }},
        MetaModelica::Array{_extends, [](auto &e) { return e->toMetaModelica(); }},
        MetaModelica::Array{_imports, [](auto &i) { return i.toNF(); }},
        DuplicateTree{}
      }};

    case State::Expanded:
      return MetaModelica::Record{EXPANDED_TREE, NFClassTree_ClassTree_EXPANDED__TREE__desc, {
        ltree,
        MetaModelica::Array{_classes, [](auto &c) { return c->toMetaModelica(); }},
        MetaModelica::Array{_components, [](auto &c) { return c->toMetaModelica(); }},
        MetaModelica::Array{_extends, [](auto &e) { return e->toMetaModelica(); }},
        MetaModelica::Array{_imports, [](auto &i) { return i.toNF(); }},
        DuplicateTree{},
      }};

    case State::Instantiated:
      return MetaModelica::Record{INSTANTIATED_TREE, NFClassTree_ClassTree_INSTANTIATED__TREE__desc, {
        ltree,
        MetaModelica::Array{_classes, [](auto &c) { return MetaModelica::Mutable{c->toMetaModelica()}; }},
        MetaModelica::Array{_components, [](auto &c) { return MetaModelica::Mutable{c->toMetaModelica()}; }},
        MetaModelica::List{_localComponents, [](auto &c) { return MetaModelica::Value{static_cast<int64_t>(c)}; }},
        MetaModelica::Array{_extends, [](auto &e) { return e->toMetaModelica(); }},
        MetaModelica::Array{_imports, [](auto &i) { return i.toNF(); }},
        DuplicateTree{}
      }};

    case State::Flat:
      return MetaModelica::Record{FLAT_TREE, NFClassTree_ClassTree_FLAT__TREE__desc, {
        ltree,
        MetaModelica::Array{_classes, [](auto &c) { return c->toMetaModelica(); }},
        MetaModelica::Array{_components, [](auto &c) { return c->toMetaModelica(); }},
        MetaModelica::Array{_imports, [](auto &i) { return i.toNF(); }},
        DuplicateTree{}
      }};

    default:
      return MetaModelica::Record{EMPTY_TREE, NFClassTree_ClassTree_EMPTY__TREE__desc, {}};
  }
}

void ClassTree::addLocalName(const std::string &name, Entry entry, const InstNode &/*node*/)
{
  auto [it, inserted] = _table.try_emplace(name, entry);

  if (!inserted) {
    if (it->second.type == EntryType::Import) {
      // Local elements overwrite imported elements with the same name.
      it->second = entry;
    } else {
      // Otherwise we have two local elements with the same name, which is an error.
      throw std::runtime_error("Name conflict");
    }
  }
}

void ClassTree::addInheritedName(const std::string &name, Entry entry)
{
  auto [it, inserted] = _table.try_emplace(name, entry);

  if (!inserted) {
    if (it->second.type == EntryType::Import) {
      // Overwrite the existing entry if it's an import. This happens when a
      // class both imports and inherits the same name.
      it->second = entry;
    } else {
      throw std::runtime_error("Inherited name conflict");
    }
  }
}

void ClassTree::countInheritedElements(size_t &classCount, size_t &componentCount) const
{
  if (_state <= State::Expanded) {
    // The component array contains placeholders for extends, which need to be
    // subtracted to get the proper component count.
    componentCount += _components.size() - _extends.size();
    classCount += _classes.size();

    for (auto &ext: _extends) {
      ext->getClass()->classTree()->countInheritedElements(classCount, componentCount);
    }
  } else {
    classCount += _classes.size();
    componentCount += _components.size();
  }
}

void ClassTree::expandExtends(const InstNode &extends, size_t classOffset, size_t componentOffset)
{
  // The extends node's lookup tree should contain both local and inherited
  // entries at this point, so all that's needed here is to apply the
  // class/component offset to each entry and add them to the lookup tree.
  auto ext_tree = extends.getClass()->classTree();

  // TODO: Copy entries from the extends node's duplicate tree if there are any.
  //if not NFDuplicateTree.isEmpty(ext_dups) then
  //  // Offset the entries so they're correct for the inheriting class tree.
  //  dups := NFDuplicateTree.map(ext_dups,
  //    function offsetDuplicates(classOffset = classOffset, componentOffset = componentOffset));
  //  // Join the two duplicate trees together.
  //  dups := NFDuplicateTree.join(Mutable.access(duplicates), dups, joinDuplicates);
  //  Mutable.update(duplicates, dups);
  //end if;

  // Copy entries from the extends' lookup tree, except imports which are not inherited.
  for (auto &entry: ext_tree->_table) {
    if (entry.second.type != EntryType::Import) {
      addInheritedName(entry.first, entry.second.offset(classOffset, componentOffset));
    }
  }
}
