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

encapsulated package SCodeFlatten
" file:        SCodeFlatten.mo
  package:     SCodeFlatten
  description: SCode flattening

  RCS: $Id$

  This module flattens the SCode representation by removing all extends, imports
  and redeclares, and fully qualifying class names.
"

public import SCode;
public import SCodeFlattenImports;
public import SCodeFlattenExtends;
public import SCodeFlattenRedeclare;

protected import SCodeEnv;

protected type Env = SCodeEnv.Env;

public function flattenProgram
  input SCode.Program inProgram;
  output SCode.Program outProgram;
protected
  Env env;
algorithm
  //System.startTimer();
  env := SCodeEnv.newEnvironment(NONE());
  env := SCodeEnv.buildInitialEnv();
  env := SCodeEnv.extendEnvWithClasses(inProgram, env);
  env := SCodeEnv.insertClassExtendsIntoEnv(env);
  
  outProgram := SCodeFlattenImports.flattenProgram(inProgram, env);
  outProgram := SCodeFlattenExtends.flattenProgram(outProgram, env);
  outProgram := SCodeFlattenRedeclare.flattenProgram(outProgram, env);
  //System.stopTimer();
  //print("flatten took " +& realString(System.getTimerIntervalTime()) +& 
  //  " seconds\n");
end flattenProgram;

public function flattenClass
  input SCode.Class inClass;
  output SCode.Class outClass;
algorithm
  outClass := matchcontinue(inClass)
    local
      SCode.Class cls;

    case _ then inClass;

    case _
      equation
        {cls} = flattenProgram({inClass});
      then
        cls;

  end matchcontinue;
end flattenClass;

end SCodeFlatten;
