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

encapsulated package NFLookupTree
public
  uniontype Entry
    record CLASS
      Integer index;
    end CLASS;

    record COMPONENT
      Integer index;
    end COMPONENT;

    record IMPORT
      Integer index;
    end IMPORT;

    function index
      input Entry entry;
      output Integer index;
     algorithm
       index := match entry
         case CLASS() then entry.index;
         case COMPONENT() then entry.index;
         case IMPORT() then entry.index;
       end match;
    end index;

    function isEqual
      input Entry entry1;
      input Entry entry2;
      output Boolean isEqual = index(entry1) == index(entry2);
    end isEqual;

    function isImport
      input Entry entry;
      output Boolean isImport;
    algorithm
      isImport := match entry
        case IMPORT() then true;
        else false;
      end match;
    end isImport;
  end Entry;

public
import BaseAvlTree;
extends BaseAvlTree(redeclare type Key = String,
                    redeclare type Value = Entry);

  redeclare function extends keyStr
  algorithm
    outString := inKey;
  end keyStr;

  redeclare function extends valueStr
  algorithm
    outString := match inValue
      case Entry.CLASS() then "class " + String(inValue.index);
      case Entry.COMPONENT() then "comp " + String(inValue.index);
    end match;
  end valueStr;

  redeclare function extends keyCompare
  algorithm
    outResult := stringCompare(inKey1, inKey2);
  end keyCompare;

  annotation(__OpenModelica_Interface="util");
end NFLookupTree;
