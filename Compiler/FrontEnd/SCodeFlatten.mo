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

public import Absyn;
public import SCode;
public import SCodeDependency;
public import SCodeFlattenImports;
public import SCodeFlattenExtends;
public import SCodeFlattenRedeclare;

protected import Debug;
protected import RTOpts;
protected import SCodeEnv;
protected import System;
protected import Util;

protected type Env = SCodeEnv.Env;

public function flattenProgram
  "Flattens the last class in a program."
  input SCode.Program inProgram;
  output SCode.Program outProgram;
protected
  Absyn.Path cls_path;
algorithm
  cls_path := getLastClassNameInProgram(inProgram);
  outProgram := flattenClassInProgram(cls_path, inProgram);
end flattenProgram;

protected function getLastClassNameInProgram
  "Returns the name of the last class in the program."
  input SCode.Program inProgram;
  output Absyn.Path outClassName;
protected
  SCode.Program prog;
  String name;
algorithm
  prog := listReverse(inProgram);
  SCode.CLASS(name = name) := Util.listSelectFirst(prog, isClass);
  outClassName := Absyn.IDENT(name);
end getLastClassNameInProgram;

protected function isClass
  "Checks if the given SCode.Class is a class, i.e. not a function."
  input SCode.Class inClass;
  output Boolean outIsClass;
algorithm
  outIsClass := match(inClass)
    case SCode.CLASS(restriction = SCode.R_FUNCTION()) then false;
    case SCode.CLASS(restriction = SCode.R_EXT_FUNCTION()) then false;
    else then true;
  end match;
end isClass;

public function flattenClass
  "Flattens a single class."
  input SCode.Class inClass;
  output SCode.Class outClass;
algorithm
  {outClass} := flattenProgram({inClass});
end flattenClass;

public function flattenClassInProgram
  "Flattens a specific class in a program."
  input Absyn.Path inClassName;
  input SCode.Program inProgram;
  output SCode.Program outProgram;
protected
  Env env;
  SCode.Program prog;
algorithm
  outProgram := matchcontinue(inClassName, inProgram)
    local
      Env env;
      SCode.Program prog;

    case (_, _)
      equation
        false = RTOpts.debugFlag("scodeFlatten");
      then
        inProgram;

    case (_, prog)
      equation
        true = RTOpts.debugFlag("scodeFlatten");
        //System.startTimer();

        env = SCodeEnv.buildInitialEnv();
        env = SCodeEnv.extendEnvWithClasses(prog, env);
        env = SCodeEnv.insertClassExtendsIntoEnv(env);

        (prog, env) = SCodeDependency.analyse(inClassName, env, prog);
        prog = SCodeFlattenImports.flattenProgram(prog, env);
        prog = SCodeFlattenExtends.flattenProgram(prog, env);
        prog = SCodeFlattenRedeclare.flattenProgram(prog, env);

        //System.stopTimer();
        //Debug.traceln("SCodeFlatten.flattenClassInProgram took " +& 
        //  realString(System.getTimerIntervalTime()) +& " seconds");
      then
        prog;

    else
      equation
        Debug.fprintln("failtrace", "SCodeFlatten.flattenClassInProgram failed on " +&
          Absyn.pathString(inClassName));
      then
        fail();

  end matchcontinue;
end flattenClassInProgram;

end SCodeFlatten;
