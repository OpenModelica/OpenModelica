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

#include "InstNode.h"
#include "ComplexType.h"

using namespace OpenModelica;

constexpr int EXTENDS_TYPE = 1;
constexpr int CONNECTOR = 2;
constexpr int EXPANDABLE_CONNECTOR = 3;
constexpr int RECORD = 4;
constexpr int EXTERNAL_OBJECT = 5;

extern record_description NFComplexType_EXTENDS__TYPE__desc;
extern record_description NFComplexType_CONNECTOR__desc;
extern record_description NFComplexType_EXPANDABLE__CONNECTOR__desc;
extern record_description NFComplexType_RECORD__desc;
extern record_description NFComplexType_EXTERNAL__OBJECT__desc;

std::unique_ptr<ComplexType> ComplexType::fromNF(MetaModelica::Record value)
{
  switch (value.index()) {
    case EXTENDS_TYPE:         return std::make_unique<ExtendsComplexType>(value);
    case CONNECTOR:            return std::make_unique<ConnectorComplexType>(value);
    case EXPANDABLE_CONNECTOR: return std::make_unique<ExpandableConnectorComplexType>(value);
    case RECORD:               return std::make_unique<RecordComplexType>(value);
    case EXTERNAL_OBJECT:      return std::make_unique<ExternalObjectComplexType>(value);
  }

  return nullptr;
}

ExtendsComplexType::ExtendsComplexType(InstNode *baseClass)
  : _baseClass{baseClass}
{

}

ExtendsComplexType::ExtendsComplexType(MetaModelica::Record value)
: _baseClass{InstNode::getReference(value[0])}
{

}

std::unique_ptr<ComplexType> ExtendsComplexType::clone()
{
  return std::make_unique<ExtendsComplexType>(_baseClass);
}

MetaModelica::Value ExtendsComplexType::toNF() const
{
  return MetaModelica::Record{EXTENDS_TYPE, NFComplexType_EXTENDS__TYPE__desc, {
    _baseClass->toNF()
  }};
}

ConnectorComplexType::ConnectorComplexType(std::vector<InstNode*> potentials, std::vector<InstNode*> flows, std::vector<InstNode*> streams)
  : _potentials{std::move(potentials)}, _flows{std::move(flows)}, _streams{std::move(streams)}
{

}

ConnectorComplexType::ConnectorComplexType(MetaModelica::Record value)
  : _potentials{InstNode::getReferences(value[0])},
    _flows{InstNode::getReferences(value[1])},
    _streams{InstNode::getReferences(value[2])}
{

}

std::unique_ptr<ComplexType> ConnectorComplexType::clone()
{
  return std::make_unique<ConnectorComplexType>(_potentials, _flows, _streams);
}

MetaModelica::Value ConnectorComplexType::toNF() const
{
  return MetaModelica::Record{CONNECTOR, NFComplexType_CONNECTOR__desc, {
    MetaModelica::List{_potentials, [](auto &c) { return c->toNF(); }},
    MetaModelica::List{_flows, [](auto &c) { return c->toNF(); }},
    MetaModelica::List{_streams, [](auto &c) { return c->toNF(); }}
  }};
}

ExpandableConnectorComplexType::ExpandableConnectorComplexType(std::vector<InstNode*> potentiallyPresents,
                                                               std::vector<InstNode*> expandableConnectors)
  : _potentiallyPresents{potentiallyPresents}, _expandableConnectors{expandableConnectors}
{

}

ExpandableConnectorComplexType::ExpandableConnectorComplexType(MetaModelica::Record value)
  : _potentiallyPresents{InstNode::getReferences(value[0])},
    _expandableConnectors{InstNode::getReferences(value[1])}
{

}

std::unique_ptr<ComplexType> ExpandableConnectorComplexType::clone()
{
  return std::make_unique<ExpandableConnectorComplexType>(_potentiallyPresents, _expandableConnectors);
}

MetaModelica::Value ExpandableConnectorComplexType::toNF() const
{
  return MetaModelica::Record{EXPANDABLE_CONNECTOR, NFComplexType_EXPANDABLE__CONNECTOR__desc, {
    MetaModelica::List{_potentiallyPresents, [](auto &c) { return c->toNF(); }},
    MetaModelica::List{_expandableConnectors, [](auto &c) { return c->toNF(); }}
  }};
}

RecordComplexType::RecordComplexType(InstNode *constructor, MetaModelica::Value fields, MetaModelica::Value indexMap)
  : _constructor{constructor}, _fields{fields}, _indexMap{indexMap}
{

}

RecordComplexType::RecordComplexType(MetaModelica::Record value)
  : _constructor{InstNode::getReference(value[0])}, _fields{value[1]}, _indexMap{value[2]}
{

}

std::unique_ptr<ComplexType> RecordComplexType::clone()
{
  return std::make_unique<RecordComplexType>(_constructor, _fields, _indexMap);
}

MetaModelica::Value RecordComplexType::toNF() const
{
  return MetaModelica::Record{RECORD, NFComplexType_RECORD__desc, {
    _constructor->toNF(),
    _fields,
    _indexMap
  }};
}

ExternalObjectComplexType::ExternalObjectComplexType(InstNode *constructor, InstNode *destructor)
  : _constructor{constructor}, _destructor{destructor}
{

}

ExternalObjectComplexType::ExternalObjectComplexType(MetaModelica::Record value)
  : _constructor{InstNode::getReference(value[0])},
    _destructor{InstNode::getReference(value[1])}
{

}

std::unique_ptr<ComplexType> ExternalObjectComplexType::clone()
{
  return std::make_unique<ExternalObjectComplexType>(_constructor, _destructor);
}

MetaModelica::Value ExternalObjectComplexType::toNF() const
{
  return MetaModelica::Record{EXTERNAL_OBJECT, NFComplexType_EXTERNAL__OBJECT__desc, {
    _constructor->toNF(),
    _destructor->toNF()
  }};
}
