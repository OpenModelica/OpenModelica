#include <string>
#include <vector>
#include <iostream>
#include <chrono>
#include <utility>

#include "MetaModelica.h"
#include "Absyn/Element.h"
#include "Absyn/Class.h"
#include "ClassNode.h"
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

  // Mark annotations as builtin.


  // Add the annotation scope to the top scopes node type.
  top_node->setNodeType(std::make_unique<TopScopeType>(std::move(ann_node)));
  return nullptr;
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
