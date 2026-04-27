/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "NameNode.h"

using namespace OpenModelica;

constexpr int NAME_INDEX = 0;

extern record_description NFInstNode_InstNode_NAME__NODE__desc;

NameNode::NameNode(MetaModelica::Record value)
  : _name{value[NAME_INDEX].toString()}
{

}

NameNode::NameNode(std::string name)
  : _name{std::move(name)}
{

}

NameNode::~NameNode() = default;

std::unique_ptr<InstNode> NameNode::clone() const
{
  return std::make_unique<NameNode>(*this);
}

const std::string& NameNode::name() const noexcept
{
  return _name;
}

MetaModelica::Value NameNode::toNF() const
{
  return MetaModelica::Record{InstNode::NAME_NODE, NFInstNode_InstNode_NAME__NODE__desc, {
    MetaModelica::Value{_name}
  }};
}

