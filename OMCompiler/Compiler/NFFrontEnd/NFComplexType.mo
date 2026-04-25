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

encapsulated uniontype NFComplexType
  import NFInstNode.InstNode;
  import Record = NFRecord;
  import UnorderedMap;

protected
  import ComplexType = NFComplexType;

public
  record CLASS end CLASS;

  record EXTENDS_TYPE
    "Used for long class declarations extending from a type, e.g.:
       type SomeType
         extends Real;
       end SomeType;"
    InstNode baseClass;
  end EXTENDS_TYPE;

  record CONNECTOR
    list<InstNode> potentials;
    list<InstNode> flows;
    list<InstNode> streams;
  end CONNECTOR;

  record EXPANDABLE_CONNECTOR
    list<InstNode> potentiallyPresents;
    list<InstNode> expandableConnectors;
  end EXPANDABLE_CONNECTOR;

  record RECORD
    InstNode constructor;
    array<Record.Field> fields;
    UnorderedMap<String, Integer> indexMap;
  end RECORD;

  record EXTERNAL_OBJECT
    InstNode constructor;
    InstNode destructor;
  end EXTERNAL_OBJECT;

annotation(__OpenModelica_Interface="frontend");
end NFComplexType;
