/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package TypeCheck
" file:        TypeCheck.mo
  package:     TypeCheck
  description: SCodeInst type checking.

  RCS: $Id: TypeCheck.mo 12209 2012-06-26 14:57:43Z sjoelund.se $

  Functions used by SCodeInst for type checking and type conversion where needed.
"

public import Absyn;
public import DAE;
public import HashTablePathToFunction;
public import InstSymbolTable;
public import InstTypes;
public import SCode;

protected import BaseHashTable;
protected import ComponentReference;
protected import Connect;
protected import DAEUtil;
protected import Error;
protected import Expression;
protected import ExpressionDump;
protected import ExpressionSimplify;
protected import InstUtil;
protected import List;
protected import Types;
protected import Util;

public type Element = InstTypes.Element;
public type Equation = InstTypes.Equation;
public type Class = InstTypes.Class;
public type DaePrefixes = InstTypes.DaePrefixes;
public type Dimension = InstTypes.Dimension;
public type Binding = InstTypes.Binding;
public type Component = InstTypes.Component;
public type Modifier = InstTypes.Modifier;
public type ParamType = InstTypes.ParamType;
public type Prefixes = InstTypes.Prefixes;
public type Prefix = InstTypes.Prefix;
public type Statement = InstTypes.Statement;
public type SymbolTable = InstSymbolTable.SymbolTable;

public function check
  input Class inClass;
  input SymbolTable inSymbolTable;
  output Class outClass;
  output SymbolTable outSymbolTable;
algorithm
  (outClass, outSymbolTable) := match(inClass, inSymbolTable)
    local
      list<Element> comps;
      list<Equation> eq, ieq;
      list<list<Statement>> al, ial;
      SymbolTable st;

    case (_, st) then (inClass, st);
  end match;
end check;

end TypeCheck;
