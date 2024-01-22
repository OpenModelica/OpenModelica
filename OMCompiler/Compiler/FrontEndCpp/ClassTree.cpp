#include "Absyn/ElementVisitor.h"
#include "ClassNode.h"
#include "Class.h"
#include "ClassTree.h"

using namespace OpenModelica;

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
