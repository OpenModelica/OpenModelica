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

encapsulated package FFI
  import Expression = NFExpression;
  import Type = NFType;

  type ArgSpec = enumeration(
    INPUT,
    OUTPUT,
    LOCAL
  );

  function callFunction
    "Calls the function identified by the given handle (from
     System.lookupFunction) using the given array of arguments and the type of
     the return value. Each argument should also have a corresponding specifier
     in the specs array that tells whether the variable is an input, output, or
     local variable. The return value of the called function is returned, along
     with a list of any output values of the function."
    input Integer fnHandle;
    input array<Expression> args;
    input array<ArgSpec> specs;
    input Type returnType;
    output Expression returnValue;
    output list<Expression> outputArgs;
    external "C" returnValue = FFI_callFunction(fnHandle, args, specs, returnType, outputArgs)
    annotation(Library = "omcruntime");
  end callFunction;

annotation(__OpenModelica_Interface="frontend");
end FFI;
