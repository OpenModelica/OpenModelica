#include <string>
#include <vector>
#include <iostream>
#include <chrono>
#include <utility>

#include "MetaModelica.h"
#include "Absyn/Element.h"
#include "Absyn/Class.h"
#include "ClassNode.h"
#include "Class.h"
#include "Inst.h"

using namespace OpenModelica;

void* Inst_test(void *scode);

class Timer
{
  using clock = std::chrono::steady_clock;

  public:
    Timer(std::string name)
      : _start{clock::now()},
        _name{std::move(name)}
    {
    }

    ~Timer()
    {
      auto end = clock::now();
      auto diff = std::chrono::duration<double>(end - _start);
      auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(diff).count();
      std::cout << _name << ": " << ms << "ms" << std::endl;
    }

  private:
    clock::time_point _start;
    std::string _name;
};

void* Inst_makeTopNode(void *program, void *annotationProgram)
{
  // Create an Absyn class for the top scope to put the elements in.
  auto top_elements = MetaModelica::List(program).mapVector(
    [] (auto e) { return Absyn::Element::fromSCode(e); }
  );

  // if Flags.getConfigBool(Flags.BASE_MODELICA) then
  //   top_elements := NFBuiltinFuncs.BASE_MODELICA_POSITIVE_MAX_SIMPLE :: top_elements;
  // end if;

  // Create a Class for the top scope with all the elements.
  auto top_package = Absyn::Class("<top>", Absyn::ElementPrefixes{}, Encapsulated{false},
                               Partial{false}, Restriction::Package(),
                               std::make_unique<Absyn::ClassParts>(std::move(top_elements)));

  // Make an InstNode for the top scope, to use as the parent of the top level elements.
  auto top_node = std::make_unique<ClassNode>(&top_package, nullptr);

  // Create a node for the builtin annotation classes. These should only be
  // accessible in annotations, so they're stored in a separate scope stored in
  // the node type for the top scope.
  auto ann_elements = MetaModelica::List(annotationProgram).mapVector(
    [] (auto e) { return Absyn::Element::fromSCode(e); }
  );
  auto ann_package = Absyn::Class("<annotations>", Absyn::ElementPrefixes{}, Encapsulated{true},
                                  Partial{false}, Restriction::Package(),
                                  std::make_unique<Absyn::ClassParts>(std::move(ann_elements)));

  auto ann_node = std::make_unique<ClassNode>(&ann_package, top_node.get(), std::make_unique<ImplicitScopeType>());

  // TODO:
  // expand(ann_node, NFInstContext.NO_CONTEXT);

  // TODO: Mark annotations as builtin.
  // cls := InstNode.getClass(ann_node);
  // elems := Class.classTree(cls);
  // ClassTree.mapClasses(elems, markBuiltinTypeNodes);
  // cls := Class.setClassTree(elems, cls);
  // ann_node := InstNode.updateClass(cls, ann_node);

  // Add the annotation scope to the top scopes node type.
  top_node->setNodeType(std::make_unique<TopScopeType>(std::move(ann_node)));

  // Create a new class from the elements.
  top_node->partialInst();

  // TODO: The class needs to be expanded to allow lookup in it. The top scope will
  // only contain classes, so we can do this instead of the whole expandClass.
  // top_node->initExpandedClass();

  // TODO: Set the correct InstNodeType for classes with builtin annotation.
  // This could also be done when creating InstNodes, but only top-level
  // classes should have this annotation anyway.
  // elems := Class.classTree(cls);
  // ClassTree.mapClasses(elems, markBuiltinTypeNodesByAnnotation);

  // TODO: ModelicaBuiltin has a dummy declaration of Clock to make sure no one
  // can declare another Clock class in the top scope, here we replace it with
  // the actual Clock node (which can't be defined in regular Modelica).
  // ClassTree.replaceClass(NFBuiltin.CLOCK_NODE, elems);

  return top_node->toMetaModelica().data();
}

void* Inst_test(void *scode)
{
  MetaModelica::Value value(scode);
  std::vector<std::unique_ptr<Absyn::Element>> elements;

  {
    Timer t{"Creating elements"};
    for (auto e: value.toList()) {
      elements.emplace_back(Absyn::Element::fromSCode(e));
      std::cout << *elements.back() << ';' << std::endl;
    }
  }

  MetaModelica::List lst;

  {
    Timer t{"Generating SCode"};
    for (auto it = elements.rbegin(); it != elements.rend(); ++it) {
      lst.cons((*it)->toSCode());
    }
  }

  return lst.data();
}
