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
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
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
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NFRedeclare
" file:        NFRedeclare.mo
  package:     NFRedeclare
  description: Utility functions for redeclare.


"

public import NFInstTypes;
public import NFEnv;
public import NFMod;
public import SCode;

protected import Error;

public type Env = NFEnv.Env;
public type Modifier = NFMod.Modifier;

//public function applyRedeclares
//  input ModTable inMods;
//  input Env inEnv;
//  output Env outEnv;
//protected
//  list<Modifier> redecl;
//algorithm
//  redecl := NFMod.getRedeclaresFromTable(inMods);
//  outEnv := List.fold(redecl, applyRedeclare, inEnv);
//end applyRedeclares;
//
protected function applyRedeclare
  input Modifier inMod;
  input Env inEnv;
  output Env outEnv;
algorithm
  outEnv := match(inMod, inEnv)
    local
      SCode.Element elem;
      Env env;

    case (NFInstTypes.REDECLARE(element = elem, env = env), _)
      equation
        (env, _) = NFEnv.replaceElement(elem, env, inEnv);
      then
        env;

    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR,
          {"NFRedeclare.applyRedeclare failed on non-redeclare modifier."});
      then
        fail();

  end match;
end applyRedeclare;

annotation(__OpenModelica_Interface="frontend");
end NFRedeclare;
