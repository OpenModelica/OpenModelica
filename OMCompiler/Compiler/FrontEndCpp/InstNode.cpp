#include "InstNode.h"

using namespace OpenModelica;

extern record_description NFInstNode_InstNode_EMPTY__NODE__desc;

const MetaModelica::Value OpenModelica::InstNode::emptyMMNode =
  MetaModelica::Record(InstNode::EMPTY_NODE, NFInstNode_InstNode_EMPTY__NODE__desc, {}, true);
