#ifndef NODE_CONTAINER_HPP_
#define NODE_CONTAINER_HPP_

#include <stack>
#include <string>

class node_container
{
public:
  node_container();
  virtual ~node_container();
  
  void push(std::string name);
  void pop();
  bool empty();

  int index();
  int peek_index();
  std::string name();
  
private:
  std::stack<std::pair<int,std::string> > m_nodes;
  int m_index;
};
#endif
