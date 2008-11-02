#ifndef INDENTATION_HPP_
#define INDENTATION_HPP_

#include <stack>
#include <string>

using namespace std ;


class indentation
{
public:
  indentation();

  void push(int element);
  int top();
  void pop();

  void indent_next(bool f);
  bool indent_next();
  void init();
  void space_before(bool f);
  bool spacebefore();

private:
  std::stack<int> m_indent;
  bool m_indent_next;
  bool m_space_before;
};


#endif
