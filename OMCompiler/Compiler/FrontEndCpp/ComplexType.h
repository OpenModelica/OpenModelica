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

#ifndef COMPLEXTYPE_H
#define COMPLEXTYPE_H

#include <memory>
#include <vector>

#include "MetaModelica.h"

namespace OpenModelica
{
  class InstNode;

  class ComplexType
  {
    public:
      virtual ~ComplexType() = default;

      virtual std::unique_ptr<ComplexType> clone() = 0;

      virtual MetaModelica::Value toNF() const = 0;

      static std::unique_ptr<ComplexType> fromNF(MetaModelica::Record value);
  };

  class ExtendsComplexType : public ComplexType
  {
    public:
      ExtendsComplexType(InstNode *baseClass);
      ExtendsComplexType(MetaModelica::Record value);

      std::unique_ptr<ComplexType> clone() override;

      MetaModelica::Value toNF() const override;

    private:
      InstNode *_baseClass;
  };

  class ConnectorComplexType : public ComplexType
  {
    public:
      ConnectorComplexType(std::vector<InstNode*> potentials, std::vector<InstNode*> flows, std::vector<InstNode*> streams);
      ConnectorComplexType(MetaModelica::Record value);

      std::unique_ptr<ComplexType> clone() override;

      MetaModelica::Value toNF() const override;

    private:
      std::vector<InstNode*> _potentials;
      std::vector<InstNode*> _flows;
      std::vector<InstNode*> _streams;
  };

  class ExpandableConnectorComplexType : public ComplexType
  {
    public:
      ExpandableConnectorComplexType(std::vector<InstNode*> potentiallyPresents, std::vector<InstNode*> expandableConnectors);
      ExpandableConnectorComplexType(MetaModelica::Record value);

      std::unique_ptr<ComplexType> clone() override;

      MetaModelica::Value toNF() const override;

    private:
      std::vector<InstNode*> _potentiallyPresents;
      std::vector<InstNode*> _expandableConnectors;
  };

  class RecordComplexType : public ComplexType
  {
    public:
      RecordComplexType(InstNode *constructor, MetaModelica::Value fields, MetaModelica::Value indexMap);
      RecordComplexType(MetaModelica::Record value);

      std::unique_ptr<ComplexType> clone() override;

      MetaModelica::Value toNF() const override;

    private:
      InstNode *_constructor;
      //std::vector<Record.Field> _fields;
      MetaModelica::Value _fields;
      //std::unordered_map<std::string, int> _indexMap;
      MetaModelica::Value _indexMap;
  };

  class ExternalObjectComplexType : public ComplexType
  {
    public:
      ExternalObjectComplexType(InstNode *constructor, InstNode *destructor);
      ExternalObjectComplexType(MetaModelica::Record value);

      std::unique_ptr<ComplexType> clone() override;

      MetaModelica::Value toNF() const override;

    private:
      InstNode *_constructor;
      InstNode *_destructor;
  };
}

#endif /* COMPLEXTYPE_H */
