#include "InstNode.h"

using namespace OpenModelica;

extern record_description NFInstNode_InstNode_EMPTY__NODE__desc;

MetaModelica::Value InstNode::emptyMMNode()
{
  static auto val = MetaModelica::Record{InstNode::EMPTY_NODE, NFInstNode_InstNode_EMPTY__NODE__desc, {}};
  return val;
}
