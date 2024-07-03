#include <string>
#include <vector>
#include <iostream>
#include <chrono>
#include <utility>

#include "MetaModelica.h"
#include "Absyn/Element.h"
#include "Inst.h"

using namespace OpenModelica;

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

void* Inst_test(void *scode)
{
  MetaModelica::Value value(scode);
  std::vector<Absyn::Element> elements;

  {
    Timer t{"Creating elements"};
    for (auto e: value.toList()) {
      elements.emplace_back(e);
      //std::cout << elements.back() << ';' << std::endl;
    }
  }

  MetaModelica::List lst;

  {
    Timer t{"Generating SCode"};
    for (auto it = elements.rbegin(); it != elements.rend(); ++it) {
      lst.cons(it->toSCode());
    }
  }

  return lst.data();
}
