#include "indentation.hpp"

indentation::indentation() : m_indent_next(false),m_space_before(false)
{
}

void indentation::push(int element)
{
  m_indent.push(element);
}

int indentation::top()
{
  if (!m_indent.empty())
    return m_indent.top();
  else
    return 0;
}

void indentation::pop()
{
  if (m_indent.size() > 1)
    m_indent.pop();
}

void indentation::indent_next(bool f)
{
  m_indent_next = f;
}  

bool indentation::indent_next()
{
  return m_indent_next;
}

void indentation::init()
{
  m_indent.push(0);
}

void indentation::space_before(bool f)
{
  m_space_before = f;
}

bool indentation::space_before()
{
  return m_space_before;
}
