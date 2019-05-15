/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC License conditions for more details.
 *
 */

encapsulated package ExpressionSimplifyTypes
" file:        ExpressionSimplifyTypes.mo
  package:     ExpressionSimplifyTypes
  description: ExpressionSimplifyTypes


  This file contains types for the module ExpressionSimplify"

import DAE;
import SCode;

uniontype Evaluate "The expression should be evaluated to a literal value; return an error if this fails"
  record NO_EVAL end NO_EVAL;
  record DO_EVAL end DO_EVAL;
end Evaluate;

type SymbolTable = Integer /* TODO: Make replaceable type or specialized package for bootstrapping */;

type SymbolTableInterface = tuple<SymbolTableLookupValue,SymbolTableLookupVariability,SymbolTableAddScope,SymbolTableRemoveScope>;

partial function SymbolTableLookupValue
  input SymbolTable st;
  input DAE.ComponentRef cr;
  output DAE.Exp exp;
end SymbolTableLookupValue;

partial function SymbolTableLookupVariability
  input SymbolTable st;
  input DAE.ComponentRef cr;
  output SCode.Variability var;
end SymbolTableLookupVariability;

partial function SymbolTableAddScope
  input SymbolTable st;
  input DAE.ComponentRef cr;
  input DAE.Exp exp;
  output SymbolTable ost;
end SymbolTableAddScope;

partial function SymbolTableRemoveScope
  input SymbolTable st;
  output SymbolTable ost;
end SymbolTableRemoveScope;

type Options = tuple<Option<tuple<SymbolTable,SymbolTableInterface>>,Evaluate> "I am a stupid tuple because MM does not like type variables in records";

uniontype IntOp
  record MULOP end MULOP;
  record DIVOP end DIVOP;
  record ADDOP end ADDOP;
  record SUBOP end SUBOP;
  record POWOP end POWOP;
end IntOp;

constant Options optionSimplifyOnly = (NONE(),NO_EVAL());

annotation(__OpenModelica_Interface="frontend");
end ExpressionSimplifyTypes;
