/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

package BackendVarTransform
" file:	       BackendVarTransform_stub.mo
  package:     BackendVarTransform
  description: BackendVarTransform is only a stub.

  RCS: $Id: BackendVarTransform_stub.mo 3772 2008-12-13 16:04:48Z adrpo $
  
  This file is a stub!"

public import DAELow;
public import Exp;
public import VarTransform; 
protected import Util;

public function replaceEquations 
"function: replaceEquations
  This function takes a list of equations ana a set of variable 
  replacements and applies the replacements on all equations.
  The function returns the updated list of equations"
  input list<DAELow.Equation> inDAELowEquationLst;
  input VarTransform.VariableReplacements inVariableReplacements;
  output list<DAELow.Equation> outDAELowEquationLst;
algorithm
  outDAELowEquationLst := {};
end replaceEquations;
  
protected function replaceWhenEquation "Replaces variables in a when equation"
	input DAELow.WhenEquation whenEqn;
  input VarTransform.VariableReplacements repl;
  output DAELow.WhenEquation outWhenEqn;
algorithm
  outWhenEqn := whenEqn;
end replaceWhenEquation;

public function replaceMultiDimEquations "function: replaceMultiDimEquations
 
  This function takes a list of equations ana a set of variable replacements
  and applies the replacements on all array equations.
  The function returns the updated list of array equations
"
  input list<DAELow.MultiDimEquation> inDAELowEquationLst;
  input VarTransform.VariableReplacements inVariableReplacements;
  output list<DAELow.MultiDimEquation> outDAELowEquationLst;
algorithm 
  outDAELowEquationLst := {};
end replaceMultiDimEquations;

end BackendVarTransform;