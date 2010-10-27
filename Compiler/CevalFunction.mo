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

package CevalFunction
" file:         CevalFunction.mo
  package:      CevalFunction
  description:  This module constant evaluates DAE.Function objects, i.e.
  modelica functions defined by the user.
  "

public import Absyn;
public import DAE;
public import Env;
public import Values;

protected import DAEDump;
protected import Debug;
protected import RTOpts;
protected import Types;

public function evaluate
  input Env.Env inEnv;
  input DAE.Function inFunction;
  input list<Values.Value> inFunctionArguments;
  output Values.Value outResult;
algorithm
  outResult := matchcontinue(inEnv, inFunction, inFunctionArguments)
    local
      Absyn.Path p;
      DAE.FunctionDefinition func;
      DAE.Type ty;
      Values.Value result;
    case (_, DAE.FUNCTION(
        path = p,
        functions = func :: _,
        type_ = ty,
        partialPrefix = false), _)
      equation
        result = evaluateFunction(inEnv, func, ty, inFunctionArguments);
      then
        result;
    case (_, _, _)
      equation
        true = RTOpts.debugFlag("failtrace");
        print("- CevalFunction.evaluate failed for:\n");
        print(DAEDump.dumpFunctionStr(inFunction));
      then
        fail();
  end matchcontinue;
end evaluate;

protected function evaluateFunction
  input Env.Env inEnv;
  input DAE.FunctionDefinition inFunc;
  input DAE.Type inFuncType;
  input list<Values.Value> inFuncArgs;
  output Values.Value outResult;
algorithm
  outResult := matchcontinue(inEnv, inFunc, inFuncType, inFuncArgs)
    case (_, DAE.FUNCTION_DEF(body = body), _, _)
      local
        list<DAE.Element> body;
      equation
      then
        fail();
    case (_, _, _, _)
      equation
        Debug.fprintln("failtrace", "- CevalFunction.evaluateFunction failed.\n");
      then
        fail();
  end matchcontinue;
end evaluateFunction;

end CevalFunction;
