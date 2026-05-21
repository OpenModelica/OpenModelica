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

encapsulated package AvlTreePathFunction
" file:        AvlTreePathFunction.mo
  package:     AvlTreePathFunction
  description: AVL tree for managing paths to functions"

import Absyn;
import BaseAvlTree;
import DAE;

protected import AbsynUtil;
public

extends BaseAvlTree;
redeclare type Key = Absyn.Path;
redeclare type Value = Option<DAE.Function>;
redeclare function extends keyStr
algorithm
  outString := AbsynUtil.pathString(inKey);
end keyStr;
redeclare function extends valueStr
algorithm
  outString := match inValue
    local
      Absyn.Path path;
    case SOME(DAE.FUNCTION(path=path)) then AbsynUtil.pathString(path);
    case SOME(DAE.RECORD_CONSTRUCTOR(path=path)) then AbsynUtil.pathString(path);
    case SOME(DAE.RECORD_CONSTRUCTOR(path=path)) then "<SOME_FUNCTION>";
    else "<NO_FUNCTION>";
  end match;
end valueStr;
redeclare function extends keyCompare
algorithm
  outResult := AbsynUtil.pathCompareNoQual(inKey1,inKey2);
end keyCompare;

redeclare function addConflictDefault = addConflictReplace;

annotation(__OpenModelica_Interface="frontend");
end AvlTreePathFunction;
