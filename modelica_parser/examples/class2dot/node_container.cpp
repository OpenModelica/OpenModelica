#include "node_container.hpp"

node_container::node_container() : m_index(0)
{
}

node_container::~node_container()
{
}

void node_container::push(std::string name)
{
  m_index++;
  m_nodes.push(std::make_pair(m_index,name));
}

void node_container::pop()
{
  m_nodes.pop();
}

bool node_container::empty()
{
  return m_nodes.empty();
}

int node_container::index()
{
  return m_nodes.top().first;
}

int node_container::peek_index()
{
  return m_index+1;
}
std::string node_container::name()
{
  return m_nodes.top().second;
}
